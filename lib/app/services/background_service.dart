import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:workmanager/workmanager.dart';

import 'background_dispatcher.dart';

/// Registers work that runs without the app being open.
abstract class BackgroundScheduler {
  /// Makes sure the daily job is scheduled. Safe to call at every launch.
  Future<void> registerDailyJob();

  /// Makes sure the pre-generation job is scheduled. It only runs while the
  /// phone is charging.
  Future<void> registerPregenerationJob();
}

/// [BackgroundScheduler] backed by `workmanager`.
class WorkmanagerScheduler implements BackgroundScheduler {
  var _initialized = false;

  Future<void> _initialize() async {
    if (_initialized) return;
    await Workmanager().initialize(backgroundCallbackDispatcher);
    _initialized = true;
  }

  @override
  Future<void> registerPregenerationJob() async {
    await _initialize();
    await Workmanager().registerPeriodicTask(
      pregenerateJobName,
      pregenerateJobName,
      frequency: const Duration(hours: 24),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresCharging: true,
        requiresBatteryNotLow: true,
      ),
    );
  }

  @override
  Future<void> registerDailyJob() async {
    await _initialize();
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
    try {
      await _scheduler.registerPregenerationJob();
    } catch (e) {
      // Without it everything is written when asked for, a little slower.
      debugPrint('Pre-generation job could not be scheduled: $e');
    }
  }
}
