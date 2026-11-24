import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../stations/services/api_service.dart';
import '../../wallet/models/wallet_transaction.dart';
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
  static const String _prefSessionKey = 'ishower_mobile_session_v1';
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal();

  final ValueNotifier<UserSession?> sessionNotifier =
      ValueNotifier<UserSession?>(null);
  final ValueNotifier<int> walletVersion = ValueNotifier<int>(0);

  final List<WalletTransaction> _localTransactions = [
    WalletTransaction(
      id: 'tx-welcome',
      amountCents: 15000,
      type: 'DEPOSIT_PIX',
      referenceId: 'BONUS_BOAS_VINDAS',
      createdAt: DateTime.now(),
    ),
  ];

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
      balance: 0,
    ),
    const _LocalUserRecord(
      name: 'Gerente Ipiranga Rota 26',
      email: 'gerente.ipiranga@ishower.com',
      password: '123456',
      role: 'PARTNER_MANAGER',
      stationId: '22222222-2222-4222-8222-222222222222',
      stationName: 'Posto Ipiranga Rota 26',
      balance: 0,
    ),
    const _LocalUserRecord(
      name: 'Operador Graal BR-381',
      email: 'operador.graal@ishower.com',
      password: '123456',
      role: 'PARTNER_OPERATOR',
      stationId: '11111111-1111-4111-8111-111111111111',
      stationName: 'Posto Graal - BR 381',
      balance: 0,
    ),
    const _LocalUserRecord(
      name: 'Administrador Geral',
      email: 'admin@ishower.com',
      password: '123456',
      role: 'SUPER_ADMIN',
      balance: 0,
    ),
  ];

  UserSession? get currentSession => sessionNotifier.value;

  Future<void> _persistSession(UserSession? session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (session == null) {
        await prefs.remove(_prefSessionKey);
      } else {
        await prefs.setString(_prefSessionKey, jsonEncode(session.toJson()));
      }
    } catch (_) {
      // Ignore in headless widget tests
    }
  }

  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefSessionKey);
      if (raw == null || raw.isEmpty) return;
      final parsed = jsonDecode(raw) as Map<String, dynamic>;
      final restored = UserSession.fromJson(parsed);
      if (restored.email.isNotEmpty) {
        sessionNotifier.value = restored;
        await refreshSession();
      }
    } catch (_) {
      // Ignore invalid/unavailable storage
    }
  }

  Future<void> refreshSession({bool notifyWallet = false}) async {
    final current = sessionNotifier.value;
    if (current == null ||
        current.token.isEmpty ||
        current.token.startsWith('local-')) {
      return;
    }

    final snapshotToken = current.token;
    final snapshotUserId = current.userId;

    try {
      final response = await http
          .get(
            Uri.parse('${ApiService.baseUrl}/auth/me'),
            headers: {'Authorization': 'Bearer $snapshotToken'},
          )
          .timeout(const Duration(seconds: 3));

      // Se o usuário deslogou ou trocou de conta enquanto a requisição estava em andamento, ignora!
      final latest = sessionNotifier.value;
      if (latest == null ||
          latest.token != snapshotToken ||
          latest.userId != snapshotUserId) {
        return;
      }

      if (response.statusCode == 200) {
        ApiService.isOfflineNotifier.value = false;
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        data['token'] = snapshotToken;
        final refreshed = UserSession.fromJson(data);
        sessionNotifier.value = refreshed;
        if (notifyWallet) {
          walletVersion.value++;
        }
        await _persistSession(refreshed);
      }
    } catch (_) {
      // Keep current session in memory if offline
    }
  }

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
        ApiService.isOfflineNotifier.value = false;
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final session = UserSession.fromJson(data);
        sessionNotifier.value = session;
        await _persistSession(session);
        return session;
      } else if (response.statusCode == 401) {
        throw Exception('E-mail ou senha inválidos.');
      }
    } catch (e) {
      if (e.toString().contains('inválidos')) rethrow;
      ApiService.isOfflineNotifier.value = true;
    }

    final localMatch = _localUsers.where(
      (u) =>
          (u.email.toLowerCase() == cleanId ||
              u.name.toLowerCase() == cleanId) &&
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
    await _persistSession(session);
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
        ApiService.isOfflineNotifier.value = false;
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final session = UserSession.fromJson(data);
        sessionNotifier.value = session;
        await _persistSession(session);
        return session;
      } else if (response.statusCode == 409) {
        throw Exception('Este e-mail já está cadastrado.');
      }
    } catch (e) {
      if (e.toString().contains('já está cadastrado')) rethrow;
      ApiService.isOfflineNotifier.value = true;
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
    await _persistSession(session);
    return session;
  }

  Future<double> depositMockPix(double amount) async {
    final current = sessionNotifier.value;
    if (current == null) {
      throw Exception('Sessão não encontrada.');
    }
    final amountCents = (amount * 100).round();
    if (amountCents <= 0) {
      throw Exception('Valor de recarga inválido.');
    }

    if (current.token.isNotEmpty && !current.token.startsWith('local-')) {
      try {
        final key = 'pix_${DateTime.now().microsecondsSinceEpoch}';
        final response = await http
            .post(
              Uri.parse('${ApiService.baseUrl}/wallet/deposit'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ${current.token}',
                'Idempotency-Key': key,
              },
              body: jsonEncode({
                'amount_cents': amountCents,
                'gateway_reference': 'PIX_APP_RECARGA',
              }),
            )
            .timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
          ApiService.isOfflineNotifier.value = false;
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          final newBalanceCents = (body['balance_cents'] as num?)?.toInt();
          if (newBalanceCents != null) {
            current.balance = newBalanceCents / 100.0;
          } else {
            current.balance += amount;
          }
          walletVersion.value++;
          await _persistSession(current);
          return current.balance;
        }
      } catch (_) {
        ApiService.isOfflineNotifier.value = true;
      }
    }

    current.balance += amount;
    _localTransactions.insert(
      0,
      WalletTransaction(
        id: 'tx-pix-${DateTime.now().millisecondsSinceEpoch}',
        amountCents: amountCents,
        type: 'DEPOSIT_PIX',
        referenceId: 'PIX_MOCKUP_RECARGA',
        createdAt: DateTime.now(),
      ),
    );
    walletVersion.value++;
    await _persistSession(current);
    return current.balance;
  }

  Future<List<WalletTransaction>> fetchTransactions() async {
    final current = sessionNotifier.value;
    if (current != null &&
        current.token.isNotEmpty &&
        !current.token.startsWith('local-')) {
      try {
        final response = await http
            .get(
              Uri.parse('${ApiService.baseUrl}/drivers/transactions'),
              headers: {'Authorization': 'Bearer ${current.token}'},
            )
            .timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
          ApiService.isOfflineNotifier.value = false;
          final List<dynamic> data = jsonDecode(response.body);
          return data
              .whereType<Map<String, dynamic>>()
              .map(WalletTransaction.fromJson)
              .toList();
        }
      } catch (_) {
        ApiService.isOfflineNotifier.value = true;
      }
    }
    return List.unmodifiable(_localTransactions);
  }

  void recordLocalUsage(double amount, String textCode) {
    final current = sessionNotifier.value;
    if (current == null) return;
    current.balance = (current.balance - amount).clamp(0.0, 999999.0);
    _localTransactions.insert(
      0,
      WalletTransaction(
        id: 'tx-use-${DateTime.now().millisecondsSinceEpoch}',
        amountCents: (amount * 100).round(),
        type: 'VOUCHER_USAGE',
        referenceId: 'BANHO_$textCode',
        createdAt: DateTime.now(),
      ),
    );
    walletVersion.value++;
    _persistSession(current);
  }

  void recordLocalRefund(double amount, String textCode) {
    final current = sessionNotifier.value;
    if (current == null) return;
    current.balance += amount;
    _localTransactions.insert(
      0,
      WalletTransaction(
        id: 'tx-ref-${DateTime.now().millisecondsSinceEpoch}',
        amountCents: (amount * 100).round(),
        type: 'VOUCHER_REFUND',
        referenceId: 'ESTORNO_$textCode',
        createdAt: DateTime.now(),
      ),
    );
    walletVersion.value++;
    _persistSession(current);
  }

  void deductBalance(double amount) {
    final current = sessionNotifier.value;
    if (current == null) return;
    current.balance = (current.balance - amount).clamp(0.0, 999999.0);
    walletVersion.value++;
    _persistSession(current);
  }

  void logout() {
    sessionNotifier.value = null;
    _persistSession(null);
  }
}
