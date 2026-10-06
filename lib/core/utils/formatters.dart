class Formatters {
  static String formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2)}';
  }

  static String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
