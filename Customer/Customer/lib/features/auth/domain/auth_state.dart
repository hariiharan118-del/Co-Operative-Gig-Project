class PasswordResetChallenge {
  const PasswordResetChallenge({
    required this.phone,
    this.debugOtp,
  });

  final String phone;
  final String? debugOtp;
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.phone,
    this.name,
    this.email,
    this.role,
  });

  final String id;
  final String phone;
  final String? name;
  final String? email;
  final String? role;

  String get roleName => (role ?? '').trim().toUpperCase();
  bool get isCustomer => roleName == 'CUSTOMER';
  bool get isWorker => roleName == 'WORKER';

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final profile = json['customerProfile'];
    final profileMap = profile is Map<String, dynamic> ? profile : null;
    final rawRole = json['role'] ?? json['userRole'];
    return AuthUser(
      id: '${json['id'] ?? json['_id'] ?? json['sub'] ?? ''}',
      phone: '${json['phone'] ?? ''}',
      name: json['name'] as String? ?? profileMap?['name'] as String?,
      email: json['email'] as String? ?? profileMap?['email'] as String?,
      role: rawRole is String && rawRole.trim().isNotEmpty
          ? rawRole.trim().toUpperCase()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (role != null) 'role': role,
      };

  AuthUser copyWith({
    String? id,
    String? phone,
    String? name,
    String? email,
    String? role,
  }) {
    return AuthUser(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
    );
  }
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    this.user,
  });

  final String accessToken;
  final String refreshToken;
  final AuthUser? user;
}

sealed class AuthState {
  const AuthState();
}

class AuthUnknown extends AuthState {
  const AuthUnknown();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.session);

  final AuthSession session;
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;
}
