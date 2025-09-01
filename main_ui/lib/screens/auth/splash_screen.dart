// main_ui/lib/screens/auth/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(localeNotifierProvider.notifier); // Ensure locale is loaded
      await ref.read(authProvider.notifier).checkAuth();
      final user = ref.read(authProvider);
      if (user != null) {
        Navigator.pushReplacementNamed(context, '/${user.role}/home');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}