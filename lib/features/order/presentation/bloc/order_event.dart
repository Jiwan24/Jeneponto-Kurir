import 'package:equatable/equatable.dart';

import '../../domain/entities/order_entity.dart';

/// Event [OrderBloc].
abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => const [];
}

/// Mulai (atau ganti) langganan daftar pesanan milik pelanggan.
class OrderListRequested extends OrderEvent {
  const OrderListRequested({required this.customerId});

  final String customerId;

  @override
  List<Object?> get props => [customerId];
}

/// Data baru dari stream Firestore (internal).
class OrderReceived extends OrderEvent {
  const OrderReceived(this.orders);

  final List<OrderEntity> orders;

  @override
  List<Object?> get props => [orders];
}

class OrderWatchFailed extends OrderEvent {
  const OrderWatchFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Simpan pesanan baru (form Kirim Paket).
class OrderCreateSubmitted extends OrderEvent {
  const OrderCreateSubmitted({
    required this.customerId,
    required this.customerName,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.distanceKm,
    required this.price,
    this.note = '',
  });

  final String customerId;
  final String customerName;
  final String pickupAddress;
  final String destinationAddress;
  final double distanceKm;
  final int price;
  final String note;

  OrderDraft toDraft() => OrderDraft(
        customerId: customerId,
        customerName: customerName,
        pickupAddress: pickupAddress,
        destinationAddress: destinationAddress,
        distanceKm: distanceKm,
        price: price,
        note: note,
      );

  @override
  List<Object?> get props => [
        customerId,
        customerName,
        pickupAddress,
        destinationAddress,
        distanceKm,
        price,
        note,
      ];
}

class OrderCancelRequested extends OrderEvent {
  const OrderCancelRequested(this.orderId);

  final String orderId;

  @override
  List<Object?> get props => [orderId];
}
