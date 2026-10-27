import 'package:equatable/equatable.dart';

import 'package:jeneponto_kurir/features/delivery/domain/services/price_calculator.dart';
import 'package:jeneponto_kurir/features/delivery/domain/entities/order_status.dart';
import 'delivery_address.dart';
import 'payment_method.dart';

/// Pesanan pengiriman dari sudut pandang pelanggan.
///
/// Entitas ini memetakan dokumen `orders/{id}` yang sama dengan modul kurir
/// dan admin. Field lama tetap dipertahankan agar modul lain tidak rusak.
class DeliveryOrder extends Equatable {
  const DeliveryOrder({
    required this.id,
    required this.code,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.pickup,
    required this.dropoff,
    required this.status,
    required this.fare,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAt,
    required this.updatedAt,
    this.courierId,
    this.courierName,
    this.courierPhone,
    this.itemCategory = 'Paket',
    this.weightKg = 0,
    this.itemNotes = '',
    this.paymentId,
    this.cancelledReason,
    this.acceptedAt,
    this.pickedUpAt,
    this.inTransitAt,
    this.deliveredAt,
    this.paidAt,
    this.cancelledAt,
  });

  final String id;

  /// Kode yang mudah dibaca manusia, mis. `JK-261027-8F2A`.
  final String code;

  final String customerId;
  final String customerName;
  final String customerPhone;

  final String? courierId;
  final String? courierName;
  final String? courierPhone;

  final DeliveryAddress pickup;
  final DeliveryAddress dropoff;

  final OrderStatus status;
  final FareBreakdown fare;
  final double weightKg;
  final String itemCategory;
  final String itemNotes;

  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final String? paymentId;
  final DateTime? paidAt;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? inTransitAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final String? cancelledReason;

  int get price => fare.total;

  double get distanceKm => fare.distanceKm;

  bool get isAwaitingPayment =>
      !paymentStatus.isPaid &&
      (status == OrderStatus.awaitingPayment ||
          (status == OrderStatus.pending && paymentMethod.requiresGateway));

  bool get isSearchingCourier =>
      status == OrderStatus.pending &&
      (!paymentMethod.requiresGateway || paymentStatus.isPaid);

  bool get canCancel =>
      (status == OrderStatus.awaitingPayment ||
          status == OrderStatus.pending) &&
      !paymentStatus.isPaid;

  bool get isActive => !status.isFinished;

  bool get hasCourier => courierId != null && courierId!.isNotEmpty;

  DeliveryOrder copyWith({
    String? code,
    OrderStatus? status,
    String? courierId,
    String? courierName,
    String? courierPhone,
    PaymentStatus? paymentStatus,
    String? paymentId,
    DateTime? paidAt,
    DateTime? updatedAt,
    DateTime? acceptedAt,
    DateTime? pickedUpAt,
    DateTime? inTransitAt,
    DateTime? deliveredAt,
    DateTime? cancelledAt,
    String? cancelledReason,
  }) {
    return DeliveryOrder(
      id: id,
      code: code ?? this.code,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      pickup: pickup,
      dropoff: dropoff,
      status: status ?? this.status,
      fare: fare,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentId: paymentId ?? this.paymentId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      courierId: courierId ?? this.courierId,
      courierName: courierName ?? this.courierName,
      courierPhone: courierPhone ?? this.courierPhone,
      itemCategory: itemCategory,
      weightKg: weightKg,
      itemNotes: itemNotes,
      cancelledReason: cancelledReason ?? this.cancelledReason,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      inTransitAt: inTransitAt ?? this.inTransitAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      paidAt: paidAt ?? this.paidAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        code,
        customerId,
        customerName,
        customerPhone,
        courierId,
        courierName,
        courierPhone,
        pickup,
        dropoff,
        status,
        fare.distanceKm,
        fare.billableDistanceKm,
        fare.baseFare,
        fare.perKmFare,
        fare.distanceCharge,
        fare.roundingAdjustment,
        fare.total,
        fare.minimumApplied,
        weightKg,
        itemCategory,
        itemNotes,
        paymentMethod,
        paymentStatus,
        paymentId,
        paidAt,
        createdAt,
        updatedAt,
        acceptedAt,
        pickedUpAt,
        inTransitAt,
        deliveredAt,
        cancelledAt,
        cancelledReason,
      ];
}

/// Data yang dikirim form ke repository saat membuat pesanan.
///
/// Harga dihitung dari [distanceKm] dan [fareConfig] saat draft dibuat.
/// Cloud Function tetap menghitung ulang tarif dari titik peta sebelum
/// pembayaran dan saat pesanan selesai.
class DeliveryDraft extends Equatable {
  const DeliveryDraft({
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.pickup,
    required this.dropoff,
    required this.distanceKm,
    required this.paymentMethod,
    this.itemCategory = 'Paket',
    this.weightKg = 1,
    this.itemNotes = '',
    this.fareConfig = const FareConfig(),
  });

  final String customerId;
  final String customerName;
  final String customerPhone;
  final DeliveryAddress pickup;
  final DeliveryAddress dropoff;

  /// Jarak yang sudah dikoreksi ke perkiraan jarak jalan.
  final double distanceKm;
  final PaymentMethod paymentMethod;
  final String itemCategory;
  final double weightKg;
  final String itemNotes;
  final FareConfig fareConfig;

  FareBreakdown get fareQuote =>
      PriceCalculator.quote(distanceKm: distanceKm, config: fareConfig);

  @override
  List<Object?> get props => [
        customerId,
        customerName,
        customerPhone,
        pickup,
        dropoff,
        distanceKm,
        paymentMethod,
        itemCategory,
        weightKg,
        itemNotes,
        fareConfig.baseFare,
        fareConfig.perKmFare,
        fareConfig.minimumDistanceKm,
        fareConfig.roundingStep,
      ];
}

/// Satu halaman hasil query riwayat pesanan.
class DeliveryOrderPage extends Equatable {
  const DeliveryOrderPage({required this.orders, required this.hasMore});

  final List<DeliveryOrder> orders;
  final bool hasMore;

  @override
  List<Object?> get props => [orders, hasMore];
}
