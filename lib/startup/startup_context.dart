// lib/startup/startup_context.dart

import 'package:get_it/get_it.dart';

import 'observability_service.dart';

/// Provides a shared context for [StartupTask]s using a service locator (`GetIt`).
/// It allows tasks to register and retrieve dependencies by their type.
/// It also provides access to shared services like [ObservabilityService].
class StartupContext {
  final GetIt getIt;
  final ObservabilityService observabilityService;
  final Map<String, dynamic> flags;

  StartupContext({
    required this.getIt,
    required this.observabilityService,
    required this.flags,
  });

  /// Registers a value (singleton) in the service locator.
  /// The value is registered under its specific [Type].
  void put<T extends Object>(T value) {
    // Note: We are registering the result of a task as a singleton.
    // The orchestrator ensures we don't try to register the same type twice.
    if (!getIt.isRegistered<T>()) {
      getIt.registerSingleton<T>(value);
      observabilityService.logVerbose('StartupContext: Type ${T.toString()} registered with value $value');
    } else {
      // This should not happen if the graph is resolved correctly.
      observabilityService.logError('StartupContext: Attempted to register Type ${T.toString()} which is already registered.');
    }
  }

  /// Retrieves a value from the service locator by its [Type].
  /// Throws an exception if the type is not found.
  T get<T extends Object>() {
    try {
      return getIt.get<T>();
    } catch (e) {
      observabilityService.logError('StartupContext: Value for type "${T.toString()}" not found.');
      // Re-throw to fail the task, as this is a critical dependency failure.
      rethrow;
    }
  }

  /// Retrieves a value from the context if it exists, otherwise returns null.
  T? getOrNull<T extends Object>() {
    if (getIt.isRegistered<T>()) {
      return getIt.get<T>();
    }
    return null;
  }
}
