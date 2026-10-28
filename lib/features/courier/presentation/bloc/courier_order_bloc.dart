import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../order/domain/entities/order_entity.dart';
import '../../order/domain/repositories/order_repository.dart';
import 'courier_order_event.dart';
import 'courier_order_state.dart';

/// Mengelola dashboard kurir: order tersedia, tugas saya,
/// penerimaan order, dan progres status pengiriman.
class CourierOrderBloc extends Bloc<CourierOrderEvent, CourierOrderState> {
  CourierOrderBloc({required OrderRepository orderRepository})
      : _orderRepository = orderRepository,
        super(const CourierOrderState()) {
    on<CourierOrdersRequested>(_onRequested);
    on<CourierAvailableReceived>(_onAvailableReceived);
    on<CourierDeliveriesReceived>(_onDeliveriesReceived);
    on<CourierWatchFailed>(_onWatchFailed);
    on<CourierAcceptRequested>(_onAccept);
    on<CourierAdvanceRequested>(_onAdvance);
  }

  final OrderRepository _orderRepository;
  StreamSubscription<List<OrderEntity>>? _availableSubscription;
  StreamSubscription<List<OrderEntity>>? _deliveriesSubscription;

  String _courierId = '';
  String _courierName = '';

  Future<void> _onRequested(
    CourierOrdersRequested event,
    Emitter<CourierOrderState> emit,
  ) async {
    _courierId = event.courierId;
    _courierName = event.courierName;
    emit(state.copyWith(isLoading: true, clearMessage: true));

    await _availableSubscription?.cancel();
    await _deliveriesSubscription?.cancel();

    _availableSubscription =
        _orderRepository.watchPendingOrders().listen(
              (orders) => add(CourierAvailableReceived(orders)),
              onError: (_) => add(
                const CourierWatchFailed('Gagal memuat order tersedia.'),
              ),
            );

    _deliveriesSubscription =
        _orderRepository.watchCourierOrders(_courierId).listen(
              (orders) => add(CourierDeliveriesReceived(orders)),
              onError: (_) => add(
                const CourierWatchFailed('Gagal memuat tugas saya.'),
              ),
            );
  }

  void _onAvailableReceived(
    CourierAvailableReceived event,
    Emitter<CourierOrderState> emit,
  ) {
    emit(state.copyWith(
      isLoading: false,
      availableOrders: event.orders,
      clearMessage: true,
    ));
  }

  void _onDeliveriesReceived(
    CourierDeliveriesReceived event,
    Emitter<CourierOrderState> emit,
  ) {
    emit(state.copyWith(
      isLoading: false,
      myDeliveries: event.orders,
      clearMessage: true,
    ));
  }

  void _onWatchFailed(CourierWatchFailed event, Emitter<CourierOrderState> emit) {
    emit(state.copyWith(isLoading: false, message: event.message));
  }

  Future<void> _onAccept(
    CourierAcceptRequested event,
    Emitter<CourierOrderState> emit,
  ) async {
    emit(state.copyWith(
      processingOrderId: event.order.id,
      clearMessage: true,
    ));
    final result = await _orderRepository.acceptOrder(
      orderId: event.order.id,
      courierId: _courierId,
      courierName: _courierName,
    );
    result.fold(
      (failure) => emit(state.copyWith(
        clearProcessing: true,
        message: failure.message,
      )),
      (_) => emit(state.copyWith(
        clearProcessing: true,
        message: 'Order diterima. Selamat mengantar!',
      )),
    );
  }

  Future<void> _onAdvance(
    CourierAdvanceRequested event,
    Emitter<CourierOrderState> emit,
  ) async {
    final OrderStatus? next = event.order.status.nextStep;
    if (next == null) return;

    emit(state.copyWith(
      processingOrderId: event.order.id,
      clearMessage: true,
    ));
    final result = await _orderRepository.updateStatus(
      orderId: event.order.id,
      status: next,
    );
    result.fold(
      (failure) => emit(state.copyWith(
        clearProcessing: true,
        message: failure.message,
      )),
      (_) => emit(state.copyWith(
        clearProcessing: true,
        message: 'Status diperbarui: ${next.label}.',
      )),
    );
  }

  @override
  Future<void> close() async {
    await _availableSubscription?.cancel();
    await _deliveriesSubscription?.cancel();
    return super.close();
  }
}
