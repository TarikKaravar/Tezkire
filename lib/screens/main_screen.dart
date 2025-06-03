import 'package:flutter/material.dart';
import 'package:flutter_app/services/bottom_menu.dart';

// Sayfa placeholder'ları
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const Center(child: Text('Ana Sayfa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
}

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const Center(child: Text('Bildirimler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const Center(child: Text('Profil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const Center(child: Text('Ayarlar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    NotificationScreen(),
    ProfileScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomMenu(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
