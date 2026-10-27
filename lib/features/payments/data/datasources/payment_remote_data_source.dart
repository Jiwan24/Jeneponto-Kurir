import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:jeneponto_kurir/features/common/constants/app_constants.dart';
import 'package:jeneponto_kurir/features/common/constants/firestore_collections.dart';
import 'package:jeneponto_kurir/features/common/error/exceptions.dart';
import '../../../delivery/domain/entities/delivery_order.dart';
import '../../domain/entities/payment.dart';
import '../models/payment_model.dart';

/// Akses Firestore + Cloud Functions untuk pembayaran.
abstract class PaymentRemoteDataSource {
  Stream<Payment?> watchPayment(String orderId);

  Future<Payment?> fetchPayment(String orderId);

  Future<Payment> createMidtransPayment(DeliveryOrder order);
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  PaymentRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseFunctions functions,
  })  : _firestore = firestore,
        _functions = functions;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _payments =>
      _firestore.collection(FirestoreCollections.payments);

  @override
  Stream<Payment?> watchPayment(String orderId) {
    if (orderId.isEmpty) return Stream.value(null);
    return _payments.doc(orderId).snapshots().map(
          (doc) => doc.exists ? PaymentModel.fromDoc(doc) : null,
        );
  }

  @override
  Future<Payment?> fetchPayment(String orderId) async {
    if (orderId.isEmpty) return null;
    try {
      final doc = await _payments.doc(orderId).get();
      return doc.exists ? PaymentModel.fromDoc(doc) : null;
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Gagal memuat status pembayaran.');
    }
  }

  @override
  Future<Payment> createMidtransPayment(DeliveryOrder order) async {
    try {
      final HttpsCallable callable =
          _functions.httpsCallable(AppConstants.midtransFunction);
      final HttpsCallableResult<Map<String, dynamic>> result = await callable
          .call<Map<String, dynamic>>(<String, dynamic>{
        'orderId': order.id
      }).timeout(const Duration(seconds: 40));

      final Map<String, dynamic> data = result.data;
      return PaymentModel.fromFunctionResponse(data, order: order);
    } on TimeoutException {
      throw const ServerException(
        'Layanan pembayaran terlalu lama merespons. Coba lagi.',
      );
    } on FirebaseFunctionsException catch (e) {
      throw ServerException(_messageFor(e));
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Gagal membuat pembayaran.');
    }
  }

  String _messageFor(FirebaseFunctionsException error) {
    switch (error.code) {
      case 'unauthenticated':
        return 'Sesi login berakhir. Silakan masuk ulang.';
      case 'permission-denied':
        return 'Kamu tidak berhak membayar pesanan ini.';
      case 'failed-precondition':
        return error.message ??
            'Pembayaran tidak dapat dibuat untuk status pesanan ini.';
      case 'not-found':
        return 'Layanan pembayaran belum dikonfigurasi. '
            'Hubungi admin atau pilih COD.';
      case 'unavailable':
      case 'deadline-exceeded':
        return 'Layanan pembayaran sedang sibuk. Coba lagi sebentar.';
      case 'internal':
        return 'Terjadi gangguan pada layanan pembayaran.';
      default:
        return error.message ?? 'Gagal membuat pembayaran. Silakan coba lagi.';
    }
  }
}
