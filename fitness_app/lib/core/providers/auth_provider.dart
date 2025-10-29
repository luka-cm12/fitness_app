import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';

// Simple auth provider for now - mock implementation
final authProvider = StateProvider<User?>((ref) => null);
final authLoadingProvider = StateProvider<bool>((ref) => false);

class AuthService {
  static Future<User?> login(String email, String password) async {
    // Mock login - replace with actual API call
    await Future.delayed(const Duration(seconds: 1));

    final user = User(
      id: 1,
      email: email,
      firstName: 'Test',
      lastName: 'User',
      userType: UserType.trainer,
      createdAt: DateTime.now(),
    );

    await StorageService.saveToken('mock_token');
    return user;
  }

  static Future<User?> register(String firstName, String lastName, String email,
      String password, UserType userType) async {
    // Mock registration - replace with actual API call
    await Future.delayed(const Duration(seconds: 1));

    final user = User(
      id: 1,
      email: email,
      firstName: firstName,
      lastName: lastName,
      userType: userType,
      createdAt: DateTime.now(),
    );

    await StorageService.saveToken('mock_token');
    return user;
  }

  static Future<void> logout() async {
    await StorageService.clearToken();
  }

  static Future<User?> getCurrentUser() async {
    final token = await StorageService.getToken();
    if (token != null) {
      // Mock user loading - replace with actual API call
      return User(
        id: 1,
        email: 'test@test.com',
        firstName: 'Test',
        lastName: 'User',
        userType: UserType.trainer,
        createdAt: DateTime.now(),
      );
    }
    return null;
  }
}
