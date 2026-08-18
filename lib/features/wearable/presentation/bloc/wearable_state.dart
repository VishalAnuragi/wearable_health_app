import '../../domain/wearable_service.dart';

class WearableState {
  final DeviceConnectionState connectionState;
  final HealthDataPacket? latestData;
  final String? errorMessage;

  const WearableState({
    this.connectionState = DeviceConnectionState.disconnected,
    this.latestData,
    this.errorMessage,
  });

  WearableState copyWith({
    DeviceConnectionState? connectionState,
    HealthDataPacket? latestData,
    String? errorMessage,
  }) {
    return WearableState(
      connectionState: connectionState ?? this.connectionState,
      latestData: latestData ?? this.latestData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}