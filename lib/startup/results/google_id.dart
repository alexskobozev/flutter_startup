// lib/startup/results/google_id.dart

/// A type-safe wrapper for the Google Advertising ID string.
/// Used for dependency injection with GetIt.
class GoogleId {
  final String value;
  GoogleId(this.value);

  @override
  String toString() => 'GoogleId(value: $value)';
}
