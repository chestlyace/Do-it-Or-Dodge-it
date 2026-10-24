import '../../data/models/gemma_model_option.dart';
import '../../services/device_info_service.dart';

const _gib = 1024 * 1024 * 1024;

/// Phones with at least this much RAM are offered E4B first.
const e4bMinRamBytes = 8 * _gib;

/// Below this the app warns that Gemma may not load.
const minSupportedRamBytes = 4 * _gib;

/// Free space kept on top of the model file.
const storageHeadroomBytes = 1 * _gib;

/// E4B at 8 GB of RAM or more, otherwise E2B.
GemmaModelOption recommendModel(DeviceInfo info) {
  return info.totalRamBytes >= e4bMinRamBytes
      ? GemmaModelOption.gemma4E4B
      : GemmaModelOption.gemma4E2B;
}

/// Free storage needed to download [option].
int requiredFreeBytes(GemmaModelOption option) =>
    option.sizeBytes + storageHeadroomBytes;

bool hasEnoughStorage(DeviceInfo info, GemmaModelOption option) =>
    info.freeStorageBytes >= requiredFreeBytes(option);

bool isBelowMinimumRam(DeviceInfo info) =>
    info.totalRamBytes < minSupportedRamBytes;

/// "2.4 GB" style text for sizes shown to the user.
String formatBytes(int bytes) {
  const gb = 1000 * 1000 * 1000;
  const mb = 1000 * 1000;
  if (bytes >= gb) return '${(bytes / gb).toStringAsFixed(1)} GB';
  return '${(bytes / mb).round()} MB';
}
