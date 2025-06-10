import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// AppColors sınıfınızı import edin
// import 'app_colors.dart';

class AppColors {
  static const Color primary = Color(0xFF6366F1);
  
  static Color getPrayerColor(BuildContext context) {
    return primary;
  }
  
  static Color primaryLight(BuildContext context) {
    return primary.withOpacity(0.1);
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
  
  // Bildirim ayarları
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
                      color: AppColors.getPrayerColor(context).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$tempMinutes dakika önce',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getPrayerColor(context),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Slider(
                          value: tempMinutes.toDouble(),
                          min: 5,
                          max: 60,
                          divisions: 11,
                          activeColor: AppColors.getPrayerColor(context),
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
                    });
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.getPrayerColor(context),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Kaydet',
                    style: GoogleFonts.poppins(color: Colors.white),
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
    final prayerColor = AppColors.getPrayerColor(context);
    
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: masterNotification 
              ? [prayerColor.withOpacity(0.8), prayerColor.withOpacity(0.6)]
              : [colorScheme.surface, colorScheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: masterNotification 
              ? prayerColor.withOpacity(0.3)
              : colorScheme.outline.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: masterNotification 
                ? prayerColor.withOpacity(0.2)
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
                  ? Colors.white.withOpacity(0.2)
                  : prayerColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              masterNotification ? Icons.notifications_active : Icons.notifications_off,
              color: masterNotification ? Colors.white : prayerColor,
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
                    color: masterNotification ? Colors.white : colorScheme.onSurface,
                  ),
                ),
                Text(
                  masterNotification ? 'Aktif' : 'Kapalı',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: masterNotification 
                        ? Colors.white.withOpacity(0.8)
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
              });
            },
            activeColor: Colors.white,
            activeTrackColor: Colors.white.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerNotificationCard(String prayerKey) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnabled = prayerNotifications[prayerKey] ?? false;
    final minutes = notificationMinutes[prayerKey] ?? 30;
    final prayerColor = AppColors.getPrayerColor(context); // Tüm vakitler için aynı renk
    
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
                      prayerColor.withOpacity(0.1),
                      prayerColor.withOpacity(0.05),
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
                          ? prayerColor.withOpacity(0.2)
                          : colorScheme.onSurface.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      prayerIcons[prayerKey],
                      color: isEnabled ? prayerColor : colorScheme.onSurface.withOpacity(0.5),
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
                                ? prayerColor 
                                : colorScheme.onSurface.withOpacity(0.5),
                            fontWeight: isEnabled ? FontWeight.w500 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isEnabled && masterNotification,
                    onChanged: masterNotification ? (value) {
                      setState(() {
                        prayerNotifications[prayerKey] = value;
                      });
                    } : null,
                    activeColor: prayerColor,
                    activeTrackColor: prayerColor.withOpacity(0.3),
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
                      color: prayerColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: prayerColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.schedule,
                          color: prayerColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Zamanı Ayarla ($minutes dk)',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: prayerColor,
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
    final prayerColor = AppColors.getPrayerColor(context);
    
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
                color: soundEnabled ? prayerColor : colorScheme.onSurface.withOpacity(0.5),
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
                onChanged: masterNotification ? (value) {
                  setState(() {
                    soundEnabled = value;
                  });
                } : null,
                activeColor: prayerColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.vibration,
                color: vibrationEnabled ? prayerColor : colorScheme.onSurface.withOpacity(0.5),
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
                onChanged: masterNotification ? (value) {
                  setState(() {
                    vibrationEnabled = value;
                  });
                } : null,
                activeColor: prayerColor,
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
    final prayerColor = AppColors.getPrayerColor(context);
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [prayerColor, prayerColor.withOpacity(0.8)],
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
                    color: Colors.white,
                  ),
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Master Switch
                      _buildMasterSwitch(context),
                      
                      // Prayer Notifications
                      ...prayerNotifications.keys.map((prayerKey) => 
                        _buildPrayerNotificationCard(prayerKey)
                      ),
                      
                      // Sound Settings
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