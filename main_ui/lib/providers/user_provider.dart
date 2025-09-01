import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'api_provider.dart';

class UserNotifier extends StateNotifier<List<User>> {
  UserNotifier() : super([]) {
    // Initialize by fetching users on creation
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      final users = await UserService.getUsers();
      state = users ?? []; // Handle null response
    } catch (e) {
      print('Error fetching users: $e');
      state = []; // Reset state on error
    }
  }

  Future<void> addUser(Map<String, dynamic> userData) async {
    try {
      await UserService.addUser(userData); // Static call
      await fetchUsers(); // Refresh user list
    } catch (e) {
      print('Error adding user: $e');
    }
  }

  Future<void> updateUser(int userId, Map<String, dynamic> userData) async {
    try {
      await UserService.updateUser(userId, userData); // Static call
      await fetchUsers(); // Refresh user list
    } catch (e) {
      print('Error updating user: $e');
    }
  }

  Future<void> deleteUser(int userId) async {
    try {
      await UserService.deleteUser(userId); // Static call
      await fetchUsers(); // Refresh user list
    } catch (e) {
      print('Error deleting user: $e');
    }
  }
}

final userProvider = StateNotifierProvider<UserNotifier, List<User>>((ref) {
  return UserNotifier();
});