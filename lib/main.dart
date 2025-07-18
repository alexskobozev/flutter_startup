import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

// Startup Pipeline Core
import 'startup/observability_service.dart';
import 'startup/startup_orchestrator.dart';
import 'startup/startup_task.dart';

// Results Wrappers
import 'startup/results/app_flags.dart';
import 'startup/results/database_path.dart';
import 'startup/results/firebase_app_id.dart';
import 'startup/results/google_id.dart';


// Startup Tasks
import 'startup/tasks/console_logger_task.dart';
import 'startup/tasks/google_id_task.dart';
import 'startup/tasks/observability_init_task.dart';
import 'startup/tasks/flags_task.dart';
import 'startup/tasks/firebase_task.dart';
import 'startup/tasks/crashlytics_task.dart';
import 'startup/tasks/database_task.dart';
import 'startup/tasks/analytics_task.dart';
import 'startup/tasks/remote_config_task.dart';
import 'startup/tasks/ads_sdk_task.dart';
import 'startup/tasks/feature_x_task.dart';
import 'startup/tasks/feature_y_task.dart';

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// --- Fake Flags Configuration ---
final Map<String, dynamic> fakeFlags = {
  // General services
  'observability_enabled': true,
  'firebase_enabled': true,
  'database_enabled': true,
  'remote_config_enabled': true,

  // Feature-specific
  'crashlytics_enabled': true,
  'analytics_enabled': true,
  'ads_enabled': false, // Ads are disabled by default
  'feature_x_enabled': true,
  'feature_y_enabled': true,

  // Task-specific overrides (if any task needs finer control not covered by above)
  // e.g. 'SpecificSubFeatureOfFirebase': false
};


void main() {
  final getIt = GetIt.instance;
  final observabilityService = ObservabilityService(); // Instantiate your stub

  // Pre-register services that are needed by the context or tasks but aren't
  // produced by a task themselves.
  getIt.registerSingleton<ObservabilityService>(observabilityService);

  // Instantiate all tasks
  final List<StartupTask<dynamic>> allTasks = [
    ConsoleLoggerTask(),
    GoogleIdTask(),
    ObservabilityInitTask(),
    FlagsTask(),
    FirebaseTask(),
    CrashlyticsTask(),
    DatabaseTask(),
    AnalyticsTask(),
    RemoteConfigTask(),
    AdsSdkTask(),
    FeatureXTask(),
    FeatureYTask(),
  ];

  final orchestrator = StartupOrchestrator(
    tasks: allTasks,
    observabilityService: observabilityService,
    flags: fakeFlags,
    getIt: getIt,
  );

  runApp(MyApp(orchestrator: orchestrator));
}

class MyApp extends StatelessWidget {
  final StartupOrchestrator orchestrator;

  const MyApp({super.key, required this.orchestrator});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Startup Pipeline Demo',
      navigatorKey: navigatorKey, // Assign navigatorKey
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashScreen(orchestrator: orchestrator),
    );
  }
}

// --- UI Screens ---

class SplashScreen extends StatefulWidget {
  final StartupOrchestrator orchestrator;

  const SplashScreen({super.key, required this.orchestrator});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  StreamSubscription<StartupProgress>? _progressSubscription;
  StartupProgress? _currentProgress;
  String _statusMessage = "Initializing application...";

  @override
  void initState() {
    super.initState();
    _startStartupSequence();
  }

  Future<void> _startStartupSequence() async {
    _progressSubscription = widget.orchestrator.progressStream.listen(
      (progress) {
        if (mounted) {
          setState(() {
            _currentProgress = progress;
            _statusMessage = "Running: ${progress.currentTaskName}";
          });
        }
      },
      onError: (error, stackTrace) {
        if (mounted) {
          widget.orchestrator.observabilityService.logError(
              "Error during startup sequence", error, stackTrace);
          navigatorKey.currentState?.pushReplacement(
            MaterialPageRoute(
              builder: (_) => FatalErrorScreen(
                errorMessage: error.toString(),
                stackTrace: stackTrace.toString(),
              ),
            ),
          );
        }
      },
      onDone: () {
        // This onDone will be called if the stream closes successfully.
        // Error case is handled by onError.
        // We need to check if it was successful or if an error occurred before onDone.
        // The orchestrator.execute() future result tells us the actual outcome.
      },
    );

    // Execute the orchestrator
    final bool success = await widget.orchestrator.execute();

    if (mounted) {
      if (success) {
        navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        // Error should have been caught by stream's onError,
        // but as a fallback or if error happens outside stream emission:
        if (navigatorKey.currentState?.canPop() == false) { // Ensure it hasn't already navigated
           navigatorKey.currentState?.pushReplacement(
            MaterialPageRoute(
              builder: (_) => const FatalErrorScreen(
                errorMessage: "Startup failed. Check console for details.",
              ),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    // Orchestrator dispose might be called elsewhere if it's a singleton,
    // for this demo, if it's tied to SplashScreen lifecycle, dispose it.
    // widget.orchestrator.dispose(); // Handled by stream controller auto-closing.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const CircularProgressIndicator(), // General loading indicator
            const SizedBox(height: 20),
            Text(_statusMessage, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            if (_currentProgress != null && _currentProgress!.totalTasks > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: LinearProgressIndicator(
                  value: _currentProgress!.percentage,
                  minHeight: 10,
                ),
              ),
            if (_currentProgress != null)
              Text('${(_currentProgress!.percentage * 100).toStringAsFixed(0)}% completed'),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen'),
      ),
      body: const Center(
        child: Text(
          'Hello world! Startup complete.',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

class FatalErrorScreen extends StatelessWidget {
  final String errorMessage;
  final String? stackTrace;

  const FatalErrorScreen({super.key, required this.errorMessage, this.stackTrace});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fatal Error'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 20),
              Text(
                'Application Startup Failed',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
              ),
              if (stackTrace != null) ...[
                const SizedBox(height: 20),
                Text(
                  'Details:',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      stackTrace!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
