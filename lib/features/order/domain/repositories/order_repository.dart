import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/order_entity.dart';

/// Kontrak akses data pesanan.
abstract class OrderRepository {
  Stream<List<OrderEntity>> watchCustomerOrders(String customerId);

  /// Pesanan berstatus `pending` — daftar yang bisa diterima kurir.
  Stream<List<OrderEntity>> watchPendingOrders();

  Stream<List<OrderEntity>> watchCourierOrders(String courierId);

  /// Semua pesanan (khusus admin).
  Stream<List<OrderEntity>> watchAllOrders();

  /// Mengembalikan id pesanan yang dibuat.
  Future<Either<Failure, String>> createOrder(OrderDraft draft);

  Future<Either<Failure, Unit>> acceptOrder({
    required String orderId,
    required String courierId,
    required String courierName,
  });

  Future<Either<Failure, Unit>> updateStatus({
    required String orderId,
    required OrderStatus status,
  });

  Future<Either<Failure, Unit>> cancelOrder(String orderId);
}
