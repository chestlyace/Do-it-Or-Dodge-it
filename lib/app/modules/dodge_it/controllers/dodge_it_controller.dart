import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../data/db/app_database.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/prompt_jobs.dart';
import '../../../data/repositories/excuse_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../services/gemma_service.dart';
import '../../../services/outcome_service.dart';
import '../../../services/pregenerated_excuses.dart';
import '../../../services/share_service.dart';

enum DodgePhase { loading, notFound, form, generating, ready, failed }

class DodgeItController extends GetxController {
  final _tasks = Get.find<TaskRepository>();
  final _excuses = Get.find<ExcuseRepository>();
  final _gemma = Get.find<GemmaService>();
  final _outcomes = Get.find<OutcomeService>();
  final _share = Get.find<ShareService>();
  final _pregenerated = Get.find<PregeneratedExcuses>();

  final recipientField = TextEditingController();

  final phase = DodgePhase.loading.obs;
  final task = Rxn<Task>();
  final tone = ExcuseTone.polite.obs;
  final excuse = Rxn<ExcuseDraft>();

  /// True to copy and share the short variant instead of the full excuse.
  final useShort = false.obs;
  final formError = RxnString();
  final failureReason = RxnString();
  final failureRaw = RxnString();

  /// True while the excuse on screen was written ahead of time, while the
  /// phone charged, and is not about anyone in particular.
  final readyMade = false.obs;

  /// True once an excuse was copied or shared and the dodge was logged.
  final logged = false.obs;
  final notice = RxnString();

  int? taskId;

  /// The task was already closed when the screen opened.
  bool get alreadyClosed {
    final t = task.value;
    return t != null && isClosed(t.status) && !logged.value;
  }

  String get selectedText {
    final e = excuse.value;
    if (e == null) return '';
    return useShort.value ? e.shortVariant : e.text;
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    taskId = args is int ? args : null;
    _start();
  }

  Future<void> _start() async {
    final id = taskId;
    final found = id == null ? null : await _tasks.getById(id);
    if (found == null) {
      phase.value = DodgePhase.notFound;
      return;
    }
    task.value = found;
    phase.value = DodgePhase.form;

    // An excuse written ahead of time shows straight away.
    final ready = isClosed(found.status)
        ? null
        : await _pregenerated.read(found.id);
    if (ready != null) {
      excuse.value = ready;
      useShort.value = false;
      readyMade.value = true;
      phase.value = DodgePhase.ready;
    }
  }

  /// Writes an excuse, avoiding the last 5 already used for this person.
  Future<void> generate() async {
    final current = task.value;
    if (current == null || phase.value == DodgePhase.generating) return;
    final recipient = recipientField.text.trim();
    if (recipient.isEmpty) {
      formError.value = 'Say who the excuse is for';
      return;
    }
    formError.value = null;
    notice.value = null;
    // The user wants a different one: the ready-made excuse is not needed.
    readyMade.value = false;
    await _pregenerated.consume(current.id);
    phase.value = DodgePhase.generating;

    final previous = await _excuses.recentForRecipient(
      recipient,
      limit: maxExcuseHistory,
    );
    final result = await _gemma.writeExcuse(
      ExcuseInput(
        taskTitle: current.title,
        recipient: recipient,
        tone: tone.value,
        previousExcuses: [for (final e in previous) e.body],
      ),
    );

    switch (result) {
      case JobSuccess<ExcuseDraft>():
        excuse.value = result.value;
        useShort.value = false;
        phase.value = DodgePhase.ready;
      case JobFallback<ExcuseDraft>():
        failureReason.value = result.reason;
        failureRaw.value = result.rawText;
        phase.value = DodgePhase.failed;
    }
  }

  Future<void> stopGenerating() => _gemma.stop();

  /// Checks the excuse can be used for the person typed in. Returns false and
  /// says why in [formError] if not.
  Future<bool> _canUse(String text) async {
    final recipient = recipientField.text.trim();
    if (recipient.isEmpty) {
      formError.value = 'Say who the excuse is for';
      return false;
    }
    final previous = await _excuses.recentForRecipient(
      recipient,
      limit: maxExcuseHistory,
    );
    final wanted = _normalise(text);
    if (previous.any((e) => _normalise(e.body) == wanted)) {
      formError.value =
          'You already used this one for $recipient. Tap Regenerate for a new one.';
      return false;
    }
    formError.value = null;
    return true;
  }

  static String _normalise(String text) =>
      text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

  Future<void> copy() async {
    final text = selectedText;
    if (text.isEmpty) return;
    if (!await _canUse(text)) return;
    await _share.copy(text);
    notice.value = 'Copied';
    await _logUse(text);
  }

  /// Opens the Android share sheet; a dismissed sheet logs nothing.
  Future<void> share() async {
    final text = selectedText;
    if (text.isEmpty) return;
    if (!await _canUse(text)) return;
    final shared = await _share.share(text);
    if (shared) await _logUse(text);
  }

  /// Saves the excuse that was used and logs the dodge once.
  Future<void> _logUse(String text) async {
    final current = task.value;
    if (current == null) return;
    final saved = await _excuses.create(
      taskId: current.id,
      recipientLabel: recipientField.text.trim(),
      tone: tone.value.label,
      text: text,
    );
    await _excuses.markShared(saved.id);
    await _outcomes.markDodged(current.id);
    await _pregenerated.consume(current.id);
    logged.value = true;
  }

  @override
  void onClose() {
    if (phase.value == DodgePhase.generating) _gemma.stop();
    recipientField.dispose();
    super.onClose();
  }
}
