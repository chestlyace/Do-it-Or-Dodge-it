import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:workmanager/workmanager.dart';

import 'background_dispatcher.dart';

/// Registers work that runs without the app being open.
abstract class BackgroundScheduler {
  /// Makes sure the daily job is scheduled. Safe to call at every launch.
  Future<void> registerDailyJob();
}

/// [BackgroundScheduler] backed by `workmanager`.
class WorkmanagerScheduler implements BackgroundScheduler {
  @override
  Future<void> registerDailyJob() async {
    await Workmanager().initialize(backgroundCallbackDispatcher);
    // The default policy updates an existing job without resetting its timing.
    await Workmanager().registerPeriodicTask(
      dailyJobName,
      dailyJobName,
      frequency: const Duration(hours: 24),
    );
  }
}

/// Wakes once a day to re-plan nudges, even if the app is never opened.
class BackgroundService extends GetxService {
  BackgroundService({BackgroundScheduler? scheduler})
    : _scheduler = scheduler ?? WorkmanagerScheduler();

  final BackgroundScheduler _scheduler;

  /// True once the daily job is scheduled.
  final registered = false.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(register());
  }

  Future<void> register() async {
    try {
      await _scheduler.registerDailyJob();
      registered.value = true;
    } catch (e) {
      // The app works without it; nudges just are not re-planned in the
      // background.
      debugPrint('Background job could not be scheduled: $e');
    }
  }
}
