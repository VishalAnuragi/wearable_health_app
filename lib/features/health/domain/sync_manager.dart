import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/network/api_client.dart';

class SyncManager {
  final ApiClient _apiClient;
  final DatabaseHelper _dbHelper;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _periodicSyncTimer;
  bool _isSyncing = false;

  SyncManager(this._apiClient, this._dbHelper) {
    _init();
  }

  void _init() {
    // 1. Listen for network changes (Offline to Online recovery)
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi)) {
        syncData();
      }
    });

    // 2. Fallback periodic sync (e.g., every 1 minute) just in case the stream misses a beat
    _periodicSyncTimer = Timer.periodic(const Duration(minutes: 1), (_) => syncData());
  }

  Future<void> syncData() async {
    // Prevent overlapping sync operations
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      // Fetch up to 100 pending records from SQLite
      final unsynced = await _dbHelper.getUnsyncedReadings(limit: 100);

      if (unsynced.isEmpty) {
        _isSyncing = false;
        return;
      }

      // Send the batch payload to your Node.js backend
      final response = await _apiClient.dio.post(
        '/health/readings',
        data: {'readings': unsynced},
      );

      // If the backend accepts the payload (200 OK or 201 Created)
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Extract the SQLite IDs of the records we just successfully uploaded
        final syncedIds = unsynced.map((e) => e['id'] as int).toList();

        // Mark them as synced in the local database so they aren't sent again
        await _dbHelper.markAsSynced(syncedIds);
        print('✅ Sync Engine: Successfully pushed ${syncedIds.length} records.');

        // If we hit the limit of 100, there might be more pending. Call recursively.
        if (unsynced.length == 100) {
          _isSyncing = false;
          await syncData();
        }
      }
    } on DioException catch (e) {
      print('❌ Sync Engine Network Error: ${e.message}');
      // Leave is_synced = 0 in SQLite. It will retry on the next connectivity event.
    } catch (e) {
      print('❌ Sync Engine Error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _periodicSyncTimer?.cancel();
  }
}