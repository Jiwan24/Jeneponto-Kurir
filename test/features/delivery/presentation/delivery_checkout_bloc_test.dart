import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeneponto_kurir/features/common/error/failures.dart';
import 'package:jeneponto_kurir/features/delivery/domain/entities/coordinate.dart';
import 'package:jeneponto_kurir/features/delivery/domain/entities/delivery_address.dart';
import 'package:jeneponto_kurir/features/delivery/domain/entities/delivery_order.dart';
import 'package:jeneponto_kurir/features/delivery/domain/entities/payment_method.dart';
import 'package:jeneponto_kurir/features/delivery/domain/repositories/delivery_repository.dart';
import 'package:jeneponto_kurir/features/delivery/presentation/bloc/delivery_checkout_bloc.dart';
import 'package:jeneponto_kurir/features/delivery/presentation/bloc/delivery_checkout_state.dart';
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

  const DeliveryDraft draft = DeliveryDraft(
    customerId: 'customer-1',
    customerName: 'Budi',
    customerPhone: '081234567890',
    pickup: pickup,
    dropoff: dropoff,
    distanceKm: 4.2,
    paymentMethod: PaymentMethod.cod,
    itemCategory: 'Paket',
    weightKg: 1.5,
  );

  setUp(() {
    repository = _MockDeliveryRepository();
  });

  blocTest<DeliveryCheckoutBloc, DeliveryCheckoutState>(
    'membuat order dan mengembalikan id pesanan',
    setUp: () {
      when(() => repository.createOrder(draft))
          .thenAnswer((_) async => const Right<Failure, String>('order-1'));
    },
    build: () => DeliveryCheckoutBloc(repository: repository),
    act: (bloc) => bloc.add(const DeliveryCheckoutSubmitted(draft)),
    expect: () => [
      isA<DeliveryCheckoutState>()
          .having((state) => state.status, 'status',
              DeliveryCheckoutStatus.submitting)
          .having((state) => state.paymentMethod, 'paymentMethod',
              PaymentMethod.cod),
      isA<DeliveryCheckoutState>()
          .having(
              (state) => state.status, 'status', DeliveryCheckoutStatus.success)
          .having((state) => state.createdOrderId, 'createdOrderId', 'order-1'),
    ],
    verify: (_) {
      verify(() => repository.createOrder(draft)).called(1);
    },
  );

  blocTest<DeliveryCheckoutBloc, DeliveryCheckoutState>(
    'meneruskan pesan kegagalan dari repository',
    setUp: () {
      when(() => repository.createOrder(draft)).thenAnswer(
        (_) async => const Left<Failure, String>(ServerFailure('Gagal.')),
      );
    },
    build: () => DeliveryCheckoutBloc(repository: repository),
    act: (bloc) => bloc.add(const DeliveryCheckoutSubmitted(draft)),
    expect: () => [
      isA<DeliveryCheckoutState>().having(
          (state) => state.status, 'status', DeliveryCheckoutStatus.submitting),
      isA<DeliveryCheckoutState>()
          .having(
              (state) => state.status, 'status', DeliveryCheckoutStatus.failure)
          .having((state) => state.message, 'message', 'Gagal.'),
    ],
  );
}
