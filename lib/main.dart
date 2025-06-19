import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/core/themes.dart';
import 'package:flutter_app/services/notification_service.dart';
import 'screens/app_colors.dart';
import 'screens/loading_screen.dart';
import 'core/theme_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize NotificationService
  await NotificationService().init();
  await NotificationService().schedulePrayerNotifications();

  // Tema ayarlarını yükle
  await ThemeManager().loadThemeFromPrefs();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

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
      valueListenable: ThemeManager(),
      builder: (context, themeMode, child) {
        return MaterialApp(
          title: 'Namaz Vakitleri',
          debugShowCheckedModeBanner: false,
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: themeMode,
          home: const LoadingScreen(),
        );
      },
    );
  }
}

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

class QuickThemeToggle extends StatelessWidget {
  const QuickThemeToggle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager(),
      builder: (context, currentTheme, child) {
        return FloatingActionButton.small(
          onPressed: () {
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