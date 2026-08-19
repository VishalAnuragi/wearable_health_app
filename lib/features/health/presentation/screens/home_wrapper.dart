import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Add this import
import '../../domain/sync_manager.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import '../../../shopping/presentation/screens/shop_screen.dart';

class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  int _currentIndex = 0;
  bool _isRestoring = true; // Add a loading state for the initial download

  final List<Widget> _screens = [
    const DashboardScreen(),
    const HistoryScreen(),
    const ShopScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _performInitialSync();
  }

  // Trigger the download when the home screen first loads
  Future<void> _performInitialSync() async {
    final syncManager = context.read<SyncManager>();
    await syncManager.restoreDataFromServer();

    if (mounted) {
      setState(() => _isRestoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading spinner while downloading historical data
    if (_isRestoring) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Restoring health history...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Live'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Shop'),
        ],
      ),
    );
  }
}