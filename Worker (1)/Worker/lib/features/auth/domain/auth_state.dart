class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

Map<String, dynamic>? authJsonMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.phone,
    this.name,
    this.skill,
    this.city,
    this.role,
  });

  final String id;
  final String phone;
  final String? name;
  final String? skill;
  final String? city;
  final String? role;

  String get roleName => (role ?? '').trim().toUpperCase();
  bool get isWorker => roleName == 'WORKER';
  bool get isCustomer => roleName == 'CUSTOMER';

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final worker = authJsonMap(json['workerProfile']);
    String? skill;
    final skills = worker?['skills'];
    if (skills is List) {
      for (final entry in skills) {
        final category = authJsonMap(entry)?['category'];
        final categoryName = authJsonMap(category)?['name'];
        if (categoryName is String && categoryName.isNotEmpty) {
          skill = categoryName;
          break;
        }
      }
    }

    final society = authJsonMap(worker?['society']);
    final federation = authJsonMap(society?['federation']);
    final storedCity = worker?['city'];
    final cityFromProfile =
        storedCity is String && storedCity.trim().isNotEmpty
            ? storedCity.trim()
            : null;
    final city = cityFromProfile ??
        federation?['region'] as String? ??
        society?['name'] as String?;

    final rawRole = json['role'] ?? json['userRole'];
    return AuthUser(
      id: '${json['id'] ?? json['_id'] ?? json['sub'] ?? ''}',
      phone: '${json['phone'] ?? ''}',
      name: json['name'] as String? ?? worker?['name'] as String?,
      skill: skill,
      city: city,
      role: rawRole is String && rawRole.trim().isNotEmpty
          ? rawRole.trim().toUpperCase()
          : null,
    );
  }

  AuthUser copyWith({
    String? id,
    String? phone,
    String? name,
    String? skill,
    String? city,
    String? role,
  }) {
    return AuthUser(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      skill: skill ?? this.skill,
      city: city ?? this.city,
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
