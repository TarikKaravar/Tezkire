import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart'; // Yeni eklendi

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Placeholder prayer times (replace with actual PrayerTimeService or API)
  final Map<String, DateTime> _prayerTimes = {
    'Faj74': DateTime(2025, 6, 20, 5, 0), // Example: 5:00 AM
    'Dhuhr': DateTime(2025, 6, 20, 12, 0), // Example: 12:00 PM
    'Asr': DateTime(2025, 6, 20, 15, 0), // Example: 3:00 PM
    'Maghrib': DateTime(2025, 6, 20, 18, 0), // Example: 6:00 PM
    'Isha': DateTime(2025, 6, 20, 20, 0), // Example: 8:00 PM
  };

  final Map<String, String> _turkishPrayerNames = {
    'Fajr': 'SABAH',
    'Dhuhr': 'ÖĞLE',
    'Asr': 'İKİNDİ',
    'Maghrib': 'AKŞAM',
    'Isha': 'YATSI',
  };

  // Initialize notification plugin
  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Request notification permissions for Android
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Request SCHEDULE_EXACT_ALARM permission for Android 12+
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
      if (await Permission.scheduleExactAlarm.isPermanentlyDenied) {
        // Kullanıcıyı ayarlar sayfasına yönlendirin
        await openAppSettings();
      }
    }

    // Request permissions for iOS
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  // Load notification settings from SharedPreferences
  Future<Map<String, dynamic>> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final masterNotification = prefs.getBool('masterNotification') ?? true;
    final soundEnabled = prefs.getBool('soundEnabled') ?? true;
    final vibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;

    final prayerNotifications = {
      'Fajr': prefs.getBool('prayer_Fajr') ?? true,
      'Dhuhr': prefs.getBool('prayer_Dhuhr') ?? true,
      'Asr': prefs.getBool('prayer_Asr') ?? false,
      'Maghrib': prefs.getBool('prayer_Maghrib') ?? true,
      'Isha': prefs.getBool('prayer_Isha') ?? true,
    };

    final notificationMinutes = {
      'Fajr': prefs.getInt('minutes_Fajr') ?? 30,
      'Dhuhr': prefs.getInt('minutes_Dhuhr') ?? 15,
      'Asr': prefs.getInt('minutes_Asr') ?? 30,
      'Maghrib': prefs.getInt('minutes_Maghrib') ?? 10,
      'Isha': prefs.getInt('minutes_Isha') ?? 30,
    };

    return {
      'masterNotification': masterNotification,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'prayerNotifications': prayerNotifications,
      'notificationMinutes': notificationMinutes,
    };
  }

  // Schedule notifications for all enabled prayers
  Future<void> schedulePrayerNotifications() async {
    // Cancel all existing notifications to avoid duplicates
    await _flutterLocalNotificationsPlugin.cancelAll();

    final settings = await _loadSettings();
    final bool masterNotification = settings['masterNotification'];
    final bool soundEnabled = settings['soundEnabled'];
    final bool vibrationEnabled = settings['vibrationEnabled'];
    final Map<String, bool> prayerNotifications = settings['prayerNotifications'];
    final Map<String, int> notificationMinutes = settings['notificationMinutes'];

    if (!masterNotification) return;

    for (var prayerKey in prayerNotifications.keys) {
      if (prayerNotifications[prayerKey] == true) {
        final prayerTime = _prayerTimes[prayerKey];
        final minutesBefore = notificationMinutes[prayerKey] ?? 30;

        if (prayerTime != null) {
          final notificationTime =
              prayerTime.subtract(Duration(minutes: minutesBefore));
          if (notificationTime.isAfter(DateTime.now())) {
            await _scheduleNotification(
              prayerKey: prayerKey,
              notificationTime: notificationTime,
              soundEnabled: soundEnabled,
              vibrationEnabled: vibrationEnabled,
            );
          }
        }
      }
    }
  }

  // Schedule a single notification
  Future<void> _scheduleNotification({
    required String prayerKey,
    required DateTime notificationTime,
    required bool soundEnabled,
    required bool vibrationEnabled,
  }) async {
    final turkishName = _turkishPrayerNames[prayerKey] ?? prayerKey;
    final notificationId = prayerKey.hashCode % 1000000; // Unique ID for each prayer

    final androidDetails = AndroidNotificationDetails(
      'prayer_channel',
      'Prayer Notifications',
      channelDescription: 'Notifications for prayer times',
      importance: Importance.high,
      priority: Priority.high,
      playSound: soundEnabled,
      enableVibration: vibrationEnabled,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: soundEnabled,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      '$turkishName Namazı',
      '$turkishName namazı vakti yaklaşıyor! (${notificationTime.toString().substring(0, 16)})',
      tz.TZDateTime.from(notificationTime, tz.local),
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}