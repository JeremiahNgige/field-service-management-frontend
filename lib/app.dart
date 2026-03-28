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

// ─────────────────────────────────────────────────────────────────────────────
// App — owns the DI-provided BLoCs and hands them down the tree.
// AppView — owns the router, FCM interactions, and all root-level listeners.
// Splitting these means AppView.initState runs with a valid context that has
// full access to the BlocProviders, avoiding the AuthInitial timing issue.
// ─────────────────────────────────────────────────────────────────────────────

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => getIt<AuthBloc>()),
        BlocProvider<JobCubit>(create: (_) => getIt<JobCubit>()),
        BlocProvider<JobFilterCubit>(create: (_) => getIt<JobFilterCubit>()),
      ],
      child: const AppView(),
    );
  }
}

class AppView extends StatefulWidget {
  const AppView({super.key});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> {
  late final AppRouter _appRouter;

  String? _pendingJobId;
  String? _pendingTargetUserId;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _registerFcmInteractions();
    });
  }

  void _registerFcmInteractions() {
    getIt<FcmService>().setupInteractions((jobId, targetUserId) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        _handleDeepLink(authState, jobId, targetUserId);
      } else {
        _pendingJobId = jobId;
        _pendingTargetUserId = targetUserId;
      }
    });
  }

  void _handleDeepLink(
    AuthAuthenticated authState,
    String jobId,
    String targetUserId,
  ) {
    final currentUserId = authState.user?.userId.toString();
    if (targetUserId.isEmpty || currentUserId == targetUserId) {
      _appRouter.push(JobDetailRoute(jobId: jobId));
    } else {
      debugPrint(
        '[FCM DeepLink] Push Ignored → Malicious/Stale tap. '
        'Intended: $targetUserId, Active: $currentUserId',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) =>
              current is AuthSessionExpired ||
              current is AuthUnauthenticated ||
              (current is AuthAuthenticated && _pendingJobId != null),
          listener: (context, state) {
            if (state is AuthSessionExpired) {
              _appRouter.replaceAll([LoginRoute(expired: true)]);
            } else if (state is AuthUnauthenticated) {
              _appRouter.replaceAll([LoginRoute()]);
            } else if (state is AuthAuthenticated && _pendingJobId != null) {
              _handleDeepLink(
                state,
                _pendingJobId!,
                _pendingTargetUserId ?? '',
              );
              _pendingJobId = null;
              _pendingTargetUserId = null;
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
    );
  }
}
