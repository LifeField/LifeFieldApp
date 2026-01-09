import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  Future<void> Function(NotificationResponse response)?
      _onNotificationResponse;

  Future<void> initialize() async {
    tz.initializeTimeZones();
    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosInit = DarwinInitializationSettings(
      notificationCategories: _iosCategories(),
    );
    final initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final response = launchDetails?.notificationResponse;
    if (response != null) {
      await _handleNotificationResponse(response);
    }

    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        'workout_recovery',
        'Recupero allenamento',
        description: 'Notifiche per timer di recupero allenamento',
        importance: Importance.max,
        playSound: true,
      ),
    );

    final iosImpl =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iosImpl?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    // Foreground presentation options handled in AppDelegate via delegate.
  }

  Future<void> scheduleRecoveryNotification({
    required int id,
    required String title,
    required String body,
    required Duration after,
    String? payload,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'workout_recovery',
        'Recupero allenamento',
        channelDescription: 'Notifiche per timer di recupero allenamento',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        channelShowBadge: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
        sound: 'default',
        interruptionLevel: InterruptionLevel.active,
        categoryIdentifier: 'workout_recovery',
      ),
    );
    final scheduledAt = tz.TZDateTime.now(tz.local).add(after);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledAt,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
      payload: payload,
    );
  }

  Future<void> showRecoveryNotificationNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'workout_recovery',
        'Recupero allenamento',
        channelDescription: 'Notifiche per timer di recupero allenamento',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        channelShowBadge: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
        sound: 'default',
        interruptionLevel: InterruptionLevel.active,
        categoryIdentifier: 'workout_recovery',
      ),
    );
    await _plugin.show(id, title, body, details, payload: payload);
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  void setOnNotificationResponse(
    Future<void> Function(NotificationResponse response) handler,
  ) {
    _onNotificationResponse = handler;
  }

  Future<void> _handleNotificationResponse(
    NotificationResponse response,
  ) async {
    final handler = _onNotificationResponse;
    if (handler != null) {
      await handler(response);
    }
  }

  List<DarwinNotificationCategory> _iosCategories() {
    return [
      DarwinNotificationCategory(
        'workout_recovery',
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain(
            'open_workout',
            'Apri allenamento',
            options: {DarwinNotificationActionOption.foreground},
          ),
          DarwinNotificationAction.plain(
            'dismiss_recovery',
            'Chiudi',
            options: {DarwinNotificationActionOption.destructive},
          ),
        ],
      ),
    ];
  }
}
