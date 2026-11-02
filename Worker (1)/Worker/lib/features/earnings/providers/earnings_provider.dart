import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/earnings_models.dart';

final earningsProvider =
    NotifierProvider<EarningsNotifier, WalletSnapshot>(EarningsNotifier.new);

class EarningsNotifier extends Notifier<WalletSnapshot> {
  @override
  WalletSnapshot build() {
    // TODO: GET /workers/me/wallet
    // TODO: GET /workers/me/transactions
    final now = DateTime.now();
    return WalletSnapshot(
      balancePaise: 124500,
      transactions: [
        WalletTransaction(
          id: 'txn_1',
          title: 'Electrician · MG Road',
          amountPaise: 34900,
          type: TransactionType.credit,
          at: now.subtract(const Duration(hours: 6)),
        ),
        WalletTransaction(
          id: 'txn_2',
          title: 'Payout to UPI',
          amountPaise: 50000,
          type: TransactionType.payout,
          at: now.subtract(const Duration(days: 2)),
        ),
        WalletTransaction(
          id: 'txn_3',
          title: 'Plumber · Indiranagar',
          amountPaise: 42000,
          type: TransactionType.credit,
          at: now.subtract(const Duration(days: 4)),
        ),
        WalletTransaction(
          id: 'txn_4',
          title: 'Platform fee',
          amountPaise: 2500,
          type: TransactionType.debit,
          at: now.subtract(const Duration(days: 4)),
        ),
      ],
    );
  }

  Future<void> requestPayout(int amountPaise) async {
    // TODO: POST /workers/me/payouts  body: { "amountPaise": amountPaise }
    final nextBalance = state.balancePaise - amountPaise;
    state = state.copyWith(
      balancePaise: nextBalance < 0 ? 0 : nextBalance,
      transactions: [
        WalletTransaction(
          id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Payout requested',
          amountPaise: amountPaise,
          type: TransactionType.payout,
          at: DateTime.now(),
        ),
        ...state.transactions,
      ],
    );
  }
}
