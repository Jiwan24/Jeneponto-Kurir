import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/order_repository.dart';
import 'order_event.dart';
import 'order_state.dart';

/// Mengelola daftar pesanan pelanggan + pembuatan/pembatalan pesanan.
///
/// Satu instance dibuat per halaman (`sl.registerFactory`), sehingga
/// langganan stream selalu sesuai user yang sedang aktif.
class OrderBloc extends Bloc<OrderEvent, OrderState> {
  OrderBloc({required OrderRepository orderRepository})
      : _orderRepository = orderRepository,
        super(const OrderState()) {
    on<OrderListRequested>(_onListRequested);
    on<OrderReceived>(_onReceived);
    on<OrderWatchFailed>(_onWatchFailed);
    on<OrderCreateSubmitted>(_onCreateSubmitted);
    on<OrderCancelRequested>(_onCancelRequested);
  }

  final OrderRepository _orderRepository;
  StreamSubscription<List<OrderEntity>>? _subscription;

  Future<void> _onListRequested(
    OrderListRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(state.copyWith(
      status: OrderListStatus.loading,
      clearMessage: true,
      clearCreatedOrderId: true,
    ));

    await _subscription?.cancel();
    _subscription = _orderRepository.watchCustomerOrders(event.customerId).listen(
          (orders) => add(OrderReceived(orders)),
          onError: (_) =>
              add(const OrderWatchFailed('Gagal memuat daftar pesanan.')),
        );
  }

  void _onReceived(OrderReceived event, Emitter<OrderState> emit) {
    emit(state.copyWith(
      status: OrderListStatus.success,
      orders: event.orders,
      clearMessage: true,
    ));
  }

  void _onWatchFailed(OrderWatchFailed event, Emitter<OrderState> emit) {
    emit(state.copyWith(status: OrderListStatus.failure, message: event.message));
  }

  Future<void> _onCreateSubmitted(
    OrderCreateSubmitted event,
    Emitter<OrderState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearMessage: true));
    final result = await _orderRepository.createOrder(event.toDraft());
    result.fold(
      (failure) =>
          emit(state.copyWith(isSubmitting: false, message: failure.message)),
      (id) => emit(state.copyWith(
        isSubmitting: false,
        createdOrderId: id,
        message: 'Pesanan berhasil dibuat.',
      )),
    );
  }

  Future<void> _onCancelRequested(
    OrderCancelRequested event,
    Emitter<OrderState> emit,
  ) async {
    emit(state.copyWith(clearMessage: true));
    final result = await _orderRepository.cancelOrder(event.orderId);
    result.fold(
      (failure) => emit(state.copyWith(message: failure.message)),
      (_) => emit(state.copyWith(message: 'Pesanan dibatalkan.')),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
