import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:do_it_or_dodge_it/app/data/db/app_database.dart';
import 'package:do_it_or_dodge_it/app/data/models/gemma_model_option.dart';
import 'package:do_it_or_dodge_it/app/data/models/settings_keys.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/settings_repository.dart';
import 'package:do_it_or_dodge_it/app/services/device_info_service.dart';
import 'package:do_it_or_dodge_it/app/services/background_service.dart';
import 'package:do_it_or_dodge_it/app/services/model_runtime.dart';
import 'package:do_it_or_dodge_it/app/services/notification_gateway.dart';
import 'package:do_it_or_dodge_it/app/services/share_service.dart';

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

class ModelCall {
  const ModelCall(this.prompt, this.systemInstruction, this.maxOutputTokens);

  final String prompt;
  final String? systemInstruction;
  final int? maxOutputTokens;
}

class FakeLoadedModel implements LoadedModel {
  FakeLoadedModel(
    this.activeBackend, {
    this.tokens = const ['a', 'b', 'c'],
    this.responder,
    this.failWith,
  });

  /// When set, the reply is whatever this returns, streamed in small chunks.
  final String Function(ModelCall call)? responder;

  /// Makes [generate] throw this before streaming anything.
  final Object? failWith;

  /// Every generate call, in order.
  final List<ModelCall> calls = [];

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
    final call = ModelCall(prompt, systemInstruction, maxOutputTokens);
    calls.add(call);
    await gate?.future;
    final failure = failWith;
    if (failure != null) throw failure;
    final reply = responder?.call(call);
    final chunks = reply == null
        ? tokens
        : [
            for (var i = 0; i < reply.length; i += 12)
              reply.substring(i, i + 12 > reply.length ? reply.length : i + 12),
          ];
    for (final token in chunks) {
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

  /// Scripts the model's replies for every model this runtime loads.
  String Function(ModelCall call)? responder;

  /// Makes every generate call throw this.
  Object? generateError;

  /// Every generate call across all loaded models, in order.
  List<ModelCall> get calls => [for (final m in models) ...m.calls];

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
      responder: responder,
      failWith: generateError,
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

/// Records copies and shares instead of touching the platform.
class FakeShareService extends ShareService {
  final List<String> copied = [];
  final List<String> shared = [];

  /// What the share sheet "returns": false means the user dismissed it.
  bool shareResult = true;

  @override
  Future<void> copy(String text) async => copied.add(text);

  @override
  Future<bool> share(String text) async {
    shared.add(text);
    return shareResult;
  }
}

/// Runs [body] in real async (needed for database streams) and unmounts the
/// app afterwards, so drift's cleanup timers run outside the fake-async zone.
Future<void> runWithApp(
  WidgetTester tester,
  Future<void> Function() body,
) async {
  await tester.runAsync(() async {
    try {
      await body();
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  });
}

class ScheduledNotification {
  const ScheduledNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.at,
    required this.payload,
  });

  final int id;
  final String title;
  final String body;
  final DateTime at;
  final String? payload;
}

/// Records notifications instead of talking to Android.
class FakeNotificationGateway implements NotificationGateway {
  bool enabled = true;

  /// What the permission dialog answers.
  bool grantOnRequest = true;
  int permissionRequests = 0;
  int initializeCalls = 0;
  Object? initializeError;
  String? launch;
  void Function(String? payload)? onTap;

  final Map<int, ScheduledNotification> scheduled = {};
  final List<int> cancelled = [];

  List<ScheduledNotification> get inOrder =>
      scheduled.values.toList()..sort((a, b) => a.at.compareTo(b.at));

  @override
  Future<void> initialize({void Function(String? payload)? onTap}) async {
    initializeCalls++;
    final error = initializeError;
    if (error != null) throw error;
    this.onTap = onTap;
  }

  @override
  Future<String?> launchPayload() async => launch;

  @override
  Future<bool> areEnabled() async => enabled;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    enabled = grantOnRequest;
    return grantOnRequest;
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    String? payload,
  }) async {
    scheduled[id] = ScheduledNotification(
      id: id,
      title: title,
      body: body,
      at: at,
      payload: payload,
    );
  }

  @override
  Future<void> cancel(int id) async {
    scheduled.remove(id);
    cancelled.add(id);
  }

  @override
  Future<List<int>> pendingIds() async => scheduled.keys.toList();
}

class FakeBackgroundScheduler implements BackgroundScheduler {
  int registerCalls = 0;
  Object? error;

  @override
  Future<void> registerDailyJob() async {
    registerCalls++;
    final e = error;
    if (e != null) throw e;
  }
}
