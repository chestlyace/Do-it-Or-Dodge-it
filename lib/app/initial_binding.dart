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
import 'services/notification_gateway.dart';
import 'services/nudge_service.dart';
import 'services/outcome_service.dart';
import 'services/predictor_service.dart';
import 'services/share_service.dart';

class InitialBinding extends Bindings {
  /// Pass [database], [modelRuntime] and [deviceInfo] in tests to use fakes.
  InitialBinding({
    this.database,
    this.modelRuntime,
    this.deviceInfo,
    this.checksumOf,
    this.shareService,
    this.notifications,
    this.backgroundScheduler,
    this.clock,
  });

  final AppDatabase? database;
  final ModelRuntime? modelRuntime;
  final DeviceInfoSource? deviceInfo;
  final Future<String> Function(String path)? checksumOf;
  final ShareService? shareService;
  final NotificationGateway? notifications;
  final BackgroundScheduler? backgroundScheduler;
  final DateTime Function()? clock;

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
    Get.put(shareService ?? ShareService(), permanent: true);

    final outcomes = Get.put(
      OutcomeService(
        tasks: Get.find<TaskRepository>(),
        outcomes: Get.find<OutcomeRepository>(),
      ),
      permanent: true,
    );
    final nudges = Get.put(
      NudgeService(
        tasks: Get.find<TaskRepository>(),
        steps: Get.find<StepRepository>(),
        nudges: Get.find<NudgeRepository>(),
        settings: Get.find<SettingsRepository>(),
        outcomes: outcomes,
        gateway: notifications ?? LocalNotificationsGateway(),
        gemma: Get.find<GemmaService>(),
        now: clock,
      ),
      permanent: true,
    );
    outcomes.onClosed = nudges.cancelFor;

    Get.put(BackgroundService(scheduler: backgroundScheduler), permanent: true);
  }
}
