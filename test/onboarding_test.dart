import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:do_it_or_dodge_it/app/data/db/app_database.dart';
import 'package:do_it_or_dodge_it/app/data/models/gemma_model_option.dart';
import 'package:do_it_or_dodge_it/app/data/models/settings_keys.dart';
import 'package:do_it_or_dodge_it/app/data/repositories/settings_repository.dart';
import 'package:do_it_or_dodge_it/main.dart';

import 'data/test_database.dart';
import 'support/fakes.dart';

void main() {
  late AppDatabase db;
  late FakeModelRuntime runtime;
  late FakeDeviceInfoSource device;

  setUp(() {
    db = createTestDatabase();
    runtime = FakeModelRuntime();
    device = FakeDeviceInfoSource();
  });

  tearDown(() async {
    Get.reset();
    await db.close();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      DoItOrDodgeItApp(
        database: db,
        modelRuntime: runtime,
        deviceInfo: device,
        notifications: FakeNotificationGateway(),
        backgroundScheduler: FakeBackgroundScheduler(),
        checksumOf: (_) async => GemmaModelOption.gemma4E2B.sha256,
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }

  Finder downloadButton(String label) =>
      find.widgetWithText(FilledButton, 'Download $label');

  testWidgets('goes straight to Home when the model is installed', (
    tester,
  ) async {
    await runWithApp(tester, () async {
      await installModelFixture(db, runtime);
      await pumpApp(tester);
      await settle(tester);

      expect(find.textContaining('No tasks yet'), findsOneWidget);
      expect(find.text('Set up'), findsNothing);
      expect(runtime.installCalls, 0);
    });
  });

  testWidgets('shows the sizes and recommends E2B on a 6 GB phone', (
    tester,
  ) async {
    await runWithApp(tester, () async {
      device.totalRamBytes = 6 * gib;
      await pumpApp(tester);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump();

      expect(find.text('Gemma 4 E2B (recommended)'), findsOneWidget);
      expect(find.text('Gemma 4 E4B'), findsOneWidget);
      expect(find.textContaining('2.6 GB download'), findsOneWidget);
      expect(find.textContaining('3.7 GB download'), findsOneWidget);
      expect(downloadButton('Gemma 4 E2B'), findsOneWidget);
    });
  });

  testWidgets('recommends E4B on a 12 GB phone', (tester) async {
    await runWithApp(tester, () async {
      device.totalRamBytes = 12 * gib;
      await pumpApp(tester);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump();

      expect(find.text('Gemma 4 E4B (recommended)'), findsOneWidget);
      expect(downloadButton('Gemma 4 E4B'), findsOneWidget);
    });
  });

  testWidgets('warns below 4 GB of RAM', (tester) async {
    await runWithApp(tester, () async {
      device.totalRamBytes = 3 * gib;
      await pumpApp(tester);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump();

      expect(find.textContaining('less than 4 GB of RAM'), findsOneWidget);
    });
  });

  testWidgets('disables the download when storage is too low', (tester) async {
    await runWithApp(tester, () async {
      device.freeStorageBytes = 2 * gib;
      await pumpApp(tester);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump();

      expect(find.textContaining('Not enough free storage'), findsOneWidget);
      final button = tester.widget<FilledButton>(downloadButton('Gemma 4 E2B'));
      expect(button.onPressed, isNull);
    });
  });

  testWidgets('Wi-Fi only blocks a download on mobile data', (tester) async {
    await runWithApp(tester, () async {
      device.onUnmeteredNetwork = false;
      await pumpApp(tester);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump();

      await tester.tap(downloadButton('Gemma 4 E2B'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump();

      expect(runtime.installCalls, 0);
      expect(find.textContaining('Wi-Fi only is on'), findsOneWidget);
    });
  });

  testWidgets('turning Wi-Fi only off allows mobile data and is remembered', (
    tester,
  ) async {
    await runWithApp(tester, () async {
      device.onUnmeteredNetwork = false;
      await pumpApp(tester);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump();

      await tester.tap(find.byType(Switch));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump();
      expect(await SettingsRepository(db).get(SettingsKeys.wifiOnly), 'false');

      await tester.tap(downloadButton('Gemma 4 E2B'));
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await tester.pump(const Duration(seconds: 1));

      expect(runtime.installCalls, 1);
    });
  });

  testWidgets('shows progress, then Home when the download finishes', (
    tester,
  ) async {
    await runWithApp(tester, () async {
      runtime.installGate = Completer<void>();
      await pumpApp(tester);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump();

      await tester.tap(downloadButton('Gemma 4 E2B'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await tester.pump();

      expect(find.textContaining('Downloading Gemma 4 E2B'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      runtime.installGate!.complete();
      await settle(tester);

      expect(find.textContaining('No tasks yet'), findsOneWidget);
    });
  });

  testWidgets('resumes an interrupted download on launch', (tester) async {
    await runWithApp(tester, () async {
      await SettingsRepository(db)
          .set(SettingsKeys.downloadingModelId, GemmaModelOption.gemma4E4B.id);
      await pumpApp(tester);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await tester.pump(const Duration(seconds: 1));

      expect(runtime.installCalls, 1);
    });
  });

  testWidgets('shows an error and lets the user retry', (tester) async {
    await runWithApp(tester, () async {
      runtime.installError = Exception('connection lost');
      await pumpApp(tester);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump();

      await tester.tap(downloadButton('Gemma 4 E2B'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await tester.pump();

      expect(find.textContaining('The download failed'), findsOneWidget);
      expect(downloadButton('Gemma 4 E2B'), findsOneWidget);
    });
  });
}
