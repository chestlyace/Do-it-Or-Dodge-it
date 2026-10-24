import 'package:get/get.dart';

import 'data/db/app_database.dart';
import 'data/repositories/excuse_repository.dart';
import 'data/repositories/nudge_repository.dart';
import 'data/repositories/outcome_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/step_repository.dart';
import 'data/repositories/task_repository.dart';
import 'services/background_service.dart';
import 'services/device_info_service.dart';
import 'services/edge_ai_model_runtime.dart';
import 'services/gemma_service.dart';
import 'services/model_runtime.dart';
import 'services/nudge_service.dart';
import 'services/predictor_service.dart';
import 'services/share_service.dart';

class InitialBinding extends Bindings {
  /// Pass [database], [modelRuntime] and [deviceInfo] in tests to use fakes.
  InitialBinding({
    this.database,
    this.modelRuntime,
    this.deviceInfo,
    this.checksumOf,
  });

  final AppDatabase? database;
  final ModelRuntime? modelRuntime;
  final DeviceInfoSource? deviceInfo;
  final Future<String> Function(String path)? checksumOf;

  @override
  void dependencies() {
    final db = Get.put(database ?? AppDatabase(), permanent: true);
    Get.put(TaskRepository(db), permanent: true);
    Get.put(StepRepository(db), permanent: true);
    Get.put(OutcomeRepository(db), permanent: true);
    Get.put(ExcuseRepository(db), permanent: true);
    Get.put(NudgeRepository(db), permanent: true);
    Get.put(SettingsRepository(db), permanent: true);

    Get.put<DeviceInfoSource>(
      deviceInfo ?? DeviceInfoService(),
      permanent: true,
    );
    Get.put(
      GemmaService(
        runtime: modelRuntime ?? EdgeAiModelRuntime(),
        settings: Get.find<SettingsRepository>(),
        checksumOf: checksumOf,
      ),
      permanent: true,
    );
    Get.put(PredictorService(), permanent: true);
    Get.put(NudgeService(), permanent: true);
    Get.put(ShareService(), permanent: true);
    Get.put(BackgroundService(), permanent: true);
  }
}
