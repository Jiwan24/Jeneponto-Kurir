import 'package:equatable/equatable.dart';

import '../../domain/entities/delivery_order.dart';
import '../../domain/entities/payment_method.dart';

enum DeliveryCheckoutStatus { initial, submitting, success, failure }

class DeliveryCheckoutState extends Equatable {
  const DeliveryCheckoutState({
    this.status = DeliveryCheckoutStatus.initial,
    this.createdOrderId,
    this.paymentMethod = PaymentMethod.cod,
    this.message,
  });

  final DeliveryCheckoutStatus status;
  final String? createdOrderId;
  final PaymentMethod paymentMethod;
  final String? message;

  bool get isSubmitting => status == DeliveryCheckoutStatus.submitting;

  DeliveryCheckoutState copyWith({
    DeliveryCheckoutStatus? status,
    String? createdOrderId,
    PaymentMethod? paymentMethod,
    String? message,
    bool clearMessage = false,
    bool clearCreatedOrder = false,
  }) {
    return DeliveryCheckoutState(
      status: status ?? this.status,
      createdOrderId:
          clearCreatedOrder ? null : createdOrderId ?? this.createdOrderId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
        status,
        createdOrderId,
        paymentMethod,
        message,
      ];
}

abstract class DeliveryCheckoutEvent extends Equatable {
  const DeliveryCheckoutEvent();

  @override
  List<Object?> get props => const [];
}

class DeliveryCheckoutSubmitted extends DeliveryCheckoutEvent {
  const DeliveryCheckoutSubmitted(this.draft);

  final DeliveryDraft draft;

  @override
  List<Object?> get props => [draft];
}

class DeliveryCheckoutReset extends DeliveryCheckoutEvent {
  const DeliveryCheckoutReset();
}
