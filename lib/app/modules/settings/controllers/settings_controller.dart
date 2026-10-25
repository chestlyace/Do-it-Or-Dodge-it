import 'package:get/get.dart';

import '../../../core/utils/nudge_planner.dart';
import '../../../data/models/gemma_model_option.dart';
import '../../../data/models/settings_keys.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../routes/app_routes.dart';
import '../../../services/data_reset_service.dart';
import '../../../services/gemma_service.dart';
import '../../../services/nudge_service.dart';

/// "21:00" for a time given as minutes after midnight.
String formatMinutes(int minutes) {
  final h = (minutes ~/ 60).toString().padLeft(2, '0');
  final m = (minutes % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

class SettingsController extends GetxController {
  final _settings = Get.find<SettingsRepository>();
  final _nudges = Get.find<NudgeService>();
  final _reset = Get.find<DataResetService>();
  final gemma = Get.find<GemmaService>();

  final loading = true.obs;
  final quietStart = QuietHours.standard.startMinutes.obs;
  final quietEnd = QuietHours.standard.endMinutes.obs;
  final nudgeLimit = maxNudgesPerDay.obs;
  final wifiOnly = true.obs;

  /// What the last change did, for example "Nudges updated."
  final message = RxnString();
  final busy = false.obs;

  /// The model that is installed, if any.
  GemmaModelOption? get model => gemma.installed.value;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    final quiet = QuietHours.fromSettings(
      await _settings.get(SettingsKeys.quietHoursStart),
      await _settings.get(SettingsKeys.quietHoursEnd),
    );
    quietStart.value = quiet.startMinutes;
    quietEnd.value = quiet.endMinutes;
    nudgeLimit.value =
        (int.tryParse(
                  await _settings.get(SettingsKeys.maxNudgesPerDay) ?? '',
                ) ??
                maxNudgesPerDay)
            .clamp(1, maxNudgesPerDay);
    wifiOnly.value = await _settings.get(SettingsKeys.wifiOnly) != 'false';
    loading.value = false;
  }

  Future<void> setQuietStart(int minutes) async {
    quietStart.value = minutes;
    await _settings.set(SettingsKeys.quietHoursStart, formatMinutes(minutes));
    await _applyToNudges();
  }

  Future<void> setQuietEnd(int minutes) async {
    quietEnd.value = minutes;
    await _settings.set(SettingsKeys.quietHoursEnd, formatMinutes(minutes));
    await _applyToNudges();
  }

  Future<void> setMaxNudgesPerDay(int value) async {
    final clamped = value.clamp(1, maxNudgesPerDay);
    nudgeLimit.value = clamped;
    await _settings.set(SettingsKeys.maxNudgesPerDay, '$clamped');
    await _applyToNudges();
  }

  Future<void> setWifiOnly(bool value) async {
    wifiOnly.value = value;
    await _settings.set(SettingsKeys.wifiOnly, value.toString());
  }

  /// Plans the nudges again, so the change applies now, not at the next launch.
  Future<void> _applyToNudges() async {
    final count = await _nudges.replanAll();
    message.value = count == 0
        ? 'Saved. It applies to the nudges you get from now on.'
        : 'Saved. $count nudges were planned again.';
  }

  /// Deletes the model file and goes back to the download screen.
  Future<void> deleteModel() async {
    if (busy.value) return;
    busy.value = true;
    try {
      await gemma.deleteModel();
      Get.offAllNamed(Routes.onboarding);
    } finally {
      busy.value = false;
    }
  }

  /// Clears tasks, history and what the app learned. The model and these
  /// settings stay.
  Future<void> clearData() async {
    if (busy.value) return;
    busy.value = true;
    try {
      await _reset.clearUserData();
    } finally {
      busy.value = false;
    }
  }
}
