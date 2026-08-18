import 'dart:async';
import 'dart:math';
import '../domain/wearable_service.dart';

class MockWearableService implements WearableService {
  final _stateController = StreamController<DeviceConnectionState>.broadcast();
  final _dataController = StreamController<HealthDataPacket>.broadcast();

  DeviceConnectionState _currentState = DeviceConnectionState.disconnected;
  Timer? _readingTimer;
  int _cumulativeSteps = 6420;
  int _batteryLevel = 72;
  String _activeDeviceId = 'FITRING-001';

  @override
  Stream<DeviceConnectionState> get connectionStateStream => _stateController.stream;

  @override
  Stream<HealthDataPacket> get healthDataStream => _dataController.stream;

  @override
  DeviceConnectionState get currentState => _currentState;

  void _updateState(DeviceConnectionState state) {
    _currentState = state;
    _stateController.add(state);
  }

  @override
  Future<void> connect(String deviceId) async {
    _activeDeviceId = deviceId;
    _updateState(DeviceConnectionState.connecting);

    await Future.delayed(const Duration(milliseconds: 1200));
    _updateState(DeviceConnectionState.connected);
    _startDataEmission();
  }

  void _startDataEmission() {
    _readingTimer?.cancel();
    final random = Random();

    _readingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentState != DeviceConnectionState.connected) return;

      _cumulativeSteps += random.nextInt(5);
      final packet = HealthDataPacket(
        deviceId: _activeDeviceId,
        heartRate: 70 + random.nextInt(18), // 70-88 BPM [cite: 36]
        spo2: 96 + random.nextInt(4),       // 96-99% [cite: 38]
        steps: _cumulativeSteps,            // [cite: 40]
        batteryLevel: _batteryLevel,        // [cite: 42]
        timestamp: DateTime.now().toUtc(),
      );

      _dataController.add(packet);
    });
  }

  @override
  Future<void> disconnect() async {
    _readingTimer?.cancel();
    _updateState(DeviceConnectionState.disconnected);
  }

  @override
  Future<void> retryConnection() async {
    _updateState(DeviceConnectionState.reconnecting);
    await Future.delayed(const Duration(seconds: 2));
    _updateState(DeviceConnectionState.connected);
    _startDataEmission();
  }

  void dispose() {
    _readingTimer?.cancel();
    _stateController.close();
    _dataController.close();
  }
}