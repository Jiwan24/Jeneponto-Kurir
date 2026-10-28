import 'package:dartz/dartz.dart';

import 'package:jeneponto_kurir/features/common/di/person2_locator.dart';
import 'package:jeneponto_kurir/features/common/error/failures.dart';
import 'package:jeneponto_kurir/features/delivery/domain/entities/coordinate.dart';
import 'package:jeneponto_kurir/features/delivery/domain/entities/delivery_address.dart';
import 'package:jeneponto_kurir/features/delivery/domain/entities/delivery_order.dart';
import 'package:jeneponto_kurir/features/delivery/domain/entities/order_status.dart';
import 'package:jeneponto_kurir/features/delivery/domain/entities/payment_method.dart';
import 'package:jeneponto_kurir/features/delivery/domain/repositories/delivery_repository.dart';
import 'package:jeneponto_kurir/features/delivery/domain/services/price_calculator.dart';
import 'package:jeneponto_kurir/features/delivery/presentation/bloc/delivery_checkout_bloc.dart';
import 'package:jeneponto_kurir/features/delivery/presentation/bloc/delivery_history_bloc.dart';
import 'package:jeneponto_kurir/features/delivery/presentation/bloc/delivery_order_bloc.dart';
import 'package:jeneponto_kurir/features/payments/domain/entities/payment.dart';
import 'package:jeneponto_kurir/features/payments/domain/repositories/payment_repository.dart';
import 'package:jeneponto_kurir/features/payments/presentation/bloc/payment_bloc.dart';
import 'package:jeneponto_kurir/features/wallet/domain/entities/wallet.dart';
import 'package:jeneponto_kurir/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:jeneponto_kurir/features/wallet/presentation/bloc/wallet_bloc.dart';

/// Identitas demo yang biasanya dikirim host aplikasi (hasil login Person 1).
const String demoCustomerId = 'demo-customer';
const String demoCustomerName = 'Aisyah Demo';
const String demoCustomerPhone = '081234567890';
const String demoCourierId = 'demo-courier';

/// Registrasi dependency Person 2 dengan repository in-memory.
///
/// Tidak memanggil `initPerson2Dependencies()` karena fungsi itu mengikat
/// Firestore. Tujuannya: demo bisa jalan tanpa Firebase dan tanpa login.
void registerDemoDependencies() {
  if (sl.isRegistered<DeliveryRepository>()) return;

  sl.registerLazySingleton<DeliveryRepository>(() => DemoDeliveryRepository());
  sl.registerFactory<DeliveryCheckoutBloc>(
    () => DeliveryCheckoutBloc(repository: sl()),
  );
  sl.registerFactory<DeliveryOrderBloc>(
    () => DeliveryOrderBloc(repository: sl()),
  );
  sl.registerFactory<DeliveryHistoryBloc>(
    () => DeliveryHistoryBloc(repository: sl()),
  );

  sl.registerLazySingleton<WalletRepository>(() => DemoWalletRepository());
  sl.registerFactory<WalletBloc>(() => WalletBloc(repository: sl()));

  sl.registerLazySingleton<PaymentRepository>(() => DemoPaymentRepository());
  sl.registerFactory<PaymentBloc>(() => PaymentBloc(repository: sl()));
}

// ---------------------------------------------------------------------------
// Pesanan
// ---------------------------------------------------------------------------

/// Pesanan in-memory: cukup untuk memutar seluruh alur Person 2.
class DemoDeliveryRepository implements DeliveryRepository {
  DemoDeliveryRepository() {
    for (final DeliveryOrder order in _seed()) {
      _orders[order.id] = order;
    }
  }

  final Map<String, DeliveryOrder> _orders = <String, DeliveryOrder>{};
  int _sequence = 900;

