import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:viva_livre_app/features/auth/presentation/auth_bloc.dart';
import 'package:viva_livre_app/features/health/presentation/health_bloc.dart';
import 'package:viva_livre_app/features/health/data/repositories/health_repository.dart';
import 'package:viva_livre_app/features/map/presentation/bloc/map_bloc.dart';
import 'package:viva_livre_app/features/map/data/repositories/bathroom_repository_impl.dart';
import 'package:viva_livre_app/app.dart';
import 'package:viva_livre_app/core/api/api_client.dart';
import 'package:viva_livre_app/features/auth/data/repositories/auth_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);

  // Initialize Core Services
  final apiClient = ApiClient();
  final authRepository = AuthRepository(apiClient: apiClient);

  // Repositories
  final healthRepository = HealthRepositoryImpl(apiClient: apiClient);
  final bathroomRepository = BathroomRepositoryImpl(apiClient: apiClient);

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(authRepository: authRepository)..add(AuthAppStarted()),
        ),
        BlocProvider<HealthBloc>(
          create: (_) => HealthBloc(healthRepository: healthRepository),
        ),
        BlocProvider<MapBloc>(
          create: (_) => MapBloc(repository: bathroomRepository)..add(const RequestGpsLocation()),
        ),
      ],
      child: const App(),
    ),
  );
}
