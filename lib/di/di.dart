import 'package:awesome_dio_interceptor/awesome_dio_interceptor.dart';
import 'package:dio/dio.dart' show BaseOptions, Dio;
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:fsm_frontend/data/api/interceptors.dart';
import 'package:fsm_frontend/utils/constants.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'dart:developer';

import 'di.config.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async => getIt.init();

@module
abstract class DioModule {
  @lazySingleton
  MemCacheStore get cacheStore => MemCacheStore();

  @lazySingleton
  CacheOptions get cacheOptions => CacheOptions(
        store: cacheStore,
        policy: CachePolicy.refreshForceCache,
        hitCacheOnErrorCodes: [401, 403],
        maxStale: const Duration(days: 7),
        priority: CachePriority.normal,
      );

  @lazySingleton
  Dio dio(CacheOptions cacheOptions) {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(),
      DioCacheInterceptor(options: cacheOptions),
      if (kDebugMode) ...[
        AwesomeDioInterceptor(),
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          compact: true,
          maxWidth: 90,
        ),
      ]
    ]);

    return dio;
  }
}

@module
abstract class NotificationsModule {
  @lazySingleton
  FlutterLocalNotificationsPlugin get notification =>
      FlutterLocalNotificationsPlugin();

  @lazySingleton
  FirebaseMessaging get firebaseMessaging => FirebaseMessaging.instance;
}

abstract class IndividualAppModule {

  FlutterLocalNotificationsPlugin get notification;

  Future<void> initializePackages() async {
    tz.initializeTimeZones();

    //notifications
    await _initializeNotification(notification);
  }
}

FutureOr<void> _initializeNotification(
  FlutterLocalNotificationsPlugin notification,
) async {
  await notification.initialize(
    InitializationSettings(
      android: androidSettings,
      iOS: initializationSettingsIOS,
    ),
  );
}

@LazySingleton(as: IndividualAppModule)
class AppModule extends IndividualAppModule {
  AppModule(this.notification);

  @override
  final FlutterLocalNotificationsPlugin notification;

  @override
  @PostConstruct(preResolve: true)
  Future<void> initializePackages() async {
    try {
      log('Initializing app packages');
      await super.initializePackages();
    } catch (e, s) {
      log('Error initializing packages: ', error: e, stackTrace: s);
    }
  }
}

const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

// Ios initialization
const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings();
