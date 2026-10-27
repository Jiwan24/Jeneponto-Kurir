import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../order/domain/entities/order_entity.dart';
import '../../../order/domain/repositories/order_repository.dart';
import 'admin_event.dart';
import 'admin_state.dart';

/// Mengelola data seluruh pesanan untuk dashboard admin.
class AdminBloc extends Bloc<AdminEvent, AdminState> {
  AdminBloc({required OrderRepository orderRepository})
      : _orderRepository = orderRepository,
        super(const AdminState()) {
    on<AdminOrdersRequested>(_onRequested);
    on<AdminOrdersReceived>(_onReceived);
    on<AdminOrdersFailed>(_onFailed);
  }

  final OrderRepository _orderRepository;
  StreamSubscription<List<OrderEntity>>? _subscription;

  Future<void> _onRequested(
    AdminOrdersRequested event,
    Emitter<AdminState> emit,
  ) async {
    emit(const AdminState(status: AdminStatus.loading));
    await _subscription?.cancel();
    _subscription = _orderRepository.watchAllOrders().listen(
          (orders) => add(AdminOrdersReceived(orders)),
          onError: (_) => add(
            const AdminOrdersFailed('Gagal memuat data pesanan.'),
          ),
        );
  }

  void _onReceived(AdminOrdersReceived event, Emitter<AdminState> emit) {
    emit(AdminState(status: AdminStatus.success, orders: event.orders));
  }

  void _onFailed(AdminOrdersFailed event, Emitter<AdminState> emit) {
    emit(AdminState(status: AdminStatus.failure, message: event.message));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
