import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/di/injector.dart';
import '../../../../../core/router/app_paths.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../order/domain/entities/order_entity.dart';
import '../../../domain/entities/delivery_order.dart';
import '../../../domain/entities/payment_method.dart';
import '../../bloc/delivery_order_bloc.dart';
import '../../bloc/delivery_order_state.dart';
import '../../widgets/delivery_status_badge.dart';
import '../../widgets/delivery_timeline.dart';
import '../../widgets/fare_summary_card.dart';

/// Halaman proses pencarian kurir + status pesanan setelah checkout.
class CourierSearchingPage extends StatelessWidget {
  const CourierSearchingPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DeliveryOrderBloc>(
      create: (_) =>
          sl<DeliveryOrderBloc>()..add(DeliveryOrderRequested(orderId)),
      child: _SearchingView(orderId: orderId),
    );
  }
}

class _SearchingView extends StatelessWidget {
  const _SearchingView({required this.orderId});

  final String orderId;

  Future<void> _confirmCancel(
    BuildContext context,
    DeliveryOrder order,
  ) async {
    final bool? confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Batalkan pesanan?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Kurir belum menerima pesanan ini. Pembatalan tidak '
                'dikenakan biaya.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              AppButton(
                label: 'Ya, Batalkan',
                onPressed: () => Navigator.of(sheetContext).pop(true),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(false),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
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
        if (state.cancelSucceeded) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pesanan dibatalkan.')),
          );
          context.pushReplacement(AppPaths.deliveryHistory);
        } else if (state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
        }
      },
      builder: (context, state) {
        final DeliveryOrder? order = state.order;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Status Pesanan'),
            actions: [
              if (order != null)
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
        icon: Icons.search_off_outlined,
        title: 'Pesanan tidak ditemukan',
        message: state.message ?? 'Coba muat ulang halaman ini.',
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
        _StatusHeader(order: order),
        const SizedBox(height: 16),
        if (order.isAwaitingPayment)
          _PaymentRequiredCard(
            order: order,
            canCancel: order.canCancel,
            onCancel: () => _confirmCancel(context, order),
          )
        else if (order.status == OrderStatus.pending)
          _SearchCard(
            order: order,
            canCancel: order.canCancel,
            onCancel: () => _confirmCancel(context, order),
          )
        else if (order.status == OrderStatus.cancelled)
          _CancelledCard(order: order)
        else if (order.status == OrderStatus.delivered)
          _DeliveredCard(order: order)
        else
          _CourierFoundCard(order: order),
        const SizedBox(height: 16),
        DeliveryTimeline(order: order),
        const SizedBox(height: 16),
        FareSummaryCard(order: order),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => context.push(AppPaths.deliveryDetail(order.id)),
          icon: const Icon(Icons.open_in_new, size: 18),
          label: const Text('Lihat Detail Pesanan'),
        ),
      ],
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.order});

  final DeliveryOrder order;

  String get _title {
    switch (order.status) {
      case OrderStatus.awaitingPayment:
        return 'Selesaikan pembayaran';
      case OrderStatus.pending:
        return 'Mencari kurir terdekat';
      case OrderStatus.accepted:
        return 'Kurir ditemukan';
      case OrderStatus.pickedUp:
        return 'Paket sedang diambil';
      case OrderStatus.inTransit:
        return 'Paket dalam perjalanan';
      case OrderStatus.delivered:
        return 'Paket sudah terkirim';
      case OrderStatus.cancelled:
        return 'Pesanan dibatalkan';
    }
  }

  String get _subtitle {
    switch (order.status) {
      case OrderStatus.awaitingPayment:
        return 'Pesanan akan diteruskan ke kurir setelah pembayaran berhasil.';
      case OrderStatus.pending:
        return 'Kami menghubungkan pesananmu ke kurir lokal Jeneponto.';
      case OrderStatus.accepted:
        return '${order.courierName ?? 'Kurir'} akan segera menuju titik jemput.';
      case OrderStatus.pickedUp:
        return 'Kurir sudah memegang paketmu.';
      case OrderStatus.inTransit:
        return 'Paket sedang menuju alamat tujuan.';
      case OrderStatus.delivered:
        return 'Terima kasih sudah menggunakan Jeneponto Kurir.';
      case OrderStatus.cancelled:
        return 'Pesanan ini tidak dilanjutkan.';
    }
  }

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
              Text(
                order.code,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _subtitle,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentRequiredCard extends StatelessWidget {
  const _PaymentRequiredCard({
    required this.order,
    required this.canCancel,
    required this.onCancel,
  });

  final DeliveryOrder order;
  final bool canCancel;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.payment_outlined, color: AppColors.warning),
              SizedBox(width: 8),
              Text(
                'Menunggu pembayaran',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${order.paymentMethod.label} • '
            '${order.paymentMethod.description}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          AppButton(
            label: 'Bayar Sekarang',
            icon: Icons.lock_outline,
            onPressed: () => context.push(AppPaths.deliveryPayment(order.id)),
          ),
          if (canCancel) ...[
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Batalkan Pesanan'),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchCard extends StatelessWidget {
  const _SearchCard({
    required this.order,
    required this.canCancel,
    required this.onCancel,
  });

  final DeliveryOrder order;
  final bool canCancel;
  final VoidCallback onCancel;

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
        children: [
          const _RadarPulse(),
          const SizedBox(height: 8),
          const Text(
            'Sedang mencari kurir...',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Biasanya kurir menerima dalam 1–5 menit. '
            'Kamu bisa menutup aplikasi; status tetap tersimpan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          if (canCancel)
            TextButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Batalkan Pesanan'),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            )
          else
            const Text(
              'Pesanan yang sudah dibayar tidak dapat dibatalkan. '
              'Hubungi dukungan bila perlu bantuan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

class _RadarPulse extends StatefulWidget {
  const _RadarPulse();

  @override
  State<_RadarPulse> createState() => _RadarPulseState();
}

class _RadarPulseState extends State<_RadarPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              for (int i = 0; i < 3; i++)
                Builder(
                  builder: (context) {
                    final double t = (_controller.value + i / 3) % 1;
                    final double size = 64 + (t * 108);
                    return Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary
                              .withValues(alpha: (1 - t) * 0.35),
                          width: 2,
                        ),
                      ),
                    );
                  },
                ),
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delivery_dining,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CourierFoundCard extends StatelessWidget {
  const _CourierFoundCard({required this.order});

  final DeliveryOrder order;

  @override
  Widget build(BuildContext context) {
    final String name = order.courierName ?? 'Kurir Jeneponto';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              name.trim().isEmpty ? 'K' : name.trim()[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kurir kamu',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
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
          const Icon(Icons.verified, color: AppColors.primary),
        ],
      ),
    );
  }
}

class _DeliveredCard extends StatelessWidget {
  const _DeliveredCard({required this.order});

  final DeliveryOrder order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Paket terkirim',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  order.paymentMethod == PaymentMethod.cod
                      ? 'Pembayaran COD otomatis dicatat setelah pesanan selesai.'
                      : 'Pembayaran online sudah tercatat dan paket telah diterima.',
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
    );
  }
}

class _CancelledCard extends StatelessWidget {
  const _CancelledCard({required this.order});

  final DeliveryOrder order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cancel_outlined, color: AppColors.danger, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              order.cancelledReason?.trim().isNotEmpty == true
                  ? order.cancelledReason!
                  : 'Pesanan dibatalkan.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
