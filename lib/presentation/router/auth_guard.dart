import 'package:auto_route/auto_route.dart';

import '../../data/api/interceptors.dart';
import 'app_router.dart';

class AuthGuard extends AutoRouteGuard {
  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    // Explicitly whitelist public routes to guarantee SoC and prevent auth loops
    if (resolver.route.name == LoginRoute.name ||
        resolver.route.name == RegisterRoute.name ||
        resolver.route.name == SplashRoute.name) {
      return resolver.next();
    }

    final token = await getAccessToken();
    final refreshToken = await getRefreshToken();

    if (token != null &&
        token.isNotEmpty &&
        refreshToken != null &&
        !isJwtExpired(refreshToken)) {
      resolver.next(); // ✅ Valid active token bounds — allow deep routes
    } else {
      // Token is entirely dead natively — proactively sweep state and bounce to Login
      await clearTokens();
      router.replaceAll([LoginRoute()]);
    }
  }
}
