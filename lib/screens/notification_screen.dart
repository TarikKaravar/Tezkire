import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart'; // Yeni eklendi

class AppColors {
  static const Color primary = Color(0xFF4CAF50);
  static const Color secondary = Color(0xFF81C784);

  static Color getPrayerColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  static Color primaryLight(BuildContext context) {
    return Theme.of(context).colorScheme.primary.withOpacity(0.1);
  }
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  Map<String, bool> prayerNotifications = {
    'Fajr': true,
    'Dhuhr': true,
    'Asr': false,
    'Maghrib': true,
    'Isha': true,
  };

  Map<String, int> notificationMinutes = {
    'Fajr': 30,
    'Dhuhr': 15,
    'Asr': 30,
    'Maghrib': 10,
    'Isha': 30,
  };

  bool masterNotification = true;
  bool soundEnabled = true;
  bool vibrationEnabled = true;

  final Map<String, String> turkishPrayerNames = {
    'Fajr': 'SABAH',
    'Dhuhr': 'ÖĞLE',
    'Asr': 'İKİNDİ',
    'Maghrib': 'AKŞAM',
    'Isha': 'YATSI',
  };

  final Map<String, IconData> prayerIcons = {
    'Fajr': Icons.wb_sunny_outlined,
    'Dhuhr': Icons.wb_sunny,
    'Asr': Icons.wb_twilight,
    'Maghrib': Icons.brightness_3,
    'Isha': Icons.nights_stay,
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkAlarmPermission(); // İzin kontrolünü başlat
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  // SCHEDULE_EXACT_ALARM iznini kontrol et ve iste
  Future<void> _checkAlarmPermission() async {
    final status = await Permission.scheduleExactAlarm.status;
    if (status.isDenied) {
      final result = await Permission.scheduleExactAlarm.request();
      if (result.isPermanentlyDenied) {
        _showPermissionDialog();
      }
    } else if (status.isPermanentlyDenied) {
      _showPermissionDialog();
    }
  }

  // İzin reddedildiğinde kullanıcıyı bilgilendiren dialog
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Bildirim İzni Gerekli',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Namaz bildirimlerinin doğru çalışması için tam zamanlı alarm izni gerekiyor. Lütfen cihaz ayarlarından bu izni verin.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
          ),
          TextButton(
            onPressed: () async {
              await openAppSettings();
              Navigator.pop(context);
            },
            child: Text(
              'Ayarlara Git',
              style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      masterNotification = prefs.getBool('masterNotification') ?? true;
      soundEnabled = prefs.getBool('soundEnabled') ?? true;
      vibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;

      prayerNotifications = {
        'Fajr': prefs.getBool('prayer_Fajr') ?? true,
        'Dhuhr': prefs.getBool('prayer_Dhuhr') ?? true,
        'Asr': prefs.getBool('prayer_Asr') ?? false,
        'Maghrib': prefs.getBool('prayer_Maghrib') ?? true,
        'Isha': prefs.getBool('prayer_Isha') ?? true,
      };

      notificationMinutes = {
        'Fajr': prefs.getInt('minutes_Fajr') ?? 30,
        'Dhuhr': prefs.getInt('minutes_Dhuhr') ?? 15,
        'Asr': prefs.getInt('minutes_Asr') ?? 30,
        'Maghrib': prefs.getInt('minutes_Maghrib') ?? 10,
        'Isha': prefs.getInt('minutes_Isha') ?? 30,
      };
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('masterNotification', masterNotification);
    await prefs.setBool('soundEnabled', soundEnabled);
    await prefs.setBool('vibrationEnabled', vibrationEnabled);

    for (var key in prayerNotifications.keys) {
      await prefs.setBool('prayer_$key', prayerNotifications[key]!);
      await prefs.setInt('minutes_$key', notificationMinutes[key]!);
    }

    // Reschedule notifications after saving settings
    await NotificationService().schedulePrayerNotifications();
  }

  void _showTimePickerDialog(String prayerKey) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        int tempMinutes = notificationMinutes[prayerKey] ?? 30;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                '${turkishPrayerNames[prayerKey]} Bildirimi',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Namaz vaktinden kaç dakika önce hatırlatılsın?',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$tempMinutes dakika önce',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Slider(
                          value: tempMinutes.toDouble(),
                          min: 5,
                          max: 60,
                          divisions: 11,
                          activeColor: colorScheme.primary,
                          inactiveColor: colorScheme.onSurface.withOpacity(0.3),
                          onChanged: (value) {
                            setDialogState(() {
                              tempMinutes = value.round();
                            });
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('5 dk', style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            )),
                            Text('60 dk', style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            )),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'İptal',
                    style: GoogleFonts.poppins(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      notificationMinutes[prayerKey] = tempMinutes;
                      _saveSettings();
                    });
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Kaydet',
                    style: GoogleFonts.poppins(color: colorScheme.onPrimary),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMasterSwitch(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: masterNotification
              ? [colorScheme.primary.withOpacity(0.9), colorScheme.primary.withOpacity(0.7)]
              : [colorScheme.surface, colorScheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: masterNotification
              ? colorScheme.primary.withOpacity(0.3)
              : colorScheme.outline.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: masterNotification
                ? colorScheme.primary.withOpacity(0.2)
                : colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: masterNotification
                  ? colorScheme.onPrimary.withOpacity(0.2)
                  : colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              masterNotification ? Icons.notifications_active : Icons.notifications_off,
              color: masterNotification ? colorScheme.onPrimary : colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Namaz Bildirimleri',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: masterNotification ? colorScheme.onPrimary : colorScheme.onSurface,
                  ),
                ),
                Text(
                  masterNotification ? 'Aktif' : 'Kapalı',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: masterNotification
                        ? colorScheme.onPrimary.withOpacity(0.8)
                        : colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: masterNotification,
            onChanged: (value) {
              setState(() {
                masterNotification = value;
                _saveSettings();
              });
            },
            activeColor: colorScheme.onPrimary,
            activeTrackColor: colorScheme.onPrimary.withOpacity(0.3),
            inactiveTrackColor: colorScheme.onSurface.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerNotificationCard(String prayerKey) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnabled = prayerNotifications[prayerKey] ?? false;
    final minutes = notificationMinutes[prayerKey] ?? 30;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Card(
        elevation: isEnabled ? 6 : 2,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isEnabled
                ? LinearGradient(
                    colors: [
                      colorScheme.primary.withOpacity(0.1),
                      colorScheme.primary.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isEnabled
                          ? colorScheme.primary.withOpacity(0.2)
                          : colorScheme.onSurface.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      prayerIcons[prayerKey],
                      color: isEnabled ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.5),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          turkishPrayerNames[prayerKey] ?? prayerKey,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isEnabled ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        Text(
                          isEnabled ? '$minutes dakika önce hatırlat' : 'Bildirim kapalı',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: isEnabled
                                ? colorScheme.primary
                                : colorScheme.onSurface.withOpacity(0.5),
                            fontWeight: isEnabled ? FontWeight.w500 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isEnabled && masterNotification,
                    onChanged: masterNotification
                        ? (value) {
                            setState(() {
                              prayerNotifications[prayerKey] = value;
                              _saveSettings();
                            });
                          }
                        : null,
                    activeColor: colorScheme.primary,
                    activeTrackColor: colorScheme.primary.withOpacity(0.3),
                    inactiveTrackColor: colorScheme.onSurface.withOpacity(0.3),
                  ),
                ],
              ),
              if (isEnabled && masterNotification) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _showTimePickerDialog(prayerKey),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.schedule,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Zamanı Ayarla ($minutes dk)',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSoundSettings(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bildirim Ayarları',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.volume_up,
                color: soundEnabled ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ses',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Switch(
                value: soundEnabled && masterNotification,
                onChanged: masterNotification
                    ? (value) {
                        setState(() {
                          soundEnabled = value;
                          _saveSettings();
                        });
                      }
                    : null,
                activeColor: colorScheme.primary,
                activeTrackColor: colorScheme.primary.withOpacity(0.3),
                inactiveTrackColor: colorScheme.onSurface.withOpacity(0.3),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.vibration,
                color: vibrationEnabled ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Titreşim',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Switch(
                value: vibrationEnabled && masterNotification,
                onChanged: masterNotification
                    ? (value) {
                        setState(() {
                          vibrationEnabled = value;
                          _saveSettings();
                        });
                      }
                    : null,
                activeColor: colorScheme.primary,
                activeTrackColor: colorScheme.primary.withOpacity(0.3),
                inactiveTrackColor: colorScheme.onSurface.withOpacity(0.3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Text(
                  'Bildirimler',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildMasterSwitch(context),
                      ...prayerNotifications.keys.map((prayerKey) =>
                          _buildPrayerNotificationCard(prayerKey)),
                      _buildSoundSettings(context),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}