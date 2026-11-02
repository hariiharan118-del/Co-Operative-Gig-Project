import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../core/socket_service.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_repository.dart';
import '../domain/auth_state.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(tokenStorage: ref.watch(tokenStorageProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(() {
      final client = ref.read(apiClientProvider);
      client.onSessionExpired = logout;
      client.onTokensRefreshed = applyRefreshedTokens;
      restoreSession();
    });
    return const AuthUnknown();
  }

  TokenStorage get _storage => ref.read(tokenStorageProvider);
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<void> restoreSession() async {
    final access = await _storage.readAccessToken();
    final refresh = await _storage.readRefreshToken();
    if (access == null || refresh == null) {
      await _storage.clear();
      state = const AuthUnauthenticated();
      return;
    }

    if (access.startsWith('demo-')) {
      var user = await _readStoredUser();
      user ??= const AuthUser(
        id: 'demo',
        phone: '+919876543210',
        name: 'Asha Rao',
        role: 'CUSTOMER',
      );
      state = AuthAuthenticated(
        AuthSession(accessToken: access, refreshToken: refresh, user: user),
      );
      return;
    }

    await _storage.clearUser();
    SocketService.instance.connect(accessToken: access);
    state = AuthAuthenticated(
      AuthSession(
        accessToken: access,
        refreshToken: refresh,
        user: _userFromAccessToken(access) ?? const AuthUser(id: '', phone: ''),
      ),
    );
    await refreshProfile();
  }

  Future<void> refreshProfile() async {
    final auth = state;
    if (auth is! AuthAuthenticated) return;
    if (auth.session.accessToken.startsWith('demo-')) return;
    final token = auth.session.accessToken;
    try {
      final user = await _repo.getMe();
      final current = state;
      if (current is! AuthAuthenticated ||
          current.session.accessToken != token) {
        return;
      }
      await _persistUser(user);
      state = AuthAuthenticated(
        AuthSession(
          accessToken: current.session.accessToken,
          refreshToken: current.session.refreshToken,
          user: user,
        ),
      );
    } catch (_) {
      // Keep this session's placeholder; never restore a previous user's cache.
    }
  }

  Future<void> register({
    required String phone,
    required String name,
    required String password,
  }) async {
    await _establishSession(
      await _repo.register(phone: phone, name: name, password: password),
      fallbackPhone: phone,
    );
  }

  Future<void> login({
    required String phone,
    required String password,
  }) async {
    await _establishSession(
      await _repo.login(phone: phone, password: password),
      fallbackPhone: phone,
    );
  }

  Future<PasswordResetChallenge> requestPasswordReset(String phone) {
    return _repo.requestPasswordReset(phone);
  }

  Future<void> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  }) {
    return _repo.resetPassword(
      phone: phone,
      otp: otp,
      newPassword: newPassword,
    );
  }

  Future<void> devLogin() async {
    const phone = '+919876543210';
    await _establishSession(
      await _repo.devLogin(phone: phone),
      fallbackPhone: phone,
    );
  }

  Future<void> _establishSession(
    AuthSession session, {
    required String fallbackPhone,
  }) async {
    state = const AuthLoading();
    try {
      SocketService.instance.disconnect(clearRooms: true);
      await _storage.clear();
      await _storage.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      SocketService.instance.connect(accessToken: session.accessToken);
      final placeholder = AuthUser(
        id: session.user?.id ?? '',
        phone: (session.user?.phone.isNotEmpty == true)
            ? session.user!.phone
            : fallbackPhone,
        role: session.user?.role ?? 'CUSTOMER',
      );
      state = AuthAuthenticated(
        AuthSession(
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
          user: placeholder,
        ),
      );
      await refreshProfile();
    } catch (error) {
      await _storage.clear();
      state = const AuthUnauthenticated();
      rethrow;
    }
  }

  Future<void> enterDemo() async {
    SocketService.instance.disconnect(clearRooms: true);
    await _storage.clear();
    const user = AuthUser(
      id: 'demo',
      phone: '+919876543210',
      name: 'Asha Rao',
      email: 'asha@example.com',
      role: 'CUSTOMER',
    );
    const session = AuthSession(
      accessToken: 'demo-access-token',
      refreshToken: 'demo-refresh-token',
      user: user,
    );
    await _storage.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    await _persistUser(user);
    state = const AuthAuthenticated(session);
  }

  Future<void> updateUser(AuthUser user) async {
    final auth = state;
    if (auth is! AuthAuthenticated) return;
    await _persistUser(user);
    state = AuthAuthenticated(
      AuthSession(
        accessToken: auth.session.accessToken,
        refreshToken: auth.session.refreshToken,
        user: user,
      ),
    );
  }

  Future<void> saveCustomerProfile({
    required String name,
    String? email,
  }) async {
    final auth = state;
    if (auth is! AuthAuthenticated) return;
    if (!auth.session.accessToken.startsWith('demo-')) {
      await _repo.saveCustomerProfile(name: name, email: email);
    }
    final latest = state;
    if (latest is! AuthAuthenticated) return;
    final current = latest.session.user;
    final next = (current ?? AuthUser(id: '', phone: '')).copyWith(
      name: name,
      email: email,
    );
    await updateUser(next);
  }

  void applyRefreshedTokens(String accessToken, String refreshToken) {
    final auth = state;
    if (auth is! AuthAuthenticated) return;
    if (accessToken.isEmpty || accessToken.startsWith('demo-')) return;
    if (auth.session.accessToken == accessToken &&
        auth.session.refreshToken == refreshToken) {
      return;
    }
    SocketService.instance.connect(accessToken: accessToken);
    state = AuthAuthenticated(
      AuthSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: auth.session.user,
      ),
    );
  }

  Future<void> logout() async {
    await _storage.clear();
    SocketService.instance.disconnect(clearRooms: true);
    state = const AuthUnauthenticated();
  }

  Future<void> _persistUser(AuthUser? user) async {
    if (user == null) return;
    await _storage.saveUserJson(jsonEncode(user.toJson()));
  }

  Future<AuthUser?> _readStoredUser() async {
    final raw = await _storage.readUserJson();
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      if (json is Map<String, dynamic>) return AuthUser.fromJson(json);
    } catch (_) {}
    return null;
  }

  AuthUser? _userFromAccessToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final json = jsonDecode(payload);
      if (json is! Map<String, dynamic>) return null;
      final user = AuthUser.fromJson(json);
      if (user.phone.isEmpty) return null;
      return user;
    } catch (_) {
      return null;
    }
  }
}
