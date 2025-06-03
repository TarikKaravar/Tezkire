import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/core/themes.dart';
import 'screens/app_colors.dart'; // Güncellenmiş AppColors ve AppThemes için
import 'screens/loading_screen.dart';

void main() {
  // Flutter widget binding'i başlatır
  WidgetsFlutterBinding.ensureInitialized();
  
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

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  // Tema modu için state
  ThemeMode _themeMode = ThemeMode.system;
  
  // Tema değiştirme fonksiyonu
  void changeThemeMode(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Namaz Vakitleri',
      debugShowCheckedModeBanner: false,
      
      // Güncellenmiş tema ayarları
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: _themeMode,
      
      // Tema değiştirme fonksiyonunu child widget'lara geçir
      home: ThemeProvider(
        changeThemeMode: changeThemeMode,
        currentThemeMode: _themeMode,
        child: const LoadingScreen(),
      ),
    );
  }
}

// Tema sağlayıcı widget'ı
class ThemeProvider extends InheritedWidget {
  final Function(ThemeMode) changeThemeMode;
  final ThemeMode currentThemeMode;
  
  const ThemeProvider({
    Key? key,
    required this.changeThemeMode,
    required this.currentThemeMode,
    required Widget child,
  }) : super(key: key, child: child);
  
  // Herhangi bir widget'tan tema fonksiyonlarına erişim için
  static ThemeProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeProvider>();
  }
  
  @override
  bool updateShouldNotify(ThemeProvider oldWidget) {
    return currentThemeMode != oldWidget.currentThemeMode;
  }
}

// Tema değiştirme widget'ı (isteğe bağlı - diğer sayfalarda kullanabilirsiniz)
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.of(context);
    
    if (themeProvider == null) return const SizedBox.shrink();
    
    return PopupMenuButton<ThemeMode>(
      icon: Icon(
        AppThemes.isDark(context) ? Icons.dark_mode : Icons.light_mode,
        color: AppThemes.getTextColor(context),
      ),
      onSelected: themeProvider.changeThemeMode,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: ThemeMode.system,
          child: Row(
            children: [
              Icon(
                Icons.settings_system_daydream,
                color: AppThemes.getTextColor(context),
              ),
              const SizedBox(width: 8),
              Text(
                'Sistem',
                style: TextStyle(color: AppThemes.getTextColor(context)),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: ThemeMode.light,
          child: Row(
            children: [
              Icon(
                Icons.light_mode,
                color: AppThemes.getTextColor(context),
              ),
              const SizedBox(width: 8),
              Text(
                'Açık Tema',
                style: TextStyle(color: AppThemes.getTextColor(context)),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: ThemeMode.dark,
          child: Row(
            children: [
              Icon(
                Icons.dark_mode,
                color: AppThemes.getTextColor(context),
              ),
              const SizedBox(width: 8),
              Text(
                'Koyu Tema',
                style: TextStyle(color: AppThemes.getTextColor(context)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Hızlı tema değiştirme butonu (isteğe bağlı)
class QuickThemeToggle extends StatelessWidget {
  const QuickThemeToggle({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.of(context);
    
    if (themeProvider == null) return const SizedBox.shrink();
    
    return FloatingActionButton.small(
      onPressed: () {
        // Hızlı geçiş: Açık ↔ Koyu
        final newMode = AppThemes.isDark(context) 
            ? ThemeMode.light 
            : ThemeMode.dark;
        themeProvider.changeThemeMode(newMode);
      },
      child: Icon(
        AppThemes.isDark(context) ? Icons.light_mode : Icons.dark_mode,
      ),
    );
  }
}