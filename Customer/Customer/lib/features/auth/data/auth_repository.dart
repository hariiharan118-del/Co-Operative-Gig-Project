import 'package:dio/dio.dart';

import '../../../core/api_client.dart';
import '../../../core/env.dart';
import '../domain/auth_state.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

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
        data: {
          'phone': phone,
          'password': password,
        },
      );
      return _sessionFrom(response.data, fallbackPhone: phone);
    } on DioException catch (error) {
      throw AuthException(_messageFrom(error) ?? 'Could not log in');
    }
  }

  Future<PasswordResetChallenge> requestPasswordReset(String phone) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        '/auth/forgot-password/request',
        data: {'phone': phone},
      );
      final data = response.data ?? const <String, dynamic>{};
      final otp = data['otp'];
      return PasswordResetChallenge(
        phone: phone,
        debugOtp: otp is String && otp.isNotEmpty ? otp : null,
      );
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
        data: {'phone': phone},
      );
      return _sessionFrom(response.data, fallbackPhone: phone);
    } on DioException catch (error) {
      throw AuthException(_messageFrom(error) ?? 'Dev login failed');
    }
  }

  Future<AuthUser> getMe() async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>('/auth/me');
      final data = response.data;
      if (data == null) throw AuthException('Profile response was empty');
      return AuthUser.fromJson(data);
    } on DioException catch (error) {
      throw AuthException(_messageFrom(error) ?? 'Could not load profile');
    }
  }

  Future<void> saveCustomerProfile({
    required String name,
    String? email,
  }) async {
    try {
      await _api.dio.put<Map<String, dynamic>>(
        '/users/customer/me',
        data: {
          'name': name,
          if (email != null && email.isNotEmpty) 'email': email,
        },
      );
    } on DioException catch (error) {
      throw AuthException(_messageFrom(error) ?? 'Could not save profile');
    }
  }

  AuthSession _sessionFrom(Map<String, dynamic>? data, {required String fallbackPhone}) {
    final access = data?['accessToken'] as String?;
    final refresh = data?['refreshToken'] as String?;
    if (access == null || refresh == null) {
      throw AuthException('Auth response missing tokens');
    }
    final userJson = data?['user'];
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
    final status = error.response?.statusCode;
    if (status != null) {
      return 'Could not continue (HTTP $status).';
    }
    return error.message;
  }
}
