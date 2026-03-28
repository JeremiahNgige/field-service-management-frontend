import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sizer/sizer.dart';

import 'di/di.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/job/job_cubit.dart';
import 'presentation/bloc/job_filter/job_filter_cubit.dart';
import 'presentation/router/app_router.dart';
import 'theme/app_theme.dart';
import 'data/services/fcm_service.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      getIt<FcmService>().setupInteractions((jobId, targetUserId) {
        final authState = getIt<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          final currentUserId = authState.user?.userId.toString();
          
          // Execute routing STRICTLY if the notification belongs to the actual phone driver safely.
          if (targetUserId.isEmpty || currentUserId == targetUserId) {
             _appRouter.push(JobDetailRoute(jobId: jobId));
          } else {
             debugPrint('[FCM DeepLink] Push Ignored -> Malicious/Stale tap. Intended: $targetUserId, Active: $currentUserId');
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => getIt<AuthBloc>(),
        ),
        BlocProvider<JobCubit>(
          create: (_) => getIt<JobCubit>(),
        ),
        BlocProvider<JobFilterCubit>(
          create: (_) => getIt<JobFilterCubit>(),
        ),
      ],
      child: Sizer(
        builder: (context, orientation, deviceType) {
          return BlocListener<AuthBloc, AuthState>(
            // ── Root-level session expiry handler ──────────────────────────
            // Listens globally so any screen deep in the stack is covered.
            listenWhen: (_, current) =>
                current is AuthSessionExpired ||
                current is AuthUnauthenticated,
            listener: (context, state) {
              if (state is AuthSessionExpired) {
                // Session expired involuntarily — navigate to login with banner.
                _appRouter.replaceAll([LoginRoute(expired: true)]);
              } else if (state is AuthUnauthenticated) {
                // Explicit logout — go to login without banner.
                _appRouter.replaceAll([LoginRoute()]);
              }
            },
            child: MaterialApp.router(
              title: 'FSM Field Service',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: ThemeMode.system,
              routerConfig: _appRouter.config(),
            ),
          );
        },
      ),
    );
  }
}
