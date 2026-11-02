import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'env.dart';
import 'storage/token_storage.dart';

/// HTTP client that attaches a JWT access token and refreshes on 401.
class ApiClient {
  ApiClient({
    required TokenStorage tokenStorage,
    Dio? dio,
    Dio? refreshDio,
  })  : _tokenStorage = tokenStorage,
        _refreshDio = refreshDio ??
            Dio(
              BaseOptions(
                baseUrl: Env.apiBaseUrl,
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 20),
                headers: const {'Content-Type': 'application/json'},
              ),
            ) {
    _dio = dio ??
        Dio(
          BaseOptions(
            baseUrl: Env.apiBaseUrl,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
            headers: const {'Content-Type': 'application/json'},
          ),
        );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }

  final TokenStorage _tokenStorage;
  late final Dio _dio;
  final Dio _refreshDio;
  Completer<void>? _refreshLock;
  void Function()? onSessionExpired;
  void Function(String accessToken, String refreshToken)? onTokensRefreshed;

  Dio get dio => _dio;

  static bool _isPublicAuthPath(String path) {
    final normalized = path.toLowerCase();
    return normalized.contains('/auth/register') ||
        normalized.contains('/auth/login') ||
        normalized.contains('/auth/forgot-password') ||
        normalized.contains('/auth/refresh') ||
        normalized.contains('/auth/logout') ||
        normalized.contains('/auth/dev-login') ||
        normalized.contains('/services') ||
        normalized.contains('/health');
  }

  static bool _isDemoToken(String? token) {
    return token != null && token.startsWith('demo-');
  }

  static bool _isAccessTokenExpired(
    String token, {
    // Small skew: refresh just before expiry so proactive refresh rarely
    // blocks ordinary requests with a full round-trip.
    Duration skew = const Duration(seconds: 5),
  }) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map<String, dynamic>) return false;
      final exp = payload['exp'];
      if (exp is! num) return false;
      final expiry = DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
      return DateTime.now().isAfter(expiry.subtract(skew));
    } catch (_) {
      return false;
    }
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isPublicAuthPath(options.path)) {
      handler.next(options);
      return;
    }
    final token = await _ensureFreshAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    } else {
      options.headers.remove('Authorization');
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final alreadyRetried = err.requestOptions.extra['retried'] == true;
    if (status != 401 ||
        alreadyRetried ||
        _isPublicAuthPath(err.requestOptions.path)) {
      handler.next(err);
      return;
    }

    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null ||
        refreshToken.isEmpty ||
        _isDemoToken(refreshToken)) {
      handler.next(err);
      return;
    }

    try {
      await _refreshAccessToken();
      final token = await _tokenStorage.readAccessToken();
      if (token == null || token.isEmpty) {
        throw StateError('Missing access token after refresh');
      }
      final request = err.requestOptions;
      request.headers['Authorization'] = 'Bearer $token';
      request.extra['retried'] = true;
      final response = await _dio.fetch(request);
      handler.resolve(response);
    } catch (_) {
      await _tokenStorage.clear();
      onSessionExpired?.call();
      handler.next(err);
    }
  }

  Future<String?> _ensureFreshAccessToken() async {
    final access = await _tokenStorage.readAccessToken();
    if (access == null || access.isEmpty || _isDemoToken(access)) {
      return access;
    }
    if (!_isAccessTokenExpired(access)) return access;

    final refresh = await _tokenStorage.readRefreshToken();
    if (refresh == null || refresh.isEmpty || _isDemoToken(refresh)) {
      return access;
    }

    try {
      await _refreshAccessToken();
      return _tokenStorage.readAccessToken();
    } catch (_) {
      return access;
    }
  }

  Future<void> _refreshAccessToken() async {
    final inFlight = _refreshLock;
    if (inFlight != null) return inFlight.future;

    final lock = Completer<void>();
    _refreshLock = lock;
    unawaited(lock.future.catchError((_) {}));

    try {
      final refreshToken = await _tokenStorage.readRefreshToken();
      if (refreshToken == null ||
          refreshToken.isEmpty ||
          _isDemoToken(refreshToken)) {
        throw StateError('No refresh token');
      }
      final response = await _refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = response.data ?? const {};
      final access = data['accessToken'] as String?;
      if (access == null || access.isEmpty) {
        throw StateError('Refresh response missing accessToken');
      }
      final nextRefresh = data['refreshToken'] as String? ?? refreshToken;
      await _tokenStorage.saveTokens(
        accessToken: access,
        refreshToken: nextRefresh,
      );
      onTokensRefreshed?.call(access, nextRefresh);
      if (!lock.isCompleted) lock.complete();
    } catch (error, stack) {
      if (!lock.isCompleted) {
        lock.completeError(error, stack);
      }
    } finally {
      _refreshLock = null;
    }
    return lock.future;
  }
}
