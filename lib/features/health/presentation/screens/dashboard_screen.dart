import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../wearable/domain/wearable_service.dart';
import '../../../wearable/presentation/bloc/wearable_bloc.dart';
import '../../../wearable/presentation/bloc/wearable_event.dart';
import '../../../wearable/presentation/bloc/wearable_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Dashboard'),
        actions: [
          // Existing Bluetooth Toggle
          BlocBuilder<WearableBloc, WearableState>(
            builder: (context, state) {
              final isConnected = state.connectionState == DeviceConnectionState.connected;
              return IconButton(
                icon: Icon(isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled),
                onPressed: () {
                  if (isConnected) {
                    context.read<WearableBloc>().add(DisconnectDevice());
                  } else {
                    context.read<WearableBloc>().add(ConnectDevice('FITRING-001'));
                  }
                },
              );
            },
          ),
          // 2. New Logout Button
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              // This single event clears the token and triggers the root redirect!
              context.read<AuthBloc>().add(LogoutRequested());
            },
          ),
        ],
      ),
      body: BlocBuilder<WearableBloc, WearableState>(
        builder: (context, state) {
          final data = state.latestData;

          return Column(
            children: [
              _ConnectionStatusBar(state: state.connectionState),
              Expanded(
                child: data == null
                    ? const Center(child: Text('Waiting for device data...'))
                    : GridView.count(
                  crossAxisCount: 2,
                  padding: const EdgeInsets.all(16),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _MetricCard(
                      title: 'Heart Rate',
                      value: '${data.heartRate}',
                      unit: 'BPM',
                      icon: Icons.favorite,
                      color: Colors.red,
                    ),
                    _MetricCard(
                      title: 'SpO2',
                      value: '${data.spo2}',
                      unit: '%',
                      icon: Icons.water_drop,
                      color: Colors.blue,
                    ),
                    _MetricCard(
                      title: 'Steps',
                      value: '${data.steps}',
                      unit: 'steps',
                      icon: Icons.directions_walk,
                      color: Colors.orange,
                    ),
                    _MetricCard(
                      title: 'Battery',
                      value: '${data.batteryLevel}',
                      unit: '%',
                      icon: Icons.battery_charging_full,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ConnectionStatusBar extends StatelessWidget {
  final DeviceConnectionState state;

  const _ConnectionStatusBar({required this.state});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    String text;

    switch (state) {
      case DeviceConnectionState.connected:
        bgColor = Colors.green.shade100;
        text = 'Status: Connected';
        break;
      case DeviceConnectionState.connecting:
      case DeviceConnectionState.reconnecting:
        bgColor = Colors.orange.shade100;
        text = 'Status: Connecting...';
        break;
      case DeviceConnectionState.disconnected:
        bgColor = Colors.grey.shade300;
        text = 'Status: Disconnected';
        break;
      case DeviceConnectionState.failed:
        bgColor = Colors.red.shade100;
        text = 'Status: Connection Failed';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: bgColor,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  TextSpan(
                    text: value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  TextSpan(text: ' $unit'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}