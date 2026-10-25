import 'package:flutter_test/flutter_test.dart';
import 'package:do_it_or_dodge_it/app/core/utils/risk_features.dart';
import 'package:do_it_or_dodge_it/app/data/models/enums.dart';

final now = DateTime(2030, 1, 7, 10);

Map<String, double> features({
  TaskCategory category = TaskCategory.admin,
  DateTime? created,
  DateTime? due,
  bool noDue = false,
  int steps = 0,
  int minutes = 0,
  double? categoryRate,
  double? recentRate,
}) {
  return buildFeatures(
    FeatureInput(
      category: category,
      createdAt: created ?? DateTime(2030, 1, 7, 9),
      dueAt: noDue ? null : (due ?? DateTime(2030, 1, 22)),
      now: now,
      stepCount: steps,
      totalMinutes: minutes,
      categoryDodgeRate: categoryRate,
      recentDodgeRate: recentRate,
    ),
  );
}

void main() {
  test('has one named feature per input, in a fixed order', () {
    final f = features();
    expect(f.keys.toSet(), featureNames.toSet());
    expect(featureNames.length, TaskCategory.values.length + 9);
    expect(toVector(f), hasLength(featureNames.length));
  });

  test('the category is one-hot', () {
    final f = features(category: TaskCategory.health);
    for (final c in TaskCategory.values) {
      expect(f['cat_${c.name}'], c == TaskCategory.health ? 1 : 0);
    }
  });

  group('days until due', () {
    test('a task with no due date counts as far away', () {
      expect(features(noDue: true)['days_until_due'], 1);
    });

    test('scales over 30 days from now', () {
      // End of 22 Jan is 15.57 days after 7 Jan 10:00.
      expect(features()['days_until_due'], closeTo(0.52, 0.01));
      expect(
        features(due: DateTime(2030, 1, 7))['days_until_due'],
        closeTo(0.0, 0.02),
      );
    });

    test('overdue is 0 and far away stops growing at 1', () {
      expect(features(due: DateTime(2030, 1, 1))['days_until_due'], 0);
      expect(features(due: DateTime(2031, 1, 1))['days_until_due'], 1);
    });
  });

  test('steps and minutes are capped', () {
    expect(features(steps: 0, minutes: 0)['step_count'], 0);
    expect(features(steps: 7, minutes: 120)['step_count'], 1);
    expect(features(steps: 7, minutes: 120)['total_minutes'], 1);
    expect(features(steps: 20, minutes: 900)['step_count'], 1);
    expect(features(steps: 20, minutes: 900)['total_minutes'], 1);
    expect(features(minutes: 60)['total_minutes'], 0.5);
  });

  test('hour and weekday wrap around', () {
    double distance(Map<String, double> a, Map<String, double> b, String x) {
      final dx = a['${x}_sin']! - b['${x}_sin']!;
      final dy = a['${x}_cos']! - b['${x}_cos']!;
      return (dx * dx + dy * dy);
    }

    // 23:30 is close to 00:30 and far from noon.
    final late = features(created: DateTime(2030, 1, 7, 23, 30));
    final early = features(created: DateTime(2030, 1, 8, 0, 30));
    final noon = features(created: DateTime(2030, 1, 7, 12));
    expect(
      distance(late, early, 'hour'),
      lessThan(distance(late, noon, 'hour') / 10),
    );

    // Sunday is next to Monday, and far from Thursday.
    final sunday = features(created: DateTime(2030, 1, 6));
    final monday = features(created: DateTime(2030, 1, 7));
    final thursday = features(created: DateTime(2030, 1, 10));
    expect(
      distance(sunday, monday, 'dow'),
      lessThan(distance(sunday, thursday, 'dow')),
    );
    expect(monday['dow_sin'], 0);
    expect(monday['dow_cos'], 1);
  });

  test('dodge rates are centred, and no history is 0', () {
    expect(features()['category_dodge_rate'], 0);
    expect(features()['recent_dodge_rate'], 0);
    expect(
      features(categoryRate: 0.9)['category_dodge_rate'],
      closeTo(0.4, 1e-9),
    );
    expect(features(recentRate: 0.1)['recent_dodge_rate'], closeTo(-0.4, 1e-9));
  });

  test('every value is small enough to train without scaling', () {
    final f = features(steps: 5, minutes: 40, categoryRate: 1, recentRate: 0);
    for (final value in f.values) {
      expect(value.abs(), lessThanOrEqualTo(1));
    }
  });

  test('a vector ignores unknown names and treats missing ones as 0', () {
    final v = toVector({'cat_work': 1, 'something_new': 5});
    expect(v[featureNames.indexOf('cat_work')], 1);
    expect(v.where((x) => x != 0), hasLength(1));
  });

  group('reasons', () {
    List<double> weightsFor(Map<String, double> byName) => [
      for (final name in featureNames) byName[name] ?? 0,
    ];
    final context = ReasonContext(
      category: TaskCategory.admin,
      createdAt: DateTime(2030, 1, 7, 9),
      categoryDodgeRate: 0.7,
      recentDodgeRate: 0.6,
    );

    test('names the category and the rate when it pushes the risk up', () {
      final text = explainModel(
        features: features(categoryRate: 0.7),
        weights: weightsFor({'cat_admin': 2.0, 'days_until_due': 0.1}),
        context: context,
      );
      expect(text, 'You dodge admin tasks 70% of the time.');
    });

    test('says so when the category pulls the risk down', () {
      final text = explainModel(
        features: features(category: TaskCategory.health),
        weights: weightsFor({'cat_health': -2.0}),
        context: ReasonContext(
          category: TaskCategory.health,
          createdAt: DateTime(2030, 1, 7),
          categoryDodgeRate: 0.2,
        ),
      );
      expect(text, 'You finish health tasks 80% of the time.');
    });

    test('picks the factor with the largest weighted value', () {
      final text = explainModel(
        features: features(noDue: true),
        weights: weightsFor({'cat_admin': 0.2, 'days_until_due': 3.0}),
        context: context,
      );
      expect(text, contains('deadline is far away'));
    });

    test('explains the other factors in plain words', () {
      String reason(Map<String, double> w, Map<String, double> f) =>
          explainModel(features: f, weights: weightsFor(w), context: context);

      expect(
        reason({'recent_dodge_rate': 5}, features(recentRate: 0.6)),
        'You dodged 60% of your tasks in the last 14 days.',
      );
      expect(
        reason({'recent_dodge_rate': 5}, features(recentRate: 0.1)),
        contains('finishing most of your tasks'),
      );
      expect(
        reason({'step_count': 4}, features(steps: 7)),
        'It has a lot of steps.',
      );
      expect(
        reason({'total_minutes': 4}, features(minutes: 120)),
        'It will take a while.',
      );
      expect(
        reason({'days_until_due': -4}, features(due: DateTime(2030, 1, 8))),
        contains('deadline is close'),
      );
    });

    test('mentions the hour or weekday', () {
      String reason(Map<String, double> w) => explainModel(
        features: features(created: DateTime(2030, 1, 7, 9)),
        weights: weightsFor(w),
        context: context,
      );
      expect(reason({'hour_sin': 3}), contains('09:00'));
      expect(reason({'dow_cos': 3}), contains('Mondays'));
    });

    test('is honest when nothing stands out', () {
      final text = explainModel(
        features: features(),
        weights: weightsFor({'cat_admin': 0.01}),
        context: context,
      );
      expect(text, 'Your history does not point either way yet.');
    });

    test('the rule explains itself', () {
      expect(
        explainRule(category: TaskCategory.admin, categoryDodgeRate: 0.7),
        'You dodge admin tasks 70% of the time.',
      );
      expect(
        explainRule(category: TaskCategory.admin, categoryDodgeRate: null),
        'Not enough history yet, so this starts at 50%.',
      );
      expect(
        explainRule(category: TaskCategory.other, categoryDodgeRate: 0.5),
        'You dodge these tasks 50% of the time.',
      );
    });
  });
}
