import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../core/prompts/excuse_prompt.dart';
import '../core/prompts/help_prompt.dart';
import '../core/prompts/nudge_prompt.dart';
import '../core/prompts/prompt_job.dart';
import '../core/prompts/shrink_prompt.dart';
import '../core/utils/file_checksum.dart';
import '../data/models/benchmark_result.dart';
import '../data/models/gemma_model_option.dart';
import '../data/models/prompt_jobs.dart';
import '../data/models/settings_keys.dart';
import '../data/repositories/settings_repository.dart';
import 'model_runtime.dart';

/// Where the model file is in its life on this phone.
enum ModelInstallState {
  /// Looking at settings and the file.
  checking,
  notInstalled,
  downloading,

  /// Checking the downloaded file against its published checksum.
  verifying,
  installed,
  failed,
}

/// Owns the on-device model: download, load, release and prompt jobs.
///
/// This is the only code that touches the inference package.
class GemmaService extends GetxService with WidgetsBindingObserver {
  GemmaService({
    required this._runtime,
    required this._settings,
    Future<String> Function(String path)? checksumOf,
  }) : _checksumOf = checksumOf ?? sha256OfFile;

  final ModelRuntime _runtime;
  final SettingsRepository _settings;
  final Future<String> Function(String path) _checksumOf;

  final installState = ModelInstallState.checking.obs;

  /// Download progress, 0 to 100.
  final progress = 0.obs;
  final errorMessage = RxnString();

  /// The model that is installed and verified, when [installState] is installed.
  final installed = Rxn<GemmaModelOption>();

  /// A download that was started earlier and not finished, if any.
  final pendingDownload = Rxn<GemmaModelOption>();

  final isLoaded = false.obs;
  final isGenerating = false.obs;

  /// "gpu", "cpu" or "npu" once the model is loaded.
  final activeBackend = RxnString();

  /// True when the GPU could not load the model and the CPU was used.
  final fellBackToCpu = false.obs;

  LoadedModel? _model;
  LoadOptions? _loadedWith;
  Future<void>? _loading;
  bool _stopRequested = false;
  Future<void>? _started;

  /// Completes once the engine is set up and the install state is known.
  /// Starts on first use, so a background job can use the service without the
  /// app's lifecycle.
  Future<void> get started => _started ??= _start();

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    started;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  Future<void> _start() async {
    try {
      await _runtime.initialize();
      await refreshInstallState();
    } catch (e) {
      _fail('Could not start the model engine: $e');
    }
  }

