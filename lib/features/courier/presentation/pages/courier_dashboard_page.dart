import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../order/domain/entities/order_entity.dart';
import '../../../order/presentation/widgets/order_card.dart';
import '../bloc/courier_order_bloc.dart';
import '../bloc/courier_order_event.dart';
import '../bloc/courier_order_state.dart';

/// Dashboard kurir: tab "Order Tersedia" dan "Tugas Saya".
class CourierDashboardPage extends StatelessWidget {
  const CourierDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    return BlocProvider<CourierOrderBloc>(
      create: (_) => sl<CourierOrderBloc>()
        ..add(CourierOrdersRequested(
          courierId: user?.uid ?? '',
          courierName: user?.name ?? '',
        )),
      child: const _CourierDashboardView(),
    );
  }
}

class _CourierDashboardView extends StatelessWidget {
  const _CourierDashboardView();

  static String _advanceLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.accepted:
        return 'Konfirmasi Paket Diambil';
      case OrderStatus.pickedUp:
        return 'Mulai Perjalanan';
      case OrderStatus.inTransit:
        return 'Tandai Terkirim';
      default:
        return 'Perbarui Status';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard Kurir'),
          bottom: const TabBar(
            labelColor: Color(0xFF0F766E),
            tabs: [
              Tab(text: 'Order Tersedia'),
              Tab(text: 'Tugas Saya'),
            ],
          ),
        ),
        body: BlocConsumer<CourierOrderBloc, CourierOrderState>(
          listenWhen: (previous, current) =>
              current.message != null && current.message != previous.message,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message!)),
            );
          },
          builder: (context, state) {
            if (state.isLoading &&
                state.availableOrders.isEmpty &&
                state.myDeliveries.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            return TabBarView(
              children: [
                _buildAvailable(context, state),
                _buildDeliveries(context, state),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAvailable(BuildContext context, CourierOrderState state) {
    if (state.availableOrders.isEmpty) {
      return const EmptyState(
        icon: Icons.hourglass_empty,
        title: 'Belum ada order baru',
        message: 'Order dari pelanggan akan muncul di sini secara realtime.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.availableOrders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final OrderEntity order = state.availableOrders[index];
        return OrderCard(
          order: order,
          footer: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pelanggan: ${order.customerName}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              AppButton(
                label: 'Terima Order',
                isLoading: state.processingOrderId == order.id,
                onPressed: () => context
                    .read<CourierOrderBloc>()
                    .add(CourierAcceptRequested(order)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeliveries(BuildContext context, CourierOrderState state) {
    if (state.myDeliveries.isEmpty) {
      return const EmptyState(
        icon: Icons.local_shipping_outlined,
        title: 'Belum ada tugas',
        message: 'Terima order dari tab sebelumnya untuk mulai mengantar.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.myDeliveries.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final OrderEntity order = state.myDeliveries[index];
        final OrderStatus? next = order.status.nextStep;
        return OrderCard(
          order: order,
          footer: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pelanggan: ${order.customerName}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              if (next != null) ...[
                const SizedBox(height: 8),
                AppButton(
                  label: _advanceLabel(order.status),
                  isLoading: state.processingOrderId == order.id,
                  onPressed: () => context
                      .read<CourierOrderBloc>()
                      .add(CourierAdvanceRequested(order)),
                ),
              ] else
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Pengiriman selesai. Terima kasih!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF16A34A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
