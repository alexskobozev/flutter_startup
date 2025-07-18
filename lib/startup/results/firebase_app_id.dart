// lib/startup/results/firebase_app_id.dart

/// A type-safe wrapper for the Firebase App ID string.
/// Used for dependency injection with GetIt.
class FirebaseAppId {
  final String value;
  FirebaseAppId(this.value);

  @override
  String toString() => 'FirebaseAppId(value: $value)';
}
