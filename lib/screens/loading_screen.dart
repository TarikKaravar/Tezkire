import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'home_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHomeScreen();
  }

  void _navigateToHomeScreen() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;

              var tween = Tween(begin: begin, end: end).chain(
                CurveTween(curve: curve),
              );

              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Uygulama simgesi
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.mosque,
                  size: 80,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),

              // Lottie animasyonu
              Lottie.asset(
                'assets/motions/loading.json',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                repeat: true,
                errorBuilder: (context, error, stackTrace) {
                  return SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                      strokeWidth: 3,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Yükleniyor metni
              Text(
                'Namaz Vakitleri Yükleniyor...',
                style: textTheme.titleMedium!.copyWith(
                  color: colorScheme.onBackground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Lütfen bekleyiniz',
                style: textTheme.bodyMedium,
              ),

              const SizedBox(height: 40),

              // Progress bar
              Container(
                width: 200,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
