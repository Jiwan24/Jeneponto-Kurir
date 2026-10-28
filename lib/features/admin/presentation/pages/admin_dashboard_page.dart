import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../order/domain/entities/order_entity.dart';
import '../../../order/presentation/widgets/order_card.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

/// Dashboard admin: ringkasan jumlah pesanan + seluruh transaksi.
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminBloc>(
      create: (_) => sl<AdminBloc>()..add(const AdminOrdersRequested()),
      child: const _AdminDashboardView(),
    );
  }
}

class _AdminDashboardView extends StatelessWidget {
  const _AdminDashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Admin')),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          switch (state.status) {
            case AdminStatus.initial:
            case AdminStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case AdminStatus.failure:
              return EmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'Gagal memuat data',
                message: state.message,
              );
            case AdminStatus.success:
              return RefreshIndicator(
                onRefresh: () async => context
                    .read<AdminBloc>()
                    .add(const AdminOrdersRequested()),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    const Text(
                      'Ringkasan Pesanan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _StatsGrid(state: state),
                    const SizedBox(height: 24),
                    const Text(
                      'Semua Pesanan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (state.orders.isEmpty)
                      const EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'Belum ada pesanan',
                      )
                    else
                      for (final OrderEntity order in state.orders) ...[
                        OrderCard(order: order),
                        const SizedBox(height: 12),
                      ],
                  ],
                ),
              );
          }
        },
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.state});

  final AdminState state;

  @override
  Widget build(BuildContext context) {
    final items = <_StatItem>[
      _StatItem('Total', state.total, AppColors.primary),
      _StatItem('Menunggu', state.countOf(OrderStatus.pending), AppColors.warning),
      _StatItem('Dalam Proses', state.active, AppColors.accent),
      _StatItem('Terkirim', state.countOf(OrderStatus.delivered), AppColors.success),
      _StatItem('Dibatalkan', state.countOf(OrderStatus.cancelled), AppColors.danger),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.9,
      children: [
        for (final item in items)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${item.value}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: item.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatItem {
  const _StatItem(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;
}
