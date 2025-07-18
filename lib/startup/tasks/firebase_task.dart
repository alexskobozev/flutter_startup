// lib/startup/tasks/firebase_task.dart
import 'dart:async';
import 'dart:math';
import '../results/app_flags.dart';
import '../results/firebase_app_id.dart';
import '../startup_task.dart';
import '../startup_context.dart';

/// Initializes Firebase services.
class FirebaseTask extends StartupTask<FirebaseAppId> {
  static const String id = 'FirebaseTask';

  @override
  String get id => FirebaseTask.id;

  @override
  Set<Type> get dependencies => {AppFlags};

  @override
  bool isEnabled(Map<String, dynamic> flags) {
    return flags['firebase_enabled'] ?? true;
  }

  @override
  Future<FirebaseAppId> run(StartupContext context) async {
    context.observabilityService.logInfo('$id: Initializing Firebase...');

    // Access flags from context if needed for Firebase initialization
    final appFlags = context.get<AppFlags>();
    context.observabilityService.logVerbose('$id: Firebase init with flags: ${appFlags.values}');

    await Future.delayed(Duration(milliseconds: 400 + Random().nextInt(200)));

    final firebaseAppIdValue = 'mock-firebase-app-${Random().nextInt(100)}';
    context.observabilityService.logInfo('$id: Firebase initialized with App ID: $firebaseAppIdValue.');
    return FirebaseAppId(firebaseAppIdValue);
  }
}
