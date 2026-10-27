import 'package:dartz/dartz.dart';

import 'package:jeneponto_kurir/features/common/error/failures.dart';
import '../entities/delivery_order.dart';

/// Kontrak akses data pesanan pengiriman untuk alur pelanggan.
abstract class DeliveryRepository {
  /// Pantau satu pesanan secara realtime (detail & proses cari kurir).
  Stream<DeliveryOrder?> watchOrder(String orderId);

  /// Ambil satu pesanan sekali (dipakai sebelum membuka pembayaran).
  Future<Either<Failure, DeliveryOrder?>> getOrder(String orderId);

  /// Buat pesanan baru dan kembalikan id dokumen `orders/{id}`.
  Future<Either<Failure, String>> createOrder(DeliveryDraft draft);

  /// Riwayat pesanan dengan paginasi cursor berbasis `createdAt`.
  Future<Either<Failure, DeliveryOrderPage>> fetchCustomerOrders({
    required String customerId,
    int limit = 20,
    DateTime? before,
  });

  /// Pantau pesanan terbaru pelanggan (untuk beranda).
  Stream<List<DeliveryOrder>> watchCustomerOrders(
    String customerId, {
    int limit = 10,
  });

  /// Batalkan pesanan yang belum diambil kurir.
  Future<Either<Failure, Unit>> cancelOrder({
    required String orderId,
    String? reason,
  });
}
