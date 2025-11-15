import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw Exception('Ошибка регистрации: ${e.message}');
    } catch (e) {
      throw Exception('Неизвестная ошибка: $e');
    }
  }

  Future<bool> isEmailVerified() async {
    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        final emailConfirmedAt = user.emailConfirmedAt;
        print('Время подтверждения: $emailConfirmedAt');
        return emailConfirmedAt != null;
      }
      return false;
    }
    catch (e) {
      print('Ошибка проверки email: $e');
      return false;
    }
  }



  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw Exception('Ошибка входа: ${e.message}');
    } catch (e) {
      throw Exception('Неизвестная ошибка: $e');
    }
  }

  // Выход
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw Exception('Ошибка выхода: ${e.message}');
    } catch (e) {
      throw Exception('Неизвестная ошибка: $e');
    }
  }

  // Получение текущего пользователя
  User? get currentUser => _client.auth.currentUser;

  // Проверка, авторизован ли пользователь
  bool get isLoggedIn => currentUser != null;

  // Stream для отслеживания состояния аутентификации
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Восстановление пароля
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception('Ошибка восстановления пароля: ${e.message}');
    } catch (e) {
      throw Exception('Неизвестная ошибка: $e');
    }
  }

  // Обновление профиля пользователя
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    try {
      final user = currentUser;
      if (user != null) {
        await _client.from('profiles').update(data).eq('id', user.id);
      }
    } on PostgrestException catch (e) {
      throw Exception('Ошибка обновления профиля: ${e.message}');
    } catch (e) {
      throw Exception('Неизвестная ошибка: $e');
    }
  }

  // Получение профиля пользователя
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = currentUser;
      if (user != null) {
        final response = await _client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();
        return response;
      }
      return null;
    } on PostgrestException catch (e) {
      throw Exception('Ошибка получения профиля: ${e.message}');
    } catch (e) {
      throw Exception('Неизвестная ошибка: $e');
    }
  }
}