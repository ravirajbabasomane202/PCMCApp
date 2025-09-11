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
      
      rethrow;
    }
  }

  Future<void> register(String name, String email, String password) async {
    try {
      await AuthService.register(name, email, password);
      await _fetchUserAndUpdateState();
    } catch (e) {
      
      rethrow;
    }
  }

  Future<void> loginWithEmail(String email, String password) async {
    try {
      await AuthService.passwordLogin(email, password);
      await _fetchUserAndUpdateState();
    } catch (e) {
      
      rethrow;
    }
  }

  Future<void> loginWithOtp(String phoneNumber, String otp) async {
    try {
      await AuthService.verifyOtp(phoneNumber, otp);
      await _fetchUserAndUpdateState();
    } catch (e) {
      
      rethrow;
    }
  }

  Future<void> requestOtp(String phoneNumber) async {
    try {
      await AuthService.requestOtp(phoneNumber);
    } catch (e) {
     
      rethrow;
    }
  }

  Future<void> logout() async {
    
    await AuthService.logout();
    state = null;
  }

  Future<void> checkAuth() async {
    final user = await AuthService.getCurrentUser();
    if (user != null) {
      
      state = user;
    } else {
      
      state = null;
    }
  }

  Future<void> processNewToken(String token) async {
    try {
      await AuthService.storeToken(token);
      await _fetchUserAndUpdateState();
    } catch (e) {
      
      rethrow;
    }
  }

  Future<void> _fetchUserAndUpdateState() async {
    try {
      final userData = await AuthService.getCurrentUser();
      
      state = userData;
    } catch (e) {
      
      await logout();
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) => AuthNotifier());