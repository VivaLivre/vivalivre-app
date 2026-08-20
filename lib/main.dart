import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:viva_livre_app/features/auth/presentation/auth_bloc.dart';
import 'package:viva_livre_app/features/health/presentation/health_bloc.dart';
import 'package:viva_livre_app/features/health/data/repositories/health_repository.dart';
import 'package:viva_livre_app/features/health/domain/repositories/i_health_repository.dart';
import 'package:viva_livre_app/features/map/presentation/bloc/map_bloc.dart';
import 'package:viva_livre_app/features/map/data/repositories/bathroom_repository_impl.dart';
import 'package:viva_livre_app/features/ratings/presentation/bloc/rating_bloc.dart';
import 'package:viva_livre_app/features/ratings/data/repositories/rating_repository.dart';
import 'package:viva_livre_app/features/ratings/data/datasources/rating_remote_datasource.dart';
import 'package:viva_livre_app/app.dart';
import 'package:viva_livre_app/core/api/api_client.dart';
import 'package:viva_livre_app/features/auth/data/repositories/auth_repository.dart';
import 'package:viva_livre_app/features/auth/data/repositories/onboarding_repository.dart';
import 'package:viva_livre_app/features/profile/data/repositories/profile_repository.dart';
import 'package:viva_livre_app/features/crowdsource/data/repositories/crowdsource_repository_impl.dart';
import 'package:viva_livre_app/features/crowdsource/presentation/bloc/crowdsource_bloc.dart';
import 'package:viva_livre_app/features/map/domain/repositories/i_bathroom_repository.dart';
import 'package:viva_livre_app/core/theme/theme_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);

  // Initialize Core Services
  final apiClient = ApiClient();
  final authRepository = AuthRepository(apiClient: apiClient);
  final profileRepository = ProfileRepository(apiClient: apiClient);
  final onboardingRepository = OnboardingRepository();

  // Repositories
  final healthRepository = HealthRepositoryImpl(apiClient: apiClient);
  final bathroomRepository = BathroomRepositoryImpl(apiClient: apiClient);
  final ratingRemoteDataSource = RatingRemoteDataSourceImpl(apiClient: apiClient);
  final ratingRepository = RatingRepositoryImpl(remoteDataSource: ratingRemoteDataSource);
  final crowdsourceRepository = CrowdsourceRepositoryImpl(dio: apiClient.dio);

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: profileRepository),
        RepositoryProvider.value(value: onboardingRepository),
        RepositoryProvider<IBathroomRepository>.value(value: bathroomRepository),
        RepositoryProvider<IHealthRepository>.value(value: healthRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (_) => AuthBloc(
              authRepository: authRepository,
              onboardingRepository: onboardingRepository,
            ),
          ),
          BlocProvider<HealthBloc>(
            create: (_) => HealthBloc(healthRepository: healthRepository),
          ),
          BlocProvider<MapBloc>(
            create: (_) => MapBloc(repository: bathroomRepository),
          ),
          BlocProvider<RatingBloc>(
            create: (_) => RatingBloc(ratingRepository: ratingRepository),
          ),
          BlocProvider<CrowdsourceBloc>(
            create: (_) => CrowdsourceBloc(repository: crowdsourceRepository),
          ),
          BlocProvider<ThemeCubit>(
            create: (_) => ThemeCubit(),
          ),
        ],
        child: const App(),
      ),
    ),
  );
}
