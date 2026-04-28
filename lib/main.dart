import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:viva_livre_app/features/auth/presentation/auth_bloc.dart';
import 'package:viva_livre_app/features/health/presentation/health_bloc.dart';
import 'package:viva_livre_app/features/health/data/repositories/health_repository.dart';
import 'package:viva_livre_app/features/map/presentation/bloc/map_bloc.dart';
import 'package:viva_livre_app/features/map/data/repositories/bathroom_repository_impl.dart';
import 'package:viva_livre_app/app.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  await Firebase.initializeApp();

  final firebaseAuth = FirebaseAuth.instance;
  // HealthRepositoryImpl: implementação real com Firestore.
  // IHealthRepository: o BLoC depende apenas da interface, nunca da implementação.
  final healthRepository = HealthRepositoryImpl();
  // O repositório é criado uma única vez e injetado no MapBloc via construtor.
  // Jamais use 'late' para dependências de ciclo de vida longo.
  final bathroomRepository = BathroomRepositoryImpl();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(firebaseAuth: firebaseAuth)..add(AuthAppStarted()),
        ),
        BlocProvider<HealthBloc>(
          // WatchHealthEntries será disparado dentro do initState da HealthPage
          // após o utilizador estar autenticado e o uid disponível.
          create: (_) => HealthBloc(healthRepository: healthRepository),
        ),
        // MapBloc recebe o repositório via injeção de dependência no construtor.
        // Isso garante que _repository seja sempre 'final' e nunca 'late'.
        BlocProvider<MapBloc>(
          create: (_) => MapBloc(repository: bathroomRepository)..add(const RequestGpsLocation()),
        ),
      ],
      child: App(firebaseAuth: firebaseAuth),
    ),
  );
}
