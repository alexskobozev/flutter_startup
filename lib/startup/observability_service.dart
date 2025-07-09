// lib/startup/observability_service.dart

// No direct dependencies on other startup files for this one,
// but StartupOrchestrator will depend on it.

/// Represents the progress of the startup sequence.
/// Emitted by the [StartupOrchestrator] for UI updates.
class StartupProgress {
  final String currentTaskName;
  final int completedTasks;
  final int totalTasks;

  StartupProgress({
    required this.currentTaskName,
    required this.completedTasks,
    required this.totalTasks,
  });

  double get percentage => totalTasks > 0 ? completedTasks / totalTasks : 0.0;

  @override
  String toString() {
    return 'StartupProgress: $currentTaskName ($completedTasks/$totalTasks)';
  }
}

/// A stub for an observability service.
/// In a real application, this would integrate with services like Firebase Analytics,
/// Sentry, or a custom logging backend.
class ObservabilityService {
  void logInfo(String message) {
    // ignore: avoid_print
    print('[INFO] $message');
  }

  void logVerbose(String message) {
    // ignore: avoid_print
    print('[VERBOSE] $message');
  }

  void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    // ignore: avoid_print
    print('[ERROR] $message');
    if (error != null) {
      // ignore: avoid_print
      print('  Error: $error');
    }
    if (stackTrace != null) {
      // ignore: avoid_print
      print('  StackTrace: $stackTrace');
    }
  }

  void recordStartupTaskTiming(String taskName, Duration duration, bool success) {
    logInfo('Startup Task "$taskName" ${success ? 'succeeded' : 'failed'} in ${duration.inMilliseconds}ms.');
  }

  void trackAppEvent(String eventName, {Map<String, dynamic>? parameters}) {
    logInfo('App Event: $eventName, Parameters: $parameters');
  }
}
