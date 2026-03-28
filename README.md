# FSM Field Service — Flutter Frontend

A **Flutter mobile application** for managing field service jobs. Field workers can view assigned jobs, update job status, capture photos, collect customer signatures, and receive real-time push notifications when jobs are assigned to them.

---

## Table of Contents

- [Tech Stack](#tech-stack)
- [Project Architecture](#project-architecture)
- [Prerequisites](#prerequisites)
- [Running the Backend (Docker)](#running-the-backend-docker)
- [Running the Flutter App](#running-the-flutter-app)
  - [1. Clone and Install](#1-clone-and-install)
  - [2. Configure the API endpoint](#2-configure-the-api-endpoint)
  - [3. Run code generation](#3-run-code-generation)
  - [4. Run the app](#4-run-the-app)
- [Running Tests](#running-tests)
- [Key Features](#key-features)
- [Known Limitations & Incomplete Features](#known-limitations--incomplete-features)

---

## Tech Stack

| Layer               | Technology                                             |
|---------------------|--------------------------------------------------------|
| Framework           | Flutter (Dart SDK ≥ 3.8.0)                             |
| State Management    | BLoC / Cubit (`flutter_bloc`, `hydrated_bloc`)         |
| Routing             | `auto_route`                                           |
| Networking          | `dio` + `dio_cache_interceptor`                        |
| Dependency Injection| `get_it` + `injectable`                                |
| Local Storage       | `hive` + `flutter_secure_storage`                      |
| Serialization       | `json_serializable` + `json_annotation`                |
| Maps                | `google_maps_flutter` + `geolocator`                   |
| Camera              | `camerawesome` + `flutter_image_compress`              |
| File Storage        | MinIO (S3-compatible) via presigned URLs               |
| Push Notifications  | Firebase Cloud Messaging (FCM)                         |
| Auth                | JWT (`jwt_decoder`), biometric (`local_auth`)          |
| Functional patterns | `dartz` (Either / Option)                              |

---

## Project Architecture

The app follows a **clean, layered architecture**:

```
lib/
├── data/
│   ├── api/            # Dio client, interceptors, request/response models
│   ├── models/         # JSON-serializable domain models (Job, User, etc.)
│   ├── repository/     # Repository interfaces + implementations
│   └── services/       # FCM, location, MinIO upload services
├── di/                 # GetIt dependency injection configuration
├── presentation/
│   ├── bloc/           # BLoC/Cubit state management (auth, jobs, image)
│   ├── pages/          # Screens: auth, home, jobs, camera, profile, splash
│   ├── router/         # auto_route definitions + AuthGuard
│   └── widgets/        # Shared UI components
├── theme/              # App-wide Material theme
├── utils/              # Constants, helpers, extensions
└── gen/                # flutter_gen asset references (auto-generated)
```

---

## Prerequisites

Make sure the following are installed on a **fresh machine**:

| Tool            | Version (minimum) | Notes                                            |
|-----------------|-------------------|--------------------------------------------------|
| Flutter SDK     | 3.8.0+            | `flutter --version`                              |
| Dart SDK        | 3.8.0+            | Bundled with Flutter                             |
| Docker          | 24.0+             | Required to run the backend                      |
| Docker Compose  | v2.0+             | `docker compose version`                         |
| Android Studio  | Hedgehog+         | For Android emulator / physical device builds    |
| Xcode           | 15+ (macOS only)  | For iOS simulator / physical device builds       |
| Google Maps API | Key               | Required for the maps feature (set in Android/iOS config) |

> **Firebase**: A valid `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are required. These are project-specific and **must not be committed to version control**. Contact the project maintainer for these files.

---

## Running the Backend (Docker)

The Flutter app talks to a **Django REST API** backed by **PostgreSQL** and **MinIO** (S3-compatible object storage), all orchestrated via Docker Compose.

> The backend repository is separate. Follow its README to start the services. A typical start is:

```bash
# In the backend repository root
docker compose up --build -d
```

This starts three services accessible from the host:

| Service      | Default Host Port | Description                        |
|--------------|-------------------|------------------------------------|
| Django API   | `8000`            | REST API (gunicorn)                |
| PostgreSQL   | `5432`            | Relational database                |
| MinIO        | `9000`            | S3-compatible object storage       |
| MinIO Console| `9001`            | MinIO web admin UI                 |
| Redis        | `6379`            | Celery broker (background tasks)   |

Verify everything is healthy:

```bash
docker compose ps
# All services should show status "running" or "healthy"
```

---

## Running the Flutter App

### 1. Clone and Install

```bash
git clone <repository-url> "field service management frontend"
cd "field service management frontend"

# Install Flutter packages
flutter pub get
```

### 2. Configure the API Endpoint

Open `lib/utils/constants.dart` and update `baseUrl` and `minioEndpoint` to match your run target:

```dart
// Android Emulator → host machine running Docker
static const String baseUrl = 'http://10.0.2.2:8000/api';
static const String minioEndpoint = 'http://10.0.2.2:9000';

// iOS Simulator → host machine running Docker
static const String baseUrl = 'http://localhost:8000/api';
static const String minioEndpoint = 'http://localhost:9000';

// Physical Device → replace with your machine's LAN IP
static const String baseUrl = 'http://192.168.x.x:8000/api';
static const String minioEndpoint = 'http://192.168.x.x:9000';
```

> Find your machine's LAN IP with `ipconfig getifaddr en0` (macOS) or `ip route get 1` (Linux).

### 3. Run Code Generation

The project uses `build_runner` for routing, JSON serialization, and DI. Run this once after cloning and again whenever you modify annotated files:

```bash
# Using the provided convenience script
bash runner.sh

# Or directly
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Run the App

```bash
# List available devices
flutter devices

# Run on a connected device or emulator
flutter run

# Run in release mode (faster, closer to production)
flutter run --release
```

#### Platform-Specific Notes

**Android**
- Minimum SDK: 21 (Android 5.0)
- The emulator can reach the host Docker via `10.0.2.2` (loopback alias)
- Ensure `INTERNET` permission is in `AndroidManifest.xml` (already configured)

**iOS**
- Minimum iOS: 13.0
- Run `pod install` inside the `ios/` directory if CocoaPods are stale:
  ```bash
  cd ios && pod install && cd ..
  ```
- Physical devices require a valid Apple Developer provisioning profile

---

## Running Tests

The project includes core utility unit tests (`test/widget_test.dart`) and headless UI integration tests covering critical user flows (`test/api_integration_test.dart`).

```bash
# Run all unit tests
flutter test test/widget_test.dart

# Run the API and UI Integration Testing suite (Login, Tab Navigation, Push Notifications)
flutter test test/api_integration_test.dart

# Run tests with verbose output to see individual test cases
flutter test --reporter expanded
```

> **Note on Integration Tests**: The tests in `test/api_integration_test.dart` achieve headless E2E environment testing by using `mocktail` to inject isolated versions of `FlutterSecureStorage`, `IAuthRepository`, and native platform channels (Geolocator/Connectivity). This avoids missing plugin exceptions traditionally seen in Flutter widget testing boundaries.

---

## Key Features

| Feature                     | Details                                                                     |
|-----------------------------|-----------------------------------------------------------------------------|
| **Authentication**          | JWT login / registration with biometric unlock on subsequent sessions        |
| **Token Management**        | Silent refresh, secure storage via `flutter_secure_storage`, auto-logout on expiry |
| **Job List**                | Paginated cursor-based job feed; filterable between all jobs and "My Jobs"  |
| **Job Detail**              | Full job info: status, schedule, customer, pay, address, requirements       |
| **Interactive Map**         | Google Maps card showing job location; deep-links to native Maps app for navigation |
| **Assign Job**              | One-tap self-assignment for unassigned jobs                                 |
| **Edit Job**                | Update status, notes, and other job fields                                  |
| **Photo Capture**           | In-app camera (CameraAwesome) → compresses → uploads via MinIO presigned URL |
| **Customer Signature**      | On-screen signature pad → uploads to MinIO                                  |
| **Push Notifications (FCM)**| Foreground, background, and terminated-state handling; tapping notification deep-links to the relevant job |
| **Offline Resilience**      | `HydratedBloc` persists the last-known state; `connectivity_plus` monitors reachability |
| **Route Guards**            | `AuthGuard` protects all authenticated routes; dead JWT tokens trigger auto-logout |

---

## Known Limitations & Incomplete Features

| Area                          | Limitation / Status                                                                                             |
|-------------------------------|-----------------------------------------------------------------------------------------------------------------|
| **Test Coverage**             | The frontend features extensive foundational unit tests for validators, and robust E2E UI integrations targeting Login logic, App-wide navigation, and Push Notification routing. Tests for the lowest-level repository and network parsing layers directly interacting with the live internet remain unwritten. |
| **Google Maps API Key**       | The key must be manually added to `android/app/src/main/AndroidManifest.xml` and `ios/Runner/AppDelegate.swift`. A missing key renders the map blank. |
| **Firebase Config Files**     | `google-services.json` and `GoogleService-Info.plist` are gitignored. FCM will not work without them.          |
| **API Base URL is a constant**| `baseUrl` and `minioEndpoint` are hardcoded in `constants.dart`. There is no runtime environment switcher or `.env` support; changing targets requires a code edit and rebuild. |
| **MinIO Credentials Exposed** | `minioAccessKey` / `minioSecretKey` are currently hardcoded defaults (`minioadmin`). These must be rotated and injected at build time before any production deployment. |
| **No Admin / Manager Role UI**| The app is designed for **field workers** only. There is no UI for managers to create, reassign, or delete jobs from the mobile app — those actions are backend-admin or web-only. |
| **Job Deletion**              | The repository layer supports `deleteJob`, but there is no delete button exposed in the UI.                     |
| **Pagination (Jobs List)**    | Cursor-based pagination is implemented in the API layer but the UI loads the first page only; infinite scroll / load-more is not wired up. |
| **Signature Viewer**          | Signatures are displayed as images fetched from MinIO presigned URLs. If the URL expires (default: 30 min), the image will fail to load and show an error state. |
| **Portrait-Only**             | The app is locked to portrait orientation (`DeviceOrientation.portraitUp/Down`). Landscape layout is not supported. |
| **iOS Background Notifications** | Background FCM delivery on iOS depends on APNs configuration. Without a valid APNs key in the Firebase project this will silently fail on iOS physical devices. |
| **Deep-Link Navigation**      | Maps deep-linking (directions) uses `url_launcher`. On simulators with no Maps app installed the link will silently fail. |

---

## Development Utilities

### Re-generate code after model/route changes

```bash
bash runner.sh
# Equivalent to:
flutter pub run build_runner build --delete-conflicting-outputs
```

### Analyze code for lint issues

```bash
flutter analyze
```

### Check for outdated packages

```bash
flutter pub outdated
```
