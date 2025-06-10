import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/core/themes.dart';
import 'screens/app_colors.dart'; // Güncellenmiş AppColors ve AppThemes için
import 'screens/loading_screen.dart';
import 'core/theme_manager.dart'; // ThemeManager'ı import edin

void main() async {
  // Flutter widget binding'i başlatır
  WidgetsFlutterBinding.ensureInitialized();
  
  // Tema ayarlarını yükle
  await ThemeManager().loadThemeFromPrefs();
  
  // Sistem UI ayarları (status bar, navigation bar)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Desteklenen yönleri ayarla (sadece dikey)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      // ThemeManager'ı dinle
      valueListenable: ThemeManager(),
      builder: (context, themeMode, child) {
        return MaterialApp(
          title: 'Namaz Vakitleri',
          debugShowCheckedModeBanner: false,
          
          // Dinamik tema ayarları
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: themeMode, // Gerçek zamanlı tema modu
          
          home: const LoadingScreen(),
        );
      },
    );
  }
}

// Eski ThemeProvider'ı kaldırdık, artık ThemeManager kullanıyoruz

// Tema değiştirme widget'ı (güncellenmiş)
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager(),
      builder: (context, currentTheme, child) {
        return PopupMenuButton<ThemeMode>(
          icon: Icon(
            ThemeManager().getThemeIcon(currentTheme),
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          onSelected: (ThemeMode theme) {
            ThemeManager().changeTheme(theme);
          },
          itemBuilder: (context) => ThemeMode.values.map((theme) {
            return PopupMenuItem(
              value: theme,
              child: Row(
                children: [
                  Icon(
                    ThemeManager().getThemeIcon(theme),
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  const SizedBox(width: 8),
                  Text(ThemeManager().getThemeName(theme)),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// Hızlı tema değiştirme butonu (güncellenmiş)
class QuickThemeToggle extends StatelessWidget {
  const QuickThemeToggle({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager(),
      builder: (context, currentTheme, child) {
        return FloatingActionButton.small(
          onPressed: () {
            // Hızlı geçiş: System -> Light -> Dark -> System
            ThemeMode newMode;
            switch (currentTheme) {
              case ThemeMode.system:
                newMode = ThemeMode.light;
                break;
              case ThemeMode.light:
                newMode = ThemeMode.dark;
                break;
              case ThemeMode.dark:
                newMode = ThemeMode.system;
                break;
            }
            ThemeManager().changeTheme(newMode);
          },
          child: Icon(ThemeManager().getThemeIcon(currentTheme)),
        );
      },
    );
  }
}