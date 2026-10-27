import 'package:equatable/equatable.dart';

import '../../domain/entities/wallet.dart';

enum WalletViewStatus { initial, loading, success, failure }

class WalletState extends Equatable {
  const WalletState({
    this.status = WalletViewStatus.initial,
    this.wallet,
    this.transactions = const [],
    this.message,
  });

  final WalletViewStatus status;
  final Wallet? wallet;
  final List<WalletTransaction> transactions;
  final String? message;

  WalletState copyWith({
    WalletViewStatus? status,
    Wallet? wallet,
    List<WalletTransaction>? transactions,
    String? message,
    bool clearMessage = false,
    bool clearWallet = false,
  }) {
    return WalletState(
      status: status ?? this.status,
      wallet: clearWallet ? null : wallet ?? this.wallet,
      transactions: transactions ?? this.transactions,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, wallet, transactions, message];
}

abstract class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object?> get props => const [];
}

class WalletRequested extends WalletEvent {
  const WalletRequested(this.uid);

  final String uid;

  @override
  List<Object?> get props => [uid];
}

class WalletReceived extends WalletEvent {
  const WalletReceived(this.wallet);

  final Wallet wallet;

  @override
  List<Object?> get props => [wallet];
}

class WalletTransactionsReceived extends WalletEvent {
  const WalletTransactionsReceived(this.transactions);

  final List<WalletTransaction> transactions;

  @override
  List<Object?> get props => [transactions];
}

class WalletFailed extends WalletEvent {
  const WalletFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
