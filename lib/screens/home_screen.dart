import 'package:flutter/material.dart';
import 'package:flutter_app/services/bottom_menu.dart';
import 'package:flutter_app/screens/profile_screen.dart';
import 'package:flutter_app/screens/notification_screen.dart';
import 'package:flutter_app/screens/setting_screen.dart';
import 'package:flutter_app/services/prayer_time_service.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Map<String, String> prayerTimes = {};
  bool isLoading = true;
  String currentDate = '';

  final Map<String, String> turkishPrayerNames = {
    'Fajr': 'SABAH',
    'Dhuhr': 'ÖĞLE',
    'Asr': 'İKİNDİ',
    'Maghrib': 'AKŞAM',
    'Isha': 'YATSI',
  };

  @override
  void initState() {
    super.initState();
    _setCurrentDate();
    _fetchPrayerTimes();
  }

  void _setCurrentDate() {
    final now = DateTime.now();
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    const weekdays = [
      'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'
    ];
    currentDate = '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  Future<void> _fetchPrayerTimes() async {
    setState(() => isLoading = true);
    try {
      final service = PrayerTimeService();
      final times = await service.fetchPrayerTimesForDate(
        date: DateTime.now(),
        city: 'Istanbul',
        country: 'Turkey',
      );
      setState(() {
        prayerTimes = times;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Namaz vakitleri alınamadı: $e')),
      );
    }
  }

  Widget _buildPrayerContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
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
            'Namaz Vakitleri',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: colorScheme.onPrimary,
            ),
          ),
        ),
        Expanded(
          child: isLoading
              ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
              : RefreshIndicator(
                  onRefresh: _fetchPrayerTimes,
                  color: colorScheme.primary,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          'Bugünün Namaz Vakitleri',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onBackground,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentDate,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: colorScheme.onBackground.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ...prayerTimes.entries.map((entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        turkishPrayerNames[entry.key] ?? entry.key,
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      Text(
                                        entry.value,
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _fetchPrayerTimes,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Vakitleri Yenile',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildPrayerContent(context),
      const NotificationScreen(),
      const ProfileScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: SafeArea(child: screens[_selectedIndex]),
      bottomNavigationBar: BottomMenu(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
