import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/database/database_helper.dart'; // Import the db helper
import 'core/network/api_client.dart';
import 'features/health/presentation/screens/dashboard_screen.dart';
import 'features/wearable/data/mock_wearable_service.dart';
import 'features/wearable/domain/wearable_service.dart';
import 'features/wearable/presentation/bloc/wearable_bloc.dart';
import 'features/wearable/presentation/bloc/wearable_event.dart';

void main() async {
  // Ensure bindings are initialized before accessing native channels (like SQLite)
  WidgetsFlutterBinding.ensureInitialized();

  final apiClient = ApiClient();
  final databaseHelper = DatabaseHelper(); // Initialize the DB
  final wearableService = MockWearableService();

  runApp(MyApp(
      apiClient: apiClient,
      databaseHelper: databaseHelper,
      wearableService: wearableService
  ));
}

class MyApp extends StatelessWidget {
  final ApiClient apiClient;
  final DatabaseHelper databaseHelper;
  final WearableService wearableService;

  const MyApp({
    super.key,
    required this.apiClient,
    required this.databaseHelper,
    required this.wearableService
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ApiClient>.value(value: apiClient),
        RepositoryProvider<DatabaseHelper>.value(value: databaseHelper),
        RepositoryProvider<WearableService>.value(value: wearableService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<WearableBloc>(
            // Pass the databaseHelper into the WearableBloc
            create: (context) => WearableBloc(
              context.read<WearableService>(),
              context.read<DatabaseHelper>(),
            )..add(ConnectDevice('FITRING-001')),
          ),
        ],
        child: MaterialApp(
          title: 'Wearable Health & Shop',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          ),
          home: const DashboardScreen(),
        ),
      ),
    );
  }
}