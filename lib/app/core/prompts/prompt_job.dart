import 'dart:convert';

/// Thrown by a job's parser when the model's reply is not usable.
class JobFormatException implements Exception {
  const JobFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Everything needed to run one prompt job against the model.
class PromptJob<T> {
  const PromptJob({
    required this.name,
    required this.systemInstruction,
    required this.maxOutputTokens,
    required this.parse,
  });

  final String name;
  final String systemInstruction;

  /// Cap on the reply length (the model's context window is separate).
  final int maxOutputTokens;

  /// Turns the model's raw reply into [T], or throws [JobFormatException].
  final T Function(String raw) parse;

  /// The system instruction for the one retry, with the reason it is needed.
  String stricterInstruction(String reason) {
    return '$systemInstruction\n\n'
        'IMPORTANT: Your previous reply could not be used ($reason). '
        'Reply with ONLY the JSON object: no markdown fences, no text before '
        'or after it, and exactly the keys described above.';
  }
}

/// Finds the JSON object in a model reply. Tolerates markdown fences and
/// text around the object.
Map<String, dynamic> extractJsonObject(String raw) {
  var text = raw.trim();
  final fenced = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(text);
  if (fenced != null) text = fenced.group(1)!.trim();

  final start = text.indexOf('{');
  final end = text.lastIndexOf('}');
  if (start < 0 || end <= start) {
    throw const JobFormatException('the reply has no JSON object');
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(text.substring(start, end + 1));
  } on FormatException {
    throw const JobFormatException('the reply is not valid JSON');
  }
  if (decoded is! Map<String, dynamic>) {
    throw const JobFormatException('the JSON is not an object');
  }
  return decoded;
}

/// A non-empty string field, trimmed, or a [JobFormatException].
String requireString(Map<String, dynamic> json, String key, {int? maxLength}) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw JobFormatException('"$key" is missing or empty');
  }
  final trimmed = value.trim();
  if (maxLength != null && trimmed.length > maxLength) {
    throw JobFormatException('"$key" is longer than $maxLength characters');
  }
  return trimmed;
}
