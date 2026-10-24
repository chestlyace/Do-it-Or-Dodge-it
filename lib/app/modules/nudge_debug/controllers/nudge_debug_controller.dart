import 'package:get/get.dart';

import '../../../data/db/app_database.dart';
import '../../../data/models/settings_keys.dart';
import '../../../data/repositories/nudge_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../services/daily_job.dart';
import '../../../services/nudge_service.dart';

/// A nudge with the title of its task.
class DebugNudge {
  const DebugNudge(this.nudge, this.taskTitle);

  final Nudge nudge;
  final String taskTitle;

  String get state => nudge.opened
      ? 'opened'
      : nudge.fired
      ? 'fired'
      : 'pending';
}

/// Hidden screen for checking nudges: the schedule, a fast clock, the daily
/// job and a test notification.
class NudgeDebugController extends GetxController {
  final _nudges = Get.find<NudgeRepository>();
  final _tasks = Get.find<TaskRepository>();
  final _settings = Get.find<SettingsRepository>();
  final service = Get.find<NudgeService>();

  final entries = <DebugNudge>[].obs;
  final osPending = 0.obs;
  final fastClock = false.obs;
  final message = RxnString();
  final busy = false.obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    fastClock.value =
        await _settings.get(SettingsKeys.nudgeFastClock) == 'true';
    await reload();
  }

  Future<void> reload() async {
    final rows = await _nudges.listAll();
    final titles = {for (final t in await _tasks.listAll()) t.id: t.title};
    entries.assignAll([
      for (final n in rows)
        DebugNudge(n, titles[n.taskId] ?? 'Task ${n.taskId}'),
    ]);
    try {
      osPending.value = (await service.osPendingIds()).length;
    } catch (_) {
      osPending.value = 0;
    }
  }

  Future<void> setFastClock(bool value) async {
    fastClock.value = value;
    await _settings.set(SettingsKeys.nudgeFastClock, value.toString());
  }

  Future<void> replanAll() => _run(() async {
    final count = await service.replanAll();
    message.value = 'Scheduled $count nudges.';
  });

  Future<void> runDailyJob() => _run(() async {
    final result = await DailyJob(service).run();
    message.value = 'Daily job: $result.';
  });

  Future<void> sendTest() => _run(() async {
    await service.sendTest();
    message.value = 'A test notification arrives in 10 seconds.';
  });

  Future<void> _run(Future<void> Function() action) async {
    if (busy.value) return;
    busy.value = true;
    try {
      await action();
    } catch (e) {
      message.value = 'Error: $e';
    } finally {
      busy.value = false;
      await reload();
    }
  }
}
