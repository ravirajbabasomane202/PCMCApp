// lib/screens/auth/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:main_ui/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Check if user is already authenticated
      await ref.read(authProvider.notifier).checkAuth();
      
      // Add a small delay to show the splash screen
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Navigate based on authentication status
      final user = ref.read(authProvider);
      
      if (mounted) {
        if (user != null) {
          // User is authenticated, navigate to appropriate home screen
          _navigateBasedOnRole(user.role);
        } else {
          // User is not authenticated, navigate to login
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      if (mounted) {
        // If there's an error, still navigate to login
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  void _navigateBasedOnRole(String? role) {
    switch (role?.toUpperCase()) {
      case 'ADMIN':
        Navigator.pushReplacementNamed(context, '/admin/home');
        break;
      case 'MEMBER_HEAD':
        Navigator.pushReplacementNamed(context, '/member_head/home');
        break;
      case 'FIELD_STAFF':
        Navigator.pushReplacementNamed(context, '/field_staff/home');
        break;
      case 'CITIZEN':
      default:
        Navigator.pushReplacementNamed(context, '/citizen/home');
        break;
    }
  }

  // Alternative branded splash screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade800,
              Colors.blue.shade600,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -50,
              bottom: -50,
              child: Opacity(
                opacity: 0.1,
                child: Icon(
                  Icons.gavel_rounded,
                  size: 200,
                  color: Colors.white,
                ),
              ),
            ),
            
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated logo container replaced with Lottie animation
                  SizedBox(
                    width: 200, // Adjust size as needed
                    height: 200, // Adjust size as needed
                    child: Lottie.asset(
                      'assets/animations/niwaran.json', // Ensure the JSON file is added to assets/animations/niwaran.json in pubspec.yaml
                      fit: BoxFit.contain,
                      repeat: true, // Set to false if you don't want it to loop
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // App title with animation
                  TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 800),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double value, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      'NIVARAN',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Tagline
                  Text(
                    'Easy Solutions for smart punawale',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Loading indicator with delayed appearance
                  TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 500),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double value, child) {
                      return Opacity(
                        opacity: value,
                        child: child,
                      );
                    },
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}