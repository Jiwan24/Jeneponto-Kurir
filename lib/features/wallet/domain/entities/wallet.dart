import 'package:equatable/equatable.dart';

/// Saldo dan agregat pendapatan kurir (`wallets/{uid}`).
///
/// Nilai uang bersifat server-authoritative: hanya Cloud Function yang boleh
/// menulis dokumen ini (lihat `firebase/firestore.rules`). UI hanya membaca.
class Wallet extends Equatable {
  const Wallet({
    required this.uid,
    this.balance = 0,
    this.pendingBalance = 0,
    this.totalEarnings = 0,
    this.totalWithdrawn = 0,
    this.updatedAt,
  });

  factory Wallet.empty(String uid) => Wallet(uid: uid);

  final String uid;

  /// Saldo yang bisa ditarik.
  final int balance;

  /// Pendapatan yang masih ditahan (mis. order belum selesai).
  final int pendingBalance;

  /// Akumulasi pendapatan bruto setelah komisi.
  final int totalEarnings;

  final int totalWithdrawn;
  final DateTime? updatedAt;

  int get totalBalance => balance + pendingBalance;

  bool get canRequestPayout => balance > 0;

  Wallet copyWith({
    int? balance,
    int? pendingBalance,
    int? totalEarnings,
    int? totalWithdrawn,
    DateTime? updatedAt,
  }) {
    return Wallet(
      uid: uid,
      balance: balance ?? this.balance,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      totalWithdrawn: totalWithdrawn ?? this.totalWithdrawn,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        balance,
        pendingBalance,
        totalEarnings,
        totalWithdrawn,
        updatedAt,
      ];
}

/// Jenis mutasi dompet kurir.
enum WalletTransactionType {
  earning('Pendapatan'),
  commission('Komisi platform'),
  withdrawal('Penarikan'),
  adjustment('Penyesuaian'),
  refund('Pengembalian');

  const WalletTransactionType(this.label);
  final String label;

  static WalletTransactionType fromString(String? value) {
    return WalletTransactionType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => WalletTransactionType.adjustment,
    );
  }
}

enum WalletTransactionStatus {
  pending('Menunggu'),
  available('Tersedia'),
  paid('Sudah dibayar'),
  failed('Gagal');

  const WalletTransactionStatus(this.label);
  final String label;

  static WalletTransactionStatus fromString(String? value) {
    return WalletTransactionStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => WalletTransactionStatus.available,
    );
  }
}

/// Satu baris riwayat transaksi (`wallet_transactions/{id}`).
class WalletTransaction extends Equatable {
  const WalletTransaction({
    required this.id,
    required this.uid,
    required this.type,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.orderId,
    this.description = '',
  });

  final String id;
  final String uid;
  final String? orderId;
  final WalletTransactionType type;

  /// Positif = uang masuk, negatif = uang keluar (dalam rupiah).
  final int amount;
  final WalletTransactionStatus status;
  final String description;
  final DateTime createdAt;

  bool get isCredit => amount >= 0;

  @override
  List<Object?> get props => [
        id,
        uid,
        orderId,
        type,
        amount,
        status,
        description,
        createdAt,
      ];
}
