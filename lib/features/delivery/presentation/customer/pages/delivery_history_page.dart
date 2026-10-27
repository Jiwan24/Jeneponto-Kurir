import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/di/injector.dart';
import '../../../../../core/router/app_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../auth/domain/entities/user_entity.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../order/domain/entities/order_entity.dart';
import '../../../domain/entities/delivery_order.dart';
import '../../bloc/delivery_history_bloc.dart';
import '../../bloc/delivery_history_state.dart';
import '../../widgets/delivery_order_card.dart';

/// Riwayat seluruh pesanan pelanggan, termasuk pesanan lama sebelum
/// fitur delivery diperluas.
class DeliveryHistoryPage extends StatelessWidget {
  const DeliveryHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final UserEntity? user = context.watch<AuthBloc>().state.user;
    return BlocProvider<DeliveryHistoryBloc>(
      create: (_) => sl<DeliveryHistoryBloc>()
        ..add(DeliveryHistoryRequested(user?.uid ?? '')),
      child: _HistoryView(customerId: user?.uid ?? ''),
    );
  }
}

class _HistoryView extends StatefulWidget {
  const _HistoryView({required this.customerId});

  final String customerId;

  @override
  State<_HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<_HistoryView> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    if (_controller.position.extentAfter < 240) {
      context.read<DeliveryHistoryBloc>().add(const DeliveryHistoryLoadMore());
    }
  }

  void _openOrder(DeliveryOrder order) {
    context.push(AppPaths.deliveryDetail(order.id));
  }

  void _openPrimaryAction(DeliveryOrder order) {
    if (order.isAwaitingPayment) {
      context.push(AppPaths.deliveryPayment(order.id));
    } else if (order.isSearchingCourier ||
        (order.hasCourier &&
            order.status != OrderStatus.delivered &&
            order.status != OrderStatus.cancelled)) {
      context.push(AppPaths.deliverySearching(order.id));
    } else {
      _openOrder(order);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DeliveryHistoryBloc, DeliveryHistoryState>(
      listenWhen: (previous, current) => current.message != previous.message,
      listener: (context, state) {
        if (state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Pesanan Saya'),
            actions: [
              IconButton(
                tooltip: 'Muat ulang',
                onPressed: () => context
                    .read<DeliveryHistoryBloc>()
                    .add(const DeliveryHistoryRefreshed()),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, DeliveryHistoryState state) {
    if ((state.status == DeliveryHistoryStatus.initial ||
            state.status == DeliveryHistoryStatus.loading) &&
        state.orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == DeliveryHistoryStatus.failure && state.orders.isEmpty) {
      return EmptyState(
        icon: Icons.wifi_off_outlined,
        title: 'Gagal memuat pesanan',
        message: state.message ?? 'Periksa koneksi lalu coba lagi.',
        action: FilledButton(
          onPressed: () => context
              .read<DeliveryHistoryBloc>()
              .add(const DeliveryHistoryRefreshed()),
          child: const Text('Coba Lagi'),
        ),
      );
    }

    if (widget.customerId.isEmpty) {
      return const EmptyState(
        icon: Icons.lock_outline,
        title: 'Sesi login tidak ditemukan',
        message: 'Silakan masuk ulang untuk melihat pesanan.',
      );
    }

    final List<DeliveryOrder> visible = state.visibleOrders;

    return RefreshIndicator(
      onRefresh: () async {
        context
            .read<DeliveryHistoryBloc>()
            .add(const DeliveryHistoryRefreshed());
      },
      child: CustomScrollView(
        controller: _controller,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: _FilterRow(
                value: state.filter,
                onChanged: (filter) => context
                    .read<DeliveryHistoryBloc>()
                    .add(DeliveryHistoryFilterChanged(filter)),
              ),
            ),
          ),
          if (state.orders.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.local_shipping_outlined,
                title: 'Belum ada pesanan',
                message: 'Pesanan pertamamu akan muncul di sini.',
                action: AppButton(
                  label: 'Cari Kurir',
                  icon: Icons.search,
                  expanded: false,
                  onPressed: () => context.push(AppPaths.deliveryNew),
                ),
              ),
            )
          else if (visible.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.filter_alt_off_outlined,
                title: 'Tidak ada pesanan',
                message: 'Tidak ada pesanan pada filter '
                    '"${state.filter.label}".',
                action: state.hasMore
                    ? TextButton(
                        onPressed: () => context
                            .read<DeliveryHistoryBloc>()
                            .add(const DeliveryHistoryLoadMore()),
                        child: const Text('Muat pesanan lain'),
                      )
                    : TextButton(
                        onPressed: () =>
                            context.read<DeliveryHistoryBloc>().add(
                                  const DeliveryHistoryFilterChanged(
                                    DeliveryHistoryFilter.all,
                                  ),
                                ),
                        child: const Text('Tampilkan semua'),
                      ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList.separated(
                itemCount: visible.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final DeliveryOrder order = visible[index];
                  return DeliveryOrderCard(
                    order: order,
                    onTap: () => _openOrder(order),
                    footer: _OrderFooter(
                      order: order,
                      onPress: () => _openPrimaryAction(order),
                    ),
                  );
                },
              ),
            ),
          if (state.isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (state.hasMore && visible.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Center(
                  child: TextButton(
                    onPressed: () => context
                        .read<DeliveryHistoryBloc>()
                        .add(const DeliveryHistoryLoadMore()),
                    child: const Text('Muat pesanan lain'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.value, required this.onChanged});

  final DeliveryHistoryFilter value;
  final ValueChanged<DeliveryHistoryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in DeliveryHistoryFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(filter.label),
                selected: value == filter,
                onSelected: (_) => onChanged(filter),
                selectedColor: AppColors.primary.withValues(alpha: 0.12),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: value == filter
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                side: BorderSide(
                  color: value == filter ? AppColors.primary : AppColors.border,
                ),
                showCheckmark: false,
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderFooter extends StatelessWidget {
  const _OrderFooter({required this.order, required this.onPress});

  final DeliveryOrder order;
  final VoidCallback onPress;

  String get _label {
    if (order.isAwaitingPayment) return 'Bayar Sekarang';
    if (order.isSearchingCourier) return 'Lihat Pencarian';
    if (order.hasCourier &&
        order.status != OrderStatus.delivered &&
        order.status != OrderStatus.cancelled) {
      return 'Lacak Pesanan';
    }
    return 'Lihat Detail';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            order.paymentStatus.label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        TextButton(
          onPressed: onPress,
          child: Text(_label),
        ),
      ],
    );
  }
}
