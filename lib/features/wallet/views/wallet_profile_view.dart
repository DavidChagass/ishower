import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/services/auth_service.dart';
import '../models/wallet_transaction.dart';

class WalletProfileView extends StatefulWidget {
  const WalletProfileView({super.key});

  @override
  State<WalletProfileView> createState() => _WalletProfileViewState();
}

class _WalletProfileViewState extends State<WalletProfileView> {
  final AuthService _authService = AuthService();
  List<WalletTransaction> _transactions = [];
  bool _loading = true;
  bool _depositing = false;

  @override
  void initState() {
    super.initState();
    _authService.walletVersion.addListener(_onWalletChanged);
    _refresh();
  }

  @override
  void dispose() {
    _authService.walletVersion.removeListener(_onWalletChanged);
    super.dispose();
  }

  void _onWalletChanged() {
    if (mounted) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    await _authService.refreshSession();
    final txs = await _authService.fetchTransactions();
    if (!mounted) return;
    setState(() {
      _transactions = txs;
      _loading = false;
    });
  }

  Future<void> _depositPix(double amount) async {
    if (_depositing) return;
    setState(() => _depositing = true);
    try {
      await _authService.depositMockPix(amount);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Recarga PIX de ${Formatters.formatCurrency(amount)} creditada na carteira!',
          ),
          backgroundColor: AppColors.statusAvailable,
        ),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.statusBusy,
        ),
      );
    } finally {
      if (mounted) setState(() => _depositing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = _authService.currentSession;
    final cardBg = isDark ? AppColors.cardBackground : AppColors.lightCard;
    final borderCol = isDark ? AppColors.border : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Wallet Balance Hero Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.blueGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session?.name ?? 'Motorista',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            session?.email ?? '',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Saldo Carteira iShower',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.formatCurrency(session?.balance ?? 0),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Mock PIX Top-up Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.pix_outlined,
                      color: isDark ? AppColors.buttonSky : AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Recarregar com PIX (Simulação)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Adicione créditos instantaneamente para agilizar suas reservas nas paradas.',
                  style: TextStyle(fontSize: 12.5, color: textSecondary),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [20.0, 50.0, 100.0].map((amount) {
                    return ElevatedButton.icon(
                      onPressed: _depositing ? null : () => _depositPix(amount),
                      icon: const Icon(Icons.add, size: 16),
                      label: Text('+ R\$ ${amount.toInt()}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Extrato Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Extrato da Carteira',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Atualizar'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_transactions.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderCol),
              ),
              child: Text(
                'Nenhuma movimentação registrada ainda.',
                textAlign: TextAlign.center,
                style: TextStyle(color: textSecondary),
              ),
            )
          else
            ..._transactions.map((tx) {
              final isCredit = tx.isCredit;
              final color =
                  isCredit ? AppColors.statusAvailable : AppColors.statusBusy;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isCredit ? Icons.arrow_downward_rounded : Icons.shower_outlined,
                      color: color,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    tx.displayTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    tx.referenceId.isNotEmpty
                        ? '${tx.referenceId} · ${Formatters.formatDate(tx.createdAt)}'
                        : Formatters.formatDate(tx.createdAt),
                    style: TextStyle(fontSize: 11.5, color: textSecondary),
                  ),
                  trailing: Text(
                    '${isCredit ? '+' : '-'} ${Formatters.formatCurrency(tx.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: color,
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
