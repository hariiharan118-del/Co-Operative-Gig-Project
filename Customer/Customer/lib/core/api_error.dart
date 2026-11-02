import 'package:dio/dio.dart';

import 'env.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

String? messageFromDio(DioException error) {
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
  if (status != null) return 'Request failed (HTTP $status).';
  return error.message;
}

Never throwFromDio(DioException error, String fallback) {
  throw ApiException(messageFromDio(error) ?? fallback);
}

bool looksLikeUuid(String value) {
  return RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);
}
