// lib/startup/startup_task.dart

import 'startup_context.dart'; // Added import

/// Abstract class representing a single task in the startup sequence.
/// Each task can have dependencies on other tasks and can be enabled/disabled
/// based on configuration flags.
abstract class StartupTask<T> {
  /// A unique identifier for this task. Used for dependency resolution and context storage.
  String get id;

  /// A list of task IDs that must complete before this task can run.
  Set<String> get dependencies;

  /// Determines if this task should be executed based on the provided flags.
  /// [flags] is a map of configuration flags, typically from a remote config or local settings.
  bool isEnabled(Map<String, dynamic> flags);

  /// The core logic of the task. This method is called by the [StartupOrchestrator].
  /// [context] provides a way to share data between tasks and access services.
  Future<T> run(StartupContext context);
}
