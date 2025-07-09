// lib/startup/startup_orchestrator.dart
import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart'; // For @visibleForTesting

import 'startup_task.dart';
import 'startup_context.dart';
import 'observability_service.dart';

/// Orchestrates the execution of startup tasks.
///
/// This class is responsible for:
/// 1. Determining the correct execution order of tasks based on their dependencies (topological sort).
/// 2. Executing tasks sequentially according to the resolved order.
/// 3. Handling errors that occur during task execution.
/// 4. Reporting progress through a stream.
/// 5. Recording timing for each task.
class StartupOrchestrator {
  final List<StartupTask<dynamic>> _tasks;
  final StartupContext _context;
  final ObservabilityService _observabilityService;
  final Map<String, dynamic> _flags;

  final _progressStreamController = StreamController<StartupProgress>.broadcast();
  Stream<StartupProgress> get progressStream => _progressStreamController.stream;

  int _totalEnabledTasks = 0;
  int _completedTasksCount = 0;

  StartupOrchestrator({
    required List<StartupTask<dynamic>> tasks,
    required ObservabilityService observabilityService,
    required Map<String, dynamic> flags,
  })  : _tasks = tasks,
        _observabilityService = observabilityService,
        _flags = flags,
        _context = StartupContext(observabilityService: observabilityService, flags: flags);

  /// Executes all registered startup tasks respecting their dependencies.
  ///
  /// Returns `true` if all tasks complete successfully, `false` otherwise.
  /// Emits [StartupProgress] events on the [progressStream].
  /// In case of an error in any task, execution stops, an error is logged,
  /// and `false` is returned.
  Future<bool> execute() async {
    _observabilityService.logInfo('StartupOrchestrator: Execution started.');
    final stopwatch = Stopwatch()..start();

    List<StartupTask<dynamic>> orderedTasks;
    try {
      orderedTasks = _getTasksInExecutionOrder();
    } catch (e, s) {
      _observabilityService.logError('StartupOrchestrator: Failed to determine task order.', e, s);
      _progressStreamController.addError(e, s);
      _progressStreamController.close();
      return false;
    }

    if (orderedTasks.isEmpty && _tasks.isNotEmpty) {
        _observabilityService.logInfo('StartupOrchestrator: No tasks enabled or tasks list was empty.');
    } else {
      _observabilityService.logInfo('StartupOrchestrator: Execution order: ${orderedTasks.map((t) => t.id).join(', ')}');
    }

    _totalEnabledTasks = orderedTasks.length;
    _completedTasksCount = 0;

    // Initial progress before first task
    _updateProgress("Initializing...", _completedTasksCount, _totalEnabledTasks);

    for (final task in orderedTasks) {
      _observabilityService.logInfo('StartupOrchestrator: Starting task: ${task.id}');
      _updateProgress(task.id, _completedTasksCount, _totalEnabledTasks);

      final taskStopwatch = Stopwatch()..start();
      try {
        final result = await task.run(_context);
        _context.put(task.id, result); // Store result even if null, to mark completion
        taskStopwatch.stop();
        _observabilityService.recordStartupTaskTiming(task.id, taskStopwatch.elapsed, true);
        _completedTasksCount++;
        _updateProgress(task.id, _completedTasksCount, _totalEnabledTasks);
      } catch (e, s) {
        taskStopwatch.stop();
        _observabilityService.recordStartupTaskTiming(task.id, taskStopwatch.elapsed, false);
        _observabilityService.logError('StartupOrchestrator: Task ${task.id} failed.', e, s);
        _progressStreamController.addError(e, s); // Propagate error to stream listeners
        _progressStreamController.close();
        return false; // Stop execution on first error
      }
    }

    stopwatch.stop();
    _observabilityService.logInfo('StartupOrchestrator: All tasks completed successfully in ${stopwatch.elapsedMilliseconds}ms.');
    _progressStreamController.close();
    return true;
  }

  void _updateProgress(String currentTaskName, int completed, int total) {
    if (!_progressStreamController.isClosed) {
       final progress = StartupProgress(
        currentTaskName: currentTaskName,
        completedTasks: completed,
        totalTasks: total,
      );
      _progressStreamController.add(progress);
    }
  }

  /// Performs a topological sort of the tasks.
  /// Filters out disabled tasks before sorting.
  @visibleForTesting
  List<StartupTask<dynamic>> getTasksInExecutionOrder() {
    final enabledTasks = _tasks.where((task) => task.isEnabled(_flags)).toList();
    if (enabledTasks.isEmpty && _tasks.isNotEmpty) {
        _observabilityService.logInfo("No tasks are enabled based on the current flags.");
        return [];
    }
    if (enabledTasks.isEmpty && _tasks.isEmpty) {
        _observabilityService.logInfo("Task list is empty.");
        return [];
    }


    final List<StartupTask<dynamic>> sortedList = [];
    final Map<String, _TaskNode> graph = {};
    final Set<String> allTaskIds = enabledTasks.map((t) => t.id).toSet();

    // Build the graph
    for (final task in enabledTasks) {
      if (graph.containsKey(task.id)) {
        throw StateError("Duplicate task ID found: ${task.id}. Task IDs must be unique.");
      }
      graph[task.id] = _TaskNode(task);
      // Validate dependencies
      for (final depId in task.dependencies) {
        if (!allTaskIds.contains(depId)) {
          throw StateError("Task ${task.id} has an unknown dependency: $depId. Ensure all dependencies are registered and enabled.");
        }
      }
    }

    // Calculate in-degrees
    for (final taskNode in graph.values) {
      for (final depId in taskNode.task.dependencies) {
        // Dependency must be an enabled task
        if (graph.containsKey(depId)) {
            graph[depId]!.dependents.add(taskNode.task.id);
            taskNode.inDegree++;
        } else {
            // This case should be caught by the isEnabled filter or the earlier check,
            // but as a safeguard:
            _observabilityService.logVerbose("Task ${taskNode.task.id} depends on $depId, which is not enabled or present. This dependency will be ignored.");
        }
      }
    }

    final Queue<_TaskNode> queue = Queue();
    for (final taskNode in graph.values) {
      if (taskNode.inDegree == 0) {
        queue.add(taskNode);
      }
    }

    while (queue.isNotEmpty) {
      final node = queue.removeFirst();
      sortedList.add(node.task);

      for (final dependentId in node.dependents) {
        final dependentNode = graph[dependentId]!;
        dependentNode.inDegree--;
        if (dependentNode.inDegree == 0) {
          queue.add(dependentNode);
        }
      }
    }

    if (sortedList.length != enabledTasks.length) {
      final Set<String> sortedTaskIds = sortedList.map((t) => t.id).toSet();
      final List<String> cycleTasks = enabledTasks
          .where((t) => !sortedTaskIds.contains(t.id))
          .map((t) => t.id)
          .toList();
      throw StateError(
          'Circular dependency detected in startup tasks, or missing dependency. Offending tasks might include: ${cycleTasks.join(', ')}');
    }

    return sortedList;
  }

  void dispose() {
    _progressStreamController.close();
  }
}

/// Helper class for topological sort.
class _TaskNode {
  final StartupTask<dynamic> task;
  int inDegree = 0;
  final List<String> dependents = []; // Tasks that depend on this task

  _TaskNode(this.task);
}
