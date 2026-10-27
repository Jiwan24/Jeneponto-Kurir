import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../delivery/domain/entities/delivery_order.dart';
import '../../../delivery/domain/entities/payment_method.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';
import 'payment_state.dart';

/// Mengelola pembayaran satu pesanan (COD atau Midtrans Snap).
class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  PaymentBloc({required PaymentRepository repository})
      : _repository = repository,
        super(const PaymentState()) {
    on<PaymentStarted>(_onStarted);
    on<PaymentCreateRequested>(_onCreate);
    on<PaymentCheckRequested>(_onCheck);
    on<PaymentReceived>(_onReceived);
    on<PaymentStreamFailed>(_onStreamFailed);
    on<PaymentMessageCleared>(_onMessageCleared);
  }

  final PaymentRepository _repository;
  StreamSubscription<Payment?>? _subscription;
  DeliveryOrder? _order;

  Future<void> _onStarted(
    PaymentStarted event,
    Emitter<PaymentState> emit,
  ) async {
    _order = event.order;
    await _subscription?.cancel();
    _subscription = null;

    if (event.order.paymentMethod == PaymentMethod.cod) {
      emit(state.copyWith(
        status: PaymentFlowStatus.ready,
        order: event.order,
        clearPayment: true,
        message: 'Pembayaran dilakukan tunai saat paket diterima.',
      ));
      return;
    }

    emit(state.copyWith(
      status: PaymentFlowStatus.loading,
      order: event.order,
      clearMessage: true,
    ));

    _subscription = _repository.watchPayment(event.order.id).listen(
          (payment) => add(PaymentReceived(payment)),
          onError: (_) => add(
            const PaymentStreamFailed(
              'Gagal memantau status pembayaran.',
            ),
          ),
        );
  }

  Future<void> _onCreate(
    PaymentCreateRequested event,
    Emitter<PaymentState> emit,
  ) async {
    final DeliveryOrder? order = _order;
    if (order == null || state.isBusy) return;

    emit(state.copyWith(
      status: PaymentFlowStatus.creating,
      clearMessage: true,
    ));

    final result = await _repository.createMidtransPayment(order: order);
    result.fold(
      (failure) => emit(state.copyWith(
        status: PaymentFlowStatus.failure,
        message: failure.message,
      )),
      (payment) => emit(state.copyWith(
        status: PaymentFlowStatus.waiting,
        payment: payment,
        message: 'Lanjutkan pembayaran di browser.',
      )),
    );
  }

  Future<void> _onCheck(
    PaymentCheckRequested event,
    Emitter<PaymentState> emit,
  ) async {
    if (state.isBusy) return;
    emit(state.copyWith(isChecking: true, clearMessage: true));

    final result = await _repository.fetchPayment(_order?.id ?? '');
    result.fold(
      (failure) => emit(state.copyWith(
        isChecking: false,
        message: failure.message,
      )),
      (payment) {
        if (payment == null) {
          emit(state.copyWith(
            isChecking: false,
            status: PaymentFlowStatus.ready,
            clearPayment: true,
            message: 'Pembayaran belum dibuat. Tekan "Bayar Sekarang".',
          ));
        } else {
          _emitPayment(emit, payment, isChecking: false);
        }
      },
    );
  }

  void _onReceived(
    PaymentReceived event,
    Emitter<PaymentState> emit,
  ) {
    if (event.payment == null) {
      emit(state.copyWith(
        status: PaymentFlowStatus.ready,
        clearPayment: true,
        clearMessage: true,
      ));
      return;
    }
    _emitPayment(emit, event.payment!);
  }

  void _emitPayment(
    Emitter<PaymentState> emit,
    Payment payment, {
    bool? isChecking,
  }) {
    switch (payment.status) {
      case PaymentStatus.paid:
        emit(state.copyWith(
          status: PaymentFlowStatus.paid,
          payment: payment,
          isChecking: isChecking ?? false,
          message: 'Pembayaran berhasil.',
        ));
        return;
      case PaymentStatus.pending:
        emit(state.copyWith(
          status: PaymentFlowStatus.waiting,
          payment: payment,
          isChecking: isChecking ?? false,
          clearMessage: true,
        ));
        return;
      case PaymentStatus.failed:
      case PaymentStatus.expired:
      case PaymentStatus.refunded:
        emit(state.copyWith(
          status: PaymentFlowStatus.failure,
          payment: payment,
          isChecking: isChecking ?? false,
          message: payment.failureReason ??
              'Pembayaran ${payment.status.label.toLowerCase()}. Coba lagi.',
        ));
        return;
      case PaymentStatus.unpaid:
        emit(state.copyWith(
          status: PaymentFlowStatus.ready,
          payment: payment,
          isChecking: isChecking ?? false,
          clearMessage: true,
        ));
        return;
    }
  }

  void _onStreamFailed(
    PaymentStreamFailed event,
    Emitter<PaymentState> emit,
  ) {
    emit(state.copyWith(
      status: PaymentFlowStatus.failure,
      message: event.message,
      isChecking: false,
    ));
  }

  void _onMessageCleared(
    PaymentMessageCleared event,
    Emitter<PaymentState> emit,
  ) {
    emit(state.copyWith(clearMessage: true));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
