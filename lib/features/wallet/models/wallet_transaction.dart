class WalletTransaction {
  final String id;
  final int amountCents;
  final String type; // 'DEPOSIT_PIX' | 'VOUCHER_USAGE' | 'VOUCHER_REFUND'
  final String referenceId;
  final DateTime createdAt;

  const WalletTransaction({
    required this.id,
    required this.amountCents,
    required this.type,
    required this.referenceId,
    required this.createdAt,
  });

  double get amount => amountCents / 100.0;
  bool get isCredit => type == 'DEPOSIT_PIX' || type == 'VOUCHER_REFUND';

  String get displayTitle {
    switch (type) {
      case 'DEPOSIT_PIX':
        return referenceId == 'BONUS_BOAS_VINDAS'
            ? 'Bônus de Boas-Vindas'
            : 'Recarga PIX (Carteira)';
      case 'VOUCHER_REFUND':
        return 'Estorno de Reserva';
      case 'VOUCHER_USAGE':
      default:
        return 'Reserva de Banho';
    }
  }

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: (json['id'] ?? '').toString(),
      amountCents: (json['amount_cents'] as num?)?.toInt() ?? 0,
      type: (json['type'] ?? 'VOUCHER_USAGE').toString(),
      referenceId: (json['reference_id'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
