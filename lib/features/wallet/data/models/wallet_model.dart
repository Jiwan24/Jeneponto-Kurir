import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/wallet.dart';

class WalletModel extends Wallet {
  const WalletModel({
    required super.uid,
    super.balance,
    super.pendingBalance,
    super.totalEarnings,
    super.totalWithdrawn,
    super.updatedAt,
  });

  factory WalletModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> map = doc.data() ?? <String, dynamic>{};
    return WalletModel(
      uid: (map['uid'] as String?) ?? doc.id,
      balance: (map['balance'] as num?)?.toInt() ?? 0,
      pendingBalance: (map['pendingBalance'] as num?)?.toInt() ?? 0,
      totalEarnings: (map['totalEarnings'] as num?)?.toInt() ?? 0,
      totalWithdrawn: (map['totalWithdrawn'] as num?)?.toInt() ?? 0,
      updatedAt: _date(map['updatedAt']),
    );
  }
}

class WalletTransactionModel extends WalletTransaction {
  const WalletTransactionModel({
    required super.id,
    required super.uid,
    required super.type,
    required super.amount,
    required super.status,
    required super.createdAt,
    super.orderId,
    super.description,
  });

  factory WalletTransactionModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> map = doc.data() ?? <String, dynamic>{};
    return WalletTransactionModel(
      id: doc.id,
      uid: map['uid'] as String? ?? '',
      orderId: map['orderId'] as String?,
      type: WalletTransactionType.fromString(map['type'] as String?),
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      status: WalletTransactionStatus.fromString(map['status'] as String?),
      description: map['description'] as String? ?? '',
      createdAt: _date(map['createdAt']) ?? DateTime.now(),
    );
  }
}

DateTime? _date(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
