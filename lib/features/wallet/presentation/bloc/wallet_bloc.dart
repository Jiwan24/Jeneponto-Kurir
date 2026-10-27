import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/wallet.dart';
import '../../domain/repositories/wallet_repository.dart';
import 'wallet_state.dart';

/// Memantau saldo dan riwayat transaksi dompet kurir secara realtime.
class WalletBloc extends Bloc<WalletEvent, WalletState> {
  WalletBloc({required WalletRepository repository})
      : _repository = repository,
        super(const WalletState()) {
    on<WalletRequested>(_onRequested);
    on<WalletReceived>(_onReceived);
    on<WalletTransactionsReceived>(_onTransactionsReceived);
    on<WalletFailed>(_onFailed);
  }

  final WalletRepository _repository;
  StreamSubscription<Wallet>? _walletSubscription;
  StreamSubscription<List<WalletTransaction>>? _transactionSubscription;

  Future<void> _onRequested(
    WalletRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(
      status: WalletViewStatus.loading,
      transactions: const [],
      clearMessage: true,
    ));

    await _walletSubscription?.cancel();
    await _transactionSubscription?.cancel();

    _walletSubscription = _repository.watchWallet(event.uid).listen(
          (wallet) => add(WalletReceived(wallet)),
          onError: (_) => add(
            const WalletFailed('Gagal memuat saldo dompet.'),
          ),
        );

    _transactionSubscription = _repository.watchTransactions(event.uid).listen(
          (transactions) => add(WalletTransactionsReceived(transactions)),
          onError: (_) => add(
            const WalletFailed('Gagal memuat riwayat transaksi.'),
          ),
        );
  }

  void _onReceived(WalletReceived event, Emitter<WalletState> emit) {
    emit(state.copyWith(
      status: WalletViewStatus.success,
      wallet: event.wallet,
      clearMessage: true,
    ));
  }

  void _onTransactionsReceived(
    WalletTransactionsReceived event,
    Emitter<WalletState> emit,
  ) {
    emit(state.copyWith(
      // Jangan menimpa kegagalan saldo hanya karena stream transaksi berhasil.
      status: state.wallet == null ? state.status : WalletViewStatus.success,
      transactions: event.transactions,
    ));
  }

  void _onFailed(WalletFailed event, Emitter<WalletState> emit) {
    emit(state.copyWith(
      status: state.wallet == null
          ? WalletViewStatus.failure
          : WalletViewStatus.success,
      message: event.message,
    ));
  }

  @override
  Future<void> close() async {
    await _walletSubscription?.cancel();
    await _transactionSubscription?.cancel();
    return super.close();
  }
}
