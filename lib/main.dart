import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/core/theme/app_theme.dart';
import 'app/data/db/app_database.dart';
import 'app/initial_binding.dart';
import 'app/services/device_info_service.dart';
import 'app/services/background_service.dart';
import 'app/services/model_runtime.dart';
import 'app/services/notification_gateway.dart';
import 'app/services/share_service.dart';
import 'app/routes/app_pages.dart';

void main() {
  runApp(const DoItOrDodgeItApp());
}

class DoItOrDodgeItApp extends StatelessWidget {
  const DoItOrDodgeItApp({
    super.key,
    this.database,
    this.modelRuntime,
    this.deviceInfo,
    this.checksumOf,
    this.shareService,
    this.notifications,
    this.backgroundScheduler,
    this.clock,
  });

  /// Tests pass fakes; on the phone these are null and the real ones are used.
  final AppDatabase? database;
  final ModelRuntime? modelRuntime;
  final DeviceInfoSource? deviceInfo;
  final Future<String> Function(String path)? checksumOf;
  final ShareService? shareService;
  final NotificationGateway? notifications;
  final BackgroundScheduler? backgroundScheduler;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Do It or Dodge It',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialBinding: InitialBinding(
        database: database,
        modelRuntime: modelRuntime,
        deviceInfo: deviceInfo,
        checksumOf: checksumOf,
        shareService: shareService,
        notifications: notifications,
        backgroundScheduler: backgroundScheduler,
        clock: clock,
      ),
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
    );
  }
}
