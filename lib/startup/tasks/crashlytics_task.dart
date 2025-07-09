// lib/startup/tasks/crashlytics_task.dart
import 'dart:async';
import 'dart:math';
import '../startup_task.dart';
import '../startup_context.dart';
import 'firebase_task.dart';

/// Initializes Crashlytics.
class CrashlyticsTask extends StartupTask<bool> {
  @override
  String get id => 'CrashlyticsTask';

  @override
  Set<String> get dependencies => {FirebaseTask().id};

  @override
  bool isEnabled(Map<String, dynamic> flags) {
    // Depends on both a specific flag and the general firebase_enabled flag (implicitly via dependency)
    return flags['crashlytics_enabled'] ?? true;
  }

  @override
  Future<bool> run(StartupContext context) async {
    context.observabilityService.logInfo('$id: Initializing Crashlytics...');

    final firebaseAppId = context.get<String>(FirebaseTask().id);
    context.observabilityService.logVerbose('$id: Crashlytics using Firebase App ID: $firebaseAppId');

    await Future.delayed(Duration(milliseconds: 150 + Random().nextInt(50)));

    // Simulate setting some user identifiers or custom keys
    context.observabilityService.logInfo('$id: Crashlytics initialized.');
    return true;
  }
}
