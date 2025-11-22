import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_app/screens/app_colors.dart';
import 'package:flutter_app/screens/home_screen.dart';
import 'package:flutter_app/screens/profile_screen.dart';
import 'package:flutter_app/screens/setting_screen.dart';
import 'package:flutter_app/screens/mosque_map_screen.dart';
import 'package:flutter_app/screens/compass_screen.dart'; // Pusula ekranını dahil ettik

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // SİRALAMA: Ana Sayfa - Kıble - Cami Bul
  final List<Widget> _screens = [
    const HomeScreen(),
    const CompassScreen(), // Kıble/Pusula geri geldi
    const MosqueMapScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- 1. İSTEK: ÜST BAR YOK, SADECE MENÜ İKONU VAR ---
      extendBodyBehindAppBar: true, // İçeriği yukarı kaydırır, barın altına girer
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Şeffaf arka plan
        elevation: 0, // Gölge yok
        leading: Builder(
          builder: (context) => Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface(context).withOpacity(0.8), // Hafif arka plan ki görünsün
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.menu_rounded, size: 28),
              color: AppColors.primary, // Haki Yeşil İkon
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
      ),
      
      // SOL MENÜ (DRAWER)
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primary), // Haki Yeşil Header
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FontAwesomeIcons.mosque, size: 50, color: Colors.white),
                  SizedBox(height: 10),
                  Text("Tezkire Menü", style: TextStyle(color: Colors.white, fontSize: 24)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: AppColors.primary),
              title: const Text('Profil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: AppColors.primary),
              title: const Text('Ayarlar'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
              },
            ),
          ],
        ),
      ),

      body: _screens[_selectedIndex],

      // --- 2. İSTEK: KIBLE EKLENDİ VE RENKLER HAKİ YEŞİL ---
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.compass), // Kıble İkonu
            label: 'Kıble',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.mapLocationDot),
            label: 'Cami Bul',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primary, // Seçili ikon Haki Yeşil
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: false,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}