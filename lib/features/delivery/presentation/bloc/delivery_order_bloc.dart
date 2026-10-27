import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/delivery_order.dart';
import '../../domain/repositories/delivery_repository.dart';
import 'delivery_order_state.dart';

/// Memantau satu pesanan (detail & proses mencari kurir) dan pembatalan.
class DeliveryOrderBloc extends Bloc<DeliveryOrderEvent, DeliveryOrderState> {
  DeliveryOrderBloc({required DeliveryRepository repository})
      : _repository = repository,
        super(const DeliveryOrderState()) {
    on<DeliveryOrderRequested>(_onRequested);
    on<DeliveryOrderReceived>(_onReceived);
    on<DeliveryOrderWatchFailed>(_onWatchFailed);
    on<DeliveryOrderCancelRequested>(_onCancel);
    on<DeliveryOrderMessageCleared>(_onMessageCleared);
  }

  final DeliveryRepository _repository;
  StreamSubscription<DeliveryOrder?>? _subscription;

  Future<void> _onRequested(
    DeliveryOrderRequested event,
    Emitter<DeliveryOrderState> emit,
  ) async {
    if (event.orderId.isEmpty) {
      emit(state.copyWith(
        status: DeliveryOrderViewStatus.failure,
        message: 'Pesanan tidak ditemukan.',
      ));
      return;
    }

    emit(state.copyWith(
      status: DeliveryOrderViewStatus.loading,
      clearMessage: true,
      clearCancelSucceeded: true,
    ));

    await _subscription?.cancel();
    _subscription = _repository.watchOrder(event.orderId).listen(
          (order) => add(DeliveryOrderReceived(order)),
          onError: (_) => add(
            const DeliveryOrderWatchFailed('Gagal memuat pesanan.'),
          ),
        );
  }

  void _onReceived(
    DeliveryOrderReceived event,
    Emitter<DeliveryOrderState> emit,
  ) {
    if (event.order == null) {
      emit(state.copyWith(
        status: DeliveryOrderViewStatus.failure,
        message: 'Pesanan tidak ditemukan.',
      ));
      return;
    }
    emit(state.copyWith(
      status: DeliveryOrderViewStatus.success,
      order: event.order,
      clearMessage: true,
    ));
  }

  void _onWatchFailed(
    DeliveryOrderWatchFailed event,
    Emitter<DeliveryOrderState> emit,
  ) {
    emit(state.copyWith(
      status: DeliveryOrderViewStatus.failure,
      message: event.message,
    ));
  }

  Future<void> _onCancel(
    DeliveryOrderCancelRequested event,
    Emitter<DeliveryOrderState> emit,
  ) async {
    if (state.isCancelling) return;
    emit(state.copyWith(
      isCancelling: true,
      clearMessage: true,
      clearCancelSucceeded: true,
    ));

    final result = await _repository.cancelOrder(
      orderId: event.orderId,
      reason: event.reason,
    );
    result.fold(
      (failure) => emit(state.copyWith(
        isCancelling: false,
        message: failure.message,
      )),
      (_) => emit(state.copyWith(
        isCancelling: false,
        cancelSucceeded: true,
        message: 'Pesanan dibatalkan.',
      )),
    );
  }

  void _onMessageCleared(
    DeliveryOrderMessageCleared event,
    Emitter<DeliveryOrderState> emit,
  ) {
    emit(state.copyWith(clearMessage: true));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
