import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthNotifier extends StateNotifier<User?> {
  AuthNotifier() : super(null);

  Future<void> loginWithGoogle() async {
    try {
      await AuthService.googleLogin();
      await _fetchUserAndUpdateState();
    } catch (e) {
      print('Google login failed: $e');
      rethrow;
    }
  }

  Future<void> register(String name, String email, String password) async {
    try {
      await AuthService.register(name, email, password);
      await _fetchUserAndUpdateState();
    } catch (e) {
      print('Registration failed: $e');
      rethrow;
    }
  }

  Future<void> loginWithEmail(String email, String password) async {
    try {
      await AuthService.passwordLogin(email, password);
      await _fetchUserAndUpdateState();
    } catch (e) {
      print('Login failed: $e');
      rethrow;
    }
  }

  Future<void> loginWithOtp(String phoneNumber, String otp) async {
    try {
      await AuthService.verifyOtp(phoneNumber, otp);
      await _fetchUserAndUpdateState();
    } catch (e) {
      print('OTP login failed: $e');
      rethrow;
    }
  }

  Future<void> requestOtp(String phoneNumber) async {
    try {
      await AuthService.requestOtp(phoneNumber);
    } catch (e) {
      print('OTP request failed: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    print('Logging out');
    await AuthService.logout();
    state = null;
  }

  Future<void> checkAuth() async {
    final user = await AuthService.getCurrentUser();
    if (user != null) {
      print('Found authenticated user: ${user.name}');
      state = user;
    } else {
      print('No authenticated user found');
      state = null;
    }
  }

  Future<void> processNewToken(String token) async {
    try {
      await AuthService.storeToken(token);
      await _fetchUserAndUpdateState();
    } catch (e) {
      print('Error processing token: $e');
      rethrow;
    }
  }

  Future<void> _fetchUserAndUpdateState() async {
    try {
      final userData = await AuthService.getCurrentUser();
      print('Fetched user data: ${userData?.toJson()}');
      state = userData;
    } catch (e) {
      print('Error fetching user data: $e. Logging out.');
      await logout();
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) => AuthNotifier());