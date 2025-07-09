// lib/startup/tasks/database_task.dart
import 'dart:async';
import 'dart:math';
import '../startup_task.dart';
import '../startup_context.dart';

/// Initializes the local database.
class DatabaseTask extends StartupTask<String> {
  @override
  String get id => 'DatabaseTask';

  @override
  Set<String> get dependencies => {}; // No dependencies, can run early

  @override
  bool isEnabled(Map<String, dynamic> flags) {
    return flags['database_enabled'] ?? true;
  }

  @override
  Future<String> run(StartupContext context) async {
    context.observabilityService.logInfo('$id: Initializing local database...');
    await Future.delayed(Duration(milliseconds: 500 + Random().nextInt(300)));

    // Simulate opening a database connection
    final dbPath = 'local_db_instance_path_${Random().nextInt(100)}';
    context.observabilityService.logInfo('$id: Local database initialized at $dbPath.');
    return dbPath;
  }
}
