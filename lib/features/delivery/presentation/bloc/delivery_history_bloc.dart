import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/delivery_order.dart';
import '../../domain/repositories/delivery_repository.dart';
import 'delivery_history_state.dart';

/// Riwayat pesanan pelanggan dengan paginasi cursor (`createdAt`).
class DeliveryHistoryBloc
    extends Bloc<DeliveryHistoryEvent, DeliveryHistoryState> {
  DeliveryHistoryBloc({required DeliveryRepository repository})
      : _repository = repository,
        super(const DeliveryHistoryState()) {
    on<DeliveryHistoryRequested>(_onRequested);
    on<DeliveryHistoryRefreshed>(_onRefreshed);
    on<DeliveryHistoryLoadMore>(_onLoadMore);
    on<DeliveryHistoryFilterChanged>(_onFilterChanged);
    on<DeliveryHistoryMessageCleared>(_onMessageCleared);
  }

  static const int _pageSize = 20;

  final DeliveryRepository _repository;
  String _customerId = '';
  DateTime? _before;

  Future<void> _onRequested(
    DeliveryHistoryRequested event,
    Emitter<DeliveryHistoryState> emit,
  ) async {
    _customerId = event.customerId;
    await _load(emit, reset: true);
  }

  Future<void> _onRefreshed(
    DeliveryHistoryRefreshed event,
    Emitter<DeliveryHistoryState> emit,
  ) async {
    await _load(emit, reset: true);
  }

  Future<void> _onLoadMore(
    DeliveryHistoryLoadMore event,
    Emitter<DeliveryHistoryState> emit,
  ) async {
    if (!state.hasMore ||
        state.isLoadingMore ||
        state.status == DeliveryHistoryStatus.loading) {
      return;
    }
    emit(state.copyWith(isLoadingMore: true, clearMessage: true));
    await _load(emit, reset: false);
  }

  void _onFilterChanged(
    DeliveryHistoryFilterChanged event,
    Emitter<DeliveryHistoryState> emit,
  ) {
    emit(state.copyWith(filter: event.filter));
  }

  void _onMessageCleared(
    DeliveryHistoryMessageCleared event,
    Emitter<DeliveryHistoryState> emit,
  ) {
    emit(state.copyWith(clearMessage: true));
  }

  Future<void> _load(
    Emitter<DeliveryHistoryState> emit, {
    required bool reset,
  }) async {
    if (reset) {
      _before = null;
      emit(state.copyWith(
        status: DeliveryHistoryStatus.loading,
        orders: const [],
        hasMore: false,
        isLoadingMore: false,
        clearMessage: true,
      ));
    }

    final result = await _repository.fetchCustomerOrders(
      customerId: _customerId,
      limit: _pageSize,
      before: reset ? null : _before,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: state.orders.isEmpty
            ? DeliveryHistoryStatus.failure
            : DeliveryHistoryStatus.success,
        isLoadingMore: false,
        message: failure.message,
      )),
      (page) {
        final List<DeliveryOrder> merged = reset
            ? page.orders
            : <DeliveryOrder>[...state.orders, ...page.orders];
        if (page.orders.isNotEmpty) {
          _before = page.orders.last.createdAt;
        }
        emit(state.copyWith(
          status: DeliveryHistoryStatus.success,
          orders: merged,
          hasMore: page.hasMore,
          isLoadingMore: false,
          clearMessage: true,
        ));
      },
    );
  }
}
