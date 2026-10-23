import 'package:get/get.dart';

import 'data/db/app_database.dart';
import 'data/repositories/excuse_repository.dart';
import 'data/repositories/nudge_repository.dart';
import 'data/repositories/outcome_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/step_repository.dart';
import 'data/repositories/task_repository.dart';
import 'services/background_service.dart';
import 'services/gemma_service.dart';
import 'services/nudge_service.dart';
import 'services/predictor_service.dart';
import 'services/share_service.dart';

class InitialBinding extends Bindings {
  /// Pass [database] in tests to use an in-memory database.
  InitialBinding({this.database});

  final AppDatabase? database;

  @override
  void dependencies() {
    final db = Get.put(database ?? AppDatabase(), permanent: true);
    Get.put(TaskRepository(db), permanent: true);
    Get.put(StepRepository(db), permanent: true);
    Get.put(OutcomeRepository(db), permanent: true);
    Get.put(ExcuseRepository(db), permanent: true);
    Get.put(NudgeRepository(db), permanent: true);
    Get.put(SettingsRepository(db), permanent: true);

    Get.put(GemmaService(), permanent: true);
    Get.put(PredictorService(), permanent: true);
    Get.put(NudgeService(), permanent: true);
    Get.put(ShareService(), permanent: true);
    Get.put(BackgroundService(), permanent: true);
  }
}
