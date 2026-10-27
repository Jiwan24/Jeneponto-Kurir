import 'package:equatable/equatable.dart';

/// Status pengiriman paket.
enum OrderStatus {
  /// Pesanan sudah dibuat tetapi pembayaran (non-COD) belum selesai.
  /// Tidak muncul di job board kurir sampai berubah menjadi [pending].
  awaitingPayment('Menunggu pembayaran'),
  pending('Menunggu kurir'),
  accepted('Diterima kurir'),
  pickedUp('Paket diambil'),
  inTransit('Dalam perjalanan'),
  delivered('Terkirim'),
  cancelled('Dibatalkan');

  const OrderStatus(this.label);
  final String label;

  static OrderStatus fromString(String? value) {
    return OrderStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => OrderStatus.pending,
    );
  }

  /// Urutan progres status yang boleh dijalankan kurir.
  OrderStatus? get nextStep {
    switch (this) {
      case OrderStatus.accepted:
        return OrderStatus.pickedUp;
      case OrderStatus.pickedUp:
        return OrderStatus.inTransit;
      case OrderStatus.inTransit:
        return OrderStatus.delivered;
      default:
        return null;
    }
  }

  bool get isFinished => this == delivered || this == cancelled;
}

/// Entitas pesanan pengiriman (independen dari Firebase).
class OrderEntity extends Equatable {
  const OrderEntity({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.distanceKm,
    required this.price,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.courierId,
    this.courierName,
    this.note = '',
  });

  final String id;
  final String customerId;
  final String customerName;
  final String? courierId;
  final String? courierName;
  final String pickupAddress;
  final String destinationAddress;
  final String note;
  final double distanceKm;
  final int price;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        id,
        customerId,
        customerName,
        courierId,
        courierName,
        pickupAddress,
        destinationAddress,
        note,
        distanceKm,
        price,
        status,
        createdAt,
        updatedAt,
      ];
}

/// Data mentah yang dikirim UI saat membuat pesanan baru.
/// Id dan timestamp dibuat di lapisan data.
class OrderDraft extends Equatable {
  const OrderDraft({
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
