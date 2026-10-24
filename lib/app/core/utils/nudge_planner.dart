import '../../data/models/enums.dart';

/// Risk used until the predictor exists (Phase 7): medium.
const placeholderRisk = 0.5;

/// Tasks without a due date are treated as due this many days after creation.
const noDueDateDays = 3;

/// How far ahead nudges are planned. The daily job plans the next day.
const planningHorizon = Duration(hours: 24);

/// Nudges per task stay under this, whatever the risk.
const maxNudgesPerDay = 6;

enum RiskBand { low, medium, high }

RiskBand riskBand(double risk) {
  if (risk < 0.34) return RiskBand.low;
  if (risk < 0.67) return RiskBand.medium;
  return RiskBand.high;
}

/// Time between nudges: low about 6 hours, medium 3, high 2.
Duration nudgeGap(RiskBand band) => switch (band) {
  RiskBand.low => const Duration(hours: 6),
  RiskBand.medium => const Duration(hours: 3),
  RiskBand.high => const Duration(hours: 2),
};

/// Nudges per day for a band: 2, 4 and 6.
int nudgesPerDay(RiskBand band) => switch (band) {
  RiskBand.low => 2,
  RiskBand.medium => 4,
  RiskBand.high => 6,
};

/// A due date picked on a calendar means the end of that day.
DateTime effectiveDue({required DateTime? dueAt, required DateTime createdAt}) {
  if (dueAt != null) {
    return DateTime(dueAt.year, dueAt.month, dueAt.day, 23, 59, 59);
  }
  return createdAt.add(const Duration(days: noDueDateDays));
}

/// Hours when no nudge is sent, as local time of day. May span midnight.
class QuietHours {
  const QuietHours({required this.startMinutes, required this.endMinutes});

  /// 21:00 to 09:00.
  static const standard = QuietHours(startMinutes: 21 * 60, endMinutes: 9 * 60);

  final int startMinutes;
  final int endMinutes;

  /// Reads "21:00". Returns null for anything else.
  static int? parseMinutes(String? text) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(text?.trim() ?? '');
    if (match == null) return null;
    final h = int.parse(match.group(1)!);
    final m = int.parse(match.group(2)!);
    if (h > 23 || m > 59) return null;
    return h * 60 + m;
  }

  factory QuietHours.fromSettings(String? start, String? end) {
    return QuietHours(
      startMinutes: parseMinutes(start) ?? standard.startMinutes,
      endMinutes: parseMinutes(end) ?? standard.endMinutes,
    );
  }

  bool get isEmpty => startMinutes == endMinutes;

  bool contains(DateTime time) {
    if (isEmpty) return false;
    final m = time.hour * 60 + time.minute;
    return startMinutes < endMinutes
        ? m >= startMinutes && m < endMinutes
        : m >= startMinutes || m < endMinutes;
  }

  /// The first moment at or after [time] that is outside quiet hours.
  DateTime nextAllowed(DateTime time) {
    if (!contains(time)) return time;
    var end = DateTime(
      time.year,
      time.month,
      time.day,
      endMinutes ~/ 60,
      endMinutes % 60,
    );
    if (!end.isAfter(time)) end = end.add(const Duration(days: 1));
    return end;
  }
}

class PlannedNudge {
  const PlannedNudge(this.fireAt, this.level);

  final DateTime fireAt;
  final NudgeLevel level;

  @override
  bool operator ==(Object other) =>
      other is PlannedNudge && other.fireAt == fireAt && other.level == level;

  @override
  int get hashCode => Object.hash(fireAt, level);

  @override
  String toString() => '${level.name}@$fireAt';
}

/// Plans local notifications for one task.
///
/// Higher [risk] means more nudges, closer together, and firmer wording
/// sooner. Nothing is planned inside [quiet] hours or after [due].
/// With [fastClock] the three levels fire one minute apart (for testing).
List<PlannedNudge> planNudges({
  required DateTime now,
  required DateTime due,
  required double risk,
  QuietHours quiet = QuietHours.standard,
  bool fastClock = false,
  Duration horizon = planningHorizon,
  int maxPerDay = maxNudgesPerDay,
}) {
  if (fastClock) {
    return [
      for (var i = 0; i < NudgeLevel.values.length; i++)
        PlannedNudge(now.add(Duration(minutes: i + 1)), NudgeLevel.values[i]),
    ];
  }

  final band = riskBand(risk);
  final gap = nudgeGap(band);
  // The user's limit can only lower what the risk band allows.
  final perDay = nudgesPerDay(band)
      .clamp(1, maxPerDay.clamp(1, maxNudgesPerDay));
  final horizonEnd = now.add(horizon);
  final end = due.isBefore(horizonEnd) ? due : horizonEnd;
  // Escalate sooner for high risk tasks.
  final firmWithin = band == RiskBand.high
      ? const Duration(hours: 48)
      : const Duration(hours: 24);

  final planned = <PlannedNudge>[];
  final perDate = <String, int>{};
  var t = now.add(gap);
  for (var i = 0; i < 100 && t.isBefore(end); i++) {
    t = quiet.nextAllowed(t);
    if (!t.isBefore(end)) break;

    final date = '${t.year}-${t.month}-${t.day}';
    final count = perDate[date] ?? 0;
    if (count < perDay) {
      perDate[date] = count + 1;
      // The last call is the final nudge that fits before the due time.
      final isLast = !quiet.nextAllowed(t.add(gap)).isBefore(due);
      final remaining = due.difference(t);
      final level = isLast
          ? NudgeLevel.lastCall
          : remaining <= firmWithin
          ? NudgeLevel.firm
          : NudgeLevel.gentle;
      planned.add(PlannedNudge(t, level));
    }
    t = t.add(gap);
  }
  return planned;
}

/// Notification text when the model has not written any: always available, so
/// firing a notification never needs the model.
String templateWording(NudgeLevel level, String step) {
  final text = switch (level) {
    NudgeLevel.gentle => 'Ready for a tiny step? $step',
    NudgeLevel.firm => 'Time to do it: $step',
    NudgeLevel.lastCall => 'Last call: $step',
  };
  return text.length <= 140 ? text : '${text.substring(0, 137)}...';
}
