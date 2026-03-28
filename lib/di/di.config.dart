// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart' as _i695;
import 'package:firebase_messaging/firebase_messaging.dart' as _i892;
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as _i163;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../data/api/api.dart' as _i834;
import '../data/repository/auth_repository.dart' as _i79;
import '../data/repository/job_repository.dart' as _i874;
import '../data/services/biometric_service.dart' as _i199;
import '../data/services/fcm_service.dart' as _i894;
import '../presentation/bloc/auth/auth_bloc.dart' as _i543;
import '../presentation/bloc/job/job_cubit.dart' as _i497;
import '../presentation/bloc/job_edit/image_capture_cubit.dart' as _i358;
import '../presentation/bloc/job_edit/upload_batch_cubit.dart' as _i629;
import '../presentation/bloc/job_filter/job_filter_cubit.dart' as _i1005;
import 'di.dart' as _i913;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final dioModule = _$DioModule();
    final notificationsModule = _$NotificationsModule();
    gh.factory<_i358.ImageCaptureCubit>(() => _i358.ImageCaptureCubit());
    gh.factory<_i1005.JobFilterCubit>(() => _i1005.JobFilterCubit());
    gh.lazySingleton<_i199.BiometricService>(() => _i199.BiometricService());
    gh.lazySingleton<_i695.MemCacheStore>(() => dioModule.cacheStore);
    gh.lazySingleton<_i695.CacheOptions>(() => dioModule.cacheOptions);
    gh.lazySingleton<_i163.FlutterLocalNotificationsPlugin>(
      () => notificationsModule.notification,
    );
    gh.lazySingleton<_i892.FirebaseMessaging>(
      () => notificationsModule.firebaseMessaging,
    );
    await gh.lazySingletonAsync<_i913.IndividualAppModule>(() {
      final i = _i913.AppModule(gh<_i163.FlutterLocalNotificationsPlugin>());
      return i.initializePackages().then((_) => i);
    }, preResolve: true);
    gh.lazySingleton<_i361.Dio>(() => dioModule.dio(gh<_i695.CacheOptions>()));
    gh.lazySingleton<_i894.FcmService>(
      () => _i894.FcmService(
        gh<_i892.FirebaseMessaging>(),
        gh<_i163.FlutterLocalNotificationsPlugin>(),
      ),
    );
    gh.lazySingleton<_i834.IApiService>(
      () => _i834.ApiService(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i79.IAuthRepository>(
      () => _i79.AuthRepository(gh<_i834.IApiService>()),
    );
    gh.factory<_i543.AuthBloc>(
      () => _i543.AuthBloc(
        gh<_i79.IAuthRepository>(),
        gh<_i199.BiometricService>(),
        gh<_i894.FcmService>(),
      ),
    );
    gh.lazySingleton<_i874.IJobRepository>(
      () => _i874.JobRepository(gh<_i834.IApiService>()),
    );
    gh.factory<_i497.JobCubit>(
      () => _i497.JobCubit(gh<_i874.IJobRepository>()),
    );
    gh.factory<_i629.UploadBatchCubit>(
      () => _i629.UploadBatchCubit(gh<_i874.IJobRepository>()),
    );
    return this;
  }
}

class _$DioModule extends _i913.DioModule {}

class _$NotificationsModule extends _i913.NotificationsModule {}
