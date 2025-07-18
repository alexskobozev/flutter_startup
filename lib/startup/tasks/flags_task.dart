// lib/startup/tasks/flags_task.dart
import 'dart:async';
import 'dart:math';
import '../results/app_flags.dart';
import '../results/google_id.dart';
import '../startup_task.dart';
import '../startup_context.dart';

/// Fetches remote configuration flags.
/// In this demo, it just returns the hardcoded flags from the context.
class FlagsTask extends StartupTask<AppFlags> {
  static const String id = 'FlagsTask';

  @override
  String get id => FlagsTask.id;

  @override
  Set<Type> get dependencies => {
        GoogleId,
        bool, // From ObservabilityInitTask
      };

  @override
  bool isEnabled(Map<String, dynamic> flags) => true; // Always needed

  @override
  Future<AppFlags> run(StartupContext context) async {
    context.observabilityService.logInfo('$id: Fetching feature flags...');

    // Example of getting a dependency
    final googleId = context.get<GoogleId>();
    context.observabilityService.logVerbose('$id: Flags task has access to ${googleId.toString()}');

    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 300 + Random().nextInt(150)));

    // In a real app, this would fetch from a remote config service.
    // Here, we just use the flags already provided to the orchestrator/context.
    final flags = context.flags;
    context.observabilityService.logInfo('$id: Feature flags fetched: $flags');
    return AppFlags(flags);
  }
}
