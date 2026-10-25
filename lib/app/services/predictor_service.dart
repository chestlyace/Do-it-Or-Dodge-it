import 'dart:convert';

import 'package:get/get.dart';

import '../core/utils/logistic_regression.dart';
import '../core/utils/risk_features.dart';
import '../data/db/app_database.dart';
import '../data/models/enums.dart';
import '../data/models/risk.dart';
import '../data/models/settings_keys.dart';
import '../data/repositories/outcome_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/step_repository.dart';
import '../data/repositories/task_repository.dart';

/// The model replaces the simple rule once this many outcomes with saved
/// features exist.
const coldStartOutcomes = 20;

/// Window for the "recent dodge rate" feature.
const recentWindow = Duration(days: 14);

/// Scores each task with a dodge risk from 0 to 1, learned on the phone from
/// the user's own outcomes. Nothing leaves the phone.
///
/// - Features are saved when the user chooses Do It or Dodge It, so training
///   uses what the app knew then.
/// - Below [coldStartOutcomes] outcomes a simple rule is used instead.
/// - The weights are stored in settings, so they survive restarts.
class PredictorService extends GetxService {
  PredictorService({
    required this._tasks,
    required this._steps,
    required this._outcomes,
    required this._settings,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final TaskRepository _tasks;
  final StepRepository _steps;
  final OutcomeRepository _outcomes;
  final SettingsRepository _settings;
  final DateTime Function() _now;

  // ---- Features ----

  /// The features of [task] as the app knows them right now.
  Future<Map<String, double>> featuresFor(Task task) async =>
      (await _compute(task)).features;

  ({Map<String, double> features, ReasonContext context}) _features(
    Task task,
    List<HistoryEntry> history,
    List<Step> steps,
  ) {
    final now = _now();
    final inCategory = history
        .where((e) => e.task.category == task.category)
        .toList();
    final recent = history
        .where((e) => !e.outcome.at.isBefore(now.subtract(recentWindow)))
        .toList();
    final categoryRate = _dodgeRate(inCategory);
    final recentRate = _dodgeRate(recent);
    return (
      features: buildFeatures(
        FeatureInput(
          category: task.category,
          createdAt: task.createdAt,
          dueAt: task.dueAt,
          now: now,
          stepCount: steps.length,
          totalMinutes: steps.fold(0, (sum, s) => sum + s.estMinutes),
          categoryDodgeRate: categoryRate,
          recentDodgeRate: recentRate,
        ),
      ),
      context: ReasonContext(
        category: task.category,
        createdAt: task.createdAt,
        categoryDodgeRate: categoryRate,
        recentDodgeRate: recentRate,
      ),
    );
  }

  Future<({Map<String, double> features, ReasonContext context})> _compute(
    Task task,
  ) async {
    final steps = await _steps.listForTask(task.id);
    return _features(task, await _outcomes.listHistory(), steps);
  }

  static double? _dodgeRate(List<HistoryEntry> entries) {
    if (entries.isEmpty) return null;
    final dodged = entries
        .where((e) => e.outcome.result != OutcomeResult.done)
        .length;
    return dodged / entries.length;
  }

  // ---- Decision snapshots ----

  /// Saves the features as they are now, because the user just chose Do It or
  /// Dodge It. Only the first choice for a task is kept.
  Future<void> recordDecision(int taskId) async {
    final key = '${SettingsKeys.decisionSnapshotPrefix}$taskId';
    if (await _settings.get(key) != null) return;
    final task = await _tasks.getById(taskId);
    if (task == null) return;
    final computed = await _compute(task);
    await _settings.set(key, jsonEncode(computed.features));
  }

  /// The features saved at decision time, or the current ones when the task
  /// was closed without a recorded choice. Removes the saved copy.
  Future<Map<String, dynamic>> takeDecisionSnapshot(Task task) async {
    final key = '${SettingsKeys.decisionSnapshotPrefix}${task.id}';
    final saved = await _settings.get(key);
    if (saved != null) {
      await _settings.remove(key);
      try {
        return Map<String, dynamic>.from(jsonDecode(saved) as Map);
      } catch (_) {
        // Fall through to the current features.
      }
    }
    return (await _compute(task)).features;
  }

  /// Drops the saved features of a task that is being deleted.
  Future<void> forget(int taskId) {
    return _settings.remove('${SettingsKeys.decisionSnapshotPrefix}$taskId');
  }

  // ---- Training ----

  /// Trains on every outcome that has saved features and stores the weights.
  /// Below [coldStartOutcomes] it stores nothing and the rule is used.
  /// Returns how many outcomes it trained on, or 0.
  Future<int> retrain() async {
    final rows = await _trainingRows();
    if (rows.length < coldStartOutcomes) {
      await _settings.remove(SettingsKeys.predictorWeights);
      return 0;
    }

    final model = LogisticRegression.zeros(featureNames.length)
      ..fit([for (final r in rows) r.x], [for (final r in rows) r.y]);
    await _settings.set(
      SettingsKeys.predictorWeights,
      jsonEncode({
        'version': 1,
        'names': featureNames,
        'trainedOn': rows.length,
        'trainedAt': _now().toUtc().toIso8601String(),
        ...model.toJson(),
      }),
    );
    return rows.length;
  }

  Future<List<({List<double> x, int y})>> _trainingRows() async {
    final rows = <({List<double> x, int y})>[];
    for (final entry in await _outcomes.listHistory()) {
      final snapshot = _outcomes.snapshotOf(entry.outcome);
      if (snapshot.isEmpty) continue;
      rows.add((
        x: toVector(snapshot),
        y: entry.outcome.result == OutcomeResult.done ? 0 : 1,
      ));
    }
    return rows;
  }

  Future<({LogisticRegression model, int trainedOn})?> _storedModel() async {
    final raw = await _settings.get(SettingsKeys.predictorWeights);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final names = (json['names'] as List<dynamic>).cast<String>();
      // A model trained on other features cannot be used.
      if (names.length != featureNames.length) return null;
      for (var i = 0; i < names.length; i++) {
        if (names[i] != featureNames[i]) return null;
      }
      return (
        model: LogisticRegression.fromJson(json),
        trainedOn: json['trainedOn'] as int,
      );
    } catch (_) {
      return null;
    }
  }

  // ---- Scoring ----

  /// The dodge risk of [task] with a reason. With [save] the score is also
  /// stored on the task.
  Future<RiskAssessment> assess(Task task, {bool save = true}) async {
    final computed = await _compute(task);
    final stored = await _storedModel();

    final RiskAssessment result;
    if (stored != null && stored.trainedOn >= coldStartOutcomes) {
      final x = toVector(computed.features);
      result = RiskAssessment(
        risk: stored.model.predict(x),
        reason: explainModel(
          features: computed.features,
          weights: stored.model.weights,
          context: computed.context,
        ),
        source: RiskSource.model,
        outcomesUsed: stored.trainedOn,
      );
    } else {
      final rate = computed.context.categoryDodgeRate;
      result = RiskAssessment(
        risk: rate ?? 0.5,
        reason: explainRule(category: task.category, categoryDodgeRate: rate),
        source: RiskSource.rule,
        outcomesUsed: 0,
      );
    }

    if (save && task.dodgeRisk != result.risk) {
      await _tasks.setDodgeRisk(task.id, result.risk);
    }
    return result;
  }

  /// Just the number, for pacing nudges.
  Future<double> riskFor(Task task) async =>
      (await assess(task, save: false)).risk;
}
