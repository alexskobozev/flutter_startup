// lib/startup/tasks/feature_y_task.dart
import 'dart:async';
import 'dart:math';
import '../startup_task.dart';
import '../startup_context.dart';

/// Initializes a hypothetical Feature Y.
class FeatureYTask extends StartupTask<bool> {
  static const String id = 'FeatureYTask';

  @override
  String get id => FeatureYTask.id;

  @override
  Set<Type> get dependencies => {bool}; // Depends on analytics being ready (which returns bool)

  @override
  bool isEnabled(Map<String, dynamic> flags) {
    return flags['feature_y_enabled'] ?? true; // Default to true if not specified
  }

  @override
  Future<bool> run(StartupContext context) async {
    context.observabilityService.logInfo('$id: Initializing Feature Y...');

    // Potentially use analytics context if needed
    final analyticsReady = context.get<bool>(); // This will get the first bool registered, which is from AnalyticsTask
    context.observabilityService.logVerbose('$id: Feature Y sees analytics ready: $analyticsReady');

    await Future.delayed(Duration(milliseconds: 180 + Random().nextInt(120)));

    final result = 'FeatureY initialized and ready';
    context.observabilityService.logInfo('$id: $result');
    context.observabilityService.trackAppEvent('$id:activated');
    return true;
  }
}
