# Firebase Integration Documentation

## Overview

Firebase is integrated into the Flutter application to provide managed backend
services. The current integration establishes the foundation for application
startup, user authentication, and cloud-based data persistence without requiring
a custom backend server.

The MVP uses Firebase Core, Firebase Authentication, and Cloud Firestore.
Firebase Storage is intentionally outside the current scope.

## Firebase Project Setup

A Firebase project was created through the Firebase Console, and the Flutter
application was registered with that project. The FlutterFire CLI was then used
to associate the local Flutter application with the Firebase project:

```bash
flutterfire configure
```

The command selected the appropriate Firebase project and application platforms,
then generated the platform-aware configuration file:

- `lib/firebase_options.dart`

This generated file exposes the Firebase configuration required by each
supported platform.

## Installed Dependencies

The following Firebase packages are declared in `pubspec.yaml`:

| Package | Purpose |
|---------|---------|
| `firebase_core` | Provides the core APIs required to initialize Firebase and use other Firebase plugins. |
| `firebase_auth` | Provides Firebase Authentication APIs, including anonymous sign-in, access to the current user, and sign-out. |
| `cloud_firestore` | Provides access to Cloud Firestore, Firebase's scalable cloud-hosted NoSQL database. |

These packages are resolved with the rest of the Flutter dependencies by running
`flutter pub get`.

## Firebase Initialization

Firebase is initialized before any Firebase-dependent service is used. The
application startup entry point initializes Firebase as follows:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const App());
}
```

The startup sequence performs the following operations:

- `WidgetsFlutterBinding.ensureInitialized()` creates and initializes the Flutter
  framework binding before asynchronous platform-channel operations are
  performed.
- `Firebase.initializeApp()` initializes the default Firebase application. The
  `await` ensures initialization completes before the widget tree starts.
- `DefaultFirebaseOptions.currentPlatform` selects the generated Firebase
  configuration for the platform on which the application is running.

After initialization, startup ensures that an anonymous session exists and
enables the Cloud Firestore network client before rendering the application.

## Authentication

Anonymous Authentication is enabled for the Firebase project through the
Firebase Console. This method allows the application to create a temporary
Firebase user identity without requiring an email address, password, or
third-party identity provider.

Authentication logic belongs in:

`lib/services/firebase_auth_service.dart`

The service encapsulates `FirebaseAuth` and exposes the following
operations:

- Anonymous sign-in through `signInAnonymously()`
- Session assurance through `ensureAnonymousUser()`, which reuses an existing
  session and signs in anonymously only when no session exists
- Access to the currently authenticated user through `currentUser`
- Access to the verified Firebase UID through `currentUserId`
- Sign-out through `signOut()`

A dedicated service layer prevents presentation code from depending directly on
Firebase APIs. It creates a clear boundary around authentication, improves
testability, centralizes error handling, and makes a future authentication
implementation easier to replace or extend.

## Cloud Firestore

Cloud Firestore is enabled through the Firebase Console and serves as the
application's cloud database. It will be used to store and synchronize
application data as persistence requirements are introduced.

The `cloud_firestore` package provides the Flutter APIs for accessing
collections, documents, queries, and real-time data streams. Data models,
collection paths, security rules, and repository-level Firestore operations
should be documented as those features are implemented.

## Generated Configuration Files

The Firebase setup produces platform and application configuration files that
must remain available to the build:

| File | Purpose |
|------|---------|
| `lib/firebase_options.dart` | Contains generated `FirebaseOptions` values and selects the correct configuration for the current Flutter platform. It is consumed by `Firebase.initializeApp()`. |
| `android/app/google-services.json` | Contains the Android Firebase application configuration. The Google Services Gradle plugin processes it so the Android build can connect to the registered Firebase application. |

These files contain project identifiers and configuration values rather than
Firebase administrator credentials. Nevertheless, changes should normally be
made by rerunning FlutterFire configuration or downloading an updated platform
configuration from Firebase rather than editing generated values manually.

## Firebase Service Status

| Service | Status |
|----------|--------|
| Firebase Core | Configured and initialized during startup |
| Firebase Authentication | Enabled (Anonymous); session ensured during startup |
| Cloud Firestore | Enabled; network client initialized during startup |
| FlutterFire CLI | Configured |
| Firebase Storage | Excluded from MVP |

## MVP Scope

Firebase Storage is intentionally excluded from the Minimum Viable Product
(MVP). The application currently has no requirement to upload, download, or
manage user-generated files such as images, videos, or documents. Omitting the
service keeps the initial architecture and Firebase configuration focused on
the features required by the application.

Firebase Storage can be added later if file-storage requirements are introduced.

## Project Structure

The Firebase-related files are organized as follows:

```text
lib/
├── firebase_options.dart
├── main.dart
└── services/
    └── firebase_auth_service.dart

android/
└── app/
    └── google-services.json

docs/
└── firebase.md
```

## Conclusion

Firebase has been integrated into the Flutter application and initializes during
startup. The application reuses the current authenticated user or creates an
anonymous identity when no session exists, and the Firebase UID is available
through the authentication service. Cloud Firestore is enabled and its network
client is prepared for future multiplayer data persistence and synchronization.
Firebase Storage remains intentionally excluded from the MVP.
