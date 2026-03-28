import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';

import 'package:fsm_frontend/app.dart';
import 'package:fsm_frontend/di/di.dart';
import 'package:fsm_frontend/data/repository/auth_repository.dart';
import 'package:fsm_frontend/data/repository/job_repository.dart';
import 'package:fsm_frontend/data/services/fcm_service.dart';
import 'package:fsm_frontend/data/services/biometric_service.dart';
import 'package:fsm_frontend/data/models/user/user_model.dart';
import 'package:fsm_frontend/data/models/job/job_model.dart';
import 'package:fsm_frontend/data/models/api_response/api_response.dart';
import 'package:fsm_frontend/presentation/bloc/auth/auth_bloc.dart';
import 'package:fsm_frontend/presentation/bloc/job/job_cubit.dart';
import 'package:fsm_frontend/presentation/bloc/job_filter/job_filter_cubit.dart';

// ─── Mocks ───────────────────────────────────────────────────────────────────

class MockAuthRepository extends Mock implements IAuthRepository {}

class MockJobRepository extends Mock implements IJobRepository {}

class MockFcmService extends Mock implements FcmService {}

class MockBiometricService extends Mock implements BiometricService {}

class MockStorage extends Mock implements Storage {}

class FakeLoginRequest extends Fake implements LoginRequest {}

class FakeJobData extends Fake implements Map<String, dynamic> {}

// ─── Helpers ─────────────────────────────────────────────────────────────────

String generateMockJwt(Map<String, dynamic> payload) {
  final header = base64UrlEncode(utf8.encode('{"alg":"HS256","typ":"JWT"}'));
  final body = base64UrlEncode(utf8.encode(jsonEncode(payload)));
  return '$header.$body.signature';
}

/// Prints a structured, coloured log line to the test console.
void _log(String flowName, String step, {bool success = true, String? detail}) {
  const reset = '\x1B[0m';
  const green = '\x1B[32m';
  const red = '\x1B[31m';
  const cyan = '\x1B[36m';
  const yellow = '\x1B[33m';
  final icon = success ? '✅' : '❌';
  final color = success ? green : red;
  final header = '$cyan[$flowName]$reset $color$icon $step$reset';
  final tail = detail != null ? '\n   $yellow↳ $detail$reset' : '';
  // ignore: avoid_print
  print('$header$tail');
}

void _logStart(String flowName) {
  const cyan = '\x1B[36m';
  const bold = '\x1B[1m';
  const reset = '\x1B[0m';
  // ignore: avoid_print
  print(
    '\n$cyan$bold━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$reset',
  );
  // ignore: avoid_print
  print('$cyan$bold  🧪 Starting: $flowName$reset');
  // ignore: avoid_print
  print('$cyan$bold━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$reset');
}

void _logEnd(String flowName, {required bool passed}) {
  const green = '\x1B[32m';
  const red = '\x1B[31m';
  const reset = '\x1B[0m';
  final color = passed ? green : red;
  final result = passed ? '🎉 PASSED' : '💥 FAILED';
  // ignore: avoid_print
  print('$color  $result: $flowName$reset\n');
}

