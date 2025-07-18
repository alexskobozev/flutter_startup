// lib/startup/tasks/console_logger_task.dart
import 'dart:async';
import '../startup_task.dart';
import '../startup_context.dart';

/// Initializes a simple console logger.
/// This task is always enabled and has no dependencies.
class ConsoleLoggerTask extends StartupTask<bool> {
  static const String id = 'ConsoleLoggerTask';

  @override
  String get id => ConsoleLoggerTask.id;

  @override
  Set<Type> get dependencies => {};

  @override
  bool isEnabled(Map<String, dynamic> flags) => true; // Always enabled

  @override
  Future<bool> run(StartupContext context) async {
    context.observabilityService.logInfo('$id: Initializing console logger...');
    // Simulate work
    await Future.delayed(const Duration(milliseconds: 150));
    // In a real app, this might configure a logging package.
    // For this demo, ObservabilityService already prints to console.
    context.observabilityService.logInfo('$id: Console logger initialized.');
    return true;
  }
}
