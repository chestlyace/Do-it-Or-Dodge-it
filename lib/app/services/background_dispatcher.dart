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
import 'notification_gateway.dart';
import 'nudge_service.dart';
import 'outcome_service.dart';

/// Name of the daily job in WorkManager.
const dailyJobName = 'daily-replan';

/// Entry point WorkManager runs in a background isolate, even when the app is
/// closed. It must stay a top-level function.
@pragma('vm:entry-point')
void backgroundCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    if (task != dailyJobName) return true;
    try {
      await runDailyJobInBackground();
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
    final outcomes = OutcomeService(
      tasks: tasks,
      outcomes: OutcomeRepository(db),
    );
    final nudges = NudgeService(
      tasks: tasks,
      steps: StepRepository(db),
      nudges: NudgeRepository(db),
      settings: SettingsRepository(db),
      outcomes: outcomes,
      gateway: LocalNotificationsGateway(),
    );
    outcomes.onClosed = nudges.cancelFor;
    await nudges.init(handleTaps: false, maintain: false);
    return await DailyJob(nudges).run();
  } finally {
    await db.close();
  }
}
