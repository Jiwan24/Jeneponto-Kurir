import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../delivery/domain/entities/delivery_order.dart';
import '../entities/payment.dart';

/// Kontrak pembayaran. Implementasi nyata memanggil Cloud Function Midtrans.
abstract class PaymentRepository {
  /// Pantau dokumen `payments/{orderId}`.
  Stream<Payment?> watchPayment(String orderId);

  /// Ambil status terbaru sekali (tombol "Saya sudah bayar").
  Future<Either<Failure, Payment?>> fetchPayment(String orderId);

  /// Buat transaksi Midtrans Snap untuk [order].
  Future<Either<Failure, Payment>> createMidtransPayment({
    required DeliveryOrder order,
  });
}
