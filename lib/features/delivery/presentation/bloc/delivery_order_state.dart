import 'package:equatable/equatable.dart';

import '../../domain/entities/delivery_order.dart';

enum DeliveryOrderViewStatus { initial, loading, success, failure }

class DeliveryOrderState extends Equatable {
  const DeliveryOrderState({
    this.status = DeliveryOrderViewStatus.initial,
    this.order,
    this.message,
    this.isCancelling = false,
    this.cancelSucceeded = false,
  });

  final DeliveryOrderViewStatus status;
  final DeliveryOrder? order;
  final String? message;
  final bool isCancelling;
  final bool cancelSucceeded;

  DeliveryOrderState copyWith({
    DeliveryOrderViewStatus? status,
    DeliveryOrder? order,
    String? message,
    bool? isCancelling,
    bool? cancelSucceeded,
    bool clearMessage = false,
    bool clearCancelSucceeded = false,
  }) {
    return DeliveryOrderState(
      status: status ?? this.status,
      order: order ?? this.order,
      message: clearMessage ? null : message ?? this.message,
      isCancelling: isCancelling ?? this.isCancelling,
      cancelSucceeded: clearCancelSucceeded
          ? false
          : cancelSucceeded ?? this.cancelSucceeded,
    );
  }

  @override
  List<Object?> get props =>
      [status, order, message, isCancelling, cancelSucceeded];
}

abstract class DeliveryOrderEvent extends Equatable {
  const DeliveryOrderEvent();

  @override
  List<Object?> get props => const [];
}

class DeliveryOrderRequested extends DeliveryOrderEvent {
  const DeliveryOrderRequested(this.orderId);

  final String orderId;

  @override
  List<Object?> get props => [orderId];
}

class DeliveryOrderReceived extends DeliveryOrderEvent {
  const DeliveryOrderReceived(this.order);

  final DeliveryOrder? order;

  @override
  List<Object?> get props => [order];
}

class DeliveryOrderWatchFailed extends DeliveryOrderEvent {
  const DeliveryOrderWatchFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class DeliveryOrderCancelRequested extends DeliveryOrderEvent {
  const DeliveryOrderCancelRequested({required this.orderId, this.reason});

  final String orderId;
  final String? reason;

  @override
  List<Object?> get props => [orderId, reason];
}

class DeliveryOrderMessageCleared extends DeliveryOrderEvent {
  const DeliveryOrderMessageCleared();
}
