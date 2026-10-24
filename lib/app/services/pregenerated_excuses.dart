import 'dart:convert';

import '../data/models/prompt_jobs.dart';
import '../data/models/settings_keys.dart';
import '../data/repositories/settings_repository.dart';

/// Who a ready-made excuse is "for": nobody in particular.
const genericRecipient = 'someone';

/// Excuses written ahead of time, while the phone charged, so Dodge It can show
/// one straight away. One per task, general and in a Polite tone.
class PregeneratedExcuses {
  const PregeneratedExcuses(this._settings);

  final SettingsRepository _settings;

  String _key(int taskId) => '${SettingsKeys.pregenExcusePrefix}$taskId';

  Future<bool> has(int taskId) async =>
      await _settings.get(_key(taskId)) != null;

  Future<ExcuseDraft?> read(int taskId) async {
    final raw = await _settings.get(_key(taskId));
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return ExcuseDraft(
        text: json['excuse'] as String,
        shortVariant: json['short'] as String,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> write(int taskId, ExcuseDraft excuse) {
    return _settings.set(_key(taskId), jsonEncode(excuse.toJson()));
  }

  /// Removes it: it was used, or the user asked for a different one.
  Future<void> consume(int taskId) => _settings.remove(_key(taskId));
}
