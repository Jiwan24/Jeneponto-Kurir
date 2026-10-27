import 'package:equatable/equatable.dart';

import '../../../delivery/domain/entities/payment_method.dart';

/// Penyedia pembayaran: tunai di tempat atau payment gateway.
enum PaymentProvider {
  cash('Tunai'),
  midtrans('Midtrans');

  const PaymentProvider(this.label);
  final String label;

  static PaymentProvider fromString(String? value) {
    return PaymentProvider.values.firstWhere(
      (provider) => provider.name == value,
      orElse: () => PaymentProvider.cash,
    );
  }
}

/// Catatan pembayaran di koleksi `payments/{orderId}`.
///
/// Dokumen ini ditulis oleh Cloud Function (Midtrans) atau trigger
/// `onOrderDelivered` (COD), bukan oleh client.
class Payment extends Equatable {
  const Payment({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.provider,
    required this.method,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.orderCode = '',
    this.customerId = '',
    this.courierId,
    this.channel,
    this.midtransOrderId,
    this.snapToken,
    this.redirectUrl,
    this.transactionId,
    this.failureReason,
    this.paidAt,
    this.expiresAt,
  });

  final String id;
  final String orderId;
  final String orderCode;
  final String customerId;
  final String? courierId;
  final int amount;
  final PaymentProvider provider;
  final PaymentMethod method;
  final PaymentStatus status;

  /// Kanal yang dipilih di gateway, mis. `qris`, `gopay`, `bca_va`.
  final String? channel;
  final String? midtransOrderId;
  final String? snapToken;
  final String? redirectUrl;
  final String? transactionId;
  final String? failureReason;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? paidAt;
  final DateTime? expiresAt;

  bool get isPaid => status == PaymentStatus.paid;

  bool get isWaiting => status == PaymentStatus.pending;

  bool get canOpenRedirect =>
      redirectUrl != null &&
      redirectUrl!.isNotEmpty &&
      status == PaymentStatus.pending;

  @override
  List<Object?> get props => [
        id,
        orderId,
        orderCode,
        customerId,
        courierId,
        amount,
        provider,
        method,
        status,
        channel,
        midtransOrderId,
        snapToken,
        redirectUrl,
        transactionId,
        failureReason,
        createdAt,
        updatedAt,
        paidAt,
        expiresAt,
      ];
}
