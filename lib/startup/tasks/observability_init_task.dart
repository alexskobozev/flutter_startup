// lib/startup/tasks/observability_init_task.dart
import 'dart:async';
import 'dart:math';
import '../results/google_id.dart';
import '../startup_task.dart';
import '../startup_context.dart';

/// Initializes the observability service further, possibly with user identity.
class ObservabilityInitTask extends StartupTask<bool> {
  static const String id = 'ObservabilityInitTask';

  @override
  String get id => ObservabilityInitTask.id;

  @override
  Set<Type> get dependencies => {GoogleId};

  @override
  bool isEnabled(Map<String, dynamic> flags) {
    // Usually enabled, but could be tied to a master observability flag
    return flags['observability_enabled'] ?? true;
  }

  @override
  Future<bool> run(StartupContext context) async {
    context.observabilityService.logInfo('$id: Initializing observability service...');

    // Get Google ID from context
    final googleId = context.get<GoogleId>();
    context.observabilityService.logInfo('$id: Using Google ID: ${googleId.value} for observability user scope.');

    await Future.delayed(Duration(milliseconds: 250 + Random().nextInt(100)));

    // Simulate setting user properties or other init steps
    context.observabilityService.trackAppEvent('$id:initialized', parameters: {'googleIdLength': googleId.value.length});

    context.observabilityService.logInfo('$id: Observability service initialized.');
    return true;
  }
}
