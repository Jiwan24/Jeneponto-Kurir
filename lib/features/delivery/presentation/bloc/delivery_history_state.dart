import 'package:equatable/equatable.dart';

import '../../domain/entities/delivery_order.dart';

enum DeliveryHistoryStatus { initial, loading, success, failure }

enum DeliveryHistoryFilter {
  all('Semua'),
  active('Aktif'),
  finished('Selesai');

  const DeliveryHistoryFilter(this.label);
  final String label;
}

class DeliveryHistoryState extends Equatable {
  const DeliveryHistoryState({
    this.status = DeliveryHistoryStatus.initial,
    this.orders = const [],
    this.filter = DeliveryHistoryFilter.all,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.message,
  });

  final DeliveryHistoryStatus status;
  final List<DeliveryOrder> orders;
  final DeliveryHistoryFilter filter;
  final bool hasMore;
  final bool isLoadingMore;
  final String? message;

  List<DeliveryOrder> get visibleOrders {
    switch (filter) {
      case DeliveryHistoryFilter.all:
        return orders;
      case DeliveryHistoryFilter.active:
        return orders.where((order) => order.isActive).toList(growable: false);
      case DeliveryHistoryFilter.finished:
        return orders.where((order) => !order.isActive).toList(growable: false);
    }
  }

  DeliveryHistoryState copyWith({
    DeliveryHistoryStatus? status,
    List<DeliveryOrder>? orders,
    DeliveryHistoryFilter? filter,
    bool? hasMore,
    bool? isLoadingMore,
    String? message,
    bool clearMessage = false,
  }) {
    return DeliveryHistoryState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      filter: filter ?? this.filter,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props =>
      [status, orders, filter, hasMore, isLoadingMore, message];
}

abstract class DeliveryHistoryEvent extends Equatable {
  const DeliveryHistoryEvent();

  @override
  List<Object?> get props => const [];
}

class DeliveryHistoryRequested extends DeliveryHistoryEvent {
  const DeliveryHistoryRequested(this.customerId);

  final String customerId;

  @override
  List<Object?> get props => [customerId];
}

class DeliveryHistoryRefreshed extends DeliveryHistoryEvent {
  const DeliveryHistoryRefreshed();
}

class DeliveryHistoryLoadMore extends DeliveryHistoryEvent {
  const DeliveryHistoryLoadMore();
}

class DeliveryHistoryFilterChanged extends DeliveryHistoryEvent {
  const DeliveryHistoryFilterChanged(this.filter);

  final DeliveryHistoryFilter filter;

  @override
  List<Object?> get props => [filter];
}

class DeliveryHistoryMessageCleared extends DeliveryHistoryEvent {
  const DeliveryHistoryMessageCleared();
}
