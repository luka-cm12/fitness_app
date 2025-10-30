import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';

// Simple auth providers
final authProvider = StateProvider<User?>((ref) => null);
final authLoadingProvider = StateProvider<bool>((ref) => false);

// Auth service with ref parameter for state management
class AuthStateService {
  static Future<void> login(
      WidgetRef ref, String email, String password) async {
    ref.read(authLoadingProvider.notifier).state = true;
    try {
      final user = await AuthService.login(email, password);
      ref.read(authProvider.notifier).state = user;
    } catch (error) {
      // Handle error
      rethrow;
    } finally {
      ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  static Future<void> register(WidgetRef ref, String firstName, String lastName,
      String email, String password, UserType userType) async {
    ref.read(authLoadingProvider.notifier).state = true;
    try {
      final user = await AuthService.register(
          firstName, lastName, email, password, userType);
      ref.read(authProvider.notifier).state = user;
    } catch (error) {
      // Handle error
      rethrow;
    } finally {
      ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  static Future<void> logout(WidgetRef ref) async {
    try {
      await AuthService.logout();
      ref.read(authProvider.notifier).state = null;
    } catch (error) {
      // Handle error
      rethrow;
    }
  }
}

// Mock of a notifier-like object for compatibility
class MockAuthNotifier {
  final WidgetRef ref;

  MockAuthNotifier(this.ref);

  Future<void> login(String email, String password) async {
    return AuthStateService.login(ref, email, password);
  }

  Future<void> register(String firstName, String lastName, String email,
      String password, UserType userType) async {
    return AuthStateService.register(
        ref, firstName, lastName, email, password, userType);
  }

  Future<void> logout() async {
    return AuthStateService.logout(ref);
  }
}

// Compatibility provider that returns AsyncValue
final authStateProvider = Provider<AsyncValue<User?>>((ref) {
  final user = ref.watch(authProvider);
  final isLoading = ref.watch(authLoadingProvider);

  if (isLoading) {
    return const AsyncValue.loading();
  }

  return AsyncValue.data(user);
});

// Helper provider to get notifier-like object
final authNotifierHelperProvider =
    Provider<MockAuthNotifier>((ref) => MockAuthNotifier(ref as WidgetRef));

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