  List<DeliveryOrder> get _sorted {
    final List<DeliveryOrder> orders = _orders.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  @override
  Stream<DeliveryOrder?> watchOrder(String orderId) =>
      Stream<DeliveryOrder?>.value(_orders[orderId]);

  @override
  Future<Either<Failure, DeliveryOrder?>> getOrder(String orderId) async =>
      Right(_orders[orderId]);

  @override
  Future<Either<Failure, String>> createOrder(DeliveryDraft draft) async {
    _sequence++;
    final DateTime now = DateTime.now();
    final String id = 'demo-$_sequence';
    final DeliveryOrder order = DeliveryOrder(
      id: id,
      code: 'JK-DEMO-$_sequence',
      customerId: draft.customerId,
      customerName: draft.customerName,
      customerPhone: draft.customerPhone,
      pickup: draft.pickup,
      dropoff: draft.dropoff,
      status: draft.paymentMethod == PaymentMethod.midtrans
          ? OrderStatus.awaitingPayment
          : OrderStatus.pending,
      fare: draft.fareQuote,
      weightKg: draft.weightKg,
      itemCategory: draft.itemCategory,
      itemNotes: draft.itemNotes,
      paymentMethod: draft.paymentMethod,
      paymentStatus: PaymentStatus.unpaid,
      createdAt: now,
      updatedAt: now,
    );
    _orders[id] = order;
    return Right(id);
  }

  @override
  Future<Either<Failure, DeliveryOrderPage>> fetchCustomerOrders({
    required String customerId,
    int limit = 20,
    DateTime? before,
  }) async {
    final List<DeliveryOrder> all = _sorted
        .where((order) => order.customerId == customerId)
        .where((order) => before == null || order.createdAt.isBefore(before))
        .toList();
    return Right(
      DeliveryOrderPage(
        orders: all.take(limit).toList(),
        hasMore: all.length > limit,
      ),
    );
  }

  @override
  Stream<List<DeliveryOrder>> watchCustomerOrders(
    String customerId, {
    int limit = 10,
  }) =>
      Stream<List<DeliveryOrder>>.value(
        _sorted
            .where((order) => order.customerId == customerId)
            .take(limit)
            .toList(),
      );

  @override
  Future<Either<Failure, Unit>> cancelOrder({
    required String orderId,
    String? reason,
  }) async {
    final DeliveryOrder? order = _orders[orderId];
    if (order != null) {
      _orders[orderId] = order.copyWith(
        status: OrderStatus.cancelled,
        cancelledAt: DateTime.now(),
        cancelledReason: reason ?? 'Dibatalkan pelanggan (demo).',
        updatedAt: DateTime.now(),
      );
    }
    return const Right(unit);
  }

  static List<DeliveryOrder> _seed() {
    final DateTime now = DateTime.now();

    DeliveryAddress address({
      required String label,
      required String detail,
      required String district,
      required Coordinate point,
    }) {
      return DeliveryAddress(
        label: label,
        address: detail,
        district: district,
        coordinate: point,
        contactName: demoCustomerName,
        contactPhone: demoCustomerPhone,
      );
    }

    final DeliveryAddress pickup = address(
      label: 'Penjemputan',
      detail: 'Jl. Kemakmuran No. 12, dekat pasar sentral',
      district: 'Binamu',
      point: const Coordinate(-5.6791, 119.7472),
    );
    final DeliveryAddress dropoff = address(
      label: 'Tujuan',
      detail: 'Jl. Poros Jeneponto No. 88, depan kantor pos',
      district: 'Binamu',
      point: const Coordinate(-5.6641, 119.7521),
    );

    return <DeliveryOrder>[
      DeliveryOrder(
        id: 'demo-1',
        code: 'JK-261028-8F2A',
        customerId: demoCustomerId,
        customerName: demoCustomerName,
        customerPhone: demoCustomerPhone,
        courierId: demoCourierId,
        courierName: 'Rahmat',
        courierPhone: '081298765432',
        pickup: pickup,
        dropoff: dropoff,
        status: OrderStatus.inTransit,
        fare: PriceCalculator.quote(distanceKm: 6.5),
        weightKg: 2,
        itemCategory: 'Paket',
        paymentMethod: PaymentMethod.cod,
        paymentStatus: PaymentStatus.unpaid,
        createdAt: now.subtract(const Duration(hours: 3)),
        updatedAt: now.subtract(const Duration(minutes: 25)),
        acceptedAt: now.subtract(const Duration(hours: 2, minutes: 40)),
        pickedUpAt: now.subtract(const Duration(hours: 1, minutes: 5)),
        inTransitAt: now.subtract(const Duration(minutes: 25)),
      ),
      DeliveryOrder(
        id: 'demo-2',
        code: 'JK-261028-4B7C',
        customerId: demoCustomerId,
        customerName: demoCustomerName,
        customerPhone: demoCustomerPhone,
        pickup: pickup,
        dropoff: dropoff,
        status: OrderStatus.awaitingPayment,
        fare: PriceCalculator.quote(distanceKm: 3.2),
        weightKg: 1,
        itemCategory: 'Dokumen',
        paymentMethod: PaymentMethod.midtrans,
        paymentStatus: PaymentStatus.unpaid,
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      ),
      DeliveryOrder(
        id: 'demo-3',
        code: 'JK-261027-1D9E',
        customerId: demoCustomerId,
        customerName: demoCustomerName,
        customerPhone: demoCustomerPhone,
        courierId: demoCourierId,
        courierName: 'Rahmat',
        courierPhone: '081298765432',
        pickup: pickup,
        dropoff: dropoff,
        status: OrderStatus.delivered,
        fare: PriceCalculator.quote(distanceKm: 9.4),
        weightKg: 3,
        itemCategory: 'Makanan',
        paymentMethod: PaymentMethod.cod,
        paymentStatus: PaymentStatus.paid,
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        updatedAt: now.subtract(const Duration(days: 1)),
        acceptedAt: now.subtract(const Duration(days: 1, hours: 2)),
        pickedUpAt: now.subtract(const Duration(days: 1, hours: 1, minutes: 40)),
        inTransitAt: now.subtract(const Duration(days: 1, hours: 1, minutes: 20)),
        deliveredAt: now.subtract(const Duration(days: 1)),
        paidAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
// Dompet
// ---------------------------------------------------------------------------

class DemoWalletRepository implements WalletRepository {
  final Wallet _wallet = Wallet(
    uid: demoCourierId,
    balance: 125000,
    pendingBalance: 30000,
    totalEarnings: 755000,
    totalWithdrawn: 500000,
    updatedAt: DateTime.now(),
  );

  late final List<WalletTransaction> _transactions = <WalletTransaction>[
    WalletTransaction(
      id: 'trx-1',
      uid: demoCourierId,
      orderId: 'demo-1',
      type: WalletTransactionType.earning,
      amount: 45000,
      status: WalletTransactionStatus.available,
      description: 'Pendapatan order JK-261028-8F2A',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    WalletTransaction(
      id: 'trx-2',
      uid: demoCourierId,
      type: WalletTransactionType.commission,
      amount: -5000,
      status: WalletTransactionStatus.available,
      description: 'Komisi platform 10%',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    WalletTransaction(
      id: 'trx-3',
      uid: demoCourierId,
      orderId: 'demo-3',
      type: WalletTransactionType.earning,
      amount: 30000,
      status: WalletTransactionStatus.pending,
      description: 'Pendapatan order JK-261027-1D9E',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    WalletTransaction(
      id: 'trx-4',
      uid: demoCourierId,
      type: WalletTransactionType.withdrawal,
      amount: -100000,
      status: WalletTransactionStatus.paid,
      description: 'Penarikan ke BCA ***7788',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  @override
  Stream<Wallet> watchWallet(String uid) => Stream<Wallet>.value(_wallet);

  @override
  Stream<List<WalletTransaction>> watchTransactions(
    String uid, {
    int limit = 50,
  }) =>
      Stream<List<WalletTransaction>>.value(_transactions.take(limit).toList());

  @override
  Future<Either<Failure, Wallet>> fetchWallet(String uid) async =>
      Right(_wallet);
}

// ---------------------------------------------------------------------------
// Pembayaran
// ---------------------------------------------------------------------------

class DemoPaymentRepository implements PaymentRepository {
  @override
  Stream<Payment?> watchPayment(String orderId) =>
      Stream<Payment?>.value(null);

  @override
  Future<Either<Failure, Payment?>> fetchPayment(String orderId) async =>
      const Right(null);

  @override
  Future<Either<Failure, Payment>> createMidtransPayment({
    required DeliveryOrder order,
  }) async {
    final DateTime now = DateTime.now();
    return Right(
      Payment(
        id: 'pay-${order.id}',
        orderId: order.id,
        orderCode: order.code,
        customerId: order.customerId,
        amount: order.price,
        provider: PaymentProvider.midtrans,
        method: PaymentMethod.midtrans,
        status: PaymentStatus.pending,
        channel: 'qris',
        createdAt: now,
        updatedAt: now,
        // Tanpa redirectUrl: demo tidak membuka browser eksternal.
        expiresAt: now.add(const Duration(minutes: 15)),
      ),
    );
  }
}
