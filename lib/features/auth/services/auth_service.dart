import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../stations/services/api_service.dart';
import '../models/user_session.dart';

class _LocalUserRecord {
  final String name;
  final String email;
  final String password;
  final String role;
  final String? stationId;
  final String? stationName;
  final double balance;

  const _LocalUserRecord({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.stationId,
    this.stationName,
    this.balance = 150.0,
  });
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal();

  final ValueNotifier<UserSession?> sessionNotifier = ValueNotifier<UserSession?>(null);

  final List<_LocalUserRecord> _localUsers = [
    const _LocalUserRecord(
      name: 'Carlos Caminhoneiro',
      email: 'motorista@ishower.com',
      password: '123456',
      role: 'DRIVER',
      balance: 150.0,
    ),
    const _LocalUserRecord(
      name: 'Gerente Graal BR-381',
      email: 'gerente.graal@ishower.com',
      password: '123456',
      role: 'PARTNER_MANAGER',
      stationId: '11111111-1111-4111-8111-111111111111',
      stationName: 'Posto Graal - BR 381',
    ),
    const _LocalUserRecord(
      name: 'Administrador Geral',
      email: 'admin@ishower.com',
      password: '123456',
      role: 'SUPER_ADMIN',
    ),
  ];

  UserSession? get currentSession => sessionNotifier.value;

  Future<UserSession> login({
    required String identifier,
    required String password,
  }) async {
    final cleanId = identifier.trim().toLowerCase();
    final cleanPass = password.trim();
    if (cleanId.isEmpty || cleanPass.isEmpty) {
      throw Exception('Informe o e-mail/usuário e a senha.');
    }

    try {
      final response = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': cleanId, 'password': cleanPass}),
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final session = UserSession.fromJson(data);
        sessionNotifier.value = session;
        return session;
      } else if (response.statusCode == 401) {
        throw Exception('E-mail ou senha inválidos.');
      }
    } catch (e) {
      if (e.toString().contains('inválidos')) rethrow;
      // Fallback local para funcionar offline / em demonstrações sem backend
    }

    final localMatch = _localUsers.where(
      (u) =>
          (u.email.toLowerCase() == cleanId || u.name.toLowerCase() == cleanId) &&
          u.password == cleanPass,
    );

    if (localMatch.isEmpty) {
      throw Exception('Usuário ou senha inválidos.');
    }

    final u = localMatch.first;
    final session = UserSession(
      userId: 'local-${u.email}',
      name: u.name,
      email: u.email,
      role: u.role,
      token: 'local-demo-token',
      stationId: u.stationId,
      stationName: u.stationName,
      balance: u.balance,
    );
    sessionNotifier.value = session;
    return session;
  }

  Future<UserSession> register({
    required String name,
    required String email,
    required String password,
    String? cpf,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = password.trim();

    if (cleanName.isEmpty || cleanEmail.isEmpty || cleanPass.isEmpty) {
      throw Exception('Preencha nome, e-mail e senha.');
    }

    try {
      final response = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': cleanName,
              'email': cleanEmail,
              'password': cleanPass,
              if (cpf != null && cpf.trim().isNotEmpty) 'cpf': cpf.trim(),
            }),
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final session = UserSession.fromJson(data);
        sessionNotifier.value = session;
        return session;
      } else if (response.statusCode == 409) {
        throw Exception('Este e-mail já está cadastrado.');
      }
    } catch (e) {
      if (e.toString().contains('já está cadastrado')) rethrow;
      // Fallback local caso o backend esteja indisponível
    }

    final exists = _localUsers.any((u) => u.email.toLowerCase() == cleanEmail);
    if (exists) {
      throw Exception('Este e-mail já está cadastrado.');
    }

    final newRecord = _LocalUserRecord(
      name: cleanName,
      email: cleanEmail,
      password: cleanPass,
      role: 'DRIVER',
      balance: 150.0,
    );
    _localUsers.add(newRecord);

    final session = UserSession(
      userId: 'local-${DateTime.now().millisecondsSinceEpoch}',
      name: cleanName,
      email: cleanEmail,
      role: 'DRIVER',
      token: 'local-demo-token',
      balance: 150.0,
    );
    sessionNotifier.value = session;
    return session;
  }

  void deductBalance(double amount) {
    final current = sessionNotifier.value;
    if (current == null) return;
    current.balance = (current.balance - amount).clamp(0.0, 999999.0);
  }

  void logout() {
    sessionNotifier.value = null;
  }
}
