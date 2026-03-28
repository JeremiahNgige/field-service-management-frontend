// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [CameraCapturePage]
class CameraCaptureRoute extends PageRouteInfo<void> {
  const CameraCaptureRoute({List<PageRouteInfo>? children})
    : super(CameraCaptureRoute.name, initialChildren: children);

  static const String name = 'CameraCaptureRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const CameraCapturePage();
    },
  );
}

/// generated route for
/// [EditJobPage]
class EditJobRoute extends PageRouteInfo<EditJobRouteArgs> {
  EditJobRoute({Key? key, required String jobId, List<PageRouteInfo>? children})
    : super(
        EditJobRoute.name,
        args: EditJobRouteArgs(key: key, jobId: jobId),
        rawPathParams: {'jobId': jobId},
        initialChildren: children,
      );

  static const String name = 'EditJobRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<EditJobRouteArgs>(
        orElse: () => EditJobRouteArgs(jobId: pathParams.getString('jobId')),
      );
      return EditJobPage(key: args.key, jobId: args.jobId);
    },
  );
}

class EditJobRouteArgs {
  const EditJobRouteArgs({this.key, required this.jobId});

  final Key? key;

  final String jobId;

  @override
  String toString() {
    return 'EditJobRouteArgs{key: $key, jobId: $jobId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EditJobRouteArgs) return false;
    return key == other.key && jobId == other.jobId;
  }

  @override
  int get hashCode => key.hashCode ^ jobId.hashCode;
}

/// generated route for
/// [HomePage]
class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute({List<PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const HomePage();
    },
  );
}

/// generated route for
/// [JobDetailPage]
class JobDetailRoute extends PageRouteInfo<JobDetailRouteArgs> {
  JobDetailRoute({
    Key? key,
    required String jobId,
    List<PageRouteInfo>? children,
  }) : super(
         JobDetailRoute.name,
         args: JobDetailRouteArgs(key: key, jobId: jobId),
         rawPathParams: {'jobId': jobId},
         initialChildren: children,
       );

  static const String name = 'JobDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<JobDetailRouteArgs>(
        orElse: () => JobDetailRouteArgs(jobId: pathParams.getString('jobId')),
      );
      return JobDetailPage(key: args.key, jobId: args.jobId);
    },
  );
}

class JobDetailRouteArgs {
  const JobDetailRouteArgs({this.key, required this.jobId});

  final Key? key;

  final String jobId;

  @override
  String toString() {
    return 'JobDetailRouteArgs{key: $key, jobId: $jobId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! JobDetailRouteArgs) return false;
    return key == other.key && jobId == other.jobId;
  }

  @override
  int get hashCode => key.hashCode ^ jobId.hashCode;
}

/// generated route for
/// [JobsListPage]
class JobsListRoute extends PageRouteInfo<void> {
  const JobsListRoute({List<PageRouteInfo>? children})
    : super(JobsListRoute.name, initialChildren: children);

  static const String name = 'JobsListRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const JobsListPage();
    },
  );
}

/// generated route for
/// [LoginPage]
class LoginRoute extends PageRouteInfo<LoginRouteArgs> {
  LoginRoute({Key? key, bool expired = false, List<PageRouteInfo>? children})
    : super(
        LoginRoute.name,
        args: LoginRouteArgs(key: key, expired: expired),
        rawQueryParams: {'expired': expired},
        initialChildren: children,
      );

  static const String name = 'LoginRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final queryParams = data.queryParams;
      final args = data.argsAs<LoginRouteArgs>(
        orElse: () =>
            LoginRouteArgs(expired: queryParams.getBool('expired', false)),
      );
      return LoginPage(key: args.key, expired: args.expired);
    },
  );
}

class LoginRouteArgs {
  const LoginRouteArgs({this.key, this.expired = false});

  final Key? key;

  final bool expired;

  @override
  String toString() {
    return 'LoginRouteArgs{key: $key, expired: $expired}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LoginRouteArgs) return false;
    return key == other.key && expired == other.expired;
  }

  @override
  int get hashCode => key.hashCode ^ expired.hashCode;
}

/// generated route for
/// [MyJobsPage]
class MyJobsRoute extends PageRouteInfo<void> {
  const MyJobsRoute({List<PageRouteInfo>? children})
    : super(MyJobsRoute.name, initialChildren: children);

  static const String name = 'MyJobsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const MyJobsPage();
    },
  );
}

/// generated route for
/// [ProfilePage]
class ProfileRoute extends PageRouteInfo<void> {
  const ProfileRoute({List<PageRouteInfo>? children})
    : super(ProfileRoute.name, initialChildren: children);

  static const String name = 'ProfileRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ProfilePage();
    },
  );
}

/// generated route for
/// [RegisterPage]
class RegisterRoute extends PageRouteInfo<void> {
  const RegisterRoute({List<PageRouteInfo>? children})
    : super(RegisterRoute.name, initialChildren: children);

  static const String name = 'RegisterRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const RegisterPage();
    },
  );
}

/// generated route for
/// [SplashPage]
class SplashRoute extends PageRouteInfo<void> {
  const SplashRoute({List<PageRouteInfo>? children})
    : super(SplashRoute.name, initialChildren: children);

  static const String name = 'SplashRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SplashPage();
    },
  );
}
