import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/network/api_client.dart';
import 'package:wearable_health_app/features/wearable/domain/wearable_service.dart';

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

  // Fetches historical data from the server and restores the local database
  Future<void> restoreDataFromServer() async {
    try {
      final response = await _apiClient.dio.get('/health/readings');
      final List serverReadings = response.data['readings'];

      if (serverReadings.isEmpty) return;

      // Insert the downloaded records back into SQLite
      for (var reading in serverReadings) {
        final Map<String, dynamic> cleanData = Map<String, dynamic>.from(reading);

        final packet = HealthDataPacket(
          deviceId: cleanData['device_id'] ?? cleanData['deviceId'] ?? 'FITRING-001',
          heartRate: (cleanData['heart_rate'] as num).toInt(),
          spo2: (cleanData['spo2'] as num).toInt(),
          steps: (cleanData['steps'] as num).toInt(),
          batteryLevel: (cleanData['battery_level'] as num).toInt(),
          timestamp: DateTime.parse(cleanData['timestamp']),
        );

        await _dbHelper.insertReading(packet);
      }

      print('Successfully restored ${serverReadings.length} readings from the server.');
    } catch (e) {
      print('Failed to restore data: $e');
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _periodicSyncTimer?.cancel();
  }
}