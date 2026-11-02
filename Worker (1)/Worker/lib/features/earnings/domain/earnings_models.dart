enum TransactionType { credit, debit, payout }

class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.title,
    required this.amountPaise,
    required this.type,
    required this.at,
  });

  final String id;
  final String title;
  final int amountPaise;
  final TransactionType type;
  final DateTime at;
}

class WalletSnapshot {
  const WalletSnapshot({
    required this.balancePaise,
    required this.transactions,
  });

  final int balancePaise;
  final List<WalletTransaction> transactions;

  WalletSnapshot copyWith({
    int? balancePaise,
    List<WalletTransaction>? transactions,
  }) {
    return WalletSnapshot(
      balancePaise: balancePaise ?? this.balancePaise,
      transactions: transactions ?? this.transactions,
    );
  }
}
