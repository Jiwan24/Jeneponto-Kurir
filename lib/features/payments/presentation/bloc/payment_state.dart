import 'package:equatable/equatable.dart';

import '../../../delivery/domain/entities/delivery_order.dart';
import '../../../delivery/domain/entities/payment_method.dart';
import '../../domain/entities/payment.dart';

enum PaymentFlowStatus {
  initial,
  loading,
  ready,
  creating,
  waiting,
  paid,
  failure,
}

class PaymentState extends Equatable {
  const PaymentState({
    this.status = PaymentFlowStatus.initial,
    this.order,
    this.payment,
    this.message,
    this.isChecking = false,
  });

  final PaymentFlowStatus status;
  final DeliveryOrder? order;
  final Payment? payment;
  final String? message;
  final bool isChecking;

  bool get isBusy =>
      status == PaymentFlowStatus.loading ||
      status == PaymentFlowStatus.creating ||
      isChecking;

  bool get isPaid =>
      status == PaymentFlowStatus.paid || payment?.status == PaymentStatus.paid;

  String? get redirectUrl => payment?.redirectUrl;

  PaymentState copyWith({
    PaymentFlowStatus? status,
    DeliveryOrder? order,
    Payment? payment,
    String? message,
    bool? isChecking,
    bool clearMessage = false,
    bool clearPayment = false,
  }) {
    return PaymentState(
      status: status ?? this.status,
      order: order ?? this.order,
      payment: clearPayment ? null : payment ?? this.payment,
      message: clearMessage ? null : message ?? this.message,
      isChecking: isChecking ?? this.isChecking,
    );
  }

  @override
  List<Object?> get props => [status, order, payment, message, isChecking];
}

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => const [];
}

class PaymentStarted extends PaymentEvent {
  const PaymentStarted(this.order);

  final DeliveryOrder order;

  @override
  List<Object?> get props => [order];
}

class PaymentCreateRequested extends PaymentEvent {
  const PaymentCreateRequested();
}

class PaymentCheckRequested extends PaymentEvent {
  const PaymentCheckRequested();
}

class PaymentReceived extends PaymentEvent {
  const PaymentReceived(this.payment);

  final Payment? payment;

  @override
  List<Object?> get props => [payment];
}

class PaymentStreamFailed extends PaymentEvent {
  const PaymentStreamFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class PaymentMessageCleared extends PaymentEvent {
  const PaymentMessageCleared();
}
