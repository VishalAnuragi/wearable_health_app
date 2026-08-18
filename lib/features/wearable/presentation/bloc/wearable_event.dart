import '../../domain/wearable_service.dart';

sealed class WearableEvent {}

class ConnectDevice extends WearableEvent {
  final String deviceId;
  ConnectDevice(this.deviceId);
}

class DisconnectDevice extends WearableEvent {}

class RetryConnection extends WearableEvent {}

// Made public by removing the underscores
class ConnectionStateUpdated extends WearableEvent {
  final DeviceConnectionState state;
  ConnectionStateUpdated(this.state);
}

class HealthDataUpdated extends WearableEvent {
  final HealthDataPacket packet;
  HealthDataUpdated(this.packet);
}