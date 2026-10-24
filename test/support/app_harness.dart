import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:do_it_or_dodge_it/app/data/db/app_database.dart';
import 'package:do_it_or_dodge_it/app/data/models/enums.dart';
import 'package:do_it_or_dodge_it/main.dart';

import 'fakes.dart';

/// A running app on fakes, for end-to-end widget tests. Use inside
/// `tester.runAsync`.
class AppHarness {
  AppHarness({
    required this.db,
    required this.runtime,
    required this.share,
    FakeDeviceInfoSource? device,
    FakeNotificationGateway? notifications,
    FakeBackgroundScheduler? scheduler,
  }) : device = device ?? FakeDeviceInfoSource(),
       notifications = notifications ?? FakeNotificationGateway(),
       scheduler = scheduler ?? FakeBackgroundScheduler();

  final AppDatabase db;
  final FakeModelRuntime runtime;
  final FakeShareService share;
  final FakeDeviceInfoSource device;
  final FakeNotificationGateway notifications;
  final FakeBackgroundScheduler scheduler;

  /// The app on this harness's fakes.
  Widget build() => DoItOrDodgeItApp(
    database: db,
    modelRuntime: runtime,
    deviceInfo: device,
    shareService: share,
    notifications: notifications,
    backgroundScheduler: scheduler,
  );

  Future<void> start(WidgetTester tester) async {
    await installModelFixture(db, runtime);
    await tester.pumpWidget(build());
    await settle(tester);
  }

  /// Long-press timers run in real time inside `runAsync`, so hold the
  /// gesture for real.
  Future<void> longPress(WidgetTester tester, Finder finder) async {
    final gesture = await tester.startGesture(tester.getCenter(finder));
    await Future<void>.delayed(const Duration(milliseconds: 700));
    await gesture.up();
    await settle(tester);
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text).first);
    await settle(tester);
  }

  /// Adds a task through the sheet.
  Future<void> addTask(
    WidgetTester tester,
    String title, {
    String? category,
    String? customCategory,
    String? note,
  }) async {
    await tester.tap(find.text('Add task'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, title);
    if (category != null) {
      await tester.tap(find.byType(DropdownButtonFormField<TaskCategory>));
      await settle(tester);
      final item = find.text(category);
      if (item.evaluate().isEmpty) {
        // The menu builds its items lazily; scroll to the one we want.
        await tester.scrollUntilVisible(
          item,
          100,
          scrollable: find.byType(Scrollable).last,
        );
      }
      await tester.tap(item.last);
      await settle(tester);
    }
    if (customCategory != null) {
      await tester.enterText(find.byType(TextField).at(1), customCategory);
    }
    if (note != null) {
      await tester.enterText(find.byType(TextField).last, note);
    }
    await tester.tap(find.widgetWithText(FilledButton, 'Add task'));
    await settle(tester);
  }
}
