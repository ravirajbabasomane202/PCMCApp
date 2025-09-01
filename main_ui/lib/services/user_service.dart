// user_service.dart
import 'package:dio/dio.dart';
import 'package:main_ui/models/user_model.dart';
import 'package:main_ui/services/api_service.dart';

class UserService {
  /// Fetch all users
  static Future<List<User>> getUsers() async {
    try {
      print('Fetching all users...'); // Debug log
      final response = await ApiService.get(
        '/admin/users',
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.data == null || response.data is! List) {
        throw Exception('Invalid response format: Expected a list of users');
      }

      print('Fetched users: ${response.data.length}'); // Debug log
      return (response.data as List)
          .map((user) => User.fromJson(user as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      print('DioError during getUsers: ${e.message}');
      print('Response: ${e.response?.data}');
      print('Status: ${e.response?.statusCode}');

      if (e.response?.statusCode == 404) {
        throw Exception('Users endpoint not found. Check backend routes.');
      } else if (e.response?.statusCode == 405) {
        throw Exception('Invalid method. Use GET for listing users.');
      } else if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Network error: Unable to connect to the server');
      }
      throw Exception('Failed to load users: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error while loading users: $e');
    }
  }

  /// Add a new user
  static Future<User> addUser(Map<String, dynamic> data) async {
    try {
      print('Adding new user with data: $data'); // Debug log
      final response = await ApiService.post(
        '/admin/users',
        data,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Add user response: ${response.data}'); // Debug log
      return User.fromJson(response.data);
    } on DioException catch (e) {
      print('DioError during addUser: ${e.message}');
      print('Response: ${e.response?.data}');
      print('Status: ${e.response?.statusCode}');
      throw Exception('Failed to add user: ${e.response?.data?['msg'] ?? e.message}');
    } catch (e) {
      throw Exception('Unexpected error while adding user: $e');
    }
  }

  /// Update an existing user
  static Future<User> updateUser(int id, Map<String, dynamic> data) async {
    try {
      print('Updating user $id with data: $data'); // Debug log
      final response = await ApiService.put(
        '/admin/users/$id',
        data,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('Update response: ${response.data}'); // Debug log
      return User.fromJson(response.data);
    } on DioException catch (e) {
      print('DioError during update: ${e.message}');
      print('Response: ${e.response?.data}');
      print('Status: ${e.response?.statusCode}');

      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network error: Unable to connect to the server. Check if the server is running.');
      } else if (e.response != null) {
        throw Exception('Failed to update user: ${e.response?.data?['msg'] ?? e.message}');
      }
      throw Exception('Failed to update user: ${e.message}');
    } catch (e) {
      print('Unexpected error during update: $e');
      throw Exception('Unexpected error while updating user: $e');
    }
  }

  /// Delete a user
  static Future<void> deleteUser(int id) async {
    try {
      print('Deleting user $id...'); // Debug log
      final response = await ApiService.delete(
        '/admin/users/$id',
        headers: {
          'Accept': 'application/json',
        },
      );
      print('Delete response: ${response.data}'); // Debug log
    } on DioException catch (e) {
      print('DioError during deleteUser: ${e.message}');
      print('Response: ${e.response?.data}');
      print('Status: ${e.response?.statusCode}');
      throw Exception('Failed to delete user: ${e.response?.data?['msg'] ?? e.message}');
    } catch (e) {
      throw Exception('Unexpected error while deleting user: $e');
    }
  }
}
