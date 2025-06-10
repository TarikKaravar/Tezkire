import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme_manager.dart'; // ThemeManager'ı import edin

class ThemesScreen extends StatelessWidget {
  const ThemesScreen({super.key});

  void _changeTheme(BuildContext context, ThemeMode theme) {
    // Tema değiştir - bu otomatik olarak tüm uygulamayı günceller
    ThemeManager().changeTheme(theme);

    // Kullanıcıya geri bildirim ver
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tema değiştirildi: ${ThemeManager().getThemeName(theme)}'),
        duration: const Duration(seconds: 2),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tema Ayarları'),
        elevation: 0,
      ),
      body: ValueListenableBuilder<ThemeMode>(
        // ThemeManager'ı dinle - tema değiştiğinde UI otomatik güncellenir
        valueListenable: ThemeManager(),
        builder: (context, currentTheme, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                ),
                const SizedBox(height: 24),
                ...ThemeMode.values.map((theme) => _buildThemeOption(context, theme, currentTheme)),
                const SizedBox(height: 32),
                _buildPreviewCard(context),
                const SizedBox(height: 24),
                _buildColorPalette(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, ThemeMode theme, ThemeMode currentTheme) {
    final isSelected = currentTheme == theme;

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
              ThemeManager().getThemeIcon(theme),
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          title: Text(
            ThemeManager().getThemeName(theme),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
          ),
          subtitle: Text(
            ThemeManager().getThemeDescription(theme),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: isSelected
              ? Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                )
              : Icon(
                  Icons.radio_button_unchecked,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
          onTap: () => _changeTheme(context, theme),
        ),
      ),
    );
  }

  Widget _buildPreviewCard(BuildContext context) {
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

  Widget _buildColorPalette(BuildContext context) {
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildColorChip(
                    'Ana Renk', Theme.of(context).colorScheme.primary),
                _buildColorChip(
                    'İkincil', Theme.of(context).colorScheme.secondary),
                _buildColorChip(
                    'Yüzey', Theme.of(context).colorScheme.surface),
                _buildColorChip(
                    'Arka Plan', Theme.of(context).colorScheme.background),
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