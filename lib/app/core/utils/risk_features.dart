import 'dart:math' as math;

import '../../data/models/enums.dart';

/// Days until the due date at which the feature stops growing.
const _maxDays = 30;

/// Names of the features, in the order the model sees them.
final List<String> featureNames = [
  for (final c in TaskCategory.values) 'cat_${c.name}',
  'days_until_due',
  'step_count',
  'total_minutes',
  'hour_sin',
  'hour_cos',
  'dow_sin',
  'dow_cos',
  'category_dodge_rate',
  'recent_dodge_rate',
];

/// Everything the features are computed from.
class FeatureInput {
  const FeatureInput({
    required this.category,
    required this.createdAt,
    required this.dueAt,
    required this.now,
    required this.stepCount,
    required this.totalMinutes,
    this.categoryDodgeRate,
    this.recentDodgeRate,
  });

  final TaskCategory category;

  /// When the task was added: hour and weekday come from here.
  final DateTime createdAt;
  final DateTime? dueAt;

  /// When the features are read: the days left count from here.
  final DateTime now;

  /// Steps Gemma produced; 0 before Do It has run.
  final int stepCount;
  final int totalMinutes;

  /// Share of this category's past tasks that were dodged, or null with no
  /// history.
  final double? categoryDodgeRate;

  /// Share of tasks closed in the last 14 days that were dodged, or null with
  /// none.
  final double? recentDodgeRate;
}

/// Turns [input] into named features. Every value is small (about -1 to 1) so
/// training needs no scaling:
///
/// - category: one-hot
/// - days until due: 0 to 1 over 30 days; no due date counts as 1 (far away)
/// - steps: 0 to 1 over 7 steps; minutes: 0 to 1 over 2 hours
/// - hour and weekday: sin and cos, so 23:00 is close to 00:00
/// - dodge rates: the rate minus 0.5, so "no history" is 0
Map<String, double> buildFeatures(FeatureInput input) {
  final features = <String, double>{
    for (final c in TaskCategory.values)
      'cat_${c.name}': c == input.category ? 1 : 0,
  };

  final due = input.dueAt;
  if (due == null) {
    features['days_until_due'] = 1;
  } else {
    final end = DateTime(due.year, due.month, due.day, 23, 59, 59);
    final days = end.difference(input.now).inMinutes / (24 * 60);
    features['days_until_due'] = days.clamp(0, _maxDays) / _maxDays;
  }

  features['step_count'] = math.min(input.stepCount, 7) / 7;
  features['total_minutes'] = math.min(input.totalMinutes, 120) / 120;

  final hour = input.createdAt.hour + input.createdAt.minute / 60;
  features['hour_sin'] = math.sin(2 * math.pi * hour / 24);
  features['hour_cos'] = math.cos(2 * math.pi * hour / 24);
  final day = (input.createdAt.weekday - 1).toDouble();
  features['dow_sin'] = math.sin(2 * math.pi * day / 7);
  features['dow_cos'] = math.cos(2 * math.pi * day / 7);

  features['category_dodge_rate'] = (input.categoryDodgeRate ?? 0.5) - 0.5;
  features['recent_dodge_rate'] = (input.recentDodgeRate ?? 0.5) - 0.5;
  return features;
}

/// The feature values as a vector, in [featureNames] order. Names missing from
/// [features] (for example from an older snapshot) count as 0.
List<double> toVector(Map<String, dynamic> features) {
  return [
    for (final name in featureNames) (features[name] as num?)?.toDouble() ?? 0,
  ];
}

/// What the user might want to hear about, for the plain-words reason.
class ReasonContext {
  const ReasonContext({
    required this.category,
    required this.createdAt,
    this.categoryDodgeRate,
    this.recentDodgeRate,
  });

  final TaskCategory category;
  final DateTime createdAt;
  final double? categoryDodgeRate;
  final double? recentDodgeRate;
}

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// A contribution this small is not worth mentioning.
const _minContribution = 0.05;

/// One sentence about the factor that moves the score most (the largest
/// weight times value), in plain words.
String explainModel({
  required Map<String, double> features,
  required List<double> weights,
  required ReasonContext context,
}) {
  double part(Iterable<String> names) {
    var total = 0.0;
    for (final name in names) {
      final i = featureNames.indexOf(name);
      total += weights[i] * (features[name] ?? 0);
    }
    return total;
  }

  final groups = <String, double>{
    'category': part([
      for (final c in TaskCategory.values) 'cat_${c.name}',
      'category_dodge_rate',
    ]),
    'recent': part(['recent_dodge_rate']),
    'days': part(['days_until_due']),
    'steps': part(['step_count']),
    'minutes': part(['total_minutes']),
    'hour': part(['hour_sin', 'hour_cos']),
    'dow': part(['dow_sin', 'dow_cos']),
  };

  var top = 'category';
  for (final entry in groups.entries) {
    if (entry.value.abs() > groups[top]!.abs()) top = entry.key;
  }
  final value = groups[top]!;
  if (value.abs() < _minContribution) {
    return 'Your history does not point either way yet.';
  }
  final raises = value > 0;
  final label = context.category == TaskCategory.other
      ? 'these'
      : context.category.label.toLowerCase();

  switch (top) {
    case 'category':
      final rate = context.categoryDodgeRate;
      if (raises) {
        return rate == null
            ? 'Tasks like this tend to get dodged.'
            : 'You dodge $label tasks ${_percent(rate)} of the time.';
      }
      return rate == null
          ? 'Tasks like this tend to get done.'
          : 'You finish $label tasks ${_percent(1 - rate)} of the time.';
    case 'recent':
      final rate = context.recentDodgeRate ?? 0.5;
      return raises
          ? 'You dodged ${_percent(rate)} of your tasks in the last 14 days.'
          : 'You have been finishing most of your tasks lately.';
    case 'days':
      return raises
          ? 'The deadline is far away, so it is easy to put off.'
          : 'The deadline is close, which helps you act.';
    case 'steps':
      return raises ? 'It has a lot of steps.' : 'It has only a few steps.';
    case 'minutes':
      return raises ? 'It will take a while.' : 'It is quick to do.';
    case 'hour':
      final hh = context.createdAt.hour.toString().padLeft(2, '0');
      return raises
          ? 'You tend to dodge tasks you add around $hh:00.'
          : 'You tend to finish tasks you add around $hh:00.';
    default:
      final day = _weekdays[context.createdAt.weekday - 1];
      return raises
          ? 'You tend to dodge tasks you add on ${day}s.'
          : 'You tend to finish tasks you add on ${day}s.';
  }
}

/// The reason when the simple rule is used instead of the model.
String explainRule({
  required TaskCategory category,
  required double? categoryDodgeRate,
}) {
  if (categoryDodgeRate == null) {
    return 'Not enough history yet, so this starts at 50%.';
  }
  final label = category == TaskCategory.other
      ? 'these'
      : category.label.toLowerCase();
  return 'You dodge $label tasks ${_percent(categoryDodgeRate)} of the time.';
}

String _percent(double rate) => '${(rate * 100).round()}%';
