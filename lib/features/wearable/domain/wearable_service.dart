import 'dart:async';

enum DeviceConnectionState { disconnected, connecting, connected, reconnecting, failed }

class HealthDataPacket {
  final String deviceId;
  final int heartRate;
  final int spo2;
  final int steps;
  final int batteryLevel;
  final DateTime timestamp;

  HealthDataPacket({
    required this.deviceId,
    required this.heartRate,
    required this.spo2,
    required this.steps,
    required this.batteryLevel,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'heartRate': heartRate,
    'spo2': spo2,
    'steps': steps,
    'battery': batteryLevel,
    'timestamp': timestamp.toIso8601String(),
  };
}

abstract class WearableService {
  Stream<DeviceConnectionState> get connectionStateStream;
  Stream<HealthDataPacket> get healthDataStream;
  DeviceConnectionState get currentState;

  Future<void> connect(String deviceId);
  Future<void> disconnect();
  Future<void> retryConnection();
}