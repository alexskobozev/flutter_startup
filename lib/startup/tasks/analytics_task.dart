// lib/startup/tasks/analytics_task.dart
import 'dart:async';
import 'dart:math';
import '../startup_task.dart';
import '../startup_context.dart';
import 'firebase_task.dart';
import 'flags_task.dart';

/// Initializes Analytics.
class AnalyticsTask extends StartupTask<bool> {
  static const String id = 'AnalyticsTask';

  @override
  String get id => AnalyticsTask.id;

  @override
  Set<String> get dependencies => {FirebaseTask.id, FlagsTask.id};

  @override
  bool isEnabled(Map<String, dynamic> flags) {
    return flags['analytics_enabled'] ?? true;
  }

  @override
  Future<bool> run(StartupContext context) async {
    context.observabilityService.logInfo('$id: Initializing Analytics...');

    final firebaseAppId = context.get<String>(FirebaseTask.id);
    final appFlags = context.get<Map<String, dynamic>>(FlagsTask.id);
    context.observabilityService.logVerbose('$id: Analytics using Firebase App ID: $firebaseAppId and flags: $appFlags');

    await Future.delayed(Duration(milliseconds: 200 + Random().nextInt(100)));

    context.observabilityService.trackAppEvent('$id:initialized', parameters: {'source': 'startup'});
    context.observabilityService.logInfo('$id: Analytics initialized.');
    return true;
  }
}
