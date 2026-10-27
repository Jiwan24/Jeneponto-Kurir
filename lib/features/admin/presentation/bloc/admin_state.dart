import 'package:equatable/equatable.dart';

import '../../../order/domain/entities/order_entity.dart';

enum AdminStatus { initial, loading, success, failure }

class AdminState extends Equatable {
  const AdminState({
    this.status = AdminStatus.initial,
    this.orders = const [],
    this.message,
  });

  final AdminStatus status;
  final List<OrderEntity> orders;
  final String? message;

  /// Jumlah pesanan per status, dipakai kartu ringkasan di dashboard.
  int countOf(OrderStatus target) =>
      orders.where((order) => order.status == target).length;

  int get total => orders.length;

  /// Pesanan yang belum dibayar (gateway) atau belum diterima kurir.
  int get waiting =>
      countOf(OrderStatus.awaitingPayment) + countOf(OrderStatus.pending);

  int get active =>
      countOf(OrderStatus.accepted) +
      countOf(OrderStatus.pickedUp) +
      countOf(OrderStatus.inTransit);

  @override
  List<Object?> get props => [status, orders, message];
}
