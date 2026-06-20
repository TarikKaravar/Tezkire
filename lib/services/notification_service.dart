import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  // Sınıfın dışarıdan new/() ile oluşturulmasını engelliyoruz (Çökme riskini sıfırlar)
  NotificationService._();

  // Bildirim eklentisi doğrudan statik olarak tanımlanıyor
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static final Map<String, DateTime> _prayerTimes = {
    'Fajr': DateTime(2025, 6, 20, 5, 0), 
    'Dhuhr': DateTime(2025, 6, 20, 12, 0),
    'Asr': DateTime(2025, 6, 20, 15, 0), 
    'Maghrib': DateTime(2025, 6, 20, 18, 0),
    'Isha': DateTime(2025, 6, 20, 20, 0), 
  };

  static final Map<String, String> _turkishNames = {
    'Fajr': 'SABAH',
    'Dhuhr': 'ÖĞLE',
    'Asr': 'İKİNDİ',
    'Maghrib': 'AKŞAM',
    'Isha': 'YATSI',
  };

  /// 1. Kurulum işlemleri
  static Future<void> init() async {
    tz.initializeTimeZones();

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await _plugin.initialize(initSettings);
    await _requestPermissions();
  }

  /// 2. Gerekli İzinleri İsteme
  static Future<void> _requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    if (await Permission.scheduleExactAlarm.isDenied) {
      final status = await Permission.scheduleExactAlarm.request();
      if (status.isPermanentlyDenied) {
        await openAppSettings();
      }
    }
  }

  /// 3. Tüm Bildirimleri Ayarlama
  static Future<void> schedulePrayerNotifications() async {
    await _plugin.cancelAll();

    final prefs = await SharedPreferences.getInstance();
    
    if (!(prefs.getBool('masterNotification') ?? true)) return;

    final soundEnabled = prefs.getBool('soundEnabled') ?? true;
    final vibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;

    for (final entry in _prayerTimes.entries) {
      final key = entry.key;
      final prayerTime = entry.value;

      final isPrayerEnabled = prefs.getBool('prayer_$key') ?? (key != 'Asr');
      if (!isPrayerEnabled) continue;

      final minutesBefore = prefs.getInt('minutes_$key') ?? _getDefaultMinutes(key);
      final alarmTime = prayerTime.subtract(Duration(minutes: minutesBefore));

      if (alarmTime.isAfter(DateTime.now())) {
        await _setAlarm(
          id: key.hashCode % 100000,
          title: '${_turkishNames[key]} Namazı',
          body: '${_turkishNames[key]} namazı vaktine $minutesBefore dakika kaldı!',
          scheduledTime: alarmTime,
          playSound: soundEnabled,
          playVibration: vibrationEnabled,
        );
      }
    }
  }

  static int _getDefaultMinutes(String key) {
    switch (key) {
      case 'Dhuhr': return 15;
      case 'Maghrib': return 10;
      default: return 30;
    }
  }

  /// 4. Tekil Bildirim Planlama
  static Future<void> _setAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required bool playSound,
    required bool playVibration,
  }) async {
    
    final androidDetails = AndroidNotificationDetails(
      'prayer_alerts',
      'Namaz Vakitleri',
      channelDescription: 'Namaz vakitleri hatırlatıcı bildirimleri',
      importance: Importance.max,
      priority: Priority.high,
      playSound: playSound,
      enableVibration: playVibration,
      vibrationPattern: playVibration ? Int64List.fromList([0, 1000, 500, 1000]) : null,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: playSound,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}