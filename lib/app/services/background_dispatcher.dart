import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../data/db/app_database.dart';
import '../data/repositories/nudge_repository.dart';
import '../data/repositories/outcome_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/step_repository.dart';
import '../data/repositories/task_repository.dart';
import 'daily_job.dart';
import 'edge_ai_model_runtime.dart';
import 'gemma_service.dart';
import 'pregenerate_job.dart';
import 'pregenerated_excuses.dart';
import 'notification_gateway.dart';
import 'nudge_service.dart';
import 'outcome_service.dart';
import 'predictor_service.dart';

/// Name of the daily job in WorkManager.
const dailyJobName = 'daily-replan';

/// Name of the job that writes text ahead of time while the phone charges.
const pregenerateJobName = 'pregenerate';

/// Entry point WorkManager runs in a background isolate, even when the app is
/// closed. It must stay a top-level function.
@pragma('vm:entry-point')
void backgroundCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    try {
      if (task == dailyJobName) {
        await runDailyJobInBackground();
      } else if (task == pregenerateJobName) {
        await runPregenerateInBackground();
      }
      return true;
    } catch (_) {
      return false;
    }
  });
}

/// Opens its own database and notification plugin, runs the daily job and
/// cleans up. No UI, no model.
Future<DailyJobResult> runDailyJobInBackground() async {
  final db = AppDatabase();
  try {
    final tasks = TaskRepository(db);
    final steps = StepRepository(db);
    final outcomeRepo = OutcomeRepository(db);
    final settings = SettingsRepository(db);
    final predictor = PredictorService(
      tasks: tasks,
      steps: steps,
      outcomes: outcomeRepo,
      settings: settings,
    );
    final outcomes = OutcomeService(
      tasks: tasks,
      outcomes: outcomeRepo,
      predictor: predictor,
    );
    final nudges = NudgeService(
      tasks: tasks,
      steps: steps,
      nudges: NudgeRepository(db),
      settings: settings,
      outcomes: outcomes,
      gateway: LocalNotificationsGateway(),
      predictor: predictor,
    );
    outcomes.onClosed = nudges.cancelFor;
    await nudges.init(handleTaps: false, maintain: false);
    return await DailyJob(nudges, predictor: predictor).run();
  } finally {
    await db.close();
  }
}

/// Loads the model, writes notification text and ready-made excuses for open
/// tasks, and frees the model. Only scheduled while the phone is charging.
Future<PregenerateResult> runPregenerateInBackground() async {
  final db = AppDatabase();
  try {
    final tasks = TaskRepository(db);
    final steps = StepRepository(db);
    final outcomeRepo = OutcomeRepository(db);
    final settings = SettingsRepository(db);
    final gemma = GemmaService(
      runtime: EdgeAiModelRuntime(),
      settings: settings,
    );
    final predictor = PredictorService(
      tasks: tasks,
      steps: steps,
      outcomes: outcomeRepo,
      settings: settings,
    );
    final outcomes = OutcomeService(
      tasks: tasks,
      outcomes: outcomeRepo,
      predictor: predictor,
    );
    final nudges = NudgeService(
      tasks: tasks,
      steps: steps,
      nudges: NudgeRepository(db),
      settings: settings,
      outcomes: outcomes,
      gateway: LocalNotificationsGateway(),
      gemma: gemma,
      predictor: predictor,
    );
    outcomes.onClosed = nudges.cancelFor;
    await nudges.init(handleTaps: false, maintain: false);
    return await PregenerateJob(
      tasks: tasks,
      steps: steps,
      nudges: nudges,
      gemma: gemma,
      excuses: PregeneratedExcuses(settings),
    ).run();
  } finally {
    await db.close();
  }
}
