import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:do_it_or_dodge_it/app/core/utils/logistic_regression.dart';

void main() {
  test('an untrained model scores everything 0.5', () {
    final model = LogisticRegression.zeros(3);
    expect(model.predict([1, 0, -1]), 0.5);
  });

  test('learns a rule where one feature decides the label', () {
    final x = <List<double>>[];
    final y = <int>[];
    for (var i = 0; i < 40; i++) {
      final flag = i.isEven ? 1.0 : 0.0;
      x.add([flag, 0.3]);
      y.add(flag == 1 ? 1 : 0);
    }
    final model = LogisticRegression.zeros(2)..fit(x, y);

    expect(model.predict([1, 0.3]), greaterThan(0.8));
    expect(model.predict([0, 0.3]), lessThan(0.2));
    expect(model.weights[0], greaterThan(0));
  });

  test('is deterministic', () {
    final x = [
      [1.0, 0.0],
      [0.0, 1.0],
      [1.0, 1.0],
      [0.0, 0.0],
    ];
    final y = [1, 0, 1, 0];
    final a = LogisticRegression.zeros(2)..fit(x, y);
    final b = LogisticRegression.zeros(2)..fit(x, y);
    expect(a.weights, b.weights);
    expect(a.bias, b.bias);
  });

  test('fits the base rate with no informative feature', () {
    final x = List.generate(50, (_) => [0.0]);
    final y = List.generate(50, (i) => i < 40 ? 1 : 0); // 80% ones
    final model = LogisticRegression.zeros(1)..fit(x, y);
    expect(model.predict([0]), closeTo(0.8, 0.03));
  });

  test('regularisation keeps weights small on a tiny history', () {
    final x = [
      [1.0],
      [0.0],
    ];
    final y = [1, 0];
    final loose = LogisticRegression.zeros(1)..fit(x, y, l2: 0);
    final tight = LogisticRegression.zeros(1)..fit(x, y, l2: 0.5);
    expect(tight.weights[0].abs(), lessThan(loose.weights[0].abs()));
  });

  test('stays finite at extreme inputs', () {
    final model = LogisticRegression(weights: [1000], bias: 0);
    expect(model.predict([1000]), 1.0);
    expect(model.predict([-1000]), 0.0);
    expect(model.predict([1000]).isNaN, isFalse);
  });

  test('training on nothing changes nothing', () {
    final model = LogisticRegression.zeros(2)..fit([], []);
    expect(model.weights, [0, 0]);
    expect(model.bias, 0);
  });

  test('survives a round trip through JSON', () {
    final rng = Random(3);
    final x = [
      for (var i = 0; i < 30; i++) [rng.nextDouble(), rng.nextDouble()],
    ];
    final y = [for (final row in x) row[0] > 0.5 ? 1 : 0];
    final model = LogisticRegression.zeros(2)..fit(x, y);

    final copy = LogisticRegression.fromJson(model.toJson());

    expect(copy.weights, model.weights);
    expect(copy.bias, model.bias);
    expect(copy.predict([0.9, 0.1]), model.predict([0.9, 0.1]));
  });
}