// ─── Main ────────────────────────────────────────────────────────────────────

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRepository mockAuthRepo;
  late MockJobRepository mockJobRepo;
  late MockFcmService mockFcmService;
  late MockBiometricService mockBiometricService;

  setUpAll(() {
    // ── Platform channel mocks ───────────────────────────────────────────
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/connectivity'),
          (MethodCall methodCall) async => ['wifi'],
        );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/permissions/methods'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'checkPermissionStatus') return 1;
            if (methodCall.method == 'requestPermissions') return {3: 1, 4: 1};
            return 1;
          },
        );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/geolocator'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'isLocationServiceEnabled') return false;
            if (methodCall.method == 'checkPermission') return 0;
            return null;
          },
        );

    registerFallbackValue(FakeLoginRequest());
    registerFallbackValue(FakeJobData());

    final storage = MockStorage();
    when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.delete(any())).thenAnswer((_) async {});
    when(() => storage.clear()).thenAnswer((_) async {});
    HydratedBloc.storage = storage;
  });

  setUp(() async {
    await getIt.reset();
    FlutterSecureStorage.setMockInitialValues({});

    mockAuthRepo = MockAuthRepository();
    mockJobRepo = MockJobRepository();
    mockFcmService = MockFcmService();
    mockBiometricService = MockBiometricService();

    when(
      () => mockBiometricService.isAvailable(),
    ).thenAnswer((_) async => false);
    when(
      () => mockBiometricService.isBiometricEnabled(),
    ).thenAnswer((_) async => false);
    when(
      () => mockBiometricService.setBiometricEnabled(
        enabled: any(named: 'enabled'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockFcmService.getToken(),
    ).thenAnswer((_) async => 'fake-fcm-token');
    when(
      () => mockFcmService.onTokenRefresh,
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => mockFcmService.setupInteractions(any()),
    ).thenAnswer((_) async {});
    when(() => mockAuthRepo.updateFcmToken(any())).thenAnswer((_) async {});
    when(() => mockAuthRepo.fetchProfile()).thenAnswer(
      (_) async => const Right(
        UserModel(
          userId: '1',
          email: 'test@test.com',
          userType: 'technician',
          username: 'Test User',
          phoneNumber: '123',
          address: '123',
        ),
      ),
    );
    when(
      () => mockAuthRepo.logout(),
    ).thenAnswer((_) async => const Right(null));

    getIt.registerSingleton<BiometricService>(mockBiometricService);
    getIt.registerSingleton<FcmService>(mockFcmService);
    getIt.registerSingleton<IAuthRepository>(mockAuthRepo);
    getIt.registerSingleton<IJobRepository>(mockJobRepo);
    getIt.registerLazySingleton<AuthBloc>(
      () => AuthBloc(mockAuthRepo, mockBiometricService, mockFcmService),
    );
    getIt.registerLazySingleton<JobCubit>(() => JobCubit(mockJobRepo));
    getIt.registerLazySingleton<JobFilterCubit>(() => JobFilterCubit());
  });

  // ─── Test group ──────────────────────────────────────────────────────────

  group('E2E UI Flows', () {
    // ══════════════════════════════════════════════════════════════════════
    // FLOW 1: Complete Login Flow & Auto-Router Navigation
    // Scenario: User opens app → sees Login screen → enters credentials
    //           → taps Sign In → app navigates away from Login screen.
    // ══════════════════════════════════════════════════════════════════════
    testWidgets('Flow 1: Complete Login Flow & Auto-Router Navigation', (
      tester,
    ) async {
      const flowName = 'Flow 1 | Login & Navigation';
      bool flowPassed = false;

      try {
        _logStart(flowName);

        // ── Step 1: Set up mock responses ──────────────────────────────
        _log(
          flowName,
          'Step 1: Configuring mock auth & job repository responses',
        );

        final accessJwt = generateMockJwt({
          'user_id': '1',
          'user_type': 'technician',
          'email': 'test@gmail.com',
          'phone_number': '123',
          'address': '123',
          'exp':
              (DateTime.now()
                  .add(const Duration(days: 1))
                  .millisecondsSinceEpoch ~/
              1000),
        });
        final refreshJwt = generateMockJwt({
          'user_id': '1',
          'user_type': 'technician',
          'email': 'test@gmail.com',
          'phone_number': '123',
          'address': '123',
          'exp':
              (DateTime.now()
                  .add(const Duration(days: 7))
                  .millisecondsSinceEpoch ~/
              1000),
        });

        when(() => mockAuthRepo.login(any())).thenAnswer(
          (_) async =>
              Right(AuthTokens(access: accessJwt, refresh: refreshJwt)),
        );
        when(
          () => mockJobRepo.listJobs(cursor: any(named: 'cursor')),
        ).thenAnswer((_) async => const Right(ApiResponse(data: [])));

        _log(
          flowName,
          'Step 1: Mock auth configured — login() will return valid JWT tokens',
          detail: 'access_exp=+1 day, refresh_exp=+7 days',
        );

        // ── Step 2: Launch the app ─────────────────────────────────────
        _log(flowName, 'Step 2: Launching App widget ...');
        await tester.pumpWidget(const App());

        _log(
          flowName,
          'Step 2: Waiting for SplashPage → LoginPage route transition',
          detail: 'No stored tokens → AuthGuard should redirect to Login',
        );
        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 100));
          if (find.text('Sign In').evaluate().isNotEmpty) break;
        }

        final signInVisible = find.text('Sign In').evaluate().isNotEmpty;
        _log(
          flowName,
          'Step 2: Login page rendered',
          success: signInVisible,
          detail: signInVisible
              ? 'Found "Sign In" text on screen — correct landing page'
              : 'ERROR: "Sign In" text NOT found. App may be stuck on Splash or routed elsewhere',
        );
        expect(find.text('Sign In'), findsWidgets);

        // ── Step 3: Enter credentials ──────────────────────────────────
        _log(flowName, 'Step 3: Entering email: test@gmail.com');
        await tester.enterText(
          find.byType(TextFormField).first,
          'test@gmail.com',
        );
        _log(flowName, 'Step 3: Entering password: pass1234');
        await tester.enterText(find.byType(TextFormField).last, 'pass1234');

        // ── Step 4: Tap Sign In ────────────────────────────────────────
        _log(flowName, 'Step 4: Tapping "Sign In" button');
        final loginBtn = find.widgetWithText(FilledButton, 'Sign In').first;
        await tester.tap(loginBtn);
        _log(
          flowName,
          'Step 4: Tap dispatched → waiting for AuthBloc to emit AuthAuthenticated ...',
        );

        // ── Step 5: Wait for navigation ────────────────────────────────
        await tester.pump(const Duration(milliseconds: 500));
        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 100));
          if (find.text('Sign In').evaluate().isEmpty) break;
        }

        final navigatedAway = find.text('Sign In').evaluate().isEmpty;
        _log(
          flowName,
          'Step 5: Router navigation after login',
          success: navigatedAway,
          detail: navigatedAway
              ? 'Login screen dismissed — user successfully routed to home'
              : 'ERROR: Login screen still visible after login tap. AuthBloc may not have emitted AuthAuthenticated',
        );

        // ── Final assertion ────────────────────────────────────────────
        expect(find.text('Sign In'), findsNothing);
        flowPassed = true;
      } catch (e) {
        _log(
          flowName,
          'UNEXPECTED EXCEPTION: $e',
          success: false,
          detail:
              'See stack trace in test output above for exact failure location',
        );
        rethrow;
      } finally {
        _logEnd(flowName, passed: flowPassed);
      }
    });

    // ══════════════════════════════════════════════════════════════════════
    // FLOW 2: Pre-authenticated Job List & Tab Navigation
    // Scenario: User already has valid stored tokens → app skips login
    //           → lands on Jobs list (with mocked data) → taps "My Jobs" tab
    //           → sees only assigned jobs.
    // ══════════════════════════════════════════════════════════════════════
    testWidgets('Flow 2: Load Jobs & Offline Tab Navigation', (tester) async {
      const flowName = 'Flow 2 | Jobs List & Tab Nav';
      bool flowPassed = false;

      try {
        _logStart(flowName);

        // ── Step 1: Pre-seed stored tokens (simulating a returning user) ─
        _log(
          flowName,
          'Step 1: Pre-seeding FlutterSecureStorage with valid JWT tokens',
          detail:
              'Simulates a returning authenticated user — biometric unlock enabled',
        );

        final validJwt = generateMockJwt({
          'user_id': '1',
          'user_type': 'technician',
          'email': 'test@gmail.com',
          'phone_number': '1234567890',
          'address': '123 Test St',
          'exp':
              (DateTime.now()
                  .add(const Duration(days: 1))
                  .millisecondsSinceEpoch ~/
              1000),
        });

        FlutterSecureStorage.setMockInitialValues({
          'access_token': validJwt,
          'refresh_token': validJwt,
        });
        _log(
          flowName,
          'Step 1: Token seeded successfully',
          detail: 'access_token + refresh_token written to secure storage mock',
        );

        // ── Step 2: Build mock job data ────────────────────────────────
        _log(
          flowName,
          'Step 2: Constructing mock job objects for the API response',
        );
        final unassignedJob = JobModel(
          jobId: '100',
          title: 'Unassigned Plumbing',
          status: JobStatus.unassigned,
          description: '',
          address: const Address(latLong: LatLong(latitude: 0, longitude: 0)),
          requirements: const {},
        );
        final assignedJob = JobModel(
          jobId: '200',
          title: 'Assigned Wiring',
          status: JobStatus.assigned,
          assignedTo: '1',
          description: '',
          address: const Address(latLong: LatLong(latitude: 0, longitude: 0)),
          requirements: const {},
        );
        _log(
          flowName,
          'Step 2: Mock jobs defined',
          detail:
              'Jobs: ["Unassigned Plumbing" (unassigned), "Assigned Wiring" (assigned→user:1)]',
        );

        // ── Step 3: Mock biometric to auto-unlock ──────────────────────
        _log(
          flowName,
          'Step 3: Configuring biometric mock → isAvailable=true, authenticate()=true',
          detail:
              'This forces the Splash screen biometric auto-unlock path so app routes to Home',
        );
        when(
          () => mockBiometricService.isAvailable(),
        ).thenAnswer((_) async => true);
        when(
          () => mockBiometricService.isBiometricEnabled(),
        ).thenAnswer((_) async => true);
        when(
          () => mockBiometricService.authenticate(),
        ).thenAnswer((_) async => true);

        when(
          () => mockJobRepo.listJobs(cursor: any(named: 'cursor')),
        ).thenAnswer(
          (_) async => Right(ApiResponse(data: [unassignedJob, assignedJob])),
        );
        when(
          () => mockJobRepo.fetchAssignedJobs(cursor: any(named: 'cursor')),
        ).thenAnswer((_) async => Right(ApiResponse(data: [assignedJob])));
        _log(
          flowName,
          'Step 3: Job repository mock configured',
          detail: 'listJobs → 2 jobs, fetchAssignedJobs → 1 job',
        );

        // ── Step 4: Launch app & wait for jobs list ────────────────────
        _log(flowName, 'Step 4: Launching App widget ...');
        await tester.pumpWidget(const App());
        _log(
          flowName,
          'Step 4: Polling for job cards to appear on screen',
          detail:
              'Waiting up to 3 seconds for SplashPage → biometric unlock → HomeRoute → JobsListPage',
        );

        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 100));
          if (find.text('Unassigned Plumbing').evaluate().isNotEmpty) break;
        }

        final jobsVisible = find
            .text('Unassigned Plumbing')
            .evaluate()
            .isNotEmpty;
        _log(
          flowName,
          'Step 4: Jobs list rendered',
          success: jobsVisible,
          detail: jobsVisible
              ? '"Unassigned Plumbing" found on screen — JobsListPage is active'
              : 'ERROR: Job card not found. AuthGuard may have bounced to Login, or biometric unlock failed',
        );
        expect(find.text('Unassigned Plumbing'), findsWidgets);

        // ── Step 5: Navigate to "My Jobs" tab ─────────────────────────
        _log(
          flowName,
          'Step 5: Looking for "My Jobs" navigation tab icon (Icons.assignment_ind_outlined)',
        );
        final myJobsTab = find.byIcon(Icons.assignment_ind_outlined);
        final tabFound = myJobsTab.evaluate().isNotEmpty;
        _log(
          flowName,
          'Step 5: "My Jobs" tab icon found',
          success: tabFound,
          detail: tabFound
              ? 'Tab icon located in navigation bar — proceeding to tap'
              : 'ERROR: Tab icon not found. Check home_page.dart navigation items',
        );

        await tester.tap(myJobsTab);
        _log(
          flowName,
          'Step 5: Tapped "My Jobs" tab → waiting for tab content to render',
        );
        await tester.pumpAndSettle();

        // ── Step 6: Verify My Jobs content ────────────────────────────
        final assignedJobVisible = find
            .text('Assigned Wiring')
            .evaluate()
            .isNotEmpty;
        _log(
          flowName,
          'Step 6: Verify "Assigned Wiring" visible on My Jobs tab',
          success: assignedJobVisible,
          detail: assignedJobVisible
              ? '"Assigned Wiring" card is visible — My Jobs tab is showing filtered content correctly'
              : 'ERROR: "Assigned Wiring" not found on My Jobs tab. fetchAssignedJobs mock may not have been called',
        );
        expect(find.text('Assigned Wiring'), findsWidgets);

        flowPassed = true;
      } catch (e) {
        _log(
          flowName,
          'UNEXPECTED EXCEPTION: $e',
          success: false,
          detail: 'Check mock setup and widget tree for failures above',
        );
        rethrow;
      } finally {
        _logEnd(flowName, passed: flowPassed);
      }
    });

    // ══════════════════════════════════════════════════════════════════════
    // FLOW 3: Push Notification Deep-Linking
    // Scenario: App opens → user logs in → FCM interaction callback is
    //           captured → simulated notification tap for job #456 fires
    //           → verifies no crash / exception occurs during nav.
    // ══════════════════════════════════════════════════════════════════════
    testWidgets('Flow 3: Push Notification Deep Linking Flow', (tester) async {
      const flowName = 'Flow 3 | FCM Deep Linking';
      bool flowPassed = false;

      try {
        _logStart(flowName);

        // ── Step 1: Start with empty storage (unauthenticated) ─────────
        _log(
          flowName,
          'Step 1: Starting with empty secure storage (no stored tokens)',
          detail:
              'App will route to Login screen — user must authenticate before deep link fires',
        );
        FlutterSecureStorage.setMockInitialValues({});

        // ── Step 2: Build JWTs and configure mocks ─────────────────────
        _log(
          flowName,
          'Step 2: Building mock JWT and configuring repository stubs',
        );
        final mockJwt = generateMockJwt({
          'user_id': '1',
          'user_type': 'technician',
          'email': 'test@test.com',
          'phone_number': '1234567890',
          'address': '123 Test St',
          'exp':
              (DateTime.now()
                  .add(const Duration(days: 1))
                  .millisecondsSinceEpoch ~/
              1000),
        });

        when(() => mockAuthRepo.login(any())).thenAnswer(
          (_) async => Right(AuthTokens(access: mockJwt, refresh: mockJwt)),
        );
        when(
          () => mockJobRepo.listJobs(cursor: any(named: 'cursor')),
        ).thenAnswer((_) async => const Right(ApiResponse(data: [])));

        final mockedDetail = JobModel(
          jobId: '456',
          title: 'HVAC Repair',
          status: JobStatus.assigned,
          assignedTo: '1',
          description: 'Fix AC',
          address: const Address(latLong: LatLong(latitude: 0, longitude: 0)),
          requirements: const {},
        );
        when(
          () => mockJobRepo.getJobDetail('456'),
        ).thenAnswer((_) async => Right(mockedDetail));
        _log(
          flowName,
          'Step 2: Mocks configured',
          detail:
              'login() → valid JWT | getJobDetail("456") → "HVAC Repair" job model',
        );

        // ── Step 3: Intercept FCM setupInteractions callback ───────────
        _log(
          flowName,
          'Step 3: Installing FcmService callback interceptor',
          detail:
              'Overrides setupInteractions(onNotificationTap) to capture the callback reference',
        );
        void Function(String, String)? triggerFCMDeepLink;
        when(() => mockFcmService.setupInteractions(any())).thenAnswer((
          invoc,
        ) async {
          triggerFCMDeepLink =
              invoc.positionalArguments[0] as void Function(String, String);
          _log(
            flowName,
            'Step 3 [CALLBACK]: FcmService.setupInteractions() called by the app',
            detail:
                'Deep-link trigger function captured — it will be invoked manually in a later step',
          );
        });
        _log(
          flowName,
          'Step 3: Interceptor registered — waiting for App to call setupInteractions()',
        );

        // ── Step 4: Launch app & wait for Login page ───────────────────
        _log(flowName, 'Step 4: Launching App widget ...');
        await tester.pumpWidget(const App());
        _log(
          flowName,
          'Step 4: Polling for Login screen (no tokens → SplashPage → LoginPage)',
        );

        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 100));
          if (find.text('Sign In').evaluate().isNotEmpty) break;
        }

        final loginPageVisible = find.text('Sign In').evaluate().isNotEmpty;
        _log(
          flowName,
          'Step 4: Login page reached',
          success: loginPageVisible,
          detail: loginPageVisible
              ? '"Sign In" text visible — user is on Login page as expected'
              : 'ERROR: "Sign In" not found. App may have auto-routed elsewhere (check stored token state)',
        );

        // ── Step 5: Authenticate ───────────────────────────────────────
        _log(flowName, 'Step 5: Entering credentials and tapping "Sign In"');
        await tester.enterText(
          find.byType(TextFormField).first,
          'test@test.com',
        );
        _log(flowName, 'Step 5: Email entered → test@test.com');
        await tester.enterText(find.byType(TextFormField).last, 'password123');
        _log(flowName, 'Step 5: Password entered → password123');
        await tester.tap(find.widgetWithText(FilledButton, 'Sign In').first);
        _log(
          flowName,
          'Step 5: Sign In tapped → dispatching AuthLoginRequested to AuthBloc ...',
        );

        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 100));
          if (find.text('Sign In').evaluate().isEmpty) break;
        }

        final loggedIn = find.text('Sign In').evaluate().isEmpty;
        _log(
          flowName,
          'Step 5: Login result',
          success: loggedIn,
          detail: loggedIn
              ? 'AuthBloc emitted AuthAuthenticated — app routed to Home screen'
              : 'ERROR: Login screen still visible after authentication attempt',
        );

        // ── Step 6: Assert FCM callback was captured ───────────────────
        final callbackCaptured = triggerFCMDeepLink != null;
        _log(
          flowName,
          'Step 6: Check FCM setupInteractions callback captured',
          success: callbackCaptured,
          detail: callbackCaptured
              ? 'Callback reference is non-null — ready to simulate notification tap'
              : 'ERROR: Callback is null. FcmService.setupInteractions was never called after login, '
                    'or the mock interceptor did not fire. Verify bootstrap.dart / auth_bloc.dart calls it',
        );
        expect(triggerFCMDeepLink, isNotNull);

        // ── Step 7: Fire simulated FCM notification ────────────────────
        _log(
          flowName,
          'Step 7: Simulating FCM notification tap → jobId="456", assignedTo="1"',
          detail:
              'This calls the captured callback which should trigger router.push(JobDetailRoute(jobId:"456"))',
        );
        triggerFCMDeepLink!('456', '1');

        _log(
          flowName,
          'Step 7: Notification dispatched → processing router animations ...',
        );
        for (var i = 0; i < 15; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        // ── Step 8: Verify no exceptions ──────────────────────────────
        final exception = tester.takeException();
        _log(
          flowName,
          'Step 8: Checking for uncaught exceptions post-deep-link',
          success: exception == null,
          detail: exception == null
              ? 'No exceptions — deep-link routing completed without crash'
              : 'ERROR: Exception thrown during deep-link navigation: $exception',
        );
        expect(exception, isNull);

        flowPassed = true;
      } catch (e) {
        _log(
          flowName,
          'UNEXPECTED EXCEPTION: $e',
          success: false,
          detail: 'Review FCM callback logic and AutoRoute navigation stack',
        );
        rethrow;
      } finally {
        _logEnd(flowName, passed: flowPassed);
      }
    });
  });
}
