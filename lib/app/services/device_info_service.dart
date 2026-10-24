import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// What onboarding needs to know about the phone.
class DeviceInfo {
  const DeviceInfo({
    required this.totalRamBytes,
    required this.freeStorageBytes,
    required this.hasNetwork,
    required this.onUnmeteredNetwork,
  });

  final int totalRamBytes;
  final int freeStorageBytes;
  final bool hasNetwork;

  /// True on Wi-Fi and other connections the user does not pay per byte for.
  final bool onUnmeteredNetwork;
}

/// Reads [DeviceInfo]. A fake is used in tests.
abstract class DeviceInfoSource {
  Future<DeviceInfo> read();
}

/// Reads device info from the Android side through a method channel.
class DeviceInfoService extends GetxService implements DeviceInfoSource {
  static const channel = MethodChannel(
    'com.chestlyace.do_it_or_dodge_it/device',
  );

  @override
  Future<DeviceInfo> read() async {
    final map = await channel.invokeMapMethod<String, Object?>('getDeviceInfo');
    if (map == null) {
      throw PlatformException(
        code: 'no_device_info',
        message: 'The platform returned no device info.',
      );
    }
    return DeviceInfo(
      totalRamBytes: (map['totalRamBytes'] as num).toInt(),
      freeStorageBytes: (map['freeStorageBytes'] as num).toInt(),
      hasNetwork: map['hasNetwork'] as bool,
      onUnmeteredNetwork: map['onUnmeteredNetwork'] as bool,
    );
  }
}
