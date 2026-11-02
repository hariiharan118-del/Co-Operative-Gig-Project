import 'package:dio/dio.dart';

/// Human-readable API/network error for snackbars and release logs.
String describeApiError(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    final body = _bodyMessage(error.response?.data);
    final parts = <String>[
      if (status != null) 'HTTP $status',
      if (error.requestOptions.uri.toString().isNotEmpty)
        error.requestOptions.uri.toString(),
      if (body != null) body,
      if (body == null && (error.message ?? '').isNotEmpty) error.message!,
    ];
    if (parts.isNotEmpty) return parts.join(' — ');
  }
  final text = error.toString().trim();
  return text.isEmpty ? error.runtimeType.toString() : text;
}

String? _bodyMessage(dynamic data) {
  if (data == null) return null;
  if (data is String) {
    final trimmed = data.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  if (data is Map) {
    final nested = data['error'];
    if (nested is Map && nested['message'] != null) {
      return nested['message'].toString();
    }
    final message = data['message'] ?? data['error'] ?? data['detail'];
    if (message != null) return message.toString();
    return data.toString();
  }
  return data.toString();
}
