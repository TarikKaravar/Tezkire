import 'package:flutter/material.dart';
import 'package:flutter_app/services/prayer_time_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, String> prayerTimes = {};
  bool isLoading = true;
  String currentDate = '';
  int _selectedIndex = 0;

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

  Widget _buildMainContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: theme.dividerColor, width: 1),
            ),
          ),
          child: Text(
            'Namaz Vakitleri',
            textAlign: TextAlign.center,
            style: textTheme.titleLarge!.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: isLoading
              ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'Bugünün Namaz Vakitleri',
                        style: textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(currentDate, style: textTheme.bodyMedium),
                      const SizedBox(height: 32),
                      ...prayerTimes.entries.map((entry) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.dividerColor, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(turkishPrayerNames[entry.key] ?? entry.key,
                                  style: textTheme.titleMedium),
                              Text(
                                entry.value,
                                style: textTheme.titleMedium!.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _fetchPrayerTimes,
                        child: const Text('Vakitleri Yenile'),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: Theme.of(context).iconTheme.color,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Ana Sayfa'),
        BottomNavigationBarItem(icon: Icon(Icons.notifications_rounded), label: 'Bildirimler'),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
        BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Ayarlar'),
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(child: _buildMainContent(context)),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }
}
