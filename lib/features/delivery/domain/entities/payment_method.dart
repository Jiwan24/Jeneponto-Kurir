/// Metode pembayaran yang dipilih pelanggan saat membuat pesanan.
enum PaymentMethod {
  cod(
    'Bayar di Tempat (COD)',
    'Bayar tunai ke kurir saat paket diterima.',
  ),
  midtrans(
    'Bayar Online',
    'QRIS, transfer bank, atau e-wallet melalui Midtrans.',
  );

  const PaymentMethod(this.label, this.description);

  final String label;
  final String description;

  /// True bila pembayaran harus selesai sebelum kurir bisa menerima order.
  bool get requiresGateway => this == PaymentMethod.midtrans;

  static PaymentMethod fromString(String? value) {
    return PaymentMethod.values.firstWhere(
      (method) => method.name == value,
      orElse: () => PaymentMethod.cod,
    );
  }
}

/// Status pembayaran sebuah pesanan.
enum PaymentStatus {
  unpaid('Belum dibayar'),
  pending('Menunggu pembayaran'),
  paid('Dibayar'),
  failed('Pembayaran gagal'),
  expired('Pembayaran kedaluwarsa'),
  refunded('Dikembalikan');

  const PaymentStatus(this.label);

  final String label;

  bool get isPaid => this == PaymentStatus.paid;

  bool get isFailed =>
      this == PaymentStatus.failed ||
      this == PaymentStatus.expired ||
      this == PaymentStatus.refunded;

  bool get isTerminal => isPaid || isFailed;

  static PaymentStatus fromString(String? value) {
    return PaymentStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => PaymentStatus.unpaid,
    );
  }
}
