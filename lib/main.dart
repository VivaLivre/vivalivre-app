import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:viva_livre_app/features/auth/presentation/auth_bloc.dart';
import 'package:viva_livre_app/features/health/presentation/health_bloc.dart';
import 'package:viva_livre_app/features/health/data/repositories/health_repository.dart';
import 'package:viva_livre_app/app.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  await Firebase.initializeApp();

  final firebaseAuth = FirebaseAuth.instance;
  final healthRepository = HealthRepository();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(firebaseAuth: firebaseAuth)..add(AuthAppStarted()),
        ),
        BlocProvider<HealthBloc>(
          create: (_) => HealthBloc(healthRepository: healthRepository),
        ),
      ],
      child: App(firebaseAuth: firebaseAuth),
    ),
  );
}
