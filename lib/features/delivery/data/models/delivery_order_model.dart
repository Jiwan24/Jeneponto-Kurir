import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:jeneponto_kurir/features/delivery/domain/services/price_calculator.dart';
import 'package:jeneponto_kurir/features/delivery/domain/entities/order_status.dart';
import '../../domain/entities/coordinate.dart';
import '../../domain/entities/delivery_address.dart';
import '../../domain/entities/delivery_order.dart';
import '../../domain/entities/payment_method.dart';

/// Pemetaan dokumen `orders/{id}` ke entitas [DeliveryOrder].
///
/// Dokumen ini dipakai bersama modul kurir/admin. Semua field lama tetap
/// ditulis agar modul lain tidak perlu berubah; field baru bersifat aditif.
class DeliveryOrderModel extends DeliveryOrder {
  const DeliveryOrderModel({
    required super.id,
    required super.code,
    required super.customerId,
    required super.customerName,
    required super.customerPhone,
    required super.pickup,
    required super.dropoff,
    required super.status,
    required super.fare,
    required super.paymentMethod,
    required super.paymentStatus,
    required super.createdAt,
    required super.updatedAt,
    super.courierId,
    super.courierName,
    super.courierPhone,
    super.itemCategory,
    super.weightKg,
    super.itemNotes,
    super.paymentId,
    super.cancelledReason,
    super.acceptedAt,
    super.pickedUpAt,
    super.inTransitAt,
    super.deliveredAt,
    super.paidAt,
    super.cancelledAt,
  });

  factory DeliveryOrderModel.fromDraft(
    DeliveryDraft draft, {
    required String id,
    required String code,
    required DateTime now,
  }) {
    final FareBreakdown fare = draft.fareQuote;
    final bool isGateway = draft.paymentMethod.requiresGateway;
    return DeliveryOrderModel(
      id: id,
      code: code,
      customerId: draft.customerId,
      customerName: draft.customerName,
      customerPhone: draft.customerPhone,
      pickup: draft.pickup,
      dropoff: draft.dropoff,
      status: isGateway ? OrderStatus.awaitingPayment : OrderStatus.pending,
      fare: fare,
      paymentMethod: draft.paymentMethod,
      paymentStatus: PaymentStatus.unpaid,
      itemCategory: draft.itemCategory,
      weightKg: draft.weightKg,
      itemNotes: draft.itemNotes,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory DeliveryOrderModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return DeliveryOrderModel.fromMap(
      doc.data() ?? <String, dynamic>{},
      id: doc.id,
    );
  }

  factory DeliveryOrderModel.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    final String customerName = map['customerName'] as String? ?? '';
    final String customerPhone = map['customerPhone'] as String? ??
        _readContactPhone(map['pickup']) ??
        '';
    final double distanceKm = (map['distanceKm'] as num?)?.toDouble() ?? 0;
    final int storedPrice = (map['price'] as num?)?.toInt() ?? 0;
    final FareBreakdown fare = _readFare(map, distanceKm, storedPrice);
    final OrderStatus status = OrderStatus.fromString(map['status'] as String?);
    final PaymentMethod method =
        PaymentMethod.fromString(map['paymentMethod'] as String?);
    final PaymentStatus paymentStatus = _readPaymentStatus(
      map,
      status: status,
      method: method,
    );

    return DeliveryOrderModel(
      id: id,
      code: (map['code'] as String?)?.trim().isNotEmpty == true
          ? map['code'] as String
          : _fallbackCode(id),
      customerId: map['customerId'] as String? ?? '',
      customerName: customerName,
      customerPhone: customerPhone,
      pickup: _readAddress(
        map['pickup'],
        fallbackAddress: map['pickupAddress'] as String? ?? '',
        fallbackDistrict: map['pickupDistrict'] as String? ?? '',
        fallbackLat: (map['pickupLat'] as num?)?.toDouble(),
        fallbackLng: (map['pickupLng'] as num?)?.toDouble(),
        fallbackContactName: customerName,
        fallbackContactPhone: customerPhone,
        label: 'Penjemputan',
      ),
      dropoff: _readAddress(
        map['dropoff'],
        fallbackAddress: map['destinationAddress'] as String? ?? '',
        fallbackDistrict: map['dropoffDistrict'] as String? ?? '',
        fallbackLat: (map['dropoffLat'] as num?)?.toDouble(),
        fallbackLng: (map['dropoffLng'] as num?)?.toDouble(),
        fallbackContactName: map['recipientName'] as String? ?? '',
        fallbackContactPhone: map['recipientPhone'] as String? ?? '',
        label: 'Tujuan',
      ),
      status: status,
      fare: fare,
      paymentMethod: method,
      paymentStatus: paymentStatus,
      courierId: map['courierId'] as String?,
      courierName: map['courierName'] as String?,
      courierPhone: map['courierPhone'] as String?,
      itemCategory: map['itemCategory'] as String? ?? 'Paket',
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 0,
      itemNotes: map['itemNotes'] as String? ?? map['note'] as String? ?? '',
      paymentId: map['paymentId'] as String?,
      paidAt: _readDate(map['paidAt']),
      createdAt: _readDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: _readDate(map['updatedAt']) ?? DateTime.now(),
      acceptedAt: _readDate(map['acceptedAt']),
      pickedUpAt: _readDate(map['pickedUpAt']),
      inTransitAt: _readDate(map['inTransitAt']),
      deliveredAt: _readDate(map['deliveredAt']),
      cancelledAt: _readDate(map['cancelledAt']),
      cancelledReason: map['cancelledReason'] as String?,
    );
  }

