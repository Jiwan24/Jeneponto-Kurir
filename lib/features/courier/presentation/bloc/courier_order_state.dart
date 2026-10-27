import 'package:equatable/equatable.dart';

import '../../../order/domain/entities/order_entity.dart';

class CourierOrderState extends Equatable {
  const CourierOrderState({
    this.isLoading = true,
    this.availableOrders = const [],
    this.myDeliveries = const [],
    this.processingOrderId,
    this.message,
  });

  final bool isLoading;
  final List<OrderEntity> availableOrders;
  final List<OrderEntity> myDeliveries;

  /// Id order yang sedang diproses (terima/ubah status) untuk loading tombol.
  final String? processingOrderId;

  final String? message;

  CourierOrderState copyWith({
    bool? isLoading,
    List<OrderEntity>? availableOrders,
    List<OrderEntity>? myDeliveries,
    String? processingOrderId,
    String? message,
    bool clearProcessing = false,
    bool clearMessage = false,
  }) {
    return CourierOrderState(
      isLoading: isLoading ?? this.isLoading,
      availableOrders: availableOrders ?? this.availableOrders,
      myDeliveries: myDeliveries ?? this.myDeliveries,
      processingOrderId:
          clearProcessing ? null : processingOrderId ?? this.processingOrderId,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props =>
      [isLoading, availableOrders, myDeliveries, processingOrderId, message];
}
