import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_app/services/bottom_menu.dart';
import 'package:flutter_app/screens/profile_screen.dart';
import 'package:flutter_app/screens/notification_screen.dart';
import 'package:flutter_app/screens/setting_screen.dart';
import 'package:flutter_app/services/prayer_time_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  Map<String, String> prayerTimes = {};
  bool isLoading = true;
  String currentDate = '';
  Timer? _countdownTimer;
  String nextPrayerName = '';
  Duration remainingTime = Duration.zero;
  
  // Animasyon kontrolleri
  late AnimationController _citySelectionController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isCitySelectionExpanded = false;

  final Map<String, String> turkishPrayerNames = {
    'Fajr': 'SABAH',
    'Dhuhr': 'ÖĞLE',
    'Asr': 'İKİNDİ',
    'Maghrib': 'AKŞAM',
    'Isha': 'YATSI',
  };

  final List<String> prayerOrder = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  final List<String> citiesTR = [
    'Adana', 'Adıyaman', 'Afyonkarahisar', 'Ağrı', 'Aksaray', 'Amasya', 'Ankara', 'Antalya',
    'Ardahan', 'Artvin', 'Aydın', 'Balıkesir', 'Bartın', 'Batman', 'Bayburt', 'Bilecik', 'Bingöl',
    'Bitlis', 'Bolu', 'Burdur', 'Bursa', 'Çanakkale', 'Çankırı', 'Çorum', 'Denizli', 'Diyarbakır',
    'Düzce', 'Edirne', 'Elazığ', 'Erzincan', 'Erzurum', 'Eskişehir', 'Gaziantep', 'Giresun',
    'Gümüşhane', 'Hakkâri', 'Hatay', 'Iğdır', 'Isparta', 'İstanbul', 'İzmir', 'Kahramanmaraş',
    'Karabük', 'Karaman', 'Kars', 'Kastamonu', 'Kayseri', 'Kırıkkale', 'Kırklareli', 'Kırşehir',
    'Kilis', 'Kocaeli', 'Konya', 'Kütahya', 'Malatya', 'Manisa', 'Mardin', 'Mersin', 'Muğla',
    'Muş', 'Nevşehir', 'Niğde', 'Ordu', 'Osmaniye', 'Rize', 'Sakarya', 'Samsun', 'Şanlıurfa',
    'Siirt', 'Sinop', 'Şırnak', 'Sivas', 'Tekirdağ', 'Tokat', 'Trabzon', 'Tunceli', 'Uşak',
    'Van', 'Yalova', 'Yozgat', 'Zonguldak'
  ];

  // Türkçe sıralama fonksiyonu
  String _turkishSort(String text) {
    return text
        .replaceAll('Ç', 'C1')
        .replaceAll('Ğ', 'G1')
        .replaceAll('İ', 'I1')  
        .replaceAll('Ö', 'O1')
        .replaceAll('Ş', 'S1')
        .replaceAll('Ü', 'U1')
        .replaceAll('ç', 'c1')
        .replaceAll('ğ', 'g1')
        .replaceAll('ı', 'i0')
        .replaceAll('ö', 'o1')
        .replaceAll('ş', 's1')
        .replaceAll('ü', 'u1');
  }

  // Sıralanmış şehirler listesi
  List<String> get sortedCitiesTR {
    final cities = List<String>.from(citiesTR);
    cities.sort((a, b) => _turkishSort(a).compareTo(_turkishSort(b)));
    return cities;
  }

  String _selectedCity = 'İstanbul';

  @override
  void initState() {
    super.initState();
    _loadSelectedCity(); // Load the saved city
    _setCurrentDate();
    
    // Animasyon kontrolleri başlatma
    _citySelectionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _citySelectionController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
    
    _slideController.forward();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _citySelectionController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // Load the selected city from SharedPreferences
  Future<void> _loadSelectedCity() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCity = prefs.getString('selectedCity');
    if (savedCity != null && sortedCitiesTR.contains(savedCity)) {
      setState(() {
        _selectedCity = savedCity;
      });
    }
    // Fetch prayer times after loading the city
    _fetchPrayerTimes();
  }

  // Save the selected city to SharedPreferences
  Future<void> _saveSelectedCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedCity', city);
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
        city: _selectedCity,
        country: 'Turkey',
      );
      setState(() {
        prayerTimes = times;
        isLoading = false;
      });
      _startCountdown();
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Namaz vakitleri alınamadı: $e')),
      );
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _calculateNextPrayer();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateNextPrayer();
    });
  }

  void _calculateNextPrayer() {
    if (prayerTimes.isEmpty) return;

    final now = DateTime.now();
    DateTime? nextPrayerTime;
    String nextPrayer = '';

    for (String prayer in prayerOrder) {
      if (prayerTimes.containsKey(prayer)) {
        final timeStr = prayerTimes[prayer]!;
        final timeParts = timeStr.split(':');
        final prayerTime = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );

        if (prayerTime.isAfter(now)) {
          nextPrayerTime = prayerTime;
          nextPrayer = prayer;
          break;
        }
      }
    }

    if (nextPrayerTime == null && prayerTimes.containsKey('Fajr')) {
      final timeStr = prayerTimes['Fajr']!;
      final timeParts = timeStr.split(':');
      nextPrayerTime = DateTime(
        now.year,
        now.month,
        now.day + 1,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
      nextPrayer = 'Fajr';
    }

    if (nextPrayerTime != null) {
      final difference = nextPrayerTime.difference(now);
      if (mounted) {
        setState(() {
          nextPrayerName = turkishPrayerNames[nextPrayer] ?? nextPrayer;
          remainingTime = difference.isNegative ? Duration.zero : difference;
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  void _toggleCitySelection() {
    setState(() {
      _isCitySelectionExpanded = !_isCitySelectionExpanded;
    });
    
    if (_isCitySelectionExpanded) {
      _citySelectionController.forward();
    } else {
      _citySelectionController.reverse();
    }
  }

  Widget _buildModernCitySelector(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withOpacity(0.9),
                  colorScheme.primary.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Ana şehir seçici butonu
                InkWell(
                  onTap: _toggleCitySelection,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colorScheme.onPrimary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.location_city,
                            color: colorScheme.onPrimary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Şehir',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: colorScheme.onPrimary.withOpacity(0.8),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedCity,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedRotation(
                          turns: _isCitySelectionExpanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: colorScheme.onPrimary,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Genişleyen şehir listesi - DÜZELTİLMİŞ BÖLÜM
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: _isCitySelectionExpanded ? MediaQuery.of(context).size.height * 0.4 : 0,
                  child: _isCitySelectionExpanded 
                      ? FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            margin: const EdgeInsets.only(top: 8, left: 12, right: 12, bottom: 12),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Column(
                                children: [
                                  // Arama çubuğu (opsiyonel)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      border: Border(
                                        bottom: BorderSide(
                                          color: colorScheme.outline.withOpacity(0.1),
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      'Şehir Seçin',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                  ),
                                  // Şehir listesi
                                  Expanded(
                                    child: ListView.builder(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      itemCount: sortedCitiesTR.length,
                                      itemBuilder: (context, index) {
                                        final city = sortedCitiesTR[index];
                                        final isSelected = city == _selectedCity;
                                        
                                        return Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () {
                                              if (city != _selectedCity) {
                                                setState(() => _selectedCity = city);
                                                _saveSelectedCity(city);
                                                _toggleCitySelection();
                                                _fetchPrayerTimes();
                                              }
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16, 
                                                vertical: 12
                                              ),
                                              decoration: BoxDecoration(
                                                color: isSelected 
                                                    ? colorScheme.primary.withOpacity(0.1)
                                                    : Colors.transparent,
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                      color: isSelected 
                                                          ? colorScheme.primary 
                                                          : Colors.transparent,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      city,
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 15,
                                                        fontWeight: isSelected 
                                                            ? FontWeight.w600 
                                                            : FontWeight.w400,
                                                        color: isSelected 
                                                            ? colorScheme.primary 
                                                            : colorScheme.onSurface,
                                                      ),
                                                    ),
                                                  ),
                                                  if (isSelected)
                                                    Icon(
                                                      Icons.check_circle,
                                                      color: colorScheme.primary,
                                                      size: 18,
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCountdownWidget(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (nextPrayerName.isEmpty || remainingTime == Duration.zero) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.secondary.withOpacity(0.1),
            colorScheme.secondary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.secondary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Sonraki Namaz: $nextPrayerName',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colorScheme.onBackground.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.access_time,
                color: colorScheme.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _formatDuration(remainingTime),
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'kalan süre',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: colorScheme.onBackground.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
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
        
        // Modern şehir seçici
        _buildModernCitySelector(context),
        
        Expanded(
          child: isLoading
              ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
              : RefreshIndicator(
                  onRefresh: _fetchPrayerTimes,
                  color: colorScheme.primary,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
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
                            ],
                          ),
                        ),
                        _buildCountdownWidget(context),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
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