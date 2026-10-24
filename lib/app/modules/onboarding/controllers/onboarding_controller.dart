import 'package:get/get.dart';

import '../../../core/utils/model_recommender.dart';
import '../../../data/models/gemma_model_option.dart';
import '../../../data/models/settings_keys.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../routes/app_routes.dart';
import '../../../services/device_info_service.dart';
import '../../../services/gemma_service.dart';

class OnboardingController extends GetxController {
  final gemma = Get.find<GemmaService>();
  final _device = Get.find<DeviceInfoSource>();
  final _settings = Get.find<SettingsRepository>();

  final device = Rxn<DeviceInfo>();
  final selected = GemmaModelOption.gemma4E2B.obs;
  final recommended = GemmaModelOption.gemma4E2B.obs;
  final wifiOnly = true.obs;

  /// Why the download cannot start right now, if it cannot.
  final blocker = RxnString();

  @override
  void onReady() {
    super.onReady();
    _setUp();
  }

  Future<void> _setUp() async {
    await gemma.started;
    wifiOnly.value = await _settings.get(SettingsKeys.wifiOnly) != 'false';

    if (gemma.installState.value == ModelInstallState.installed) {
      _goHome();
      return;
    }

    await refreshDevice();
    final info = device.value;
    if (info != null) {
      recommended.value = recommendModel(info);
      selected.value = recommended.value;
    }

    // A download that was interrupted resumes on its own.
    final pending = gemma.pendingDownload.value;
    if (pending != null) {
      selected.value = pending;
      await startDownload();
    }
  }

  Future<void> refreshDevice() async {
    try {
      device.value = await _device.read();
    } catch (e) {
      blocker.value = 'Could not read this phone\'s details: $e';
    }
  }

  void select(GemmaModelOption option) {
    if (gemma.installState.value == ModelInstallState.downloading) return;
    selected.value = option;
    blocker.value = null;
  }

  Future<void> setWifiOnly(bool value) async {
    wifiOnly.value = value;
    await _settings.set(SettingsKeys.wifiOnly, value.toString());
  }

  bool get storageOk {
    final info = device.value;
    return info == null || hasEnoughStorage(info, selected.value);
  }

  bool get belowMinimumRam {
    final info = device.value;
    return info != null && isBelowMinimumRam(info);
  }

  Future<void> startDownload() async {
    await refreshDevice();
    final info = device.value;
    if (info == null) return;

    if (!info.hasNetwork) {
      blocker.value = 'No internet connection. Connect and try again.';
      return;
    }
    if (wifiOnly.value && !info.onUnmeteredNetwork) {
      blocker.value =
          'Wi-Fi only is on. Connect to Wi-Fi, or turn Wi-Fi only off.';
      return;
    }
    if (!hasEnoughStorage(info, selected.value)) {
      blocker.value =
          'Not enough free storage. ${formatBytes(requiredFreeBytes(selected.value))} is needed.';
      return;
    }

    blocker.value = null;
    await gemma.download(selected.value);
    if (gemma.installState.value == ModelInstallState.installed) _goHome();
  }

  Future<void> cancelDownload() => gemma.cancelDownload();

  void _goHome() => Get.offAllNamed(Routes.home);
}
