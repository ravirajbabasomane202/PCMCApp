import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../firebase_options.dart';
import 'package:main_ui/utils/constants.dart';

class AuthService {
  static final String _baseUrl = Constants.baseUrl; // Update with your backend URL
  static final fb_auth.FirebaseAuth _firebaseAuth = fb_auth.FirebaseAuth.instance;
  static String? _token;
  static final _authStateController = StreamController<String?>.broadcast();

  // Stream to notify UI about auth changes
  static Stream<String?> get authStateChanges => _authStateController.stream;

  // Initialize SharedPreferences once
  static Future<SharedPreferences> get _storage async {
    return await SharedPreferences.getInstance();
  }

  /// Initializes the AuthService
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final prefs = await _storage;
    _token = prefs.getString('access_token');
    _authStateController.add(_token); // Notify initial token state
  }

  /// Stores backend JWT token
  static Future<String?> setToken(Map<String, dynamic> response) async {
    final backendToken = response['access_token'];
    if (backendToken == null || backendToken.isEmpty) {
      throw Exception('Invalid token received');
    }
    final prefs = await _storage;
    await prefs.setString('access_token', backendToken);
    _token = backendToken;
    _authStateController.add(backendToken); // Notify token change
    return backendToken;
  }

  /// Public method to store a token (for external use if needed)
  static Future<void> storeToken(String token) async {
    if (token.isEmpty) {
      throw Exception('Cannot store empty token');
    }
    final prefs = await _storage;
    await prefs.setString('access_token', token);
    _token = token;
    _authStateController.add(token); // Notify token change
  }

  /// Initiates Google Sign-In flow using backend OAuth
  static Future<void> googleLogin() async {
    try {
      final result = await FlutterWebAuth2.authenticate(
        url: '$_baseUrl/auth/google',
        callbackUrlScheme: 'com.example.mainUi', // Update with your app's scheme
      );
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/google/callback?$result'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await setToken(data);
      } else {
        throw Exception(json.decode(response.body)['msg'] ?? 'Google login failed');
      }
    } catch (e) {
      
      rethrow;
    }
  }

  /// Registers a new user with email and password
  static Future<void> register(
    String name,
    String email,
    String password, {
    String? address,
    String? phoneNumber,
    String? voterId,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'name': name,
        'email': email,
        'password': password,
        'role': 'citizen',
        if (address != null) 'address': address,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (voterId != null) 'voter_id': voterId,
      };
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      if (response.statusCode == 200) {
        await passwordLogin(email, password); // Auto-login after registration
      } else {
        throw Exception(json.decode(response.body)['msg'] ?? 'Registration failed');
      }
    } catch (e) {
     
      rethrow;
    }
  }

  /// Signs in a user with email and password
  static Future<void> passwordLogin(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await setToken(data);
      } else {
        throw Exception(json.decode(response.body)['msg'] ?? 'Login failed');
      }
    } catch (e) {
     
      rethrow;
    }
  }

  /// Requests OTP for mobile login
  static Future<void> requestOtp(String phoneNumber) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/otp/request'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phone_number': phoneNumber}),
      );
      if (response.statusCode != 200) {
        throw Exception(json.decode(response.body)['msg'] ?? 'Failed to request OTP');
      }
    } catch (e) {
      
      rethrow;
    }
  }

  /// Verifies OTP for mobile login
  static Future<void> verifyOtp(String phoneNumber, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/otp/verify'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phone_number': phoneNumber, 'otp': otp}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await setToken(data);
      } else {
        throw Exception(json.decode(response.body)['msg'] ?? 'OTP verification failed');
      }
    } catch (e) {
      
      rethrow;
    }
  }

  /// Fetches the current user's profile from the backend
  static Future<User?> getCurrentUser() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return null;
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return User.fromJson(json.decode(response.body));
      } else {
        await logout();
        return null;
      }
    } catch (e) {
      
      return null;
    }
  }

  /// Signs out the current user
  static Future<void> logout() async {
    try {
      final prefs = await _storage;
      await prefs.remove('access_token');
      _token = null;
      _authStateController.add(null); // Notify token cleared
      await _firebaseAuth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  /// Gets the stored backend JWT
  static Future<String?> getToken() async {
    if (_token != null && _token!.isNotEmpty) return _token;
    final prefs = await _storage;
    _token = prefs.getString('access_token');
    return _token?.isNotEmpty == true ? _token : null;
  }

  /// Closes the auth state stream
  static void dispose() {
    _authStateController.close();
  }
}