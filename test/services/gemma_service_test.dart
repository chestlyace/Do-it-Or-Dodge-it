import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:do_it_or_dodge_it/app/data/db/app_database.dart';
import 'package:do_it_or_dodge_it/app/data/models/gemma_model_option.dart';
import 'package:do_it_or_dodge_it/app/data/models/settings_keys.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/settings_repository.dart';
import 'package:do_it_or_dodge_it/app/services/gemma_service.dart';
import 'package:do_it_or_dodge_it/app/services/model_runtime.dart';

import '../data/test_database.dart';
import '../support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final e2b = GemmaModelOption.gemma4E2B;

  late AppDatabase db;
  late SettingsRepository settings;
  late FakeModelRuntime runtime;
  late GemmaService service;

  Future<void> markInstalled() async {
    runtime.files[e2b.fileName] = e2b.sizeBytes;
    await settings.set(SettingsKeys.modelId, e2b.id);
    await settings.set(SettingsKeys.modelChecksum, e2b.sha256);
    await settings.set(SettingsKeys.modelVersion, e2b.version);
  }

  GemmaService create({String? checksum}) {
    final s = GemmaService(
      runtime: runtime,
      settings: settings,
      checksumOf: (_) async => checksum ?? e2b.sha256,
    );
    Get.put(s);
    return s;
  }

  setUp(() {
    db = createTestDatabase();
    settings = SettingsRepository(db);
    runtime = FakeModelRuntime();
  });

  tearDown(() async {
    Get.reset();
    await db.close();
  });

  group('install state', () {
    test('is notInstalled on a fresh install', () async {
      service = create();
      await service.started;

      expect(runtime.initialized, isTrue);
      expect(service.installState.value, ModelInstallState.notInstalled);
      expect(service.pendingDownload.value, isNull);
    });

    test('is installed when settings and the file agree', () async {
      await markInstalled();
      service = create();
      await service.started;

      expect(service.installState.value, ModelInstallState.installed);
      expect(service.installed.value, e2b);
    });

    test('is notInstalled when the file has the wrong size', () async {
      await markInstalled();
      runtime.files[e2b.fileName] = e2b.sizeBytes - 1;
      service = create();
      await service.started;

      expect(service.installState.value, ModelInstallState.notInstalled);
    });

    test('is notInstalled when the file is gone', () async {
      await markInstalled();
      runtime.files.clear();
      service = create();
      await service.started;

      expect(service.installState.value, ModelInstallState.notInstalled);
    });

    test('is notInstalled when the stored checksum differs', () async {
      await markInstalled();
      await settings.set(SettingsKeys.modelChecksum, 'other');
      service = create();
      await service.started;

      expect(service.installState.value, ModelInstallState.notInstalled);
    });
  });

  group('download', () {
    test('installs, verifies and records the model in settings', () async {
      service = create();
      await service.started;

      final seen = <int>[];
      service.progress.listen(seen.add);
      await service.download(e2b);

      expect(runtime.installCalls, 1);
      expect(seen, containsAllInOrder([10, 50, 100]));
      expect(service.installState.value, ModelInstallState.installed);
      expect(service.installed.value, e2b);
      expect(await settings.get(SettingsKeys.modelId), e2b.id);
      expect(
        await settings.get(SettingsKeys.modelPath),
        '/models/${e2b.fileName}',
      );
      expect(await settings.get(SettingsKeys.modelChecksum), e2b.sha256);
      expect(await settings.get(SettingsKeys.modelVersion), e2b.version);
      expect(await settings.get(SettingsKeys.downloadingModelId), isNull);
    });

    test('a second launch finds the model and skips onboarding', () async {
      service = create();
      await service.started;
      await service.download(e2b);
      Get.reset();

      final second = create();
      await second.started;
      expect(second.installState.value, ModelInstallState.installed);
      expect(runtime.installCalls, 1);
    });

    test('a damaged file is removed and reported', () async {
      service = create(checksum: 'wrong');
      await service.started;

      await service.download(e2b);

      expect(service.installState.value, ModelInstallState.failed);
      expect(service.errorMessage.value, contains('damaged'));
      expect(runtime.uninstalled, [e2b.fileName]);
      expect(await settings.get(SettingsKeys.modelId), isNull);
    });

    test('a failed download can be resumed on the next launch', () async {
      runtime.installError = Exception('connection lost');
      service = create();
      await service.started;

      await service.download(e2b);
      expect(service.installState.value, ModelInstallState.failed);
      expect(await settings.get(SettingsKeys.downloadingModelId), e2b.id);

      // App restarts: the interrupted download is offered again.
      Get.reset();
      final relaunched = create();
      await relaunched.started;
      expect(relaunched.installState.value, ModelInstallState.notInstalled);
      expect(relaunched.pendingDownload.value, e2b);

      runtime.installError = null;
      await relaunched.download(e2b);
      expect(relaunched.installState.value, ModelInstallState.installed);
      expect(runtime.installCalls, 2);
    });

    test(
      'cancelling returns to notInstalled and forgets the download',
      () async {
        runtime.installGate = Completer<void>();
        service = create();
        await service.started;

        final download = service.download(e2b);
        await Future<void>.delayed(Duration.zero);
        expect(service.installState.value, ModelInstallState.downloading);

        await service.cancelDownload();
        await download;

        expect(runtime.cancelCalls, 1);
        expect(service.installState.value, ModelInstallState.notInstalled);
        expect(await settings.get(SettingsKeys.downloadingModelId), isNull);
      },
    );

    test('ignores a second download while one is running', () async {
      runtime.installGate = Completer<void>();
      service = create();
      await service.started;

      final first = service.download(e2b);
      await Future<void>.delayed(Duration.zero);
      await service.download(e2b);
      runtime.installGate!.complete();
      await first;

      expect(runtime.installCalls, 1);
    });
  });

  group('loading', () {
    setUp(() async {
      await markInstalled();
      service = create();
      await service.started;
    });

    test('loads on the GPU first', () async {
      await service.load();

      expect(service.isLoaded.value, isTrue);
      expect(service.activeBackend.value, 'gpu');
      expect(service.fellBackToCpu.value, isFalse);
      expect(runtime.loadCalls.single.backend, ModelBackend.auto);
    });

    test('falls back to the CPU when the GPU fails', () async {
      runtime.failingBackends.add(ModelBackend.auto);
      await service.load();

      expect(service.activeBackend.value, 'cpu');
      expect(service.fellBackToCpu.value, isTrue);
      expect(runtime.loadCalls.map((o) => o.backend), [
        ModelBackend.auto,
        ModelBackend.cpu,
      ]);
    });

    test('can be forced onto the CPU', () async {
      await service.load(const LoadOptions(backend: ModelBackend.cpu));

      expect(service.activeBackend.value, 'cpu');
      expect(service.fellBackToCpu.value, isFalse);
      expect(runtime.loadCalls.single.backend, ModelBackend.cpu);
    });

    test('throws when the CPU fails too', () async {
      runtime.failingBackends.addAll(ModelBackend.values);
      await expectLater(service.load(), throwsStateError);
      expect(service.isLoaded.value, isFalse);
    });

    test('loading again with the same options does not reload', () async {
      await service.load();
      await service.load();
      expect(runtime.loadCalls, hasLength(1));
    });

    test('loading with other options releases the old model first', () async {
      await service.load();
      await service.load(const LoadOptions(backend: ModelBackend.cpu));

      expect(runtime.models.first.closed, isTrue);
      expect(runtime.loadCalls, hasLength(2));
    });

    test('release frees the model and is safe to repeat', () async {
      await service.load();
      await service.release();
      await service.release();

      expect(service.isLoaded.value, isFalse);
      expect(service.activeBackend.value, isNull);
      expect(runtime.models.single.closed, isTrue);
    });

    test('the model is released when the app goes to the background', () async {
      await service.load();

      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.delayed(Duration.zero);

      expect(service.isLoaded.value, isFalse);
      expect(runtime.models.single.closed, isTrue);
    });

    test('and loads again on demand afterwards', () async {
      await service.load();
      await service.release();
      await service.load();

      expect(runtime.loadCalls, hasLength(2));
      expect(service.isLoaded.value, isTrue);
    });

    test('cannot load before the model is installed', () async {
      runtime.files.clear();
      await service.refreshInstallState();

      await expectLater(service.load(), throwsStateError);
    });
  });

  group('generating', () {
    setUp(() async {
      await markInstalled();
      service = create();
      await service.started;
    });

    test('loads the model and streams the reply', () async {
      final tokens = await service
          .generate('hi', systemInstruction: 'be brief', maxOutputTokens: 32)
          .toList();

      expect(tokens, ['a', 'b', 'c']);
      final model = runtime.models.single;
      expect(model.lastPrompt, 'hi');
      expect(model.lastSystemInstruction, 'be brief');
      expect(model.lastMaxOutputTokens, 32);
      expect(service.isGenerating.value, isFalse);
    });

    test('stop ends the reply early', () async {
      await service.load();
      final model = runtime.models.single..gate = Completer<void>();

      final received = <String>[];
      final done = service.generate('hi').forEach(received.add);
      await Future<void>.delayed(Duration.zero);
      expect(service.isGenerating.value, isTrue);

      await service.stop();
      model.gate!.complete();
      await done;

      expect(model.stopped, isTrue);
      expect(received, isEmpty);
      expect(service.isGenerating.value, isFalse);
    });
  });

  group('benchmark', () {
    setUp(() async {
      await markInstalled();
      service = create();
      await service.started;
    });

    test('reports the backend, token count and timings', () async {
      final streamed = <String>[];
      final result = await service.benchmark(
        'prompt',
        options: const LoadOptions(),
        maxOutputTokens: 64,
        onToken: streamed.add,
      );

      expect(streamed, ['a', 'b', 'c']);
      expect(result.tokens, 3);
      expect(result.backendActive, 'gpu');
      expect(result.backendRequested, 'gpu');
      expect(result.maxOutputTokens, 64);
      expect(result.fellBackToCpu, isFalse);
      expect(runtime.models.single.lastMaxOutputTokens, 64);
    });

    test('reloads the model so load time is measured every run', () async {
      await service.benchmark(
        'p',
        options: const LoadOptions(),
        maxOutputTokens: 8,
      );
      await service.benchmark(
        'p',
        options: const LoadOptions(backend: ModelBackend.cpu),
        maxOutputTokens: 8,
      );

      expect(runtime.loadCalls, hasLength(2));
      expect(runtime.models.first.closed, isTrue);
    });

    test('records a CPU fallback', () async {
      runtime.failingBackends.add(ModelBackend.auto);
      final result = await service.benchmark(
        'p',
        options: const LoadOptions(),
        maxOutputTokens: 8,
      );

      expect(result.fellBackToCpu, isTrue);
      expect(result.backendActive, 'cpu');
    });
  });
}
