# Architectural Decision Record — FSM Frontend

This document captures the **why** behind the most significant technical decisions made in this Flutter application. It is written for future maintainers, reviewers, and contributors who need to understand the reasoning, not just the mechanics.

---

## Table of Contents

1. [State Management: BLoC + Cubit](#1-state-management-bloc--cubit)
2. [Offline Persistence: HydratedBloc](#2-offline-persistence-hydratebloc)
3. [Offline Sync & Conflict Resolution](#3-offline-sync--conflict-resolution)
4. [Clean Architecture & Repository Pattern](#4-clean-architecture--repository-pattern)
5. [Functional Error Handling: dartz Either](#5-functional-error-handling-dartz-either)
6. [Dependency Injection: GetIt + Injectable](#6-dependency-injection-getit--injectable)
7. [Routing: auto_route + AuthGuard](#7-routing-auto_route--authguard)
8. [Token Storage & Session Management](#8-token-storage--session-management)
9. [Concurrent JWT Refresh Lock](#9-concurrent-jwt-refresh-lock)
10. [File Uploads: Presigned URLs via MinIO](#10-file-uploads-presigned-urls-via-minio)
11. [Maps: Google Maps Flutter](#11-maps-google-maps-flutter)
12. [Push Notifications: FCM + Local Notifications](#12-push-notifications-fcm--local-notifications)
13. [Code Generation Strategy](#13-code-generation-strategy)
14. [Future: Job Checklist & Offline Write Queue](#14-future-job-checklist--offline-write-queue)

---

## 1. State Management: BLoC + Cubit

### Decision
Use `flutter_bloc` with a mix of `Bloc` (event-driven, for Auth) and `Cubit` (method-driven, for Jobs/Upload).

### Rationale
Field service apps have complex, multi-actor state: authentication lifecycle, live job lists, paginated cursors, upload progress, and connectivity status all need to coexist without race conditions.

BLoC enforces a **unidirectional data flow** — events in, states out — which makes state transitions fully auditable and reproducible. Every state change is deterministic and testable in isolation.

**Why the Bloc/Cubit split?**

| Component     | Class used | Reason |
|---------------|------------|--------|
| `AuthBloc`    | `Bloc`     | Auth has a rich, named event taxonomy (`AuthLoginRequested`, `AuthBiometricUnlockRequested`, `_AuthSessionExpiredReceived`, etc.) where the events themselves carry semantic meaning. The event type acts as documentation. |
| `JobCubit`    | `Cubit`    | Job operations (`loadJobs`, `selectJob`, `assignJob`) are imperative method calls with no meaningful distinction between event subtypes. Cubit removes the boilerplate without losing testability. |
| `ImageCaptureCubit` | `Cubit` | Simple, linear state machine (idle → capturing → done). Cubit is sufficient. |

### Alternatives Considered
- **Provider / Riverpod**: Less opinionated about data flow direction. Chosen against because BLoC's strict event→state model makes it easier to enforce an audit trail in a domain where actions (job assignments, status changes) have compliance implications.
- **GetX**: Reactive but couples UI logic to controllers in a way that is harder to test independently.

### Trade-off
BLoC is more verbose than Riverpod for simple cases (e.g., toggling a flag requires an event + handler). This is an acceptable cost for the auditability and testability it provides.

---

## 2. Offline Persistence: HydratedBloc

### Decision
`JobCubit` extends `HydratedCubit` rather than the base `Cubit`. Auth state is **not** hydrated.

### Rationale
Field technicians work in warehouses, basements, and remote sites where connectivity is intermittent. When a technician opens the app after a brief signal loss, the last-known job list must render immediately without a loading spinner. `HydratedBloc` achieves this with zero extra infrastructure — it serialises the state to the application documents directory on every `emit` and deserialises it on the next cold start.

The `fromJson` / `toJson` implementation is intentionally **partial**: it persists only the job lists and pagination cursors, not transient state like `isLoading`, `error`, or `uploadUrls`. On cold-start, the app renders stale cached data immediately and silently fetches fresh data in the background — a pattern known as _stale-while-revalidate_.

**Why Auth is not hydrated:** Persisting authentication state would bypass the JWT expiry check on startup. The splash screen always runs `AuthCheckBiometricStatus` which validates the refresh token locally before allowing navigation to proceed.

### Trade-off
- `HydratedBloc` stores state in plain JSON on disk in the app documents directory. It is **not encrypted**. Job data (customer name, phone, address) is written to disk in plaintext.
- For a production deployment in a regulated industry, this storage should be replaced with an encrypted equivalent (e.g., wrapping the `HydratedStorage` directory with an AES key derived from the device's secure enclave, or using `flutter_secure_storage` for sensitive fields only).

---

## 3. Offline Sync & Conflict Resolution

### Current Approach
The app uses a **read-cache-then-fetch** (stale-while-revalidate) strategy, not a full offline-first write queue.

**How it works:**

1. **Cold start / app resume**: `HydratedCubit` restores the last-known job list immediately. The UI renders with cached data.
2. **Background refresh**: On first `loadJobs` call, connectivity is checked via `connectivity_plus`. If online, a fresh paginated page is fetched and **merged** with the cache using a `Map<jobId, JobModel>` deduplication pattern — new server data overwrites cached entries with the same ID.
3. **Optimistic local updates**: `selectJob` shows the locally cached job immediately (`emit(... selectedJob: localJob)`) then fires a network fetch. When the server responds, the richer server version replaces the local one.
4. **Assign job fallback**: When `assignJob` succeeds but the server response is missing `assignedTo` (a known intermittent backend issue), the Cubit locally patches the model with the current user's ID and status `'assigned'` so the UI reflects the change immediately.

### Conflict Resolution Strategy
The server is the **source of truth**. Conflicts are resolved by the _last-write-wins_ rule:

- Local mutations are always immediately reflected in the in-memory BLoC state (optimistic update).
- The next network refresh overwrites them with the server version.
- There is no merge policy for concurrent edits — two technicians editing the same job would see one override the other, with no notification.

### Known Limitations
- **No write queue**: If a technician updates a job while offline, the change is **not queued** for later sync. The update will silently fail (the connectivity guard returns early) and the in-memory state will show the local version until the next refresh wipes it. A proper offline queue (e.g., using Hive as a persistent outbox) is the recommended next step.
- **No real-time conflict detection**: There is no `updatedAt`-based concurrency check (optimistic locking) on job updates. Two users editing the same job will overwrite each other silently.

---

## 4. Clean Architecture & Repository Pattern

### Decision
Three distinct layers: **Data** (API + Models + Repositories) → **Domain** (BLoC/Cubit) → **Presentation** (Pages + Widgets). Each layer depends only on the layer below, never on the layer above.

### Rationale
The repository interfaces (`IAuthRepository`, `IJobRepository`) are the seams that keep the presentation and data layers decoupled:

- **Testability**: BLoCs can be tested with mock repositories without spinning up a real Dio client or a Docker backend.
- **Replaceability**: The MinIO upload service, the Dio client, and the REST endpoints can all be swapped out without touching a single BLoC or widget.
- **Error normalisation**: All `DioException`s are translated to human-readable `String` errors at the repository boundary via `AppHelpers.friendlyError()`. Nothing above the repository layer ever sees a raw HTTP error code.

### The `Either<String, T>` Contract
Every repository method returns `Either<String, T>`:
- `Left(String)` — a user-facing error message.
- `Right(T)` — the successfully decoded domain model.

This eliminates `try/catch` boilerplate in BLoCs and forces error handling to be explicit at every call site.

---

## 5. Functional Error Handling: dartz Either

### Decision
Use `dartz`'s `Either` type for all repository return values instead of throwing exceptions.

### Rationale
Exceptions in Dart are unchecked — a method can throw anything and nothing in the type system enforces that callers handle it. `Either` makes the happy path and the error path **part of the type signature**. A BLoC calling a repository _cannot_ forget to handle the failure case — the compiler enforces it via `.fold(onLeft, onRight)`.

### Trade-off
- `dartz` adds a dependency and an unfamiliar idiom for developers who haven't used functional programming patterns.
- `Result` types are now natively discussed in the Dart community (various packages: `result_dart`, `fpdart`). If `dartz` becomes unmaintained, migrating to one of these is straightforward because the interface is the same.

---

## 6. Dependency Injection: GetIt + Injectable

### Decision
Use `get_it` as the service locator and `injectable` + `build_runner` to generate the registration boilerplate at compile time.

### Rationale
The app has ~15 singleton services (Dio, repositories, BLoCs, FcmService, BiometricService, etc.) with complex interdependencies. Wiring these manually is error-prone and produces brittle, untestable constructor chains. `injectable` reads annotations (`@LazySingleton`, `@injectable`, `@lazySingleton`) and generates a `di.config.dart` file that registers everything correctly.

**`LazySingleton` is used for most services** — instances are only created when first accessed, keeping cold-start time low.

### Trade-off
- Code generation must be re-run (`bash runner.sh`) after any DI annotation is changed. Forgetting to do so produces a runtime crash, not a compile-time error.
- The generated `di.config.dart` should not be edited manually.

---

## 7. Routing: auto_route + AuthGuard

### Decision
Use `auto_route` for all navigation. Protect authenticated routes with a custom `AuthGuard`.

### Rationale
`auto_route` generates type-safe route classes (`LoginRoute()`, `JobDetailRoute(jobId: id)`, etc.) from annotations. This eliminates stringly-typed navigation (`Navigator.pushNamed('/job-detail?id=...')`) and catches route argument errors at *compile time*.

The `AuthGuard` intercepts any navigation attempt to a protected route and checks:
1. That a non-empty access token exists in secure storage.
2. That the *refresh* token (not the access token) is not locally expired.

Checking the refresh token rather than the access token means short-lived (15-minute) access tokens don't cause unnecessary logouts — only a dead refresh session triggers a redirect to Login.

**Session expiry via stream**: The `AuthInterceptor` (Dio layer) can detect a 401 at any time during background requests. It signals the `AuthBloc` via `SessionExpiredNotifier` — a singleton `StreamController` — rather than coupling the Dio interceptor to the Flutter navigation system directly. The `AuthBloc` listens to this stream and emits `AuthSessionExpired`, which the app's router observes and uses to redirect to Login.

### Trade-off
- `auto_route` requires running `build_runner` to regenerate `app_router.gr.dart` after route changes. This is the same cost as all other code-generated tooling in the project.
- The `AuthGuard` runs on every route navigation. For routes that are navigated frequently (e.g., deep-linking from notifications), this means two async disk reads per navigation. This overhead is negligible in practice (~1ms), and the security benefit is worth it.

---

## 8. Token Storage & Session Management

### Decision
- **JWT pair** (access + refresh) stored in `flutter_secure_storage` (Android Keystore / iOS Keychain).
- **Biometric preference flag** stored separately in `flutter_secure_storage`.
- **App state** (job lists) stored in `HydratedBloc`'s plain JSON storage.

### Rationale
JWTs are credentials. Storing them in `shared_preferences` or Hive (plain disk) would expose them to any process that can read the app's data directory on a rooted/jailbroken device. `flutter_secure_storage` uses OS-level hardware-backed encryption:

| Platform | Mechanism |
|----------|-----------|
| Android  | `EncryptedSharedPreferences` (backed by Android Keystore) |
| iOS      | Keychain with `first_unlock` accessibility (available after first unlock, even in background) |

**Biometric unlock** works as follows:
1. On login, the tokens are saved to secure storage and the user is offered the option to enable biometric unlock.
2. On subsequent app opens, the splash screen checks if biometric is enabled AND a valid (non-expired refresh) token exists.
3. If both are true, the OS biometric prompt is shown. On success, the tokens are read from secure storage and the user enters the authenticated state — no network call required.
4. If the refresh token is expired, biometric is disabled and a full credential login is required.

### Trade-off
`flutter_secure_storage` has known issues on Android when users switch between different signing keys or restore from a backup — the Keystore key can be invalidated, causing a read failure that looks identical to "no token stored". The current code treats this as an unauthenticated state (safest default).

---

## 9. Concurrent JWT Refresh Lock

### Decision
The `AuthInterceptor` implements a **Completer-based refresh lock** to prevent parallel `POST /user/refresh/` calls.

### Rationale
In a real session, multiple Dio requests can fire simultaneously (e.g., loading the job list and the profile simultaneously on the Home screen). If the access token expires mid-session, all of them will receive a 401 at roughly the same time. Without a lock, all five would race to call the refresh endpoint — this is wasteful, could hit rate limits, and causes unpredictable state if some succeed and some don't.

The implementation:
1. The **first** request to receive a 401 sets `_isRefreshing = true` and creates a `Completer<bool>`.
2. All subsequent 401s check `_isRefreshing == true` and `await _refreshCompleter!.future` — they park until the single refresh resolves.
3. When the refresh completes, `_refreshCompleter.complete(true/false)` wakes all waiters simultaneously. They either retry with the new token (success) or propagate the 401 (failure).

The retry after the refresh is deliberately placed **outside** the `try/catch` block that catches the refresh failure, so a transient network error on the retry doesn't incorrectly null out `_refreshCompleter` while other waiters are still attached to it.

### Trade-off
The lock state (`_isRefreshing`, `_refreshCompleter`) is module-level (not instance-level on the interceptor), making it effectively a process-wide singleton. This is intentional — `AuthInterceptor` is stateless by design and multiple isolates are not used. If the app ever moves to multiple Dio instances on separate isolates, this would need to become an `Isolate`-safe lock.

---

## 10. File Uploads: Presigned URLs via MinIO

### Decision
Photos and signatures are **not** uploaded through the Django API. Instead:
1. The app requests one or more presigned `PUT` URLs from the backend (`POST /jobs/upload-urls/`).
2. The app uploads the file binary **directly to MinIO** by HTTP `PUT`ing the presigned URL.
3. The app stores the MinIO object key (not the full URL) in the job record via a normal job update call.

### Rationale
Routing large binary files (photos, signatures) through Django would:
- Double the bandwidth (client → Django → MinIO).
- Block a Django worker thread for the entire upload duration.
- Require Django to buffer the entire file in memory before forwarding it.

Presigned URLs eliminate all three problems. Django only handles the short, cheap metadata exchange. MinIO handles the bytes directly from the client.

**Presigned download URLs** follow the same pattern: the app requests short-lived signed GET URLs (`POST /jobs/download-urls/`) which expire after 30 minutes (1800 seconds, mirroring Django's default).

### Trade-off
- If a presigned URL expires before the upload starts (possible on slow networks), the upload fails silently. The current implementation does not retry or re-request URLs.
- MinIO credentials (`minioAccessKey`, `minioSecretKey`) and the endpoint are hardcoded in `constants.dart`. **These must be rotated and moved to a build-time secret before any production deployment.**

---

## 11. Maps: Google Maps Flutter

### Decision
Migrated from `flutter_map` (OpenStreetMap) to `google_maps_flutter` for the job location map card.

### Rationale
`flutter_map` uses tile-based rendering controlled entirely within Flutter's widget tree, which worked well for basic map display. However, after introducing a scrollable card layout, `flutter_map`'s tile layer produced `BoxConstraints forces an infinite width` layout exceptions because it could not resolve its own constraints inside a `SingleChildScrollView`.

`google_maps_flutter` embeds the native Google Maps SDK (a `PlatformView`), which owns its own rendering context and resolves its own layout constraints independently of Flutter's layout pass. Wrapping it in a `SizedBox` with explicit dimensions is sufficient to give it bounded constraints.

Additionally, Google Maps provides:
- Better satellite and street-level imagery.
- Native turn-by-turn deep-link integration (`maps.apple.com` / `maps.google.com`) via `url_launcher` for navigation directions to the job site.

### Trade-off
- Requires a **Google Maps API key** registered in the Google Cloud Console with the Maps SDK for Android and Maps SDK for iOS enabled. Without this key, a watermarked "For development purposes only" overlay appears and the map may stop rendering above a certain request quota.
- `google_maps_flutter` uses a `PlatformView`, which has a small but measurable performance cost compared to a pure Flutter widget. On low-end devices, embedding multiple `GoogleMap` widgets on the same screen should be avoided.
- Apple Maps deep-link (`maps.apple.com`) is used as the fallback on iOS devices.

---

## 12. Push Notifications: FCM + Local Notifications

### Decision
Use Firebase Cloud Messaging (FCM) for server-initiated push notifications and `flutter_local_notifications` to display heads-up banners when the app is in the **foreground**.

### Rationale
FCM is the standard push delivery mechanism for both Android and iOS and integrates directly with the Django backend's Celery/Channels task queue. It handles all three app lifecycle states:

| State        | Mechanism                                                          |
|--------------|--------------------------------------------------------------------|
| Terminated   | `FirebaseMessaging.instance.getInitialMessage()` on next launch    |
| Background   | `FirebaseMessaging.onMessageOpenedApp` stream                      |
| Foreground   | `FirebaseMessaging.onMessage` → `FlutterLocalNotificationsPlugin.show()` |

FCM does **not** show a heads-up notification when the app is in the foreground — that is the OS's default behaviour for foreground apps. `flutter_local_notifications` fills this gap by constructing the notification locally from the FCM `RemoteMessage` payload.

The FCM token is registered with the backend on every login and biometric unlock (fire-and-forget, never blocking the login flow). Token rotation is handled by subscribing to `FirebaseMessaging.onTokenRefresh` inside `AuthBloc`, which calls `updateFcmToken` on each new token without requiring user interaction.

Tapping a notification deep-links directly to the relevant `JobDetailPage` using the `job_id` embedded in the FCM data payload.

### Trade-off
- On **iOS physical devices**, FCM delivery depends on APNs (Apple Push Notification service) configuration in the Firebase project. Without a valid APNs key or certificate, notifications will silently not arrive on iOS devices, even though the code is correct.
- The background message handler (`_firebaseMessagingBackgroundHandler`) is a top-level function annotated with `@pragma('vm:entry-point')` and runs in a separate Dart isolate. It currently only logs the message. If background actions (e.g., pre-fetching the job detail) are added here, they cannot access the main isolate's `GetIt` service graph.

---

## 13. Code Generation Strategy

### Decision
Use `build_runner` to generate four categories of code: JSON serialisation (`json_serializable`), dependency injection (`injectable_generator`), routing (`auto_route_generator`), and asset references (`flutter_gen_runner`).

### Rationale

| Generator            | What it produces             | Why generated |
|----------------------|------------------------------|---------------|
| `json_serializable`  | `fromJson` / `toJson` methods on models | Manual JSON parsing is error-prone and verbose; generated code is always consistent with the annotated fields |
| `injectable_generator` | `di.config.dart`           | DI registration is structural boilerplate that is entirely derivable from annotations |
| `auto_route_generator` | `app_router.gr.dart`       | Route classes with typed arguments; generated from `@RoutePage()` annotations |
| `flutter_gen_runner` | `lib/gen/assets.gen.dart`   | Type-safe asset references (no stringly-typed `'assets/images/logo.png'`) |

All generated files are committed to the repository so that `flutter run` works without requiring `build_runner` on a fresh checkout. However, they **must be regenerated** after modifying annotated source files:

```bash
bash runner.sh
```

### Trade-off
- Stale generated files are a common source of confusing errors (e.g., a route argument not being available after adding a new `@PathParam`). The `--delete-conflicting-outputs` flag in `runner.sh` handles the most common case.
- `build_runner` can be slow on large codebases (~10–30 seconds). This is an industry-standard cost for the code quality and type safety it provides.

---

## 14. Future: Job Checklist & Offline Write Queue

### Context
Given more time, the single highest-value feature to implement next would be a **complete job checklist workflow** inside the Edit Job page — combined with a robust **offline write queue** so that every field-worker action is durably captured regardless of connectivity.

### What the Feature Would Look Like

The Edit Job page currently supports basic status and notes updates. The intended full implementation would include:

| Field / Section | Description |
|---|---|
| **Step-by-step checklist** | Ordered list of task items per job, each with a completion toggle, a required-tool indicator, and optional technician notes per step |
| **Time tracking** | Clock-in / clock-out timestamps recorded to the minute, stored alongside each checklist step |
| **Parts & materials** | A dynamic list of parts consumed during the job, with quantity and unit cost, used to compute the final job cost on the backend |
| **Sign-off confirmation** | A final "mark complete" action that captures the customer signature, locks the checklist, and transitions the job to `completed` status |
| **Photo evidence per step** | Each checklist step can optionally require one or more photos as completion evidence, uploading via the existing presigned URL pipeline |

### Offline Write Queue Design

The core problem: a technician starts filling in the checklist in a basement or remote site with no signal. Every save attempt currently returns an error and discards the input. The intended solution is a **persistent outbox queue** backed by Hive:

```
Technician edits field
        │
        ▼
Action written to Hive outbox (key: jobId + timestamp + payload)
        │
        ├─ Online? ──YES──▶ Flush immediately via Dio → remove from outbox
        │
        └─ Offline? ──────▶ Remain in outbox; connectivity_plus listener fires
                                    when signal returns
                                        │
                                        ▼
                            Outbox flushed concurrently:
                            all pending items dispatched
                            in parallel via Future.wait()
```

**Key implementation decisions:**

1. **Hive as the outbox store**: Each pending operation is a `HiveObject` containing the `jobId`, the partial JSON payload (e.g., `{'checklist_item_id': '...', 'completed': true}`), and a `createdAt` timestamp. Hive provides atomic writes and survives process termination, making it safe to use as a durable queue.

2. **`connectivity_plus` stream as the flush trigger**: A dedicated `SyncCubit` subscribes to `Connectivity().onConnectivityChanged`. When the stream emits a non-`none` result, the entire outbox is read and all pending operations are dispatched **concurrently** with `Future.wait()`, respecting operation order per `jobId` via a sequential sub-queue per job.

3. **Conflict resolution on flush**: Each outbox entry carries the `lastKnownUpdatedAt` field from the job at the time the edit was made. The backend compares this against the current `updatedAt` value and rejects (HTTP 409) if another edit occurred in the interim. The app surfaces a merge conflict UI — showing the server version alongside the queued local version — and asks the technician which to keep.

4. **Idempotency keys**: Each outbox entry includes a client-generated UUID sent as an `X-Idempotency-Key` request header. This prevents duplicate writes if the network drops between the server processing the request and the client receiving the 200 response — a common failure mode on mobile.

5. **Upload sequencing for photos**: Photo uploads (MinIO presigned PUT) are queued separately from metadata updates. The outbox entry for a photo stores the local file path, not the bytes, to avoid inflating the Hive database. The flush routine: (a) re-compresses the image, (b) requests a fresh presigned URL if the stored one has expired (checking `urlExpirySeconds`), and (c) uploads, then records the object key before dispatching the accompanying job-metadata update.

### Why This Wasn't Implemented Yet
The offline write queue is architecturally straightforward but operationally complex to make fully resilient. The failure modes (expired presigned URLs, server-side conflicts, partial flushes on process kill, duplicate delivery) each require dedicated handling and their own recovery path. Shipping an incomplete queue — one that silently loses writes or produces duplicate records — would be worse than the current "fail loudly" approach. The full implementation is the correct scope for the next development sprint.

---

*This end*
