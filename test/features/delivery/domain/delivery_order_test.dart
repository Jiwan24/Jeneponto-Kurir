import 'package:flutter_test/flutter_test.dart';
import 'package:jeneponto_kurir/core/utils/price_calculator.dart';
import 'package:jeneponto_kurir/features/delivery/domain/entities/coordinate.dart';
import 'package:jeneponto_kurir/features/delivery/domain/entities/delivery_address.dart';
import 'package:jeneponto_kurir/features/delivery/domain/entities/delivery_order.dart';
import 'package:jeneponto_kurir/features/delivery/domain/entities/payment_method.dart';
import 'package:jeneponto_kurir/features/order/domain/entities/order_entity.dart';

void main() {
  final DateTime now = DateTime(2026, 10, 27, 10);

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

  DeliveryOrder buildOrder({
    required OrderStatus status,
    required PaymentMethod paymentMethod,
    required PaymentStatus paymentStatus,
    String? courierId,
  }) {
    return DeliveryOrder(
      id: 'order-1',
      code: 'JK-261027-8F2A',
      customerId: 'customer-1',
      customerName: 'Budi',
      customerPhone: '081234567890',
      pickup: pickup,
      dropoff: dropoff,
      status: status,
      fare: PriceCalculator.quote(distanceKm: 4.2),
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      courierId: courierId,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('DeliveryOrder status helpers', () {
    test('gateway yang belum dibayar menunggu pembayaran dan bisa dibatalkan',
        () {
      final DeliveryOrder order = buildOrder(
        status: OrderStatus.awaitingPayment,
        paymentMethod: PaymentMethod.midtrans,
        paymentStatus: PaymentStatus.unpaid,
      );

      expect(order.isAwaitingPayment, isTrue);
      expect(order.isSearchingCourier, isFalse);
      expect(order.canCancel, isTrue);
      expect(order.isActive, isTrue);
    });

    test('gateway yang sudah dibayar tidak bisa dibatalkan', () {
      final DeliveryOrder order = buildOrder(
        status: OrderStatus.awaitingPayment,
        paymentMethod: PaymentMethod.midtrans,
        paymentStatus: PaymentStatus.paid,
      );

      expect(order.isAwaitingPayment, isFalse);
      expect(order.canCancel, isFalse);
    });

    test('gateway lunas berstatus pending sudah mencari kurir', () {
      final DeliveryOrder order = buildOrder(
        status: OrderStatus.pending,
        paymentMethod: PaymentMethod.midtrans,
        paymentStatus: PaymentStatus.paid,
      );

      expect(order.isAwaitingPayment, isFalse);
      expect(order.isSearchingCourier, isTrue);
      expect(order.canCancel, isFalse);
    });

    test('COD pending bisa dibatalkan sebelum kurir menerima', () {
      final DeliveryOrder order = buildOrder(
        status: OrderStatus.pending,
        paymentMethod: PaymentMethod.cod,
        paymentStatus: PaymentStatus.unpaid,
      );

      expect(order.isAwaitingPayment, isFalse);
      expect(order.isSearchingCourier, isTrue);
      expect(order.canCancel, isTrue);
    });

    test('pesanan yang sudah diambil atau selesai tidak bisa dibatalkan', () {
      final DeliveryOrder accepted = buildOrder(
        status: OrderStatus.accepted,
        paymentMethod: PaymentMethod.cod,
        paymentStatus: PaymentStatus.unpaid,
        courierId: 'courier-1',
      );
      final DeliveryOrder delivered = buildOrder(
        status: OrderStatus.delivered,
        paymentMethod: PaymentMethod.cod,
        paymentStatus: PaymentStatus.paid,
        courierId: 'courier-1',
      );
      final DeliveryOrder cancelled = buildOrder(
        status: OrderStatus.cancelled,
        paymentMethod: PaymentMethod.midtrans,
        paymentStatus: PaymentStatus.unpaid,
      );

      expect(accepted.canCancel, isFalse);
      expect(delivered.canCancel, isFalse);
      expect(delivered.isActive, isFalse);
      expect(cancelled.canCancel, isFalse);
      expect(cancelled.isAwaitingPayment, isFalse);
    });
  });
}
