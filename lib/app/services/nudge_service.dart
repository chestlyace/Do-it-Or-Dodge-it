import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';

import '../core/utils/nudge_planner.dart';
import '../data/db/app_database.dart';
import '../data/models/enums.dart';
import '../data/models/prompt_jobs.dart';
import '../data/models/settings_keys.dart';
import '../data/repositories/nudge_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/step_repository.dart';
import '../data/repositories/task_repository.dart';
import '../routes/app_routes.dart';
import 'gemma_service.dart';
import 'notification_gateway.dart';
import 'outcome_service.dart';

/// Turns each Do It task into a schedule of local notifications.
///
/// Every nudge names only the next undone step. The text is written once and
/// stored, so firing a notification never needs the model.
class NudgeService extends GetxService {
  NudgeService({
    required this._tasks,
    required this._steps,
    required this._nudges,
    required this._settings,
    required this._outcomes,
    required this._gateway,
    this._gemma,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final TaskRepository _tasks;
  final StepRepository _steps;
  final NudgeRepository _nudges;
  final SettingsRepository _settings;
  final OutcomeService _outcomes;
  final NotificationGateway _gateway;

  /// Null in the background job, which never loads the model.
  final GemmaService? _gemma;
  final DateTime Function() _now;

  /// False when the user turned notifications off for the app.
  final notificationsEnabled = true.obs;

  final _inFlight = <Future<void>>[];
  int? _pendingOpen;

  @override
  void onInit() {
    super.onInit();
    unawaited(init());
  }

  /// Sets the plugin up and cleans up after anything that happened while the
  /// app was closed. Safe to call when notifications are unavailable.
  Future<void> init({bool handleTaps = true, bool maintain = true}) async {
    try {
      await _gateway.initialize(onTap: handleTaps ? handleTap : null);
      notificationsEnabled.value = await _gateway.areEnabled();
      if (handleTaps) {
        final launch = await _gateway.launchPayload();
        if (launch != null) await handleTap(launch);
      }
    } catch (e) {
      logNotificationError('setup', e);
    }
    if (maintain) {
      try {
        await syncFired();
        await abandonOverdue();
        await replanAll();
      } catch (e) {
        logNotificationError('maintenance', e);
      }
    }
  }

  /// Asks for the notification permission the first time it is needed.
  /// Returns whether nudges can be shown.
  Future<bool> ensurePermission() async {
    try {
      if (await _gateway.areEnabled()) {
        notificationsEnabled.value = true;
        return true;
      }
      if (await _settings.get(SettingsKeys.notificationsAsked) != 'true') {
        await _settings.set(SettingsKeys.notificationsAsked, 'true');
        notificationsEnabled.value = await _gateway.requestPermission();
      } else {
        notificationsEnabled.value = false;
      }
    } catch (e) {
      logNotificationError('permission', e);
      notificationsEnabled.value = false;
    }
    return notificationsEnabled.value;
  }

  /// Schedules nudges for [task]'s next undone step, replacing any pending
  /// ones. Returns how many were scheduled.
  ///
  /// With [allowModel], wording that is not stored yet is written by the model
  /// in the background (if it is already loaded) and the schedule is refreshed.
  Future<int> plan(Task task, {bool allowModel = true}) async {
    await cancelFor(task.id);
    if (isClosed(task.status)) return 0;

    final step = await _steps.nextUndone(task.id);
    if (step == null) return 0;
    if (!await _gateway.areEnabled()) {
      notificationsEnabled.value = false;
      return 0;
    }
    notificationsEnabled.value = true;

    final quiet = QuietHours.fromSettings(
      await _settings.get(SettingsKeys.quietHoursStart),
      await _settings.get(SettingsKeys.quietHoursEnd),
    );
    final fast = await _settings.get(SettingsKeys.nudgeFastClock) == 'true';
    final now = _now();
    final planned = planNudges(
      now: now,
      due: effectiveDue(dueAt: task.dueAt, createdAt: task.createdAt),
      risk: task.dodgeRisk ?? placeholderRisk,
      quiet: quiet,
      fastClock: fast,
    );

    final wording = await _storedWording(task.id, step.id);
    var scheduled = 0;
    for (final nudge in planned) {
      final text =
          wording?.forLevel(nudge.level) ??
          templateWording(nudge.level, step.title);
      final row = await _nudges.createScheduled(
        taskId: task.id,
        fireAt: nudge.fireAt,
        level: nudge.level,
        message: text,
      );
      try {
        await _gateway.schedule(
          id: row.notificationId,
          title: 'Next tiny step',
          body: text,
          at: nudge.fireAt,
          payload: '${row.id}:${task.id}',
        );
        scheduled++;
      } catch (e) {
        logNotificationError('schedule', e);
      }
    }

    final gemma = _gemma;
    if (wording == null &&
        planned.isNotEmpty &&
        allowModel &&
        gemma != null &&
        gemma.isLoaded.value) {
      _track(_writeWording(task, step));
    }
    return scheduled;
  }

  /// Plans again for [taskId] from its current state. Used after a step is
  /// ticked or unticked.
  Future<int> replan(int taskId, {bool allowModel = true}) async {
    final task = await _tasks.getById(taskId);
    if (task == null) {
      await cancelFor(taskId);
      return 0;
    }
    return plan(task, allowModel: allowModel);
  }

  /// Plans again for every task being worked on. Used by the daily job.
  Future<int> replanAll({bool allowModel = false}) async {
    var total = 0;
    final active = [...await _tasks.listByStatus(TaskStatus.doing)];
    for (final task in active) {
      total += await plan(task, allowModel: allowModel);
    }
    return total;
  }

  /// Cancels the task's pending nudges and removes them.
  Future<void> cancelFor(int taskId) async {
    final pending = await _nudges.listPendingForTask(taskId);
    for (final nudge in pending) {
      try {
        await _gateway.cancel(nudge.notificationId);
      } catch (e) {
        logNotificationError('cancel', e);
      }
    }
    await _nudges.deletePendingForTask(taskId);
  }

  /// Marks nudges whose time has passed as fired.
  Future<int> syncFired() async {
    final now = _now();
    var count = 0;
    for (final nudge in await _nudges.listPending()) {
      if (!nudge.fireAt.isAfter(now)) {
        await _nudges.markFired(nudge.id);
        count++;
      }
    }
    return count;
  }

  /// A Do It task past its due date with no step done is abandoned.
  Future<int> abandonOverdue() async {
    final now = _now();
    var count = 0;
    for (final task in await _tasks.listByStatus(TaskStatus.doing)) {
      final due = task.dueAt;
      if (due == null) continue;
      final endOfDay = effectiveDue(dueAt: due, createdAt: task.createdAt);
      if (!now.isAfter(endOfDay)) continue;
      final steps = await _steps.listForTask(task.id);
      if (steps.any((s) => s.doneAt != null)) continue;
      if (await _outcomes.markAbandoned(task.id)) count++;
    }
    return count;
  }

  /// A notification was tapped: record it and open the task.
  Future<void> handleTap(String? payload) async {
    final parts = payload?.split(':');
    if (parts == null || parts.length != 2) return;
    final nudgeId = int.tryParse(parts[0]);
    final taskId = int.tryParse(parts[1]);
    if (nudgeId == null || taskId == null) return;

    try {
      await _nudges.markFired(nudgeId);
      await _nudges.markOpened(nudgeId);
    } catch (e) {
      logNotificationError('tap', e);
    }

    final route = Get.currentRoute;
    if (route.isEmpty || route == Routes.onboarding) {
      // The app is still starting; Home opens the task when it is ready.
      _pendingOpen = taskId;
    } else {
      unawaited(Get.toNamed(Routes.doIt, arguments: taskId));
    }
  }

  /// The task a tapped notification wants to open, once.
  int? takePendingOpen() {
    final id = _pendingOpen;
    _pendingOpen = null;
    return id;
  }

  /// Ids of notifications the OS has scheduled and not yet shown.
  Future<List<int>> osPendingIds() => _gateway.pendingIds();

  /// Schedules a test notification [after] from now (debug screen).
  Future<void> sendTest({Duration after = const Duration(seconds: 10)}) {
    return _gateway.schedule(
      id: 2147483000,
      title: 'Test nudge',
      body: 'If you can read this, nudges work.',
      at: _now().add(after),
    );
  }

  /// Completes when background wording work started by [plan] has finished.
  Future<void> settled() async {
    while (_inFlight.isNotEmpty) {
      await Future.wait(List.of(_inFlight));
    }
  }

  void _track(Future<void> work) {
    late final Future<void> tracked;
    tracked = work.whenComplete(() => _inFlight.remove(tracked));
    _inFlight.add(tracked);
  }

  Future<void> _writeWording(Task task, Step step) async {
    final gemma = _gemma;
    if (gemma == null) return;
    try {
      final result = await gemma.nudgeWording(
        NudgeInput(taskTitle: task.title, stepTitle: step.title),
      );
      if (result is! JobSuccess<NudgeWording>) return;
      await _settings.set(
        '${SettingsKeys.nudgeWordingPrefix}${task.id}:${step.id}',
        jsonEncode(result.value.toJson()),
      );
      // Only refresh if this is still the step the nudges are about.
      final next = await _steps.nextUndone(task.id);
      if (next?.id == step.id) {
        final fresh = await _tasks.getById(task.id);
        if (fresh != null) await plan(fresh, allowModel: false);
      }
    } catch (e) {
      logNotificationError('wording', e);
    }
  }

  Future<NudgeWording?> _storedWording(int taskId, int stepId) async {
    final raw = await _settings.get(
      '${SettingsKeys.nudgeWordingPrefix}$taskId:$stepId',
    );
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return NudgeWording(
        gentle: json['gentle'] as String,
        firm: json['firm'] as String,
        lastCall: json['lastCall'] as String,
      );
    } catch (_) {
      return null;
    }
  }
}
