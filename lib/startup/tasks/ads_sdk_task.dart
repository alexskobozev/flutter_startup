// lib/startup/tasks/ads_sdk_task.dart
import 'dart:async';
import 'dart:math';
import '../startup_task.dart';
import '../startup_context.dart';
import 'google_id_task.dart';
import 'flags_task.dart';

/// Initializes the Ads SDK.
class AdsSdkTask extends StartupTask<bool> {
  static const String id = 'AdsSdkTask';

  @override
  String get id => AdsSdkTask.id;

  @override
  Set<String> get dependencies => {GoogleIdTask.id, FlagsTask.id};

  @override
  bool isEnabled(Map<String, dynamic> flags) {
    return flags['ads_enabled'] ?? false; // Explicitly check 'ads_enabled'
  }

  @override
  Future<bool> run(StartupContext context) async {
    context.observabilityService.logInfo('$id: Initializing Ads SDK...');

    final googleId = context.get<String>(GoogleIdTask.id);
    final appFlags = context.get<Map<String, dynamic>>(FlagsTask.id);
    context.observabilityService.logVerbose('$id: Ads SDK using Google ID: $googleId and flags: $appFlags');

    if (!(appFlags['ads_enabled'] ?? false)) {
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
