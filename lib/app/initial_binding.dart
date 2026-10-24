import 'package:get/get.dart';

import 'data/db/app_database.dart';
import 'data/repositories/excuse_repository.dart';
import 'data/repositories/nudge_repository.dart';
import 'data/repositories/outcome_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/step_repository.dart';
import 'data/repositories/task_repository.dart';
import 'services/background_service.dart';
import 'services/data_reset_service.dart';
import 'services/device_info_service.dart';
import 'services/edge_ai_model_runtime.dart';
import 'services/gemma_service.dart';
import 'services/model_runtime.dart';
import 'services/notification_gateway.dart';
import 'services/nudge_service.dart';
import 'services/outcome_service.dart';
import 'services/predictor_service.dart';
import 'services/pregenerated_excuses.dart';
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
    final predictor = Get.put(
      PredictorService(
        tasks: Get.find<TaskRepository>(),
        steps: Get.find<StepRepository>(),
        outcomes: Get.find<OutcomeRepository>(),
        settings: Get.find<SettingsRepository>(),
        now: clock,
      ),
      permanent: true,
    );
    Get.put(shareService ?? ShareService(), permanent: true);

    final outcomes = Get.put(
      OutcomeService(
        tasks: Get.find<TaskRepository>(),
        outcomes: Get.find<OutcomeRepository>(),
        predictor: predictor,
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
        predictor: predictor,
        now: clock,
      ),
      permanent: true,
    );
    outcomes.onClosed = nudges.cancelFor;
    Get.put(
      PregeneratedExcuses(Get.find<SettingsRepository>()),
      permanent: true,
    );
    Get.put(
      DataResetService(
        tasks: Get.find<TaskRepository>(),
        settings: Get.find<SettingsRepository>(),
        nudges: nudges,
      ),
      permanent: true,
    );

    Get.put(BackgroundService(scheduler: backgroundScheduler), permanent: true);
  }
}
