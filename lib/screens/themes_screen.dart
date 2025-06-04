import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeMode { system, light, dark }

class ThemesScreen extends StatefulWidget {
  const ThemesScreen({super.key});

  @override
  State<ThemesScreen> createState() => _ThemesScreenState();
}

class _ThemesScreenState extends State<ThemesScreen> {
  ThemeMode _selectedTheme = ThemeMode.system;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode') ?? 0;
    setState(() {
      _selectedTheme = ThemeMode.values[themeIndex];
      _isLoading = false;
    });
  }

  Future<void> _saveThemePreference(ThemeMode theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', theme.index);
  }

  void _changeTheme(ThemeMode theme) {
    setState(() {
      _selectedTheme = theme;
    });
    _saveThemePreference(theme);
    
    // Snackbar ile onay mesajı
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tema değiştirildi: ${_getThemeName(theme)}'),
        duration: const Duration(seconds: 2),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  String _getThemeName(ThemeMode theme) {
    switch (theme) {
      case ThemeMode.system:
        return 'Sistem Ayarı';
      case ThemeMode.light:
        return 'Açık Tema';
      case ThemeMode.dark:
        return 'Koyu Tema';
    }
  }

  String _getThemeDescription(ThemeMode theme) {
    switch (theme) {
      case ThemeMode.system:
        return 'Cihazın sistem ayarını takip eder';
      case ThemeMode.light:
        return 'Her zaman açık tema kullanır';
      case ThemeMode.dark:
        return 'Her zaman koyu tema kullanır';
    }
  }

  IconData _getThemeIcon(ThemeMode theme) {
    switch (theme) {
      case ThemeMode.system:
        return Icons.settings_system_daydream;
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tema Ayarları'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık ve Açıklama
                  Text(
                    'Tema Seçimi',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Uygulamanın görünümünü kişiselleştirin',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tema Seçenekleri
                  ...ThemeMode.values.map((theme) => _buildThemeOption(theme)),

                  const SizedBox(height: 32),

                  // Tema Önizleme Kartı
                  _buildPreviewCard(),

                  const SizedBox(height: 24),

                  // Renk Paleti Gösterimi
                  _buildColorPalette(),
                ],
              ),
            ),
    );
  }

  Widget _buildThemeOption(ThemeMode theme) {
    final isSelected = _selectedTheme == theme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: isSelected ? 4 : 1,
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getThemeIcon(theme),
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          title: Text(
            _getThemeName(theme),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
          ),
          subtitle: Text(
            _getThemeDescription(theme),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: isSelected
              ? Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                )
              : Icon(
                  Icons.radio_button_unchecked,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
          onTap: () => _changeTheme(theme),
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.preview,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tema Önizlemesi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Örnek UI Elementleri
            ElevatedButton(
              onPressed: () {},
              child: const Text('Örnek Buton'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {},
              child: const Text('Metin Butonu'),
            ),
            const SizedBox(height: 8),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Örnek Metin Alanı',
                hintText: 'Buraya yazın...',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPalette() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Renk Paleti',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Renk Örnekleri
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildColorChip('Ana Renk', Theme.of(context).colorScheme.primary),
                _buildColorChip('İkincil', Theme.of(context).colorScheme.secondary),
                _buildColorChip('Yüzey', Theme.of(context).colorScheme.surface),
                _buildColorChip('Arka Plan', Theme.of(context).colorScheme.background),
                _buildColorChip('Hata', Theme.of(context).colorScheme.error),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _getContrastColor(color),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}