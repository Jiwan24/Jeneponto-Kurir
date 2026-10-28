import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/order_entity.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';
import '../widgets/order_card.dart';

/// Daftar pesanan milik pelanggan (+ tombol buat pesanan baru).
class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    return BlocProvider<OrderBloc>(
      create: (_) => sl<OrderBloc>()
        ..add(OrderListRequested(customerId: user?.uid ?? '')),
      child: const _OrdersView(),
    );
  }
}

class _OrdersView extends StatelessWidget {
  const _OrdersView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan Saya')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRouter.createOrderPath),
        icon: const Icon(Icons.add),
        label: const Text('Buat Pesanan'),
      ),
      body: BlocConsumer<OrderBloc, OrderState>(
        listenWhen: (previous, current) =>
            current.message != null && current.message != previous.message,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
        },
        builder: (context, state) {
          switch (state.status) {
            case OrderListStatus.initial:
            case OrderListStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case OrderListStatus.failure:
              return EmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'Gagal memuat pesanan',
                message: state.message,
              );
            case OrderListStatus.success:
              if (state.orders.isEmpty) {
                return const EmptyState(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Belum ada pesanan',
                  message: 'Tekan tombol "Buat Pesanan" untuk mulai '
                      'mengirim paket.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                itemCount: state.orders.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final OrderEntity order = state.orders[index];
                  return OrderCard(
                    order: order,
                    onTap: order.status == OrderStatus.pending
                        ? () => _confirmCancel(context, order)
                        : null,
                  );
                },
              );
          }
        },
      ),
    );
  }

  void _confirmCancel(BuildContext context, OrderEntity order) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Batalkan pesanan?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pesanan yang belum diterima kurir dapat dibatalkan.',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.read<OrderBloc>().add(
                          OrderCancelRequested(order.id),
                        );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                  ),
                  child: const Text('Ya, batalkan'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('Kembali'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
