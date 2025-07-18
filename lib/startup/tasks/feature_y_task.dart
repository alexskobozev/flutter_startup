// lib/startup/tasks/feature_y_task.dart
import 'dart:async';
import 'dart:math';
import '../startup_task.dart';
import '../startup_context.dart';
import 'analytics_task.dart';

/// Initializes a hypothetical Feature Y.
class FeatureYTask extends StartupTask<String> {
  static const String id = 'FeatureYTask';

  @override
  String get id => FeatureYTask.id;

  @override
  Set<String> get dependencies => {AnalyticsTask.id}; // Depends on analytics being ready

  @override
  bool isEnabled(Map<String, dynamic> flags) {
    return flags['feature_y_enabled'] ?? true; // Default to true if not specified
  }

  @override
  Future<String> run(StartupContext context) async {
    context.observabilityService.logInfo('$id: Initializing Feature Y...');

    // Potentially use analytics context if needed
    // final analyticsReady = context.get<bool>(AnalyticsTask().id);
    // context.observabilityService.logVerbose('$id: Feature Y sees analytics ready: $analyticsReady');

    await Future.delayed(Duration(milliseconds: 180 + Random().nextInt(120)));

    final result = 'FeatureY initialized and ready';
    context.observabilityService.logInfo('$id: $result');
    context.observabilityService.trackAppEvent('$id:activated');
    return result;
  }
}
