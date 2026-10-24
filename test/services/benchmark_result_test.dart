import 'package:flutter_test/flutter_test.dart';
import 'package:do_it_or_dodge_it/app/data/models/benchmark_result.dart';

BenchmarkResult result({
  int tokens = 11,
  Duration generation = const Duration(seconds: 2),
}) {
  return BenchmarkResult(
    backendRequested: 'gpu',
    backendActive: 'gpu',
    speculativeDecoding: false,
    maxOutputTokens: 128,
    loadTime: const Duration(milliseconds: 1500),
    timeToFirstToken: const Duration(milliseconds: 400),
    generationTime: generation,
    tokens: tokens,
    fellBackToCpu: false,
  );
}

void main() {
  test('tokens per second counts tokens after the first', () {
    expect(result().tokensPerSecond, 5.0);
  });

  test('tokens per second is 0 when there is nothing to measure', () {
    expect(result(tokens: 1).tokensPerSecond, 0);
    expect(result(generation: Duration.zero).tokensPerSecond, 0);
  });

  test('text lists the numbers to record', () {
    final text = result().toText();
    expect(text, contains('backend active: gpu'));
    expect(text, contains('load time: 1500 ms'));
    expect(text, contains('time to first token: 400 ms'));
    expect(text, contains('tokens per second: 5.0'));
  });
}
