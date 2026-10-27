import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeneponto_kurir/features/wallet/domain/entities/wallet.dart';
import 'package:jeneponto_kurir/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:jeneponto_kurir/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:jeneponto_kurir/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockWalletRepository extends Mock implements WalletRepository {}

void main() {
  late _MockWalletRepository repository;

  const Wallet wallet = Wallet(
    uid: 'courier-1',
    balance: 90000,
    pendingBalance: 0,
    totalEarnings: 90000,
    totalWithdrawn: 0,
  );
  final WalletTransaction transaction = WalletTransaction(
    id: 'earning-order-1',
    uid: 'courier-1',
    orderId: 'order-1',
    type: WalletTransactionType.earning,
    amount: 18000,
    status: WalletTransactionStatus.available,
    description: 'Pendapatan order JK-1',
    createdAt: DateTime(2026, 10, 27, 10),
  );

  setUp(() {
    repository = _MockWalletRepository();
  });

  blocTest<WalletBloc, WalletState>(
    'memantau saldo dan riwayat transaksi kurir',
    setUp: () {
      when(() => repository.watchWallet('courier-1'))
          .thenAnswer((_) => Stream<Wallet>.value(wallet));
      when(
        () => repository.watchTransactions('courier-1', limit: 50),
      ).thenAnswer((_) => Stream<List<WalletTransaction>>.value([transaction]));
    },
    build: () => WalletBloc(repository: repository),
    act: (bloc) => bloc.add(const WalletRequested('courier-1')),
    expect: () => [
      isA<WalletState>().having(
        (state) => state.status,
        'status',
        WalletViewStatus.loading,
      ),
      isA<WalletState>(),
      isA<WalletState>(),
    ],
    verify: (bloc) {
      expect(bloc.state.wallet?.balance, 90000);
      expect(bloc.state.transactions, [transaction]);
    },
  );

  blocTest<WalletBloc, WalletState>(
    'menampilkan kegagalan saat stream saldo error',
    setUp: () {
      when(() => repository.watchWallet('courier-1'))
          .thenAnswer((_) => Stream<Wallet>.error(Exception('offline')));
      when(
        () => repository.watchTransactions('courier-1', limit: 50),
      ).thenAnswer((_) => const Stream<List<WalletTransaction>>.empty());
    },
    build: () => WalletBloc(repository: repository),
    act: (bloc) => bloc.add(const WalletRequested('courier-1')),
    expect: () => [
      isA<WalletState>().having(
        (state) => state.status,
        'status',
        WalletViewStatus.loading,
      ),
      isA<WalletState>()
          .having((state) => state.status, 'status', WalletViewStatus.failure)
          .having(
            (state) => state.message,
            'message',
            'Gagal memuat saldo dompet.',
          ),
    ],
  );
}
