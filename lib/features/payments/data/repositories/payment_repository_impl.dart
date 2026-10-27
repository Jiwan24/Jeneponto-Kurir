import 'package:dartz/dartz.dart';

import 'package:jeneponto_kurir/features/common/error/exceptions.dart';
import 'package:jeneponto_kurir/features/common/error/failures.dart';
import '../../../delivery/domain/entities/delivery_order.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_remote_data_source.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl(this._remote);

  final PaymentRemoteDataSource _remote;

  @override
  Stream<Payment?> watchPayment(String orderId) =>
      _remote.watchPayment(orderId);

  @override
  Future<Either<Failure, Payment?>> fetchPayment(String orderId) {
    return _guard(() => _remote.fetchPayment(orderId));
  }

  @override
  Future<Either<Failure, Payment>> createMidtransPayment({
    required DeliveryOrder order,
  }) {
    return _guard(() => _remote.createMidtransPayment(order));
  }

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
