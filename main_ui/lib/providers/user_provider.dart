// lib/providers/user_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:main_ui/models/user_model.dart';
import 'package:main_ui/services/auth_service.dart';
import 'package:main_ui/services/api_service.dart';

// Provider for the current authenticated user
final userProvider = StateProvider<User?>((ref) => null);

// Provider for managing a list of users (for admin)
final usersProvider = StateNotifierProvider<UsersNotifier, List<User>>((ref) {
  return UsersNotifier(ref);
});

// Notifier for managing a list of users
class UsersNotifier extends StateNotifier<List<User>> {
  UsersNotifier(this.ref) : super([]) {
    fetchUsers(); // Initialize by fetching users
  }

  final Ref ref;

  // Fetch all users from the backend
  Future<void> fetchUsers() async {
    try {
      final users = await ApiService.getUsers(); // Assume ApiService method
      state = users ?? [];
    } catch (e) {
      print('Error fetching users: $e');
      state = [];
    }
  }

  // Add a new user
  Future<void> addUser(Map<String, dynamic> userData) async {
    try {
      await ApiService.addUser(userData);
      await fetchUsers(); // Refresh the user list
    } catch (e) {
      print('Error adding user: $e');
      throw e; // Let UI handle errors
    }
  }

  // Update an existing user
  Future<void> updateUser(int userId, Map<String, dynamic> userData) async {
    try {
      await ApiService.updateUser(userId, userData);
      await fetchUsers(); // Refresh the user list
      // If the updated user is the current user, refresh userProvider
      if (ref.read(userProvider)?.id == userId) {
        final updatedUser = await AuthService.getCurrentUser();
        ref.read(userProvider.notifier).state = updatedUser;

      }
    } catch (e) {
      print('Error updating user: $e');
      throw e;
    }
  }

  // Delete a user
  Future<void> deleteUser(int userId) async {
    try {
      await ApiService.deleteUser(userId);
      await fetchUsers(); // Refresh the user list
      // If the deleted user is the current user, clear userProvider
      if (ref.read(userProvider)?.id == userId) {
        ref.read(userProvider.notifier).state = null;
      }
    } catch (e) {
      print('Error deleting user: $e');
      throw e;
    }
  }
}

// Notifier for the current authenticated user (unchanged)
class UserNotifier extends StateNotifier<User?> {
  UserNotifier(this.ref) : super(null) {
    fetchCurrentUser();
  }

  final Ref ref;

  Future<void> fetchCurrentUser() async {
    try {
      final user = await AuthService.getCurrentUser();
      state = user;
    } catch (e) {
      print('Error fetching current user: $e');
      state = null;
    }
  }

  Future<void> refreshUser() async {
    await fetchCurrentUser();
  }
}

final userNotifierProvider = StateNotifierProvider<UserNotifier, User?>((ref) {
  return UserNotifier(ref);
});