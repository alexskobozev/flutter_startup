// lib/startup/tasks/database_task.dart
import 'dart:async';
import 'dart:math';
import '../results/database_path.dart';
import '../startup_task.dart';
import '../startup_context.dart';

/// Initializes the local database.
class DatabaseTask extends StartupTask<DatabasePath> {
  static const String id = 'DatabaseTask';

  @override
  String get id => DatabaseTask.id;

  @override
  Set<Type> get dependencies => {}; // No dependencies, can run early

  @override
  bool isEnabled(Map<String, dynamic> flags) {
    return flags['database_enabled'] ?? true;
  }

  @override
  Future<DatabasePath> run(StartupContext context) async {
    context.observabilityService.logInfo('$id: Initializing local database...');
    await Future.delayed(Duration(milliseconds: 500 + Random().nextInt(300)));

    // Simulate opening a database connection
    final dbPathValue = 'local_db_instance_path_${Random().nextInt(100)}';
    context.observabilityService.logInfo('$id: Local database initialized at $dbPathValue.');
    return DatabasePath(dbPathValue);
  }
}
