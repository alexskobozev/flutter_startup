// lib/startup/tasks/google_id_task.dart
import 'dart:async';
import 'dart:math';
import '../startup_task.dart';
import '../startup_context.dart';

/// Fetches a fake Google Advertising ID.
class GoogleIdTask extends StartupTask<String> {
  static const String id = 'GoogleIdTask';

  @override
  String get id => GoogleIdTask.id;

  @override
  Set<String> get dependencies => {}; // No explicit dependencies, but often a root for others

  @override
  bool isEnabled(Map<String, dynamic> flags) {
    // This task might be disabled if tracking is globally disabled,
    // for simplicity, let's assume it's always enabled if used.
    return true;
  }

  @override
  Future<String> run(StartupContext context) async {
    context.observabilityService.logInfo('$id: Fetching Google Advertising ID...');
    await Future.delayed(Duration(milliseconds: 200 + Random().nextInt(100)));

    // Simulate fetching a real ID
    final fakeId = 'fake-google-adv-id-${Random().nextInt(10000)}';
    context.observabilityService.logInfo('$id: Google Advertising ID fetched: $fakeId');
    return fakeId;
  }
}
