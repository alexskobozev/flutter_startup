// lib/startup/results/app_flags.dart

/// A type-safe wrapper for the feature flags map.
/// Used for dependency injection with GetIt.
class AppFlags {
  final Map<String, dynamic> values;
  AppFlags(this.values);

  @override
  String toString() => 'AppFlags(values: $values)';
}
