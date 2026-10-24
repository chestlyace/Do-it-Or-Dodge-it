import '../data/models/gemma_model_option.dart';

/// The model backend the app asked for.
enum ModelBackend {
  /// GPU first, CPU if the GPU cannot load the model.
  auto,

  /// CPU only.
  cpu,
}

/// Settings for loading the model.
class LoadOptions {
  const LoadOptions({
    this.backend = ModelBackend.auto,
    this.speculativeDecoding = false,
    this.maxTokens = 2048,
  });

  final ModelBackend backend;
  final bool speculativeDecoding;

  /// Context window (prompt, history and reply together), not the reply cap.
  final int maxTokens;

  LoadOptions copyWith({ModelBackend? backend}) => LoadOptions(
    backend: backend ?? this.backend,
    speculativeDecoding: speculativeDecoding,
    maxTokens: maxTokens,
  );
}

/// A model that is loaded in memory.
abstract class LoadedModel {
  /// "gpu", "cpu" or "npu": what actually loaded, or "unknown".
  String get activeBackend;

  /// Streams the reply token by token.
  Stream<String> generate(
    String prompt, {
    String? systemInstruction,
    int? maxOutputTokens,
  });

  /// Stops the reply that is being generated, if any.
  Future<void> stop();

  Future<void> close();
}

/// Everything the app needs from the on-device inference package.
///
/// `GemmaService` is the only code that holds one of these.
abstract class ModelRuntime {
  /// Called once at startup, before any other method.
  Future<void> initialize();

  Future<bool> isInstalled(String fileName);

  /// Size in bytes of the installed file, or null when it is missing.
  Future<int?> installedSize(String fileName);

  Future<String> modelPath(String fileName);

  /// Downloads and installs [option]. Resumes a download that was interrupted.
  /// Throws [DownloadCancelled] when [cancelInstall] was called.
  Future<void> install(
    GemmaModelOption option, {
    required void Function(int percent) onProgress,
  });

  Future<void> cancelInstall();

  Future<LoadedModel> load(LoadOptions options);

  Future<void> uninstall(String fileName);
}

/// Thrown by [ModelRuntime.install] when the download was cancelled.
class DownloadCancelled implements Exception {
  const DownloadCancelled();

  @override
  String toString() => 'The download was cancelled.';
}
