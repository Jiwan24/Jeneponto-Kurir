import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import 'package:jeneponto_kurir/features/common/constants/firestore_collections.dart';
import 'package:jeneponto_kurir/features/common/error/exceptions.dart';
import 'package:jeneponto_kurir/features/delivery/domain/entities/order_status.dart';
import '../../domain/entities/delivery_order.dart';
import '../models/delivery_order_model.dart';

/// Akses Firestore untuk alur pemesanan pelanggan.
abstract class DeliveryRemoteDataSource {
  Stream<DeliveryOrder?> watchOrder(String orderId);

  Future<DeliveryOrder?> getOrder(String orderId);

  Stream<List<DeliveryOrder>> watchCustomerOrders(
    String customerId, {
    int limit = 10,
  });

  Future<DeliveryOrderPage> fetchCustomerOrders({
    required String customerId,
    int limit = 20,
    DateTime? before,
  });

  Future<String> createOrder(DeliveryDraft draft);

  Future<void> cancelOrder({
    required String orderId,
    String? reason,
  });
}

class DeliveryRemoteDataSourceImpl implements DeliveryRemoteDataSource {
  DeliveryRemoteDataSourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection(FirestoreCollections.orders);

  @override
  Stream<DeliveryOrder?> watchOrder(String orderId) {
    if (orderId.isEmpty) return Stream.value(null);
    return _orders.doc(orderId).snapshots().map(
          (doc) => doc.exists ? DeliveryOrderModel.fromDoc(doc) : null,
        );
  }

  @override
  Future<DeliveryOrder?> getOrder(String orderId) async {
    if (orderId.isEmpty) return null;
    try {
      final doc = await _orders.doc(orderId).get();
      return doc.exists ? DeliveryOrderModel.fromDoc(doc) : null;
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Gagal memuat pesanan.');
    }
  }

  @override
  Stream<List<DeliveryOrder>> watchCustomerOrders(
    String customerId, {
    int limit = 10,
  }) {
    if (customerId.isEmpty) return Stream.value(const <DeliveryOrder>[]);
    return _orders
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(_toList);
  }

  @override
  Future<DeliveryOrderPage> fetchCustomerOrders({
    required String customerId,
    int limit = 20,
    DateTime? before,
  }) async {
    if (customerId.isEmpty) {
      return const DeliveryOrderPage(orders: [], hasMore: false);
    }
    try {
      Query<Map<String, dynamic>> query = _orders
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true);
      if (before != null) {
        query = query.where(
          'createdAt',
          isLessThan: Timestamp.fromDate(before),
        );
      }
      final snapshot = await query.limit(limit + 1).get();
      final bool hasMore = snapshot.docs.length > limit;
      final docs = snapshot.docs.take(limit).toList(growable: false);
      return DeliveryOrderPage(
        orders: docs.map(DeliveryOrderModel.fromDoc).toList(growable: false),
        hasMore: hasMore,
      );
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Gagal memuat riwayat pesanan.');
    }
  }

  @override
  Future<String> createOrder(DeliveryDraft draft) async {
    try {
      final DateTime now = DateTime.now();
      final String id = const Uuid().v4();
      final String code = _orderCode(now);
      final DeliveryOrderModel order = DeliveryOrderModel.fromDraft(
        draft,
        id: id,
        code: code,
        now: now,
      );
      await _orders.doc(id).set(order.toCreateMap());
      return id;
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Gagal membuat pesanan.');
    }
  }

  @override
  Future<void> cancelOrder({
    required String orderId,
    String? reason,
  }) async {
    try {
      final DateTime now = DateTime.now();
      await _orders.doc(orderId).update(<String, dynamic>{
        'status': OrderStatus.cancelled.name,
        'cancelledReason': (reason == null || reason.trim().isEmpty)
            ? 'Dibatalkan oleh pelanggan.'
            : reason.trim(),
        'cancelledAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Gagal membatalkan pesanan.');
    }
  }

  List<DeliveryOrder> _toList(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map(DeliveryOrderModel.fromDoc)
        .toList(growable: false);
  }

  String _orderCode(DateTime now) {
    final String year = now.year.toString().substring(2);
    final String month = now.month.toString().padLeft(2, '0');
    final String day = now.day.toString().padLeft(2, '0');
    final String suffix =
        const Uuid().v4().replaceAll('-', '').substring(0, 4).toUpperCase();
    return 'JK-$year$month$day-$suffix';
  }
}
