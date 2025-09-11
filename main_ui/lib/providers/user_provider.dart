import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:main_ui/models/user_model.dart';
import 'package:main_ui/services/auth_service.dart';
import 'package:main_ui/services/api_service.dart';

// Notifier for the current authenticated user
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
      
      state = null;
    }
  }

  Future<void> refreshUser() async {
    await fetchCurrentUser();
  }

  Future<void> updateUser() async {
    try {
      final response = await ApiService.get('/settings/user'); // Fetch updated user data
      if (response != null && response.data != null) {
        state = User.fromJson(response.data); // Update state with new user data
      }
    } catch (e) {
      
      rethrow; 
    }
  }

  void setUser(User? user) {
    state = user;
  }
}

// Define the user provider
final userNotifierProvider = StateNotifierProvider<UserNotifier, User?>((ref) {
  return UserNotifier(ref);
});

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
      state = users;
    } catch (e) {
    
      state = [];
    }
  }

  // Add or update a user
  Future<void> addUser(Map<String, dynamic> userData) async {
    try {
      // Convert dynamic values to strings for ApiService.addUpdateUser
      final stringUserData = userData.map((key, value) => MapEntry(key, value.toString()));
      await ApiService.addUpdateUser(stringUserData);
      await fetchUsers(); // Refresh the user list
    } catch (e) {
      
      rethrow; // Let UI handle errors
    }
  }

  // Update an existing user
  Future<void> updateUser(int userId, Map<String, dynamic> userData) async {
  try {
    final cleanData = {
      'id': userId.toString(),
      ...userData.map((key, value) => MapEntry(
            key,
            key == 'department_id' && value != null
                ? value.toString() // always send as string
                : key == 'role'
                    ? value.toString().toLowerCase() // lowercase role
                    : value.toString(),
          )),
    };

    await ApiService.addUpdateUser(cleanData); // expects Map<String, String>
    await fetchUsers();
  } catch (e) {
    
    rethrow;
  }
}


  // Delete a user
  Future<void> deleteUser(int userId) async {
    try {
      await ApiService.deleteUser(userId);
      await fetchUsers(); // Refresh the user list
      // If the deleted user is the current user, clear userNotifierProvider
      if (ref.read(userNotifierProvider)?.id == userId) {
        ref.read(userNotifierProvider.notifier).setUser(null);
      }
    } catch (e) {
      
      rethrow ;
    }
  }
}