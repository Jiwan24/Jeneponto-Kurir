import 'package:equatable/equatable.dart';

import '../../domain/entities/order_entity.dart';

enum OrderListStatus { initial, loading, success, failure }

class OrderState extends Equatable {
  const OrderState({
    this.status = OrderListStatus.initial,
    this.orders = const [],
    this.message,
    this.isSubmitting = false,
    this.createdOrderId,
  });

  final OrderListStatus status;
  final List<OrderEntity> orders;

  /// Pesan error/feedback yang sedang ditampilkan (snackbar).
  final String? message;

  /// True selama proses pembuatan pesanan berlangsung.
  final bool isSubmitting;

  /// Terisi setelah pembuatan pesanan sukses (dipakai untuk menutup form).
  final String? createdOrderId;

  OrderState copyWith({
    OrderListStatus? status,
    List<OrderEntity>? orders,
    String? message,
    bool? isSubmitting,
    String? createdOrderId,
    bool clearMessage = false,
    bool clearCreatedOrderId = false,
  }) {
    return OrderState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      message: clearMessage ? null : message ?? this.message,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      createdOrderId: clearCreatedOrderId
          ? null
          : createdOrderId ?? this.createdOrderId,
    );
  }

  @override
  List<Object?> get props =>
      [status, orders, message, isSubmitting, createdOrderId];
}
