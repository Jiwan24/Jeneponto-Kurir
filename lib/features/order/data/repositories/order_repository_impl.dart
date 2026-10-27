import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_remote_data_source.dart';

class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(this._remote);

  final OrderRemoteDataSource _remote;

  @override
  Stream<List<OrderEntity>> watchCustomerOrders(String customerId) =>
      _remote.watchCustomerOrders(customerId);

  @override
  Stream<List<OrderEntity>> watchPendingOrders() =>
      _remote.watchPendingOrders();

  @override
  Stream<List<OrderEntity>> watchCourierOrders(String courierId) =>
      _remote.watchCourierOrders(courierId);

  @override
  Stream<List<OrderEntity>> watchAllOrders() => _remote.watchAllOrders();

  @override
  Future<Either<Failure, String>> createOrder(OrderDraft draft) {
    return _guard(() => _remote.createOrder(draft));
  }

  @override
  Future<Either<Failure, Unit>> acceptOrder({
    required String orderId,
    required String courierId,
    required String courierName,
  }) {
    return _guard(() async {
      await _remote.updateOrder(orderId: orderId, data: {
        'status': OrderStatus.accepted.name,
        'courierId': courierId,
        'courierName': courierName,
        'acceptedAt': Timestamp.fromDate(DateTime.now()),
      });
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> updateStatus({
    required String orderId,
    required OrderStatus status,
  }) {
    return _guard(() async {
      final Map<String, dynamic> data = <String, dynamic>{
        'status': status.name,
      };
      final Timestamp now = Timestamp.fromDate(DateTime.now());
      switch (status) {
        case OrderStatus.accepted:
          data['acceptedAt'] = now;
          break;
        case OrderStatus.pickedUp:
          data['pickedUpAt'] = now;
          break;
        case OrderStatus.inTransit:
          data['inTransitAt'] = now;
          break;
        case OrderStatus.delivered:
          data['deliveredAt'] = now;
          break;
        case OrderStatus.awaitingPayment:
        case OrderStatus.pending:
        case OrderStatus.cancelled:
          break;
      }
      await _remote.updateOrder(orderId: orderId, data: data);
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> cancelOrder(String orderId) {
    return _guard(() async {
      await _remote.updateOrder(
        orderId: orderId,
        data: {'status': OrderStatus.cancelled.name},
      );
      return unit;
    });
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
