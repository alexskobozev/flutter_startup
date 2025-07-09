// lib/startup/tasks/firebase_task.dart
import 'dart:async';
import 'dart:math';
import '../startup_task.dart';
import '../startup_context.dart';
import 'flags_task.dart';

/// Initializes Firebase services.
class FirebaseTask extends StartupTask<String> {
  @override
  String get id => 'FirebaseTask';

  @override
  Set<String> get dependencies => {FlagsTask().id};

  @override
  bool isEnabled(Map<String, dynamic> flags) {
    return flags['firebase_enabled'] ?? true;
  }

  @override
  Future<String> run(StartupContext context) async {
    context.observabilityService.logInfo('$id: Initializing Firebase...');

    // Access flags from context if needed for Firebase initialization
    final appFlags = context.get<Map<String, dynamic>>(FlagsTask().id);
    context.observabilityService.logVerbose('$id: Firebase init with flags: $appFlags');

    await Future.delayed(Duration(milliseconds: 400 + Random().nextInt(200)));

    final firebaseAppId = 'mock-firebase-app-${Random().nextInt(100)}';
    context.observabilityService.logInfo('$id: Firebase initialized with App ID: $firebaseAppId.');
    return firebaseAppId;
  }
}
