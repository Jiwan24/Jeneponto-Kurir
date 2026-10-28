import 'package:equatable/equatable.dart';

import '../../order/domain/entities/order_entity.dart';

/// Event [CourierOrderBloc].
abstract class CourierOrderEvent extends Equatable {
  const CourierOrderEvent();

  @override
  List<Object?> get props => const [];
}

/// Mulai langganan: order tersedia + tugas saya.
class CourierOrdersRequested extends CourierOrderEvent {
  const CourierOrdersRequested({
    required this.courierId,
    required this.courierName,
  });

  final String courierId;
  final String courierName;

  @override
  List<Object?> get props => [courierId, courierName];
}

class CourierAvailableReceived extends CourierOrderEvent {
  const CourierAvailableReceived(this.orders);

  final List<OrderEntity> orders;

  @override
  List<Object?> get props => [orders];
}

class CourierDeliveriesReceived extends CourierOrderEvent {
  const CourierDeliveriesReceived(this.orders);

  final List<OrderEntity> orders;

  @override
  List<Object?> get props => [orders];
}

class CourierWatchFailed extends CourierOrderEvent {
  const CourierWatchFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Terima order tertentu (status -> accepted).
class CourierAcceptRequested extends CourierOrderEvent {
  const CourierAcceptRequested(this.order);

  final OrderEntity order;

  @override
  List<Object?> get props => [order];
}

/// Majukan status pengiriman (accepted -> pickedUp -> inTransit -> delivered).
class CourierAdvanceRequested extends CourierOrderEvent {
  const CourierAdvanceRequested(this.order);

  final OrderEntity order;

  @override
  List<Object?> get props => [order];
}
