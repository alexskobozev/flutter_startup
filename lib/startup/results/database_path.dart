// lib/startup/results/database_path.dart

/// A type-safe wrapper for the database path string.
/// Used for dependency injection with GetIt.
class DatabasePath {
  final String value;
  DatabasePath(this.value);

  @override
  String toString() => 'DatabasePath(value: $value)';
}
