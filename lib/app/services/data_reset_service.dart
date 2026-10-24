import 'package:get/get.dart';

import '../data/models/settings_keys.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/task_repository.dart';
import 'nudge_service.dart';

/// Clears what the user created, and what the app learned from it.
class DataResetService extends GetxService {
  DataResetService({
    required this._tasks,
    required this._settings,
    required this._nudges,
  });

  final TaskRepository _tasks;
  final SettingsRepository _settings;
  final NudgeService _nudges;

  /// Deletes every task with its steps, outcomes, excuses and nudges, cancels
  /// the notifications, and forgets the dodge predictor and everything saved
  /// for it. The downloaded model and the preferences (quiet hours, limits,
  /// Wi-Fi only) are kept.
  Future<void> clearUserData() async {
    for (final task in await _tasks.listAll()) {
      await _nudges.cancelFor(task.id);
    }
    await _tasks.deleteAll();
    await _settings.remove(SettingsKeys.predictorWeights);
    for (final prefix in [
      SettingsKeys.decisionSnapshotPrefix,
      SettingsKeys.nudgeWordingPrefix,
      SettingsKeys.pregenExcusePrefix,
    ]) {
      await _settings.removeWithPrefix(prefix);
    }
  }
}
