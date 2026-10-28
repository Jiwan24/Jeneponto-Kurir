import 'package:equatable/equatable.dart';

import '../../order/domain/entities/order_entity.dart';

/// Event [AdminBloc].
abstract class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object?> get props => const [];
}

class AdminOrdersRequested extends AdminEvent {
  const AdminOrdersRequested();
}

class AdminOrdersReceived extends AdminEvent {
  const AdminOrdersReceived(this.orders);

  final List<OrderEntity> orders;

  @override
  List<Object?> get props => [orders];
}

class AdminOrdersFailed extends AdminEvent {
  const AdminOrdersFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
