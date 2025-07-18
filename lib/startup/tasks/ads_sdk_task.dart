// lib/startup/tasks/ads_sdk_task.dart
import 'dart:async';
import 'dart:math';
import '../results/app_flags.dart';
import '../results/google_id.dart';
import '../startup_task.dart';
import '../startup_context.dart';

/// Initializes the Ads SDK.
class AdsSdkTask extends StartupTask<bool> {
  static const String id = 'AdsSdkTask';

  @override
  String get id => AdsSdkTask.id;

  @override
  Set<Type> get dependencies => {GoogleId, AppFlags};

  @override
  bool isEnabled(Map<String, dynamic> flags) {
    return flags['ads_enabled'] ?? false; // Explicitly check 'ads_enabled'
  }

  @override
  Future<bool> run(StartupContext context) async {
    context.observabilityService.logInfo('$id: Initializing Ads SDK...');

    final googleId = context.get<GoogleId>();
    final appFlags = context.get<AppFlags>();
    context.observabilityService.logVerbose('$id: Ads SDK using Google ID: ${googleId.value} and flags: ${appFlags.values}');

    if (!(appFlags.values['ads_enabled'] ?? false)) {
        // This check is redundant if isEnabled is correctly implemented and respected by orchestrator,
        // but good for defense.
        context.observabilityService.logInfo('$id: Ads SDK initialization skipped as per flags.');
        return false;
    }

    await Future.delayed(Duration(milliseconds: 450 + Random().nextInt(250)));

    context.observabilityService.logInfo('$id: Ads SDK initialized.');
    return true;
  }
}
