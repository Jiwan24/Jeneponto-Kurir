import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/delivery_repository.dart';
import 'delivery_checkout_state.dart';

/// Mengelola proses pembuatan pesanan dari form "Cari Kurir".
class DeliveryCheckoutBloc
    extends Bloc<DeliveryCheckoutEvent, DeliveryCheckoutState> {
  DeliveryCheckoutBloc({required DeliveryRepository repository})
      : _repository = repository,
        super(const DeliveryCheckoutState()) {
    on<DeliveryCheckoutSubmitted>(_onSubmitted);
    on<DeliveryCheckoutReset>(_onReset);
  }

  final DeliveryRepository _repository;

  Future<void> _onSubmitted(
    DeliveryCheckoutSubmitted event,
    Emitter<DeliveryCheckoutState> emit,
  ) async {
    if (state.isSubmitting) return;

    emit(state.copyWith(
      status: DeliveryCheckoutStatus.submitting,
      paymentMethod: event.draft.paymentMethod,
      clearMessage: true,
      clearCreatedOrder: true,
    ));

    final result = await _repository.createOrder(event.draft);
    result.fold(
      (failure) => emit(state.copyWith(
        status: DeliveryCheckoutStatus.failure,
        message: failure.message,
      )),
      (orderId) => emit(state.copyWith(
        status: DeliveryCheckoutStatus.success,
        createdOrderId: orderId,
        message: 'Pesanan berhasil dibuat.',
      )),
    );
  }

  void _onReset(
    DeliveryCheckoutReset event,
    Emitter<DeliveryCheckoutState> emit,
  ) {
    emit(const DeliveryCheckoutState());
  }
}
