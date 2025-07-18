// lib/startup/tasks/analytics_task.dart
import 'dart:async';
import 'dart:math';
import '../results/app_flags.dart';
import '../results/firebase_app_id.dart';
import '../startup_task.dart';
import '../startup_context.dart';

/// Initializes Analytics.
class AnalyticsTask extends StartupTask<bool> {
  static const String id = 'AnalyticsTask';

  @override
  String get id => AnalyticsTask.id;

  @override
  Set<Type> get dependencies => {FirebaseAppId, AppFlags};

  @override
  bool isEnabled(Map<String, dynamic> flags) {
    return flags['analytics_enabled'] ?? true;
  }

  @override
  Future<bool> run(StartupContext context) async {
    context.observabilityService.logInfo('$id: Initializing Analytics...');

    final firebaseAppId = context.get<FirebaseAppId>();
    final appFlags = context.get<AppFlags>();
    context.observabilityService.logVerbose('$id: Analytics using Firebase App ID: ${firebaseAppId.value} and flags: ${appFlags.values}');

    await Future.delayed(Duration(milliseconds: 200 + Random().nextInt(100)));

    context.observabilityService.trackAppEvent('$id:initialized', parameters: {'source': 'startup'});
    context.observabilityService.logInfo('$id: Analytics initialized.');
    return true;
  }
}
