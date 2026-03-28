import 'dart:async';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'di/di.dart';
import 'data/services/fcm_service.dart';
import 'firebase_options.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    // log('onChange(${bloc.runtimeType}, $change)');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('onError(${bloc.runtimeType}, $error, $stackTrace)');
    super.onError(bloc, error, stackTrace);
  }
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Bootstraps the app with all required pre-configurations.
/// Accepts a [builder] function that constructs the root [Widget].
Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- System UI ---
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // --- Firebase (must come before Hive/HydratedBloc) ---
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // --- Hive ---
  await Hive.initFlutter();

  // --- HydratedBloc storage ---
  final storageDir = await getApplicationDocumentsDirectory();
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: HydratedStorageDirectory(storageDir.path),
  );

  // --- Timezones ---
  tz.initializeTimeZones();

  Bloc.observer = const AppBlocObserver();

  // --- Dependency Injection ---
  await configureDependencies();

  // --- FCM: request permissions & set up foreground display ---
  await getIt<FcmService>().initialize();

  runApp(await builder());
}
