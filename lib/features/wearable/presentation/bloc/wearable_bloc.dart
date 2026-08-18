import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/database/database_helper.dart'; // Add this import
import '../../domain/wearable_service.dart';
import 'wearable_event.dart';
import 'wearable_state.dart';

class WearableBloc extends Bloc<WearableEvent, WearableState> {
  final WearableService _wearableService;
  final DatabaseHelper _databaseHelper; // Add database dependency
  StreamSubscription<DeviceConnectionState>? _connectionSubscription;
  StreamSubscription<HealthDataPacket>? _dataSubscription;

  // Require the DatabaseHelper in the constructor
  WearableBloc(this._wearableService, this._databaseHelper) : super(const WearableState()) {
    on<ConnectDevice>(_onConnectDevice);
    on<DisconnectDevice>(_onDisconnectDevice);
    on<RetryConnection>(_onRetryConnection);
    on<ConnectionStateUpdated>(_onConnectionStateUpdated);
    on<HealthDataUpdated>(_onHealthDataUpdated);

    _connectionSubscription = _wearableService.connectionStateStream.listen(
          (state) => add(ConnectionStateUpdated(state)),
    );

    _dataSubscription = _wearableService.healthDataStream.listen(
          (packet) => add(HealthDataUpdated(packet)),
    );
  }

  Future<void> _onConnectDevice(ConnectDevice event, Emitter<WearableState> emit) async {
    try {
      await _wearableService.connect(event.deviceId);
    } catch (e) {
      emit(state.copyWith(
        connectionState: DeviceConnectionState.failed,
        errorMessage: 'Failed to connect: ${e.toString()}',
      ));
    }
  }

  Future<void> _onDisconnectDevice(DisconnectDevice event, Emitter<WearableState> emit) async {
    await _wearableService.disconnect();
  }

  Future<void> _onRetryConnection(RetryConnection event, Emitter<WearableState> emit) async {
    try {
      await _wearableService.retryConnection();
    } catch (e) {
      emit(state.copyWith(
        connectionState: DeviceConnectionState.failed,
        errorMessage: 'Retry failed: ${e.toString()}',
      ));
    }
  }

  void _onConnectionStateUpdated(ConnectionStateUpdated event, Emitter<WearableState> emit) {
    emit(state.copyWith(
      connectionState: event.state,
      errorMessage: event.state == DeviceConnectionState.connected ? null : state.errorMessage,
    ));
  }

  void _onHealthDataUpdated(HealthDataUpdated event, Emitter<WearableState> emit) async {
    // 1. Emit the state update so the UI updates instantly
    emit(state.copyWith(latestData: event.packet));

    // 2. Asynchronously save the packet to SQLite for offline storage
    await _databaseHelper.insertReading(event.packet);
  }

  @override
  Future<void> close() {
    _connectionSubscription?.cancel();
    _dataSubscription?.cancel();
    return super.close();
  }
}