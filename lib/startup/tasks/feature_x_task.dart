// lib/startup/tasks/feature_x_task.dart
import 'dart:async';
import 'dart:math';
import '../startup_task.dart';
import '../startup_context.dart';
import 'database_task.dart';
import 'remote_config_task.dart';

/// Initializes a hypothetical Feature X.
class FeatureXTask extends StartupTask<String> {
  @override
  String get id => 'FeatureXTask';

  @override
  Set<String> get dependencies => {DatabaseTask().id, RemoteConfigTask().id};

  @override
  bool isEnabled(Map<String, dynamic> flags) {
    // This feature might be enabled via remote config, fetched by RemoteConfigTask
    // For the demo, let's assume RemoteConfigTask puts its results into context.flags
    // or that context.flags is the unified view of all configurations.
    // We'll use a specific flag for this feature.
    return flags['feature_x_enabled'] ?? false;
  }

  @override
  Future<String> run(StartupContext context) async {
    context.observabilityService.logInfo('$id: Initializing Feature X...');

    final dbPath = context.get<String>(DatabaseTask().id);
    final remoteConfig = context.get<Map<String,dynamic>>(RemoteConfigTask().id);
    final featureXSpecificSetting = remoteConfig['feature_X_specific_setting'] ?? 'default_X';

    context.observabilityService.logVerbose('$id: Feature X using DB: $dbPath and config: $featureXSpecificSetting');

    await Future.delayed(Duration(milliseconds: 220 + Random().nextInt(80)));

    final result = 'FeatureX initialized with $featureXSpecificSetting';
    context.observabilityService.logInfo('$id: $result');
    return result;
  }
}
