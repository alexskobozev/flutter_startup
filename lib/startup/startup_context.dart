// lib/startup/startup_context.dart

import 'observability_service.dart'; // Added import
import 'startup_task.dart'; // Added import for StartupTask.id documentation reference

/// Provides a shared context for [StartupTask]s.
/// It allows tasks to store and retrieve data, making results of one task
/// available to subsequent tasks. It also provides access to shared services
/// like [ObservabilityService].
class StartupContext {
  final Map<String, dynamic> _values = {};
  final ObservabilityService observabilityService;
  final Map<String, dynamic> flags;

  StartupContext({required this.observabilityService, required this.flags});

  /// Stores a value in the context, associated with a [key].
  /// Typically, the [key] is the [StartupTask.id] that produced the value.
  void put<T>(String key, T value) {
    _values[key] = value;
    observabilityService.logVerbose('StartupContext: $key registered with value $value');
  }

  /// Retrieves a value from the context by its [key].
  /// Throws an ArgumentError if the key is not found.
  T get<T>(String key) {
    if (_values.containsKey(key)) {
      return _values[key] as T;
    } else {
      observabilityService.logError('StartupContext: Value for key "$key" not found.');
      throw ArgumentError('Value for key "$key" not found in StartupContext.');
    }
  }

  /// Retrieves a value from the context if it exists, otherwise returns null.
  T? getOrNull<T>(String key) {
    return _values[key] as T?;
  }
}
