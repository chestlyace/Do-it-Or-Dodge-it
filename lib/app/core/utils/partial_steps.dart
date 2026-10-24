import 'dart:convert';
import 'dart:math' as math;

import '../../data/models/prompt_jobs.dart';

final _step = RegExp(
  r'\{\s*"title"\s*:\s*"((?:[^"\\]|\\.)*)"\s*,\s*"estMinutes"\s*:\s*'
  r'([0-9]+(?:\.[0-9]+)?)\s*\}',
);

/// Steps that are complete so far in a reply that is still streaming, so the
/// screen can show them one by one. The final result still comes from the
/// validated parser.
List<TinyStep> parsePartialSteps(String raw) {
  final steps = <TinyStep>[];
  for (final match in _step.allMatches(raw)) {
    final String title;
    try {
      title = jsonDecode('"${match.group(1)}"') as String;
    } on FormatException {
      continue;
    }
    final minutes = double.parse(match.group(2)!);
    steps.add(TinyStep(title: title, estMinutes: math.max(minutes.ceil(), 1)));
  }
  return steps;
}
