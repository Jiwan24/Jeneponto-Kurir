import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeneponto_kurir/core/error/failures.dart';
import 'package:jeneponto_kurir/core/utils/price_calculator.dart';
import 'package:jeneponto_kurir/features/delivery/domain/entities/coordinate.dart';
import 'package:jeneponto_kurir/features/delivery/domain/entities/delivery_address.dart';
import 'package:jeneponto_kurir/features/delivery/domain/entities/delivery_order.dart';
import 'package:jeneponto_kurir/features/delivery/domain/entities/payment_method.dart';
import 'package:jeneponto_kurir/features/delivery/domain/repositories/delivery_repository.dart';
import 'package:jeneponto_kurir/features/delivery/presentation/bloc/delivery_history_bloc.dart';
import 'package:jeneponto_kurir/features/delivery/presentation/bloc/delivery_history_state.dart';
import 'package:jeneponto_kurir/features/order/domain/entities/order_entity.dart';
import 'package:mocktail/mocktail.dart';

class _MockDeliveryRepository extends Mock implements DeliveryRepository {}

void main() {
  late _MockDeliveryRepository repository;

  const DeliveryAddress pickup = DeliveryAddress(
    label: 'Penjemputan',
    address: 'Jl. Sultan Hasanuddin No. 1',
    district: 'Binamu',
    coordinate: Coordinate(-5.665, 119.741),
    contactName: 'Budi',
    contactPhone: '081234567890',
  );
  const DeliveryAddress dropoff = DeliveryAddress(
    label: 'Tujuan',
    address: 'Jl. Poros Jeneponto No. 2',
    district: 'Turatea',
    coordinate: Coordinate(-5.602, 119.764),
    contactName: 'Siti',
    contactPhone: '081298765432',
  );

  DeliveryOrder order(String id, OrderStatus status) {
    final DateTime now = DateTime(2026, 10, 27, 10);
    return DeliveryOrder(
      id: id,
      code: 'JK-$id',
      customerId: 'customer-1',
      customerName: 'Budi',
      customerPhone: '081234567890',
      pickup: pickup,
      dropoff: dropoff,
      status: status,
      fare: const FareBreakdown(
        distanceKm: 4,
        billableDistanceKm: 4,
        baseFare: 8000,
        perKmFare: 2500,
        distanceCharge: 10000,
        roundingAdjustment: 0,
        total: 18000,
        minimumApplied: false,
      ),
      paymentMethod: PaymentMethod.cod,
      paymentStatus: PaymentStatus.paid,
      createdAt: now,
      updatedAt: now,
    );
  }

  setUp(() {
    repository = _MockDeliveryRepository();
  });

  blocTest<DeliveryHistoryBloc, DeliveryHistoryState>(
    'memuat halaman pertama riwayat',
    setUp: () {
      final DeliveryOrderPage page = DeliveryOrderPage(
        orders: [
          order('1', OrderStatus.pending),
          order('2', OrderStatus.delivered),
        ],
        hasMore: true,
      );
      when(
        () => repository.fetchCustomerOrders(
          customerId: 'customer-1',
          limit: 20,
          before: null,
        ),
      ).thenAnswer((_) async => Right<Failure, DeliveryOrderPage>(page));
    },
    build: () => DeliveryHistoryBloc(repository: repository),
    act: (bloc) => bloc.add(const DeliveryHistoryRequested('customer-1')),
    expect: () => [
      isA<DeliveryHistoryState>().having(
        (state) => state.status,
        'status',
        DeliveryHistoryStatus.loading,
      ),
      isA<DeliveryHistoryState>()
          .having(
              (state) => state.status, 'status', DeliveryHistoryStatus.success)
          .having((state) => state.orders.length, 'orders', 2)
          .having((state) => state.hasMore, 'hasMore', isTrue),
    ],
  );

  blocTest<DeliveryHistoryBloc, DeliveryHistoryState>(
    'filter aktif menyembunyikan pesanan selesai',
    build: () => DeliveryHistoryBloc(repository: repository),
    seed: () => DeliveryHistoryState(
      status: DeliveryHistoryStatus.success,
      orders: [
        order('1', OrderStatus.pending),
        order('2', OrderStatus.delivered),
        order('3', OrderStatus.cancelled),
      ],
    ),
    act: (bloc) => bloc.add(
      const DeliveryHistoryFilterChanged(DeliveryHistoryFilter.active),
    ),
    expect: () => [
      isA<DeliveryHistoryState>()
          .having(
              (state) => state.filter, 'filter', DeliveryHistoryFilter.active)
          .having((state) => state.visibleOrders.length, 'visible', 1),
    ],
  );

  blocTest<DeliveryHistoryBloc, DeliveryHistoryState>(
    'menampilkan kegagalan saat halaman pertama gagal dimuat',
    setUp: () {
      when(
        () => repository.fetchCustomerOrders(
          customerId: 'customer-1',
          limit: 20,
          before: null,
        ),
      ).thenAnswer(
        (_) async => const Left<Failure, DeliveryOrderPage>(
          ServerFailure('Riwayat gagal dimuat.'),
        ),
      );
    },
    build: () => DeliveryHistoryBloc(repository: repository),
    act: (bloc) => bloc.add(const DeliveryHistoryRequested('customer-1')),
    expect: () => [
      isA<DeliveryHistoryState>().having(
        (state) => state.status,
        'status',
        DeliveryHistoryStatus.loading,
      ),
      isA<DeliveryHistoryState>()
          .having(
              (state) => state.status, 'status', DeliveryHistoryStatus.failure)
          .having((state) => state.message, 'message', 'Riwayat gagal dimuat.'),
    ],
  );
}
