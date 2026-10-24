import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Everything the app needs from the local notifications plugin.
///
/// `NudgeService` is the only code that holds one of these.
abstract class NotificationGateway {
  /// Sets the plugin up. [onTap] gets the payload of a tapped notification.
  Future<void> initialize({void Function(String? payload)? onTap});

  /// The payload of the notification that launched the app, if any.
  Future<String?> launchPayload();

  /// True when the user lets the app show notifications.
  Future<bool> areEnabled();

  /// Asks for the notification permission (Android 13 and later).
  Future<bool> requestPermission();

  /// Schedules an inexact notification at [at], so the app does not need the
  /// exact-alarm permission.
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    String? payload,
  });

  Future<void> cancel(int id);

  /// Ids of notifications that are scheduled and have not fired.
  Future<List<int>> pendingIds();
}

/// [NotificationGateway] backed by `flutter_local_notifications`.
class LocalNotificationsGateway implements NotificationGateway {
  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationDetails(
    'nudges',
    'Nudges',
    channelDescription: 'Reminders about the next tiny step of a task',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  @override
  Future<void> initialize({void Function(String? payload)? onTap}) async {
    tz_data.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) =>
          onTap?.call(response.payload),
    );
  }

  @override
  Future<String?> launchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    return details?.notificationResponse?.payload;
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<bool> areEnabled() async =>
      await _android?.areNotificationsEnabled() ?? false;

  @override
  Future<bool> requestPermission() async =>
      await _android?.requestNotificationsPermission() ?? false;

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    String? payload,
  }) async {
    // An absolute moment, so the time zone does not matter.
    final when = tz.TZDateTime.from(at, tz.UTC);
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: when,
      notificationDetails: const NotificationDetails(android: _channel),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<List<int>> pendingIds() async {
    final pending = await _plugin.pendingNotificationRequests();
    return [for (final p in pending) p.id];
  }
}

/// Logs a failure without crashing the app. Notification problems must never
/// stop a user from doing a task.
void logNotificationError(String what, Object error) {
  debugPrint('Notifications: $what failed: $error');
}
