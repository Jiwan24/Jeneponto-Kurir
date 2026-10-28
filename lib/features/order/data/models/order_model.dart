import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/order_entity.dart';

/// Representasi dokumen `orders/{id}` di Firestore.
class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.customerId,
    required super.customerName,
    required super.pickupAddress,
    required super.destinationAddress,
    required super.distanceKm,
    required super.price,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    super.courierId,
    super.courierName,
    super.note,
  });

  factory OrderModel.fromDraft(
    OrderDraft draft, {
    required String id,
    required DateTime now,
  }) {
    return OrderModel(
      id: id,
      customerId: draft.customerId,
      customerName: draft.customerName,
      pickupAddress: draft.pickupAddress,
      destinationAddress: draft.destinationAddress,
      distanceKm: draft.distanceKm,
      price: draft.price,
      status: OrderStatus.pending,
      note: draft.note,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory OrderModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return OrderModel.fromMap(doc.data() ?? <String, dynamic>{}, id: doc.id);
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, {required String id}) {
    return OrderModel(
      id: id,
      customerId: map['customerId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      courierId: map['courierId'] as String?,
      courierName: map['courierName'] as String?,
      pickupAddress: map['pickupAddress'] as String? ?? '',
      destinationAddress: map['destinationAddress'] as String? ?? '',
      note: map['note'] as String? ?? '',
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0,
      price: (map['price'] as num?)?.toInt() ?? 0,
      status: OrderStatus.fromString(map['status'] as String?),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'courierId': courierId,
      'courierName': courierName,
      'pickupAddress': pickupAddress,
      'destinationAddress': destinationAddress,
      'note': note,
      'distanceKm': distanceKm,
      'price': price,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
