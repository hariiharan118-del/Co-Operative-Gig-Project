import 'package:dio/dio.dart';

import '../../../core/api_client.dart';
import '../../../core/env.dart';
import '../domain/auth_state.dart';

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  Future<AuthSession> register({
    required String phone,
    required String name,
    required String password,
  }) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'phone': phone,
          'name': name,
          'password': password,
          'role': 'WORKER',
        },
      );
      return _sessionFrom(response.data, fallbackPhone: phone);
    } on DioException catch (error) {
      throw AuthException(_messageFrom(error) ?? 'Could not create account');
    }
  }

  Future<AuthSession> login({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'phone': phone, 'password': password},
      );
      return _sessionFrom(response.data, fallbackPhone: phone);
    } on DioException catch (error) {
      throw AuthException(_messageFrom(error) ?? 'Login failed');
    }
  }

  Future<String?> requestPasswordReset(String phone) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        '/auth/forgot-password/request',
        data: {'phone': phone},
      );
      final otp = response.data?['otp'];
      return otp is String && otp.isNotEmpty ? otp : null;
    } on DioException catch (error) {
      throw AuthException(_messageFrom(error) ?? 'Could not send reset code');
    }
  }

  Future<void> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    try {
      await _api.dio.post<Map<String, dynamic>>(
        '/auth/forgot-password/reset',
        data: {
          'phone': phone,
          'otp': otp,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (error) {
      throw AuthException(_messageFrom(error) ?? 'Could not reset password');
    }
  }

  Future<AuthSession> devLogin({required String phone}) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        '/auth/dev-login',
        data: {'phone': phone, 'role': 'WORKER'},
      );
      return _sessionFrom(response.data, fallbackPhone: phone);
    } on DioException catch (error) {
      throw AuthException(_messageFrom(error) ?? 'Dev login failed');
    }
  }

  Future<Map<String, dynamic>> getMeJson() async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>('/auth/me');
      final data = response.data;
      if (data == null) throw AuthException('Profile response was empty');
      return data;
    } on DioException catch (error) {
      throw AuthException(_messageFrom(error) ?? 'Could not load profile');
    }
  }

  Future<AuthUser> getMe() async {
    return AuthUser.fromJson(await getMeJson());
  }

  Future<void> saveWorkerProfile({
    required String name,
    required String city,
    String? state,
  }) async {
    try {
      await _api.dio.patch<Map<String, dynamic>>(
        '/users/worker/me',
        data: {
          if (name.isNotEmpty) 'name': name,
          'city': city,
          if (state != null && state.isNotEmpty) 'state': state,
        },
      );
    } on DioException catch (error) {
      throw AuthException(_messageFrom(error) ?? 'Could not save profile');
    }
  }

  Future<void> addWorkerSkill(String categoryId) async {
    try {
      await _api.dio.post<dynamic>(
        '/users/worker/me/skills',
        data: {'categoryId': categoryId},
      );
    } on DioException catch (error) {
      throw AuthException(_messageFrom(error) ?? 'Could not add skill');
    }
  }

  Future<void> removeWorkerSkill(String categoryId) async {
    try {
      await _api.dio.delete<dynamic>('/users/worker/me/skills/$categoryId');
    } on DioException catch (error) {
      throw AuthException(_messageFrom(error) ?? 'Could not remove skill');
    }
  }

  AuthSession _sessionFrom(
    Map<String, dynamic>? data, {
    required String fallbackPhone,
  }) {
    final body = data ?? const <String, dynamic>{};
    final access = body['accessToken'] as String?;
    final refresh = body['refreshToken'] as String?;
    if (access == null || refresh == null) {
      throw AuthException('Login response missing tokens');
    }
    final userJson = body['user'];
    return AuthSession(
      accessToken: access,
      refreshToken: refresh,
      user: userJson is Map<String, dynamic>
          ? AuthUser.fromJson(userJson)
          : AuthUser(id: '', phone: fallbackPhone),
    );
  }

  String? _messageFrom(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final nested = data['error'];
      if (nested is Map && nested['message'] is String) {
        return nested['message'] as String;
      }
      if (data['message'] is String) {
        return data['message'] as String;
      }
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Cannot reach the API at ${Env.apiBaseUrl}. Start the backend, then try again.';
    }
    return error.message;
  }
}
