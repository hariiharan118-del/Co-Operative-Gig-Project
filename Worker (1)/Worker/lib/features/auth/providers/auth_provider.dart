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
    final client = ref.read(apiClientProvider);
    client.onSessionInvalid = () {
      SocketService.instance.disconnect(clearRooms: true);
      if (state is! AuthUnauthenticated) {
        state = const AuthUnauthenticated();
      }
    };
    client.onTokensRefreshed = applyRefreshedTokens;
    Future.microtask(restoreSession);
    return const AuthUnknown();
  }

  TokenStorage get _storage => ref.read(tokenStorageProvider);
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<void> restoreSession() async {
    final access = await _storage.readAccessToken();
    final refresh = await _storage.readRefreshToken();
    if (access == null ||
        refresh == null ||
        !ApiClient.isBackendRefreshToken(refresh)) {
      await _storage.clear();
      state = const AuthUnauthenticated();
      return;
    }
    final user = await _loadMe();
    SocketService.instance.connect(accessToken: access);
    state = AuthAuthenticated(
      AuthSession(
        accessToken: access,
        refreshToken: refresh,
        user: user,
      ),
    );
  }

  Future<void> register({
    required String phone,
    required String name,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      await _completeLogin(
        await _repo.register(
          phone: phone,
          name: name,
          password: password,
        ),
      );
    } catch (error) {
      state = const AuthUnauthenticated();
      rethrow;
    }
  }

  Future<void> login({
    required String phone,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      await _completeLogin(
        await _repo.login(
          phone: phone,
          password: password,
        ),
      );
    } catch (error) {
      state = const AuthUnauthenticated();
      rethrow;
    }
  }

  Future<String?> requestPasswordReset(String phone) {
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
    state = const AuthLoading();
    try {
      await _completeLogin(
        await _repo.devLogin(phone: '+919876543211'),
      );
    } catch (error) {
      state = const AuthUnauthenticated();
      rethrow;
    }
  }

  Future<void> _completeLogin(AuthSession session) async {
    SocketService.instance.disconnect(clearRooms: true);
    await _storage.clear();
    state = const AuthLoading();
    await _storage.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    SocketService.instance.connect(accessToken: session.accessToken);
    final placeholder = AuthUser(
      id: session.user?.id ?? '',
      phone: session.user?.phone ?? '',
      role: session.user?.role ?? 'WORKER',
    );
    final user = await _loadMe();
    state = AuthAuthenticated(
      AuthSession(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        user: user ?? placeholder,
      ),
    );
  }

  void syncUser(AuthUser user) {
    final auth = state;
    if (auth is! AuthAuthenticated) return;
    final currentPhone = auth.session.user?.phone ?? '';
    if (currentPhone.isNotEmpty &&
        user.phone.isNotEmpty &&
        currentPhone != user.phone) {
      return;
    }
    state = AuthAuthenticated(
      AuthSession(
        accessToken: auth.session.accessToken,
        refreshToken: auth.session.refreshToken,
        user: user,
      ),
    );
  }

  /// Keeps in-memory session + socket auth in sync after silent refresh.
  /// Socket reconnect is synchronous (no artificial delay).
  void applyRefreshedTokens(String accessToken, String refreshToken) {
    final auth = state;
    if (auth is! AuthAuthenticated) return;
    if (accessToken.isEmpty || accessToken.startsWith('demo-')) return;
    if (auth.session.accessToken == accessToken &&
        auth.session.refreshToken == refreshToken) {
      return;
    }
    // Reconnect immediately with the new JWT so rooms rejoin on connect.
    SocketService.instance.connect(accessToken: accessToken);
    state = AuthAuthenticated(
      AuthSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: auth.session.user,
      ),
    );
  }

  Future<AuthUser?> _loadMe() async {
    try {
      return await _repo.getMe();
    } catch (_) {
      return null;
    }
  }

  Future<void> enterDemo() async {
    SocketService.instance.disconnect(clearRooms: true);
    await _storage.clear();
    state = const AuthLoading();
    const session = AuthSession(
      accessToken: 'demo-access-token',
      refreshToken: 'demo-refresh-token',
      user: AuthUser(
        id: 'demo-worker',
        phone: '+919876543210',
        name: 'Ramesh K',
        role: 'WORKER',
      ),
    );
    await _storage.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    state = const AuthAuthenticated(session);
  }

  Future<void> logout() async {
    SocketService.instance.disconnect(clearRooms: true);
    await _storage.clear();
    state = const AuthUnauthenticated();
  }
}
