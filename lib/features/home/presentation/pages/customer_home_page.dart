import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../order/presentation/bloc/order_bloc.dart';
import '../../order/presentation/bloc/order_event.dart';
import '../../order/presentation/bloc/order_state.dart';
import '../../order/presentation/widgets/order_card.dart';

/// Beranda pelanggan: sapaan, layanan cepat, dan pesanan terbaru.
class CustomerHomePage extends StatelessWidget {
  const CustomerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: BlocProvider<OrderBloc>(
        create: (_) => sl<OrderBloc>()
          ..add(OrderListRequested(customerId: user?.uid ?? '')),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text(
              'Hai, ${user?.name ?? 'Pelanggan'} 👋',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              AppConstants.tagline,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.eco_outlined, color: Colors.white70),
                      SizedBox(width: 8),
                      Text(
                        'Layanan Lokal Terpercaya',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    AppConstants.aboutText,
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () =>
                        context.push(AppRouter.createOrderPath),
                    child: const Text('Kirim Paket Sekarang'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _ServiceCard(
                    icon: Icons.add_box_outlined,
                    label: 'Buat Pesanan',
                    onTap: () => context.push(AppRouter.createOrderPath),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ServiceCard(
                    icon: Icons.receipt_long_outlined,
                    label: 'Pesanan Saya',
                    onTap: () => context.push(AppRouter.ordersPath),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Pesanan Terbaru',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(AppRouter.ordersPath),
                  child: const Text('Lihat semua'),
                ),
              ],
            ),
            const _RecentOrders(),
            const SizedBox(height: 20),
            const _HowItWorks(),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Icon(icon, size: 28, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentOrders extends StatelessWidget {
  const _RecentOrders();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderBloc, OrderState>(
      buildWhen: (previous, current) =>
          previous.orders != current.orders ||
          previous.status != current.status,
      builder: (context, state) {
        if (state.status == OrderListStatus.initial ||
            state.status == OrderListStatus.loading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.status == OrderListStatus.failure) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Gagal memuat pesanan terbaru.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        final recent = state.orders.take(3).toList();
        if (recent.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Belum ada pesanan. Ayo kirim paket pertamamu!',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        return Column(
          children: [
            for (final order in recent) ...[
              OrderCard(order: order),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  static const _steps = [
    (icon: Icons.edit_note, title: 'Buat Pesanan', desc: 'Isi alamat jemput & tujuan'),
    (icon: Icons.person_search, title: 'Kurir Menerima', desc: 'Kurir lokal mengambil paketmu'),
    (icon: Icons.where_to_vote_outlined, title: 'Paket Terkirim', desc: 'Lacak status hingga sampai'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cara Kerja',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          for (final step in _steps)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor:
                        AppColors.primary.withValues(alpha: 0.12),
                    child: Icon(step.icon, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          step.desc,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