  /// Field yang ditulis saat pesanan dibuat.
  ///
  /// `pickupAddress`, `destinationAddress`, `note`, `price`, dan field lama
  /// lainnya sengaja dipertahankan untuk kompatibilitas job board kurir dan
  /// dashboard admin.
  Map<String, dynamic> toCreateMap() => <String, dynamic>{
        'code': code,
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'courierId': null,
        'courierName': null,
        'courierPhone': null,
        'pickup': _addressToMap(pickup),
        'dropoff': _addressToMap(dropoff),
        'pickupAddress': pickup.fullAddress,
        'destinationAddress': dropoff.fullAddress,
        'pickupDistrict': pickup.district,
        'dropoffDistrict': dropoff.district,
        'pickupLat': pickup.coordinate.latitude,
        'pickupLng': pickup.coordinate.longitude,
        'dropoffLat': dropoff.coordinate.latitude,
        'dropoffLng': dropoff.coordinate.longitude,
        'recipientName': dropoff.contactName,
        'recipientPhone': dropoff.contactPhone,
        'note': itemNotes,
        'itemCategory': itemCategory,
        'itemNotes': itemNotes,
        'weightKg': weightKg,
        'distanceKm': fare.distanceKm,
        'price': fare.total,
        'fare': fare.toMap(),
        'status': status.name,
        'paymentMethod': paymentMethod.name,
        'paymentStatus': paymentStatus.name,
        'paymentProvider': paymentMethod.requiresGateway ? 'midtrans' : 'cash',
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}

// ---------------------------------------------------------------------------
// Helper parsing (toleran terhadap dokumen lama yang belum punya field baru).
// ---------------------------------------------------------------------------

Map<String, dynamic> _addressToMap(DeliveryAddress address) {
  return <String, dynamic>{
    'label': address.label,
    'address': address.address,
    'district': address.district,
    'lat': address.coordinate.latitude,
    'lng': address.coordinate.longitude,
    'contactName': address.contactName,
    'contactPhone': address.contactPhone,
    'notes': address.notes,
  };
}

DeliveryAddress _readAddress(
  dynamic value, {
  required String fallbackAddress,
  required String fallbackDistrict,
  required double? fallbackLat,
  required double? fallbackLng,
  required String fallbackContactName,
  required String fallbackContactPhone,
  required String label,
}) {
  if (value is Map) {
    final Map<dynamic, dynamic> map = value;
    return DeliveryAddress(
      label: map['label'] as String? ?? label,
      address: map['address'] as String? ?? fallbackAddress,
      district: map['district'] as String? ?? fallbackDistrict,
      coordinate: Coordinate(
        (map['lat'] as num?)?.toDouble() ?? fallbackLat ?? 0,
        (map['lng'] as num?)?.toDouble() ?? fallbackLng ?? 0,
      ),
      contactName: map['contactName'] as String? ?? fallbackContactName,
      contactPhone: map['contactPhone'] as String? ?? fallbackContactPhone,
      notes: map['notes'] as String? ?? '',
    );
  }
  return DeliveryAddress(
    label: label,
    address: fallbackAddress,
    district: fallbackDistrict,
    coordinate: Coordinate(fallbackLat ?? 0, fallbackLng ?? 0),
    contactName: fallbackContactName,
    contactPhone: fallbackContactPhone,
  );
}

String? _readContactPhone(dynamic value) {
  if (value is Map) return value['contactPhone'] as String?;
  return null;
}

FareBreakdown _readFare(
  Map<String, dynamic> map,
  double distanceKm,
  int storedPrice,
) {
  final dynamic rawFare = map['fare'];
  if (rawFare is Map) {
    return FareBreakdown.fromMap(Map<String, dynamic>.from(rawFare));
  }

  final FareBreakdown quote = PriceCalculator.quote(distanceKm: distanceKm);
  final int total = storedPrice > 0 ? storedPrice : quote.total;
  final int base = (map['fareBase'] as num?)?.toInt() ?? quote.baseFare;
  final int perKm = (map['farePerKm'] as num?)?.toInt() ?? quote.perKmFare;
  final int distanceCharge =
      (map['fareDistanceCharge'] as num?)?.toInt() ?? quote.distanceCharge;
  return FareBreakdown(
    distanceKm: distanceKm,
    billableDistanceKm: quote.billableDistanceKm,
    baseFare: base,
    perKmFare: perKm,
    distanceCharge: distanceCharge,
    roundingAdjustment: total - base - distanceCharge,
    total: total,
    minimumApplied: quote.minimumApplied,
  );
}

PaymentStatus _readPaymentStatus(
  Map<String, dynamic> map, {
  required OrderStatus status,
  required PaymentMethod method,
}) {
  final String? raw = map['paymentStatus'] as String?;
  if (raw != null && raw.isNotEmpty) {
    return PaymentStatus.fromString(raw);
  }
  // Dokumen lama tidak punya paymentStatus. COD yang sudah delivered
  // dianggap sudah dibayar tunai.
  if (method == PaymentMethod.cod && status == OrderStatus.delivered) {
    return PaymentStatus.paid;
  }
  return PaymentStatus.unpaid;
}

DateTime? _readDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

String _fallbackCode(String id) {
  final String shortId =
      id.replaceAll('-', '').padRight(8, '0').substring(0, 8).toUpperCase();
  return '#$shortId';
}
