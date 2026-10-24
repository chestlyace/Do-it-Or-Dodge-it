import 'package:flutter_test/flutter_test.dart';
import 'package:do_it_or_dodge_it/app/core/utils/nudge_planner.dart';
import 'package:do_it_or_dodge_it/app/data/models/enums.dart';

final monday10 = DateTime(2030, 1, 7, 10);
final farDue = DateTime(2030, 1, 20);

List<PlannedNudge> plan(
  double risk, {
  DateTime? now,
  DateTime? due,
  QuietHours quiet = QuietHours.standard,
  Duration horizon = planningHorizon,
}) {
  return planNudges(
    now: now ?? monday10,
    due: due ?? farDue,
    risk: risk,
    quiet: quiet,
    horizon: horizon,
  );
}

void main() {
  group('risk bands', () {
    test('edges', () {
      expect(riskBand(0), RiskBand.low);
      expect(riskBand(0.33), RiskBand.low);
      expect(riskBand(0.34), RiskBand.medium);
      expect(riskBand(0.66), RiskBand.medium);
      expect(riskBand(0.67), RiskBand.high);
      expect(riskBand(1), RiskBand.high);
    });

    test('low 2 a day about 6h apart, medium 4 about 3h, high 6 about 2h', () {
      expect(nudgeGap(RiskBand.low), const Duration(hours: 6));
      expect(nudgeGap(RiskBand.medium), const Duration(hours: 3));
      expect(nudgeGap(RiskBand.high), const Duration(hours: 2));
      expect(nudgesPerDay(RiskBand.low), 2);
      expect(nudgesPerDay(RiskBand.medium), 4);
      expect(nudgesPerDay(RiskBand.high), 6);
    });

    test('the placeholder risk is medium', () {
      expect(riskBand(placeholderRisk), RiskBand.medium);
    });
  });

  group('schedule from 10:00 with quiet hours 21:00 to 09:00', () {
    test('low risk: 2 nudges in the next 24 hours', () {
      expect(plan(0.1).map((n) => n.fireAt), [
        DateTime(2030, 1, 7, 16),
        DateTime(2030, 1, 8, 9),
      ]);
    });

    test('medium risk: 4 nudges', () {
      expect(plan(0.5).map((n) => n.fireAt), [
        DateTime(2030, 1, 7, 13),
        DateTime(2030, 1, 7, 16),
        DateTime(2030, 1, 7, 19),
        DateTime(2030, 1, 8, 9),
      ]);
    });

    test('high risk: 6 nudges', () {
      expect(plan(0.9).map((n) => n.fireAt), [
        DateTime(2030, 1, 7, 12),
        DateTime(2030, 1, 7, 14),
        DateTime(2030, 1, 7, 16),
        DateTime(2030, 1, 7, 18),
        DateTime(2030, 1, 7, 20),
        DateTime(2030, 1, 8, 9),
      ]);
    });

    test('a higher risk gets more nudges, closer together', () {
      final low = plan(0.1);
      final medium = plan(0.5);
      final high = plan(0.9);
      expect(high.length, greaterThan(medium.length));
      expect(medium.length, greaterThan(low.length));

      Duration smallestGap(List<PlannedNudge> n) => [
        for (var i = 1; i < n.length; i++)
          n[i].fireAt.difference(n[i - 1].fireAt),
      ].reduce((a, b) => a < b ? a : b);
      expect(smallestGap(high), lessThan(smallestGap(medium)));
    });
  });

  group('quiet hours', () {
    test('no nudge is ever planned inside quiet hours', () {
      for (final risk in [0.1, 0.5, 0.9]) {
        for (var half = 0; half < 96; half++) {
          final now = DateTime(2030, 1, 7).add(Duration(minutes: 30 * half));
          for (final nudge in plan(risk, now: now)) {
            expect(
              QuietHours.standard.contains(nudge.fireAt),
              isFalse,
              reason: 'risk $risk from $now fired at ${nudge.fireAt}',
            );
          }
        }
      }
    });

    test('a nudge that would land at night moves to the morning', () {
      final planned = plan(0.5, now: DateTime(2030, 1, 7, 20, 30));
      expect(planned.first.fireAt, DateTime(2030, 1, 8, 9));
    });

    test('daytime quiet hours work too', () {
      const lunch = QuietHours(startMinutes: 13 * 60, endMinutes: 15 * 60);
      for (final nudge in plan(
        0.9,
        quiet: lunch,
        horizon: const Duration(hours: 48),
      )) {
        expect(lunch.contains(nudge.fireAt), isFalse);
      }
    });

    test('equal start and end means no quiet hours', () {
      const none = QuietHours(startMinutes: 0, endMinutes: 0);
      expect(none.contains(DateTime(2030, 1, 1, 3)), isFalse);
      expect(plan(0.9, quiet: none).length, 11);
    });

    test('contains and nextAllowed across midnight', () {
      const q = QuietHours.standard;
      expect(q.contains(DateTime(2030, 1, 1, 21)), isTrue);
      expect(q.contains(DateTime(2030, 1, 1, 23, 59)), isTrue);
      expect(q.contains(DateTime(2030, 1, 1, 0)), isTrue);
      expect(q.contains(DateTime(2030, 1, 1, 8, 59)), isTrue);
      expect(q.contains(DateTime(2030, 1, 1, 9)), isFalse);
      expect(q.contains(DateTime(2030, 1, 1, 20, 59)), isFalse);

      expect(q.nextAllowed(DateTime(2030, 1, 1, 23)), DateTime(2030, 1, 2, 9));
      expect(q.nextAllowed(DateTime(2030, 1, 2, 3)), DateTime(2030, 1, 2, 9));
      expect(q.nextAllowed(DateTime(2030, 1, 2, 12)), DateTime(2030, 1, 2, 12));
    });

    test('reads times from settings and falls back to 21:00 to 09:00', () {
      final custom = QuietHours.fromSettings('22:30', '07:15');
      expect(custom.startMinutes, 22 * 60 + 30);
      expect(custom.endMinutes, 7 * 60 + 15);

      for (final bad in [null, '', 'x', '25:00', '9']) {
        final q = QuietHours.fromSettings(bad, bad);
        expect(q.startMinutes, QuietHours.standard.startMinutes);
        expect(q.endMinutes, QuietHours.standard.endMinutes);
      }
    });
  });

  group('due date', () {
    test('nothing is planned after the due date', () {
      final due = DateTime(2030, 1, 7, 15);
      final planned = plan(0.5, due: due);
      expect(planned.map((n) => n.fireAt), [DateTime(2030, 1, 7, 13)]);
      for (final n in planned) {
        expect(n.fireAt.isBefore(due), isTrue);
      }
    });

    test('a due date in the past plans nothing', () {
      expect(plan(0.9, due: DateTime(2030, 1, 6)), isEmpty);
      expect(plan(0.9, due: monday10), isEmpty);
    });

    test('a picked date means the end of that day', () {
      expect(
        effectiveDue(
          dueAt: DateTime(2030, 1, 9),
          createdAt: DateTime(2030, 1, 1),
        ),
        DateTime(2030, 1, 9, 23, 59, 59),
      );
    });

    test('no due date means 3 days after creation', () {
      expect(
        effectiveDue(dueAt: null, createdAt: DateTime(2030, 1, 1, 8)),
        DateTime(2030, 1, 4, 8),
      );
    });
  });

  group('levels', () {
    test('far from the due date every nudge is gentle', () {
      expect(plan(0.5).map((n) => n.level).toSet(), {NudgeLevel.gentle});
    });

    test('gentle, then firm within a day of the due date, then last call', () {
      // Due at the end of Tuesday. Plan again each morning, as the daily job does.
      final due = DateTime(2030, 1, 8, 23, 59, 59);

      final monday = plan(0.5, due: due);
      expect(monday.map((n) => n.level), [
        NudgeLevel.gentle,
        NudgeLevel.gentle,
        NudgeLevel.gentle,
        NudgeLevel.firm,
      ]);

      final tuesday = plan(0.5, now: DateTime(2030, 1, 8, 10), due: due);
      expect(tuesday, [
        PlannedNudge(DateTime(2030, 1, 8, 13), NudgeLevel.firm),
        PlannedNudge(DateTime(2030, 1, 8, 16), NudgeLevel.firm),
        PlannedNudge(DateTime(2030, 1, 8, 19), NudgeLevel.lastCall),
      ]);
    });

    test(
      'a nudge is only the last call if no other fits before the due time',
      () {
        // Due in three days: the last nudge in the 24-hour window is not a last call.
        final planned = plan(0.5, due: monday10.add(const Duration(days: 3)));
        expect(
          planned.map((n) => n.level),
          isNot(contains(NudgeLevel.lastCall)),
        );
      },
    );

    test('the nudge right before the due date is the last call', () {
      final planned = plan(0.5, due: monday10.add(const Duration(hours: 4)));
      expect(planned.single.level, NudgeLevel.lastCall);
    });

    test('high risk gets firm wording sooner', () {
      final due = monday10.add(const Duration(hours: 40));
      final medium = plan(
        0.5,
        due: due,
        quiet: const QuietHours(startMinutes: 0, endMinutes: 0),
      );
      final high = plan(
        0.9,
        due: due,
        quiet: const QuietHours(startMinutes: 0, endMinutes: 0),
      );
      expect(medium.first.level, NudgeLevel.gentle);
      expect(high.first.level, NudgeLevel.firm);
    });
  });

  group('limits', () {
    test('never more than 6 a day for a task, whatever the risk', () {
      final planned = plan(
        1,
        horizon: const Duration(hours: 96),
        quiet: const QuietHours(startMinutes: 0, endMinutes: 0),
      );
      final perDay = <String, int>{};
      for (final n in planned) {
        final key = '${n.fireAt.year}-${n.fireAt.month}-${n.fireAt.day}';
        perDay[key] = (perDay[key] ?? 0) + 1;
      }
      expect(perDay.values.every((c) => c <= maxNudgesPerDay), isTrue);
    });

    test('nothing falls outside the planning horizon', () {
      for (final n in plan(0.9)) {
        expect(n.fireAt.isBefore(monday10.add(planningHorizon)), isTrue);
        expect(n.fireAt.isAfter(monday10), isTrue);
      }
    });
  });

  group('fast clock', () {
    test('three levels, a minute apart, ignoring quiet hours and due date', () {
      final night = DateTime(2030, 1, 7, 23, 30);
      final planned = planNudges(
        now: night,
        due: DateTime(2030, 1, 1),
        risk: 0.1,
        fastClock: true,
      );
      expect(planned, [
        PlannedNudge(night.add(const Duration(minutes: 1)), NudgeLevel.gentle),
        PlannedNudge(night.add(const Duration(minutes: 2)), NudgeLevel.firm),
        PlannedNudge(
          night.add(const Duration(minutes: 3)),
          NudgeLevel.lastCall,
        ),
      ]);
    });
  });

  group('template wording', () {
    test('names the step at every level', () {
      for (final level in NudgeLevel.values) {
        expect(
          templateWording(level, 'Open the file'),
          contains('Open the file'),
        );
      }
      expect(
        templateWording(NudgeLevel.lastCall, 'x'),
        startsWith('Last call'),
      );
    });

    test('stays short enough for a notification', () {
      final text = templateWording(NudgeLevel.gentle, 'a' * 500);
      expect(text.length, lessThanOrEqualTo(140));
      expect(text, endsWith('...'));
    });
  });
}
