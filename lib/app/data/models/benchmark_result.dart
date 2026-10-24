/// One benchmark run on the phone.
class BenchmarkResult {
  const BenchmarkResult({
    required this.backendRequested,
    required this.backendActive,
    required this.speculativeDecoding,
    required this.maxOutputTokens,
    required this.loadTime,
    required this.timeToFirstToken,
    required this.generationTime,
    required this.tokens,
    required this.fellBackToCpu,
  });

  final String backendRequested;
  final String backendActive;
  final bool speculativeDecoding;
  final int maxOutputTokens;
  final Duration loadTime;

  /// From sending the prompt to the first streamed token.
  final Duration timeToFirstToken;

  /// From the first streamed token to the last.
  final Duration generationTime;

  /// Streamed chunks; close to the token count.
  final int tokens;
  final bool fellBackToCpu;

  /// Decode speed after the first token; 0 when too little was generated.
  double get tokensPerSecond {
    final seconds =
        generationTime.inMicroseconds / Duration.microsecondsPerSecond;
    if (tokens < 2 || seconds <= 0) return 0;
    return (tokens - 1) / seconds;
  }

  String toText() {
    return [
      'backend requested: $backendRequested',
      'backend active: $backendActive${fellBackToCpu ? ' (fell back to CPU)' : ''}',
      'speculative decoding: ${speculativeDecoding ? 'on' : 'off'}',
      'max output tokens: $maxOutputTokens',
      'load time: ${loadTime.inMilliseconds} ms',
      'time to first token: ${timeToFirstToken.inMilliseconds} ms',
      'tokens: $tokens',
      'tokens per second: ${tokensPerSecond.toStringAsFixed(1)}',
    ].join('\n');
  }
}
