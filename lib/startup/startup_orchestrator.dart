// lib/startup/startup_orchestrator.dart
import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart'; // For @visibleForTesting
import 'package:get_it/get_it.dart';

import 'startup_task.dart';
import 'startup_context.dart';
import 'observability_service.dart';

/// Orchestrates the execution of startup tasks based on type-safe dependencies.
///
/// This class is responsible for:
/// 1. Determining the correct execution order of tasks based on their dependencies (topological sort by Type).
/// 2. Executing tasks sequentially according to the resolved order.
/// 3. Handling errors that occur during task execution.
/// 4. Reporting progress through a stream.
/// 5. Recording timing for each task.
class StartupOrchestrator {
  final List<StartupTask<dynamic>> _tasks;
  final StartupContext _context;
  final ObservabilityService _observabilityService;
  final Map<String, dynamic> _flags;
  final GetIt _getIt;

  final _progressStreamController = StreamController<StartupProgress>.broadcast();
  Stream<StartupProgress> get progressStream => _progressStreamController.stream;

  int _totalEnabledTasks = 0;
  int _completedTasksCount = 0;

  StartupOrchestrator({
    required List<StartupTask<dynamic>> tasks,
    required ObservabilityService observabilityService,
    required Map<String, dynamic> flags,
    required GetIt getIt,
  })  : _tasks = tasks,
        _observabilityService = observabilityService,
        _flags = flags,
        _getIt = getIt,
        _context = StartupContext(
            getIt: getIt,
            observabilityService: observabilityService,
            flags: flags);

  Future<bool> execute() async {
    _observabilityService.logInfo('StartupOrchestrator: Execution started.');
    final stopwatch = Stopwatch()..start();

    List<StartupTask<dynamic>> orderedTasks;
    try {
      orderedTasks = _getTasksInExecutionOrder();
    } catch (e, s) {
      _observabilityService.logError('StartupOrchestrator: Failed to determine task order.', e, s);
      _progressStreamController.addError(e, s);
      await _progressStreamController.close();
      return false;
    }

     if (orderedTasks.isEmpty && _tasks.isNotEmpty) {
      _observabilityService.logInfo('StartupOrchestrator: No tasks enabled or tasks list was empty.');
    } else {
      _observabilityService.logInfo('StartupOrchestrator: Execution order: ${orderedTasks.map((t) => t.id).join(' -> ')}');
    }

    _totalEnabledTasks = orderedTasks.length;
    _completedTasksCount = 0;

    _updateProgress("Initializing...", 0, _totalEnabledTasks);

    for (final task in orderedTasks) {
      _observabilityService.logInfo('StartupOrchestrator: Starting task: ${task.id}');
      _updateProgress(task.id, _completedTasksCount, _totalEnabledTasks);

      final taskStopwatch = Stopwatch()..start();
      try {
        final result = await task.run(_context);
        // Register the result with the context (GetIt) if it's not null and not a primitive `void`
        if (task.produces != void && result != null) {
            // The type of `result` must match `task.produces`.
            // `put` handles the `isRegistered` check.
            _context.put(result);
        }
        taskStopwatch.stop();
        _observabilityService.recordStartupTaskTiming(task.id, taskStopwatch.elapsed, true);
        _completedTasksCount++;
        _updateProgress(task.id, _completedTasksCount, _totalEnabledTasks);
      } catch (e, s) {
        taskStopwatch.stop();
        _observabilityService.recordStartupTaskTiming(task.id, taskStopwatch.elapsed, false);
        _observabilityService.logError('StartupOrchestrator: Task ${task.id} failed.', e, s);
        _progressStreamController.addError(e, s);
        await _progressStreamController.close();
        return false;
      }
    }

    stopwatch.stop();
    _observabilityService.logInfo('StartupOrchestrator: All tasks completed successfully in ${stopwatch.elapsedMilliseconds}ms.');
    await _progressStreamController.close();
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

  @visibleForTesting
  List<StartupTask<dynamic>> getTasksInExecutionOrder() {
    final enabledTasks = _tasks.where((task) => task.isEnabled(_flags)).toList();
    if (enabledTasks.isEmpty) {
      _observabilityService.logInfo("No tasks are enabled based on the current flags or task list is empty.");
      return [];
    }

    final List<StartupTask<dynamic>> sortedList = [];
    final Map<Type, _TaskNode> graph = {};
    final Map<Type, StartupTask> typeProducers = {};

    // Build the graph and validate producers
    for (final task in enabledTasks) {
      final producesType = task.produces;
      if (producesType != void) {
        if (typeProducers.containsKey(producesType)) {
          throw StateError('Duplicate producer for type $producesType: ${typeProducers[producesType]!.id} and ${task.id}');
        }
        typeProducers[producesType] = task;
      }
      graph[producesType] = _TaskNode(task);
    }

    // Validate dependencies and calculate in-degrees
    for (final node in graph.values) {
      for (final depType in node.task.dependencies) {
        if (!typeProducers.containsKey(depType) && !_getIt.isRegistered(type: depType)) {
          throw StateError('Task ${node.task.id} has an unknown dependency: $depType. No enabled task produces it and it is not pre-registered.');
        }

        // If another task produces this dependency, establish the link
        if (typeProducers.containsKey(depType)) {
          final producerNode = graph[depType]!;
          producerNode.dependents.add(node.task.produces);
          node.inDegree++;
        }
        // If the dependency is already in GetIt, its in-degree contribution is 0, so no action needed.
      }
    }

    final Queue<_TaskNode> queue = Queue.from(graph.values.where((node) => node.inDegree == 0));

    while(queue.isNotEmpty) {
      final node = queue.removeFirst();
      sortedList.add(node.task);

      for (final dependentType in node.dependents) {
        final dependentNode = graph[dependentType];
        if (dependentNode != null) {
          dependentNode.inDegree--;
          if (dependentNode.inDegree == 0) {
            queue.add(dependentNode);
          }
        }
      }
    }

    if (sortedList.length != enabledTasks.length) {
      final sortedIds = sortedList.map((t) => t.id).toSet();
      final cycleTasks = enabledTasks.where((t) => !sortedIds.contains(t.id)).map((t) => '${t.id}(produces: ${t.produces}, dependsOn: ${t.dependencies})').join(', ');
      throw StateError('Circular dependency detected in startup tasks. Offending tasks might include: $cycleTasks');
    }

    return sortedList;
  }

  void dispose() {
    _progressStreamController.close();
  }
}

/// Helper class for topological sort based on Types.
class _TaskNode {
  final StartupTask<dynamic> task;
  int inDegree = 0;
  final List<Type> dependents = []; // Types of tasks that depend on this task's produced type

  _TaskNode(this.task);
}
