import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/firestore_collections.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/order_entity.dart';
import '../models/order_model.dart';

/// Sumber data pesanan di Firestore.
abstract class OrderRemoteDataSource {
  Stream<List<OrderEntity>> watchCustomerOrders(String customerId);

  Stream<List<OrderEntity>> watchPendingOrders();

  Stream<List<OrderEntity>> watchCourierOrders(String courierId);

  Stream<List<OrderEntity>> watchAllOrders();

  /// Mengembalikan id pesanan yang baru dibuat.
  Future<String> createOrder(OrderDraft draft);

  Future<void> updateOrder({
    required String orderId,
    required Map<String, dynamic> data,
  });
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  OrderRemoteDataSourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection(FirestoreCollections.orders);

  @override
  Stream<List<OrderEntity>> watchCustomerOrders(String customerId) {
    if (customerId.isEmpty) return Stream.value(const []);
    return _orders
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_toList);
  }

  @override
  Stream<List<OrderEntity>> watchPendingOrders() {
    // Firestore butuh composite index: status + createdAt (lihat README).
    return _orders
        .where('status', isEqualTo: OrderStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_toList);
  }

  @override
  Stream<List<OrderEntity>> watchCourierOrders(String courierId) {
    if (courierId.isEmpty) return Stream.value(const []);
    return _orders
        .where('courierId', isEqualTo: courierId)
        .where(
          'status',
          whereIn: [
            OrderStatus.accepted.name,
            OrderStatus.pickedUp.name,
            OrderStatus.inTransit.name,
            OrderStatus.delivered.name,
          ],
        )
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(_toList);
  }

  @override
  Stream<List<OrderEntity>> watchAllOrders() {
    return _orders.orderBy('createdAt', descending: true).snapshots().map(_toList);
  }

  List<OrderEntity> _toList(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs.map(OrderModel.fromDoc).toList();
  }

  @override
  Future<String> createOrder(OrderDraft draft) async {
    try {
      final String id = const Uuid().v4();
      final now = DateTime.now();
      final OrderModel order = OrderModel.fromDraft(draft, id: id, now: now);
      await _orders.doc(id).set(order.toMap());
      return id;
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Gagal membuat pesanan.');
    }
  }

  @override
  Future<void> updateOrder({
    required String orderId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _orders.doc(orderId).update({
        ...data,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Gagal memperbarui pesanan.');
    }
  }
}
