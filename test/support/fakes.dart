import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:do_it_or_dodge_it/app/data/db/app_database.dart';
import 'package:do_it_or_dodge_it/app/data/models/gemma_model_option.dart';
import 'package:do_it_or_dodge_it/app/data/models/settings_keys.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/settings_repository.dart';
import 'package:do_it_or_dodge_it/app/services/device_info_service.dart';
import 'package:do_it_or_dodge_it/app/services/model_runtime.dart';

const gib = 1024 * 1024 * 1024;

class FakeDeviceInfoSource implements DeviceInfoSource {
  FakeDeviceInfoSource({
    this.totalRamBytes = 6 * gib,
    this.freeStorageBytes = 20 * gib,
    this.hasNetwork = true,
    this.onUnmeteredNetwork = true,
  });

  int totalRamBytes;
  int freeStorageBytes;
  bool hasNetwork;
  bool onUnmeteredNetwork;

  @override
  Future<DeviceInfo> read() async => DeviceInfo(
    totalRamBytes: totalRamBytes,
    freeStorageBytes: freeStorageBytes,
    hasNetwork: hasNetwork,
    onUnmeteredNetwork: onUnmeteredNetwork,
  );
}

class FakeLoadedModel implements LoadedModel {
  FakeLoadedModel(this.activeBackend, {this.tokens = const ['a', 'b', 'c']});

  @override
  final String activeBackend;
  final List<String> tokens;
  bool closed = false;
  bool stopped = false;
  String? lastPrompt;
  String? lastSystemInstruction;
  int? lastMaxOutputTokens;

  /// When set, [generate] waits for it before emitting tokens.
  Completer<void>? gate;

  @override
  Stream<String> generate(
    String prompt, {
    String? systemInstruction,
    int? maxOutputTokens,
  }) async* {
    lastPrompt = prompt;
    lastSystemInstruction = systemInstruction;
    lastMaxOutputTokens = maxOutputTokens;
    await gate?.future;
    for (final token in tokens) {
      if (stopped) return;
      yield token;
    }
  }

  @override
  Future<void> stop() async => stopped = true;

  @override
  Future<void> close() async => closed = true;
}

class FakeModelRuntime implements ModelRuntime {
  /// File name to size in bytes, for files that are "installed".
  final Map<String, int> files = {};

  bool initialized = false;
  int installCalls = 0;
  int cancelCalls = 0;
  final List<String> uninstalled = [];
  final List<LoadOptions> loadCalls = [];
  final List<FakeLoadedModel> models = [];

  /// Backends that fail to load.
  final Set<ModelBackend> failingBackends = {};

  /// Makes [install] throw this.
  Object? installError;

  /// Makes [install] wait for this before it finishes.
  Completer<void>? installGate;

  List<int> progressSteps = const [10, 50, 100];

  @override
  Future<void> initialize() async => initialized = true;

  @override
  Future<bool> isInstalled(String fileName) async =>
      files.containsKey(fileName);

  @override
  Future<int?> installedSize(String fileName) async => files[fileName];

  @override
  Future<String> modelPath(String fileName) async => '/models/$fileName';

  @override
  Future<void> install(
    GemmaModelOption option, {
    required void Function(int percent) onProgress,
  }) async {
    installCalls++;
    for (final step in progressSteps) {
      onProgress(step);
    }
    await installGate?.future;
    final error = installError;
    if (error != null) throw error;
    files[option.fileName] = option.sizeBytes;
  }

  @override
  Future<void> cancelInstall() async {
    cancelCalls++;
    installError = const DownloadCancelled();
    installGate?.complete();
  }

  @override
  Future<LoadedModel> load(LoadOptions options) async {
    loadCalls.add(options);
    if (failingBackends.contains(options.backend)) {
      throw StateError('${options.backend.name} failed to load');
    }
    final model = FakeLoadedModel(
      options.backend == ModelBackend.cpu ? 'cpu' : 'gpu',
    );
    models.add(model);
    return model;
  }

  @override
  Future<void> uninstall(String fileName) async {
    uninstalled.add(fileName);
    files.remove(fileName);
  }
}

/// Makes [option] look installed and verified, as after a finished download.
Future<void> installModelFixture(
  AppDatabase db,
  FakeModelRuntime runtime, {
  GemmaModelOption option = GemmaModelOption.gemma4E2B,
}) async {
  runtime.files[option.fileName] = option.sizeBytes;
  final settings = SettingsRepository(db);
  await settings.set(SettingsKeys.modelId, option.id);
  await settings.set(SettingsKeys.modelChecksum, option.sha256);
  await settings.set(SettingsKeys.modelVersion, option.version);
}

/// Lets real async work (database, fake runtime) and route transitions finish.
/// Call inside `tester.runAsync`.
Future<void> settle(WidgetTester tester, {int rounds = 5}) async {
  for (var i = 0; i < rounds; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await tester.pump(const Duration(milliseconds: 300));
  }
}
