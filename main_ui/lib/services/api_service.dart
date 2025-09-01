import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:main_ui/models/user_model.dart';
import 'package:main_ui/services/auth_service.dart';
import 'package:main_ui/utils/constants.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('ApiService');

class ApiService {
  static final Dio _dio = Dio();

  static Future<void> init() async {
    _dio.options.baseUrl = Constants.baseUrl;
    _dio.options.connectTimeout = Duration(seconds: 10);
    _dio.options.receiveTimeout = Duration(seconds: 15);
    _dio.options.headers = {'Content-Type': 'application/json'};

    // Add interceptor to attach JWT token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await AuthService.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
          _logger.fine('Added Authorization header with token');
        } else {
          _logger.warning('No token available for request: ${options.path}');
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        if (error.response?.statusCode == 401) {
          _logger.warning('Unauthorized request: ${error.requestOptions.path}. Logging out.');
          await AuthService.logout();
          // Optionally trigger navigation to login screen via a provider or event
        }
        return handler.next(error);
      },
    ));

    _logger.info('ApiService initialized with base URL: ${Constants.baseUrl}');
  }

  // Generic GET method
  static Future<Response> get(
    String path, {
    Map<String, dynamic>? headers,
    ResponseType? responseType,
    Options? options,
  }) async {
    final mergedOptions = options ??
        Options(
          headers: headers,
          responseType: responseType,
        );
    
    final url = _dio.options.baseUrl + path;
    print("📌 Requesting URL: $url");
    try {
      return await _dio.get(path, options: mergedOptions);
    } on DioException catch (e) {
      _logger.severe('GET request failed: $path, Error: ${e.message}');
      rethrow;
    }
  }

  // Generic POST method
  static Future<Response> post(
    String path,
    dynamic data, {
    Map<String, dynamic>? headers,
    ResponseType? responseType,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        options: Options(
          headers: headers,
          responseType: responseType,
        ),
      );
    } on DioException catch (e) {
      _logger.severe('POST request failed: $path, Error: ${e.message}');
      rethrow;
    }
  }

  // Generic PUT method
  static Future<Response> put(
    String path,
    dynamic data, {
    Map<String, dynamic>? headers,
    ResponseType? responseType,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        options: Options(
          headers: headers,
          responseType: responseType,
        ),
      );
    } on DioException catch (e) {
      _logger.severe('PUT request failed: $path, Error: ${e.message}');
      rethrow;
    }
  }

  // Generic DELETE method
  static Future<Response> delete(
    String path, {
    Map<String, dynamic>? headers,
    ResponseType? responseType,
  }) async {
    try {
      return await _dio.delete(
        path,
        options: Options(
          headers: headers,
          responseType: responseType,
        ),
      );
    } on DioException catch (e) {
      _logger.severe('DELETE request failed: $path, Error: ${e.message}');
      rethrow;
    }
  }

  // Fetch all users
  static Future<List<User>> getUsers() async {
    try {
      final response = await _dio.get('/users/');
      final List<dynamic> data = response.data;
      return data.map((json) => User.fromJson(json)).toList();
    } on DioException catch (e) {
      _logger.severe('Failed to load users: ${e.message}');
      throw Exception('Failed to load users: ${e.message}');
    }
  }

  // Add a new user
  static Future<void> addUser(Map<String, dynamic> userData) async {
    try {
      await _dio.post('/users/', data: userData);
    } on DioException catch (e) {
      _logger.severe('Failed to add user: ${e.message}');
      throw Exception('Failed to add user: ${e.message}');
    }
  }

  // Update an existing user
  static Future<void> updateUser(int userId, Map<String, dynamic> userData) async {
    try {
      await _dio.put('/users/$userId/', data: userData);
    } on DioException catch (e) {
      _logger.severe('Failed to update user $userId: ${e.message}');
      throw Exception('Failed to update user: ${e.message}');
    }
  }

  // Delete a user
  static Future<void> deleteUser(int userId) async {
    try {
      await _dio.delete('/users/$userId/');
    } on DioException catch (e) {
      _logger.severe('Failed to delete user $userId: ${e.message}');
      throw Exception('Failed to delete user: ${e.message}');
    }
  }

  // Fetch a specific grievance by ID
  static Future<Response> getGrievance(int id) async {
    try {
      final response = await _dio.get('/grievances/$id');
      return response;
    } on DioException catch (e) {
      _logger.severe('Failed to fetch grievance $id: ${e.message}');
      throw Exception('Failed to fetch grievance: ${e.message}');
    }
  }

  static Dio get dio => _dio;
}