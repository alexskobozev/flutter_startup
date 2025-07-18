// lib/startup/tasks/flags_task.dart
import 'dart:async';
import 'dart:math';
import '../startup_task.dart';
import '../startup_context.dart';
import 'google_id_task.dart';
import 'observability_init_task.dart';

/// Fetches remote configuration flags.
/// In this demo, it just returns the hardcoded flags from the context.
class FlagsTask extends StartupTask<Map<String, dynamic>> {
  static const String id = 'FlagsTask';

  @override
  String get id => FlagsTask.id;

  @override
  Set<String> get dependencies => {GoogleIdTask.id, ObservabilityInitTask.id};

  @override
  bool isEnabled(Map<String, dynamic> flags) => true; // Always needed

  @override
  Future<Map<String, dynamic>> run(StartupContext context) async {
    context.observabilityService.logInfo('$id: Fetching feature flags...');

    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 300 + Random().nextInt(150)));

    // In a real app, this would fetch from a remote config service.
    // Here, we just use the flags already provided to the orchestrator/context.
    final flags = context.flags;
    context.observabilityService.logInfo('$id: Feature flags fetched: $flags');
    return flags;
  }
}
