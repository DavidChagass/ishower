class UserSession {
  final String userId;
  final String name;
  final String email;
  final String role; // 'DRIVER' | 'PARTNER_MANAGER' | 'PARTNER_OPERATOR' | 'SUPER_ADMIN'
  final String token;
  final String? stationId;
  final String? stationName;
  double balance;

  UserSession({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.token,
    this.stationId,
    this.stationName,
    this.balance = 150.0,
  });

  bool get isStaff =>
      role == 'SUPER_ADMIN' ||
      role == 'PARTNER_MANAGER' ||
      role == 'PARTNER_OPERATOR';

  bool get isSuperAdmin => role == 'SUPER_ADMIN';

  String get roleLabel {
    switch (role) {
      case 'SUPER_ADMIN':
        return 'Admin Geral';
      case 'PARTNER_MANAGER':
        return stationName != null && stationName!.isNotEmpty
            ? 'Gerente · $stationName'
            : 'Gerente de Posto';
      case 'PARTNER_OPERATOR':
        return 'Operador de Posto';
      default:
        return 'Motorista';
    }
  }

  factory UserSession.fromJson(Map<String, dynamic> json) {
    final cents = json['balance_cents'];
    final parsedBalance = cents is num && cents > 0 ? cents.toDouble() / 100.0 : 150.0;
    final stId = (json['station_id'] ?? '').toString();
    final stName = (json['station_name'] ?? '').toString();

    return UserSession(
      userId: (json['user_id'] ?? '').toString(),
      name: (json['name'] ?? json['email'] ?? 'Usuário').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'DRIVER').toString(),
      token: (json['token'] ?? '').toString(),
      stationId: stId.isEmpty ? null : stId,
      stationName: stName.isEmpty ? null : stName,
      balance: parsedBalance,
    );
  }
}