  /// Frees the model's memory when the app leaves the foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      unawaited(release());
    }
  }

  /// Looks at settings and the file on disk to decide whether onboarding can
  /// be skipped.
  Future<void> refreshInstallState() async {
    installState.value = ModelInstallState.checking;
    errorMessage.value = null;

    final option = GemmaModelOption.byId(
      await _settings.get(SettingsKeys.modelId),
    );
    if (option != null && await _isValidInstall(option)) {
      installed.value = option;
      installState.value = ModelInstallState.installed;
      return;
    }

    installed.value = null;
    pendingDownload.value = GemmaModelOption.byId(
      await _settings.get(SettingsKeys.downloadingModelId),
    );
    installState.value = ModelInstallState.notInstalled;
  }

  Future<bool> _isValidInstall(GemmaModelOption option) async {
    if (await _settings.get(SettingsKeys.modelChecksum) != option.sha256) {
      return false;
    }
    if (await _settings.get(SettingsKeys.modelVersion) != option.version) {
      return false;
    }
    if (!await _runtime.isInstalled(option.fileName)) return false;
    return await _runtime.installedSize(option.fileName) == option.sizeBytes;
  }

  /// Downloads [option], verifies it and records it in settings. A download
  /// that was interrupted resumes where it stopped.
  Future<void> download(GemmaModelOption option) async {
    if (installState.value == ModelInstallState.downloading ||
        installState.value == ModelInstallState.verifying) {
      return;
    }
    errorMessage.value = null;
    progress.value = 0;
    installState.value = ModelInstallState.downloading;
    await _settings.set(SettingsKeys.downloadingModelId, option.id);

    try {
      await _runtime.install(
        option,
        onProgress: (percent) => progress.value = percent.clamp(0, 100),
      );

      installState.value = ModelInstallState.verifying;
      final path = await _runtime.modelPath(option.fileName);
      final checksum = await _checksumOf(path);
      if (checksum != option.sha256) {
        await _runtime.uninstall(option.fileName);
        await _settings.remove(SettingsKeys.downloadingModelId);
        _fail('The downloaded file is damaged. Please download it again.');
        return;
      }

      await _settings.set(SettingsKeys.modelId, option.id);
      await _settings.set(SettingsKeys.modelPath, path);
      await _settings.set(SettingsKeys.modelChecksum, checksum);
      await _settings.set(SettingsKeys.modelVersion, option.version);
      await _settings.remove(SettingsKeys.downloadingModelId);
      pendingDownload.value = null;
      installed.value = option;
      installState.value = ModelInstallState.installed;
    } on DownloadCancelled {
      await _settings.remove(SettingsKeys.downloadingModelId);
      pendingDownload.value = null;
      progress.value = 0;
      installState.value = ModelInstallState.notInstalled;
    } catch (e) {
      // The download id stays in settings so the next launch can resume it.
      pendingDownload.value = option;
      _fail('The download failed: $e');
    }
  }

  Future<void> cancelDownload() => _runtime.cancelInstall();

  void _fail(String message) {
    errorMessage.value = message;
    installState.value = ModelInstallState.failed;
  }

  /// Loads the model, GPU first with a CPU fallback. Does nothing when it is
  /// already loaded with the same [options].
  Future<void> load([LoadOptions options = const LoadOptions()]) {
    if (_model != null && _loadedWith == options) return Future.value();
    return _loading ??= _doLoad(options).whenComplete(() => _loading = null);
  }

  Future<void> _doLoad(LoadOptions options) async {
    await started;
    if (installState.value != ModelInstallState.installed) {
      throw StateError('The model is not installed yet.');
    }
    await release();

    fellBackToCpu.value = false;
    LoadedModel model;
    try {
      model = await _runtime.load(options);
    } catch (first) {
      if (options.backend == ModelBackend.cpu) {
        throw ModelLoadException('$first');
      }
      try {
        model = await _runtime.load(
          options.copyWith(backend: ModelBackend.cpu),
        );
        fellBackToCpu.value = true;
      } catch (second) {
        throw ModelLoadException('GPU: $first; CPU: $second');
      }
    }
    _model = model;
    _loadedWith = options;
    activeBackend.value = model.activeBackend;
    isLoaded.value = true;
  }

  /// Deletes the downloaded model and forgets it, so the app asks for it again
  /// at the next launch of onboarding.
  Future<void> deleteModel() async {
    await started;
    await release();
    final option = installed.value;
    if (option != null) {
      try {
        await _runtime.uninstall(option.fileName);
      } catch (_) {
        // The file may already be gone; the settings are cleared regardless.
      }
    }
    for (final key in [
      SettingsKeys.modelId,
      SettingsKeys.modelPath,
      SettingsKeys.modelChecksum,
      SettingsKeys.modelVersion,
      SettingsKeys.downloadingModelId,
    ]) {
      await _settings.remove(key);
    }
    installed.value = null;
    pendingDownload.value = null;
    progress.value = 0;
    errorMessage.value = null;
    installState.value = ModelInstallState.notInstalled;
  }

  /// Frees the model's memory. Safe to call when nothing is loaded.
  Future<void> release() async {
    final model = _model;
    if (model == null) return;
    _model = null;
    _loadedWith = null;
    isLoaded.value = false;
    isGenerating.value = false;
    activeBackend.value = null;
    await model.close();
  }

  /// Streams a reply, loading the model first if needed.
  Stream<String> generate(
    String prompt, {
    String? systemInstruction,
    int? maxOutputTokens,
    LoadOptions loadOptions = const LoadOptions(),
  }) async* {
    await load(loadOptions);
    final model = _model;
    if (model == null) throw StateError('The model is not loaded.');

    isGenerating.value = true;
    try {
      yield* model.generate(
        prompt,
        systemInstruction: systemInstruction,
        maxOutputTokens: maxOutputTokens,
      );
    } finally {
      isGenerating.value = false;
    }
  }

  /// Stops the reply that is being generated. A prompt job that is running
  /// ends with a stopped [JobFallback] and does not retry.
  Future<void> stop() async {
    _stopRequested = true;
    await _model?.stop();
  }

  // ---- Prompt jobs ----

  /// Splits a task into 3 to 7 tiny steps; the first takes under 2 minutes.
  Future<JobResult<ShrunkTask>> shrinkTask(
    ShrinkInput input, {
    void Function(String token)? onToken,
    void Function(int attempt)? onAttempt,
  }) {
    return runJob(
      shrinkJob(),
      shrinkUserPrompt(input),
      onToken: onToken,
      onAttempt: onAttempt,
    );
  }

  /// Drafts text (an email, message or outline) for one step.
  Future<JobResult<StepDraft>> helpWithStep(
    HelpInput input, {
    void Function(String token)? onToken,
    void Function(int attempt)? onAttempt,
  }) {
    return runJob(
      helpJob(),
      helpUserPrompt(input),
      onToken: onToken,
      onAttempt: onAttempt,
    );
  }

  /// Writes an excuse and a shorter variant, avoiding the last
  /// [maxExcuseHistory] excuses already used for the same person.
  Future<JobResult<ExcuseDraft>> writeExcuse(
    ExcuseInput input, {
    void Function(String token)? onToken,
    void Function(int attempt)? onAttempt,
  }) {
    return runJob(
      excuseJob(previousExcuses: input.previousExcuses),
      excuseUserPrompt(input),
      onToken: onToken,
      onAttempt: onAttempt,
    );
  }

  /// Writes the gentle, firm and last-call notification text for a step.
  Future<JobResult<NudgeWording>> nudgeWording(
    NudgeInput input, {
    void Function(String token)? onToken,
    void Function(int attempt)? onAttempt,
  }) {
    return runJob(
      nudgeJob(),
      nudgeUserPrompt(input),
      onToken: onToken,
      onAttempt: onAttempt,
    );
  }

  /// Runs [job]: streams the reply, parses it, and if it is unusable asks once
  /// more with a stricter instruction. Never throws for bad model output; the
  /// result is a [JobFallback] carrying the raw text instead.
  Future<JobResult<T>> runJob<T>(
    PromptJob<T> job,
    String userPrompt, {
    void Function(String token)? onToken,
    void Function(int attempt)? onAttempt,
    LoadOptions loadOptions = const LoadOptions(),
  }) async {
    _stopRequested = false;
    var instruction = job.systemInstruction;
    var raw = '';
    var reason = '';

    for (var attempt = 0; attempt < 2; attempt++) {
      onAttempt?.call(attempt);
      final buffer = StringBuffer();
      try {
        await for (final token in generate(
          userPrompt,
          systemInstruction: instruction,
          maxOutputTokens: job.maxOutputTokens,
          loadOptions: loadOptions,
        )) {
          buffer.write(token);
          onToken?.call(token);
        }
      } catch (e) {
        return JobFallback(
          reason: e is ModelLoadException
              ? ModelLoadException.message
              : 'The model could not answer: $e',
          rawText: buffer.toString(),
          retried: attempt > 0,
        );
      }
      raw = buffer.toString();

      if (_stopRequested) {
        return JobFallback(
          reason: 'Stopped.',
          rawText: raw,
          retried: attempt > 0,
          stopped: true,
        );
      }

      try {
        return JobSuccess(job.parse(raw), rawText: raw, retried: attempt > 0);
      } on JobFormatException catch (e) {
        reason = e.message;
        instruction = job.stricterInstruction(reason);
      } catch (e) {
        reason = 'the reply could not be read ($e)';
        instruction = job.stricterInstruction(reason);
      }
    }

    return JobFallback(
      reason: 'The reply was not usable: $reason.',
      rawText: raw,
      retried: true,
    );
  }

  /// Loads the model fresh with [options], runs [prompt] and times it.
  /// [onToken] receives each streamed chunk.
  Future<BenchmarkResult> benchmark(
    String prompt, {
    required LoadOptions options,
    required int maxOutputTokens,
    void Function(String token)? onToken,
  }) async {
    await release();

    final loadWatch = Stopwatch()..start();
    await load(options);
    loadWatch.stop();

    final watch = Stopwatch()..start();
    Duration? firstToken;
    var tokens = 0;
    await for (final token in generate(
      prompt,
      maxOutputTokens: maxOutputTokens,
      loadOptions: options,
    )) {
      firstToken ??= watch.elapsed;
      tokens++;
      onToken?.call(token);
    }
    watch.stop();

    final first = firstToken ?? watch.elapsed;
    return BenchmarkResult(
      backendRequested: options.backend == ModelBackend.cpu ? 'cpu' : 'gpu',
      backendActive: activeBackend.value ?? 'unknown',
      speculativeDecoding: options.speculativeDecoding,
      maxOutputTokens: maxOutputTokens,
      loadTime: loadWatch.elapsed,
      timeToFirstToken: first,
      generationTime: watch.elapsed - first,
      tokens: tokens,
      fellBackToCpu: fellBackToCpu.value,
    );
  }
}
