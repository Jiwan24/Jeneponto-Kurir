import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/delivery_order.dart';
import '../../domain/repositories/delivery_repository.dart';
import '../datasources/delivery_remote_data_source.dart';

class DeliveryRepositoryImpl implements DeliveryRepository {
  DeliveryRepositoryImpl(this._remote);

  final DeliveryRemoteDataSource _remote;

  @override
  Stream<DeliveryOrder?> watchOrder(String orderId) =>
      _remote.watchOrder(orderId);

  @override
  Stream<List<DeliveryOrder>> watchCustomerOrders(
    String customerId, {
    int limit = 10,
  }) =>
      _remote.watchCustomerOrders(customerId, limit: limit);

  @override
  Future<Either<Failure, DeliveryOrder?>> getOrder(String orderId) {
    return _guard(() => _remote.getOrder(orderId));
  }

  @override
  Future<Either<Failure, DeliveryOrderPage>> fetchCustomerOrders({
    required String customerId,
    int limit = 20,
    DateTime? before,
  }) {
    return _guard(
      () => _remote.fetchCustomerOrders(
        customerId: customerId,
        limit: limit,
        before: before,
      ),
    );
  }

  @override
  Future<Either<Failure, String>> createOrder(DeliveryDraft draft) {
    return _guard(() => _remote.createOrder(draft));
  }

  @override
  Future<Either<Failure, Unit>> cancelOrder({
    required String orderId,
    String? reason,
  }) async {
    final result = await _guard(
      () => _remote.cancelOrder(orderId: orderId, reason: reason),
    );
    return result.map((_) => unit);
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
