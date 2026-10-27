import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:jeneponto_kurir/features/common/di/person2_locator.dart';
import 'package:jeneponto_kurir/features/common/router/app_paths.dart';
import 'package:jeneponto_kurir/features/common/theme/app_colors.dart';
import 'package:jeneponto_kurir/features/common/utils/formatters.dart';
import 'package:jeneponto_kurir/features/common/widgets/app_button.dart';
import 'package:jeneponto_kurir/features/common/widgets/empty_state.dart';
import '../../../delivery/domain/entities/delivery_order.dart';
import '../../../delivery/domain/entities/payment_method.dart';
import '../../../delivery/presentation/bloc/delivery_order_bloc.dart';
import '../../../delivery/presentation/bloc/delivery_order_state.dart';
import '../../../delivery/presentation/widgets/fare_summary_card.dart';
import '../../domain/entities/payment.dart';
import '../bloc/payment_bloc.dart';
import '../bloc/payment_state.dart';

/// Halaman pembayaran satu pesanan (Midtrans Snap atau COD).
class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DeliveryOrderBloc>(
      create: (_) =>
          sl<DeliveryOrderBloc>()..add(DeliveryOrderRequested(orderId)),
      child: _PaymentOrderLoader(orderId: orderId),
    );
  }
}

class _PaymentOrderLoader extends StatelessWidget {
  const _PaymentOrderLoader({required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeliveryOrderBloc, DeliveryOrderState>(
      builder: (context, state) {
        final DeliveryOrder? order = state.order;
        if (order == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Pembayaran')),
            body: state.status == DeliveryOrderViewStatus.initial ||
                    state.status == DeliveryOrderViewStatus.loading
                ? const Center(child: CircularProgressIndicator())
                : EmptyState(
                    icon: Icons.payment_outlined,
                    title: 'Pesanan tidak ditemukan',
                    message: state.message ?? 'Coba muat ulang halaman ini.',
                    action: FilledButton(
                      onPressed: () => context
                          .read<DeliveryOrderBloc>()
                          .add(DeliveryOrderRequested(orderId)),
                      child: const Text('Muat Ulang'),
                    ),
                  ),
          );
        }

        if (order.paymentMethod == PaymentMethod.cod) {
          return _CodPaymentView(order: order);
        }

        return BlocProvider<PaymentBloc>(
          key: ValueKey<String>('payment-${order.id}'),
          create: (_) => sl<PaymentBloc>()..add(PaymentStarted(order)),
          child: _MidtransPaymentView(order: order),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// COD
// ---------------------------------------------------------------------------

class _CodPaymentView extends StatelessWidget {
  const _CodPaymentView({required this.order});

  final DeliveryOrder order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const _InfoPanel(
            icon: Icons.payments_outlined,
            color: AppColors.success,
            title: 'Bayar di Tempat (COD)',
            message: 'Tidak perlu membayar sekarang. Siapkan uang tunai dan '
                'bayarkan langsung ke kurir saat paket diterima.',
          ),
          const SizedBox(height: 16),
          _AmountCard(order: order),
          const SizedBox(height: 16),
          FareSummaryCard(order: order),
          const SizedBox(height: 20),
          AppButton(
            label: 'Lihat Status Pesanan',
            icon: Icons.local_shipping_outlined,
            onPressed: () => context.pushReplacement(
              AppPaths.deliverySearching(order.id),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go(AppPaths.deliveryHistory),
            child: const Text('Kembali ke Pesanan'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Midtrans Snap
// ---------------------------------------------------------------------------

class _MidtransPaymentView extends StatefulWidget {
  const _MidtransPaymentView({required this.order});

  final DeliveryOrder order;

  @override
  State<_MidtransPaymentView> createState() => _MidtransPaymentViewState();
}

class _MidtransPaymentViewState extends State<_MidtransPaymentView> {
  String? _openedUrl;

  Future<void> _openPaymentUrl(String url) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) {
      _showMessage('Tautan pembayaran tidak valid.');
      return;
    }
    try {
      final bool opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        _showMessage(
          'Tidak bisa membuka browser. Salin tautan pembayaran dari detail.',
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Gagal membuka halaman pembayaran.');
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PaymentBloc, PaymentState>(
      listenWhen: (previous, current) =>
          current.message != previous.message ||
          current.status != previous.status ||
          current.redirectUrl != previous.redirectUrl,
      listener: (context, state) {
        if (state.message != null && !state.isPaid) {
          _showMessage(state.message!);
        }
        final String? url = state.redirectUrl;
        if (url != null &&
            url.isNotEmpty &&
            state.payment?.status == PaymentStatus.pending &&
            _openedUrl != url) {
          _openedUrl = url;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _openPaymentUrl(url);
          });
        }
      },
      builder: (context, state) {
        // Status order adalah sumber cadangan bila webhook sudah memperbarui
        // order tetapi dokumen pembayaran belum sempat terbaca.
        final bool isPaid = state.isPaid || widget.order.paymentStatus.isPaid;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Pembayaran'),
            actions: [
              IconButton(
                tooltip: 'Muat ulang status',
                onPressed: state.isBusy
                    ? null
                    : () => context
                        .read<PaymentBloc>()
                        .add(const PaymentCheckRequested()),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: isPaid
              ? _PaidView(order: widget.order, payment: state.payment)
              : _buildPaymentBody(context, state),
        );
      },
    );
  }

  Widget _buildPaymentBody(BuildContext context, PaymentState state) {
    final Payment? payment = state.payment;
    final bool waiting = state.status == PaymentFlowStatus.waiting ||
        payment?.status == PaymentStatus.pending;
    final bool loading = state.status == PaymentFlowStatus.initial ||
        state.status == PaymentFlowStatus.loading;
    final bool failed = state.status == PaymentFlowStatus.failure;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _AmountCard(order: widget.order),
        const SizedBox(height: 16),
        if (loading)
          const _InfoPanel(
            icon: Icons.hourglass_top,
            color: AppColors.textSecondary,
            title: 'Memeriksa pembayaran',
            message: 'Mencari tagihan yang sudah ada untuk pesanan ini...',
          )
        else if (failed)
          _InfoPanel(
            icon: Icons.error_outline,
            color: AppColors.danger,
            title: 'Pembayaran belum berhasil',
            message: state.message ??
                'Terjadi masalah saat membuat pembayaran. Coba lagi.',
          )
        else if (waiting)
          const _InfoPanel(
            icon: Icons.open_in_browser,
            color: AppColors.warning,
            title: 'Menunggu pembayaran',
            message: 'Selesaikan pembayaran di halaman Midtrans. '
                'Status akan diperbarui otomatis setelah pembayaran '
                'berhasil.',
          )
        else
          const _InfoPanel(
            icon: Icons.verified_user_outlined,
            color: AppColors.primary,
            title: 'Pembayaran aman',
            message: 'Kamu akan diarahkan ke halaman Midtrans untuk memilih '
                'QRIS, transfer bank, atau e-wallet.',
          ),
        const SizedBox(height: 16),
        FareSummaryCard(order: widget.order),
        const SizedBox(height: 16),
        _PaymentMeta(order: widget.order, payment: payment),
        const SizedBox(height: 20),
        if (waiting) ...[
          AppButton(
            label: 'Buka Halaman Pembayaran',
            icon: Icons.open_in_new,
            onPressed: state.redirectUrl == null || state.redirectUrl!.isEmpty
                ? null
                : () => _openPaymentUrl(state.redirectUrl!),
          ),
          const SizedBox(height: 8),
          AppButton(
            label: 'Saya Sudah Bayar',
            icon: Icons.check_circle_outline,
            isLoading: state.isChecking,
            onPressed: state.isChecking
                ? null
                : () => context
                    .read<PaymentBloc>()
                    .add(const PaymentCheckRequested()),
          ),
        ] else if (!loading) ...[
          AppButton(
            label: failed ? 'Coba Lagi' : 'Bayar Sekarang',
            icon: Icons.lock_outline,
            isLoading: state.status == PaymentFlowStatus.creating,
            onPressed: () =>
                context.read<PaymentBloc>().add(const PaymentCreateRequested()),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: state.isBusy
                ? null
                : () => context
                    .read<PaymentBloc>()
                    .add(const PaymentCheckRequested()),
            child: const Text('Sudah pernah bayar? Periksa status'),
          ),
        ],
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.pushReplacement(
            AppPaths.deliveryDetail(widget.order.id),
          ),
          child: const Text('Lihat Detail Pesanan'),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pembayaran diproses oleh Midtrans. Jeneponto Kurir tidak '
          'menyimpan data kartu atau e-wallet kamu.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _PaidView extends StatelessWidget {
  const _PaidView({required this.order, required this.payment});

  final DeliveryOrder order;
  final Payment? payment;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      children: [
        const Icon(
          Icons.check_circle,
          size: 72,
          color: AppColors.success,
        ),
        const SizedBox(height: 12),
        const Text(
          'Pembayaran Berhasil',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Pesanan ${order.code} sudah dibayar. '
          'Kurir terdekat akan segera menerima pesananmu.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            height: 1.4,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),
        _AmountCard(order: order),
        if (payment?.transactionId != null) ...[
          const SizedBox(height: 12),
          _PaymentMeta(order: order, payment: payment),
        ],
        const SizedBox(height: 20),
        AppButton(
          label: 'Lihat Status Pesanan',
          icon: Icons.radar,
          onPressed: () => context.pushReplacement(
            AppPaths.deliverySearching(order.id),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => context.go(AppPaths.deliveryHistory),
          child: const Text('Kembali ke Pesanan'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bagian tampilan bersama
// ---------------------------------------------------------------------------

class _AmountCard extends StatelessWidget {
  const _AmountCard({required this.order});

  final DeliveryOrder order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total pembayaran',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.rupiah(order.price),
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                size: 14,
                color: Colors.white70,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${order.code} • ${order.itemCategory}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
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

class _PaymentMeta extends StatelessWidget {
  const _PaymentMeta({required this.order, required this.payment});

  final DeliveryOrder order;
  final Payment? payment;

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
        children: [
          _row('Metode', order.paymentMethod.label),
          _row('Status pesanan', order.status.label),
          _row('Status pembayaran', order.paymentStatus.label),
          if (payment?.channel != null && payment!.channel!.isNotEmpty)
            _row('Kanal', payment!.channel!),
          if (payment?.transactionId != null)
            _row('ID transaksi', payment!.transactionId!),
          if (payment?.midtransOrderId != null)
            _row('ID Midtrans', payment!.midtransOrderId!),
          if (payment?.expiresAt != null)
            _row('Bayar sebelum', Formatters.dateTime(payment!.expiresAt!)),
        ],
      ),
    );
  }

  static Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
