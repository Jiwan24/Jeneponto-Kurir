import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:jeneponto_kurir/features/common/di/person2_locator.dart';
import 'package:jeneponto_kurir/features/common/router/app_paths.dart';
import 'package:jeneponto_kurir/features/common/theme/app_colors.dart';
import 'package:jeneponto_kurir/features/common/utils/formatters.dart';
import 'package:jeneponto_kurir/features/common/widgets/app_button.dart';
import 'package:jeneponto_kurir/features/common/widgets/empty_state.dart';
import 'package:jeneponto_kurir/features/delivery/domain/entities/order_status.dart';
import '../../../domain/entities/delivery_order.dart';
import '../../../domain/entities/payment_method.dart';
import '../../bloc/delivery_order_bloc.dart';
import '../../bloc/delivery_order_state.dart';
import '../../widgets/delivery_address_card.dart';
import '../../widgets/delivery_status_badge.dart';
import '../../widgets/delivery_timeline.dart';
import '../../widgets/fare_summary_card.dart';

/// Detail lengkap satu pesanan: status, alamat, biaya, dan aksi pembayaran.
class DeliveryDetailPage extends StatelessWidget {
  const DeliveryDetailPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DeliveryOrderBloc>(
      create: (_) =>
          sl<DeliveryOrderBloc>()..add(DeliveryOrderRequested(orderId)),
      child: _DetailView(orderId: orderId),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView({required this.orderId});

  final String orderId;

  Future<void> _confirmCancel(
    BuildContext context,
    DeliveryOrder order,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Batalkan pesanan?'),
        content: const Text(
          'Pesanan yang dibatalkan tidak bisa dikembalikan. '
          'Kurir belum menerima pesanan ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    context
        .read<DeliveryOrderBloc>()
        .add(DeliveryOrderCancelRequested(orderId: order.id));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DeliveryOrderBloc, DeliveryOrderState>(
      listenWhen: (previous, current) =>
          current.message != previous.message ||
          current.cancelSucceeded != previous.cancelSucceeded,
      listener: (context, state) {
        if (state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
        }
      },
      builder: (context, state) {
        final DeliveryOrder? order = state.order;
        return Scaffold(
          appBar: AppBar(
            title: Text(
                order == null ? 'Detail Pesanan' : 'Pesanan ${order.code}'),
            actions: [
              IconButton(
                tooltip: 'Riwayat pesanan',
                onPressed: () =>
                    context.pushReplacement(AppPaths.deliveryHistory),
                icon: const Icon(Icons.receipt_long_outlined),
              ),
            ],
          ),
          body: _buildBody(context, state, order),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    DeliveryOrderState state,
    DeliveryOrder? order,
  ) {
    if ((state.status == DeliveryOrderViewStatus.initial ||
            state.status == DeliveryOrderViewStatus.loading) &&
        order == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (order == null) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Pesanan tidak ditemukan',
        message: state.message ?? 'Pesanan mungkin sudah dihapus.',
        action: FilledButton(
          onPressed: () => context
              .read<DeliveryOrderBloc>()
              .add(DeliveryOrderRequested(orderId)),
          child: const Text('Muat Ulang'),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _OrderHeader(order: order),
        const SizedBox(height: 16),
        DeliveryTimeline(order: order),
        if (order.hasCourier) ...[
          const SizedBox(height: 16),
          _CourierCard(order: order),
        ],
        const SizedBox(height: 16),
        DeliveryAddressCard(
          title: 'Penjemputan',
          address: order.pickup,
          icon: Icons.trip_origin,
          color: AppColors.primary,
        ),
        const SizedBox(height: 12),
        DeliveryAddressCard(
          title: 'Tujuan',
          address: order.dropoff,
          icon: Icons.location_on,
          color: AppColors.danger,
        ),
        const SizedBox(height: 16),
        _ItemCard(order: order),
        const SizedBox(height: 16),
        FareSummaryCard(order: order),
        const SizedBox(height: 20),
        if (order.isAwaitingPayment) ...[
          AppButton(
            label: 'Bayar Sekarang',
            icon: Icons.lock_outline,
            onPressed: () => context.push(AppPaths.deliveryPayment(order.id)),
          ),
          const SizedBox(height: 10),
        ],
        if (order.status == OrderStatus.pending) ...[
          AppButton(
            label: 'Lihat Proses Pencarian',
            icon: Icons.radar,
            onPressed: () => context.push(AppPaths.deliverySearching(order.id)),
          ),
          const SizedBox(height: 10),
        ],
        if (order.canCancel)
          OutlinedButton.icon(
            onPressed: state.isCancelling
                ? null
                : () => _confirmCancel(context, order),
            icon: state.isCancelling
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.close, size: 18),
            label: Text(
              state.isCancelling ? 'Membatalkan...' : 'Batalkan Pesanan',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
            ),
          ),
        const SizedBox(height: 16),
        const Text(
          'Butuh bantuan? Hubungi layanan pelanggan Jeneponto Kurir.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _OrderHeader extends StatelessWidget {
  const _OrderHeader({required this.order});

  final DeliveryOrder order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DeliveryStatusBadge(status: order.status),
              const Spacer(),
              if (order.paymentMethod == PaymentMethod.midtrans)
                PaymentStatusBadge(status: order.paymentStatus),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            Formatters.rupiah(order.price),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${order.itemCategory} • ${Formatters.distance(order.distanceKm)}'
            '${order.weightKg > 0 ? ' • ${order.weightKg.toStringAsFixed(1).replaceAll('.', ',')} kg' : ''}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(
                Icons.schedule,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Dibuat ${Formatters.dateTime(order.createdAt)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                order.code,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CourierCard extends StatelessWidget {
  const _CourierCard({required this.order});

  final DeliveryOrder order;

  @override
  Widget build(BuildContext context) {
    final String name = order.courierName ?? 'Kurir Jeneponto';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              name.trim().isEmpty ? 'K' : name.trim()[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kurir',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (order.courierPhone != null &&
                    order.courierPhone!.isNotEmpty)
                  Text(
                    order.courierPhone!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const Icon(Icons.verified_user_outlined, color: AppColors.primary),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.order});

  final DeliveryOrder order;

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
            'Detail Paket',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _InfoRow(
            label: 'Kategori',
            value: order.itemCategory,
          ),
          _InfoRow(
            label: 'Berat',
            value: order.weightKg > 0
                ? '${order.weightKg.toStringAsFixed(1).replaceAll('.', ',')} kg'
                : '-',
          ),
          if (order.itemNotes.trim().isNotEmpty)
            _InfoRow(label: 'Catatan', value: order.itemNotes.trim()),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
