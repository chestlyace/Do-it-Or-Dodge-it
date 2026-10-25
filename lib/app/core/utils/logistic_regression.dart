import 'dart:math' as math;

/// Logistic regression trained with batch gradient descent, in plain Dart.
///
/// Small, deterministic and fast: a few hundred rows train in milliseconds on
/// the phone. Features are expected to be roughly in [-1, 1].
class LogisticRegression {
  LogisticRegression({required this.weights, required this.bias});

  /// A model that has learned nothing: every row scores 0.5.
  factory LogisticRegression.zeros(int features) =>
      LogisticRegression(weights: List.filled(features, 0), bias: 0);

  factory LogisticRegression.fromJson(Map<String, dynamic> json) {
    return LogisticRegression(
      weights: [
        for (final w in json['weights'] as List<dynamic>) (w as num).toDouble(),
      ],
      bias: (json['bias'] as num).toDouble(),
    );
  }

  final List<double> weights;
  double bias;

  Map<String, dynamic> toJson() => {'weights': weights, 'bias': bias};

  /// Probability of label 1 for [x].
  double predict(List<double> x) {
    assert(x.length == weights.length);
    var z = bias;
    for (var i = 0; i < weights.length; i++) {
      z += weights[i] * x[i];
    }
    return _sigmoid(z);
  }

  /// Fits the model to rows [x] with labels [y] (0 or 1).
  ///
  /// [l2] pulls weights towards zero so a small history cannot produce wild
  /// scores. The bias is not penalised.
  void fit(
    List<List<double>> x,
    List<int> y, {
    double learningRate = 0.5,
    int epochs = 400,
    double l2 = 0.01,
  }) {
    assert(x.length == y.length);
    if (x.isEmpty) return;
    final n = x.length;
    final d = weights.length;

    for (var epoch = 0; epoch < epochs; epoch++) {
      final gradient = List<double>.filled(d, 0);
      var gradientBias = 0.0;
      for (var row = 0; row < n; row++) {
        final error = predict(x[row]) - y[row];
        for (var i = 0; i < d; i++) {
          gradient[i] += error * x[row][i];
        }
        gradientBias += error;
      }
      for (var i = 0; i < d; i++) {
        weights[i] -= learningRate * (gradient[i] / n + l2 * weights[i]);
      }
      bias -= learningRate * gradientBias / n;
    }
  }

  static double _sigmoid(double z) {
    if (z >= 0) return 1 / (1 + math.exp(-z));
    final e = math.exp(z);
    return e / (1 + e);
  }
}
