// lib/startup/tasks/crashlytics_task.dart
import 'dart:async';
import 'dart:math';
import '../results/firebase_app_id.dart';
import '../startup_task.dart';
import '../startup_context.dart';

/// Initializes Crashlytics.
class CrashlyticsTask extends StartupTask<bool> {
  static const String id = 'CrashlyticsTask';

  @override
  String get id => CrashlyticsTask.id;

  @override
  Set<Type> get dependencies => {FirebaseAppId};

  @override
  bool isEnabled(Map<String, dynamic> flags) {
    // Depends on both a specific flag and the general firebase_enabled flag (implicitly via dependency)
    return flags['crashlytics_enabled'] ?? true;
  }

  @override
  Future<bool> run(StartupContext context) async {
    context.observabilityService.logInfo('$id: Initializing Crashlytics...');

    final firebaseAppId = context.get<FirebaseAppId>();
    context.observabilityService.logVerbose('$id: Crashlytics using Firebase App ID: ${firebaseAppId.value}');

    await Future.delayed(Duration(milliseconds: 150 + Random().nextInt(50)));

    // Simulate setting some user identifiers or custom keys
    context.observabilityService.logInfo('$id: Crashlytics initialized.');
    return true;
  }
}
