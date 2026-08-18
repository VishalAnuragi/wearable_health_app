import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/database/database_helper.dart';
import 'core/network/api_client.dart';
import 'features/auth/data/auth_repository_impl.dart';
import 'features/auth/domain/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/health/domain/sync_manager.dart'; // Add this import
import 'features/health/presentation/screens/dashboard_screen.dart';
import 'features/wearable/data/mock_wearable_service.dart';
import 'features/wearable/domain/wearable_service.dart';
import 'features/wearable/presentation/bloc/wearable_bloc.dart';
import 'features/wearable/presentation/bloc/wearable_event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiClient = ApiClient();
  final databaseHelper = DatabaseHelper();
  final wearableService = MockWearableService();
  final authRepository = AuthRepositoryImpl(apiClient);

  // Initialize the Sync Manager
  final syncManager = SyncManager(apiClient, databaseHelper);

  runApp(MyApp(
    apiClient: apiClient,
    databaseHelper: databaseHelper,
    wearableService: wearableService,
    authRepository: authRepository,
    syncManager: syncManager,
  ));
}

class MyApp extends StatelessWidget {
  final ApiClient apiClient;
  final DatabaseHelper databaseHelper;
  final WearableService wearableService;
  final AuthRepository authRepository;
  final SyncManager syncManager; // Add to constructor

  const MyApp({
    super.key,
    required this.apiClient,
    required this.databaseHelper,
    required this.wearableService,
    required this.authRepository,
    required this.syncManager,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ApiClient>.value(value: apiClient),
        RepositoryProvider<DatabaseHelper>.value(value: databaseHelper),
        RepositoryProvider<WearableService>.value(value: wearableService),
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<SyncManager>.value(value: syncManager), // Provide globally
      ],
      // ... keep the rest of your MultiBlocProvider and MaterialApp exactly the same
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(context.read<AuthRepository>())
              ..add(AppStarted()),
          ),
          BlocProvider<WearableBloc>(
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
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return const DashboardScreen();
              } else if (state is AuthUnauthenticated || state is AuthError) {
                return const LoginScreen();
              }
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            },
          ),
        ),
      ),
    );
  }
}