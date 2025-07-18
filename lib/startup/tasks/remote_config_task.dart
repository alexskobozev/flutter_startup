// lib/startup/tasks/remote_config_task.dart
import 'dart:async';
import 'dart:math';
import '../results/firebase_app_id.dart';
import '../startup_task.dart';
import '../startup_context.dart';

/// Initializes and fetches Remote Configuration.
/// Note: This task is distinct from FlagsTask. FlagsTask might represent initial/local flags,
/// while RemoteConfigTask would be the actual fetching part if they were separate.
/// For this demo, its role is similar to FlagsTask but can have different dependencies.
class RemoteConfigTask extends StartupTask<Map<String, dynamic>> {
  static const String id = 'RemoteConfigTask';

  @override
  String get id => RemoteConfigTask.id;

  @override
  Set<Type> get dependencies => {
        FirebaseAppId,
        bool, // From ObservabilityInitTask
      };

  @override
  bool isEnabled(Map<String, dynamic> flags) {
    return flags['remote_config_enabled'] ?? true;
  }

  @override
  Future<Map<String, dynamic>> run(StartupContext context) async {
    context.observabilityService.logInfo('$id: Initializing and fetching Remote Config...');

    final firebaseAppId = context.get<FirebaseAppId>();
    context.observabilityService.logVerbose('$id: Remote Config using Firebase App ID: ${firebaseAppId.value}');

    // Simulate fetching remote values
    await Future.delayed(Duration(milliseconds: 350 + Random().nextInt(150)));

    final remoteValues = {
      'feature_A_enabled': Random().nextBool(),
      'some_string_value': 'FetchedFromRemote-${Random().nextInt(100)}',
      'some_int_value': Random().nextInt(1000),
    };

    // In a real app, you might merge these with local defaults or existing flags.
    // Here, we just return them. They are also available via context.flags.
    // This task could also update the context.flags if it were designed to.
    context.observabilityService.logInfo('$id: Remote Config fetched: $remoteValues');
    return remoteValues;
  }
}
