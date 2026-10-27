import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../delivery/domain/entities/delivery_order.dart';
import '../../../delivery/domain/entities/payment_method.dart';
import '../../domain/entities/payment.dart';

/// Pemetaan `payments/{orderId}`.
class PaymentModel extends Payment {
  const PaymentModel({
    required super.id,
    required super.orderId,
    required super.amount,
    required super.provider,
    required super.method,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    super.orderCode,
    super.customerId,
    super.courierId,
    super.channel,
    super.midtransOrderId,
    super.snapToken,
    super.redirectUrl,
    super.transactionId,
    super.failureReason,
    super.paidAt,
    super.expiresAt,
  });

  factory PaymentModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> map = doc.data() ?? <String, dynamic>{};
    return PaymentModel(
      id: doc.id,
      orderId: map['orderId'] as String? ?? doc.id,
      orderCode: map['orderCode'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      courierId: map['courierId'] as String?,
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      provider: PaymentProvider.fromString(map['provider'] as String?),
      method: PaymentMethod.fromString(map['method'] as String?),
      status: PaymentStatus.fromString(map['status'] as String?),
      channel: map['channel'] as String?,
      midtransOrderId: map['midtransOrderId'] as String?,
      snapToken: map['snapToken'] as String?,
      redirectUrl: map['redirectUrl'] as String?,
      transactionId: map['transactionId'] as String?,
      failureReason: map['failureReason'] as String?,
      createdAt: _date(map['createdAt']) ?? DateTime.now(),
      updatedAt: _date(map['updatedAt']) ?? DateTime.now(),
      paidAt: _date(map['paidAt']),
      expiresAt: _date(map['expiresAt']),
    );
  }

  factory PaymentModel.fromFunctionResponse(
    Map<String, dynamic> data, {
    required DeliveryOrder order,
  }) {
    final DateTime now = DateTime.now();
    return PaymentModel(
      id: order.id,
      orderId: order.id,
      orderCode: order.code,
      customerId: order.customerId,
      amount: (data['amount'] as num?)?.toInt() ?? order.price,
      provider: PaymentProvider.midtrans,
      method: PaymentMethod.midtrans,
      status: PaymentStatus.pending,
      midtransOrderId: data['midtransOrderId'] as String?,
      snapToken: data['token'] as String? ?? data['snapToken'] as String?,
      redirectUrl: data['redirectUrl'] as String?,
      createdAt: now,
      updatedAt: now,
      expiresAt: _date(data['expiresAt']),
    );
  }
}

DateTime? _date(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
