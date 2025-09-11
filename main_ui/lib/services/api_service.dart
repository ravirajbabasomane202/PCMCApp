import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:main_ui/models/user_model.dart';
import 'package:main_ui/services/auth_service.dart';
import 'package:main_ui/utils/constants.dart';
import 'package:logging/logging.dart';
import 'package:file_picker/file_picker.dart';

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

  // Generic POST method for multipart data (file uploads)
// Generic POST method for multipart data (file uploads)
static Future<Response> postMultipart(
  String path, {
  required List<PlatformFile> files,
  Map<String, dynamic>? data,
  String fieldName = 'files', // ✅ default field name
}) async {
  try {
    final formData = FormData.fromMap({
      ...?data,
      fieldName: files.length == 1
          ? await MultipartFile.fromBytes(files.first.bytes!, filename: files.first.name)
          : files
              .map((file) => MultipartFile.fromBytes(file.bytes!, filename: file.name))
              .toList(),
    });

    return await _dio.post(
      path,
      data: formData,
    );
  } on DioException catch (e) {
    _logger.severe('Multipart POST request failed: $path, Error: ${e.message}');
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

  // Add or update a user
  static Future<Map<String, dynamic>> addUpdateUser(Map<String, String> userData) async {
    try {
      final response = await _dio.put('admins/users', data: userData);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _logger.severe('Failed to add/update user: ${e.message}');
      throw Exception('Failed to add/update user: ${e.message}');
    }
  }

  // Upload profile picture
  static Future<Map<String, dynamic>> uploadProfilePicture(PlatformFile file) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(file.bytes!, filename: file.name),
      });
      final response = await _dio.post('/users/profile-picture', data: formData);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _logger.severe('Failed to upload profile picture: ${e.message}');
      throw Exception('Failed to upload profile picture: ${e.message}');
    }
  }
  

static Future<User> updateProfile({
  String? name,
  String? email,
  String? password,
  String? address,
  PlatformFile? profilePic,
}) async {
  try {
    final token = await AuthService.getToken();

    final Map<String, dynamic> fields = {};

    if (name != null) fields['name'] = name;
    if (email != null) fields['email'] = email;
    if (password != null && password.isNotEmpty) fields['password'] = password;
    if (address != null) fields['address'] = address;

    // Handle file upload (web vs mobile)
    if (profilePic != null) {
      if (kIsWeb) {
        fields['profile_picture'] = MultipartFile.fromBytes(
          profilePic.bytes!,
          filename: profilePic.name,
        );
      } else {
        fields['profile_picture'] = await MultipartFile.fromFile(
          profilePic.path!,
          filename: profilePic.name,
        );
      }
    }

    final formData = FormData.fromMap(fields);

    final response = await _dio.put(
      '/auth/me',
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    return User.fromJson(response.data as Map<String, dynamic>);
  } on DioException catch (e) {
    final errorMsg = e.response?.data ?? e.message;
    _logger.severe('Failed to update profile: $errorMsg');
    throw Exception('Failed to update profile: $errorMsg');
  }
}

  // Fetch area by ID
  static Future<Map<String, dynamic>?> getMasterArea(int areaId) async {
    try {
      final response = await _dio.get('/areas/$areaId');
      return response.data as Map<String, dynamic>?;
    } on DioException catch (e) {
      _logger.severe('Failed to fetch area $areaId: ${e.message}');
      throw Exception('Failed to fetch area: ${e.message}');
    }
  }

  // Delete a user
  static Future<void> deleteUser(int userId) async {
    try {
      await _dio.delete('/admins/users/$userId');
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