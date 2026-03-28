import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../pages/auth/login_page.dart';
import '../pages/auth/register_page.dart';
import '../pages/camera/camera_capture_page.dart';
import '../pages/home/home_page.dart';
import '../pages/jobs/edit_job_page.dart';
import '../pages/jobs/job_detail_page.dart';
import '../pages/jobs/jobs_list_page.dart';
import '../pages/jobs/my_jobs_page.dart';
import '../pages/profile/profile_page.dart';
import '../pages/splash/splash_page.dart';
import 'auth_guard.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: SplashRoute.page, initial: true),
    AutoRoute(page: LoginRoute.page),
    AutoRoute(page: RegisterRoute.page),
    AutoRoute(
      page: HomeRoute.page,
      guards: [AuthGuard()],
      children: [
        AutoRoute(page: JobsListRoute.page, initial: true),
        AutoRoute(page: MyJobsRoute.page),
        AutoRoute(page: ProfileRoute.page),
      ],
    ),
    AutoRoute(page: JobDetailRoute.page, guards: [AuthGuard()]),
    AutoRoute(page: EditJobRoute.page, guards: [AuthGuard()]),
    AutoRoute(page: CameraCaptureRoute.page, guards: [AuthGuard()]),
  ];
}
