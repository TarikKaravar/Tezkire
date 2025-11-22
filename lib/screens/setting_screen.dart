import 'package:flutter/material.dart';
import 'themes_screen.dart';
import 'languages_screen.dart';
import 'package:flutter_app/screens/app_colors.dart'; // Renkler

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Uygulama Ayarları',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            _buildSettingsCard(
              context,
              title: 'Tema Ayarları',
              subtitle: 'Açık/koyu tema seçimi yapın',
              icon: Icons.palette_outlined,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ThemesScreen())),
            ),
            
            const SizedBox(height: 12),
            
            _buildSettingsCard(
              context,
              title: 'Dil Ayarları',
              subtitle: 'Uygulama dilini değiştirin',
              icon: Icons.language_outlined,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LanguagesScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
        onTap: onTap,
      ),
    );
  }
}