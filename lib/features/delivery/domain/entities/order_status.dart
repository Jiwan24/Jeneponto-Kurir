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
