import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeneponto_kurir/core/error/failures.dart';
import 'package:jeneponto_kurir/core/utils/price_calculator.dart';
import 'package:jeneponto_kurir/features/delivery/domain/entities/coordinate.dart';
import 'package:jeneponto_kurir/features/delivery/domain/entities/delivery_address.dart';
import 'package:jeneponto_kurir/features/delivery/domain/entities/delivery_order.dart';
import 'package:jeneponto_kurir/features/delivery/domain/entities/payment_method.dart';
import 'package:jeneponto_kurir/features/order/domain/entities/order_entity.dart';
import 'package:jeneponto_kurir/features/payments/domain/entities/payment.dart';
import 'package:jeneponto_kurir/features/payments/domain/repositories/payment_repository.dart';
import 'package:jeneponto_kurir/features/payments/presentation/bloc/payment_bloc.dart';
import 'package:jeneponto_kurir/features/payments/presentation/bloc/payment_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockPaymentRepository extends Mock implements PaymentRepository {}

void main() {
  late _MockPaymentRepository repository;

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

  DeliveryOrder buildOrder({required PaymentMethod method}) {
    final DateTime now = DateTime(2026, 10, 27, 10);
    return DeliveryOrder(
      id: 'order-${method.name}',
      code: 'JK-${method.name}',
      customerId: 'customer-1',
      customerName: 'Budi',
      customerPhone: '081234567890',
      pickup: pickup,
      dropoff: dropoff,
      status: method.requiresGateway
          ? OrderStatus.awaitingPayment
          : OrderStatus.pending,
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
      paymentMethod: method,
      paymentStatus: PaymentStatus.unpaid,
      createdAt: now,
      updatedAt: now,
    );
  }

  setUp(() {
    repository = _MockPaymentRepository();
  });

  blocTest<PaymentBloc, PaymentState>(
    'COD langsung siap tanpa memanggil gateway',
    build: () => PaymentBloc(repository: repository),
    act: (bloc) => bloc.add(
      PaymentStarted(buildOrder(method: PaymentMethod.cod)),
    ),
    expect: () => [
      isA<PaymentState>()
          .having((state) => state.status, 'status', PaymentFlowStatus.ready)
          .having((state) => state.message, 'message', contains('tunai')),
    ],
    verify: (_) {
      verifyNever(() => repository.watchPayment(any()));
    },
  );

  blocTest<PaymentBloc, PaymentState>(
    'membuat transaksi Midtrans setelah status siap',
    setUp: () {
      final DeliveryOrder order = buildOrder(method: PaymentMethod.midtrans);
      when(() => repository.watchPayment(order.id))
          .thenAnswer((_) => Stream<Payment?>.value(null));
      when(() => repository.createMidtransPayment(order: order)).thenAnswer(
        (_) async => Right<Failure, Payment>(
          Payment(
            id: order.id,
            orderId: order.id,
            orderCode: order.code,
            customerId: order.customerId,
            amount: order.price,
            provider: PaymentProvider.midtrans,
            method: PaymentMethod.midtrans,
            status: PaymentStatus.pending,
            redirectUrl:
                'https://app.sandbox.midtrans.com/snap/v4/redirection/x',
            snapToken: 'token-1',
            createdAt: DateTime(2026, 10, 27, 10),
            updatedAt: DateTime(2026, 10, 27, 10),
          ),
        ),
      );
    },
    build: () => PaymentBloc(repository: repository),
    act: (bloc) async {
      final DeliveryOrder order = buildOrder(method: PaymentMethod.midtrans);
      bloc.add(PaymentStarted(order));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(const PaymentCreateRequested());
    },
    expect: () => [
      isA<PaymentState>().having(
        (state) => state.status,
        'status',
        PaymentFlowStatus.loading,
      ),
      isA<PaymentState>().having(
        (state) => state.status,
        'status',
        PaymentFlowStatus.ready,
      ),
      isA<PaymentState>().having(
        (state) => state.status,
        'status',
        PaymentFlowStatus.creating,
      ),
      isA<PaymentState>()
          .having((state) => state.status, 'status', PaymentFlowStatus.waiting)
          .having(
            (state) => state.redirectUrl,
            'redirectUrl',
            'https://app.sandbox.midtrans.com/snap/v4/redirection/x',
          ),
    ],
  );
}
