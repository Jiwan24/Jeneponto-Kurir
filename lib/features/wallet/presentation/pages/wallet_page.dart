import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:jeneponto_kurir/features/common/constants/app_constants.dart';
import 'package:jeneponto_kurir/features/common/di/person2_locator.dart';
import 'package:jeneponto_kurir/features/common/theme/app_colors.dart';
import 'package:jeneponto_kurir/features/common/utils/formatters.dart';
import 'package:jeneponto_kurir/features/common/widgets/app_button.dart';
import 'package:jeneponto_kurir/features/common/widgets/empty_state.dart';
import '../../domain/entities/wallet.dart';
import '../bloc/wallet_bloc.dart';
import '../bloc/wallet_state.dart';

/// Dompet kurir: saldo, pendapatan, dan riwayat transaksi.
///
/// Modul ini tidak menangani login. Host aplikasi wajib mengirim [courierId]
/// dari sesi kurir yang sedang aktif.
class WalletPage extends StatelessWidget {
  const WalletPage({super.key, this.courierId = ''});

  final String courierId;

  @override
  Widget build(BuildContext context) {
    if (courierId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dompet Kurir')),
        body: const EmptyState(
          icon: Icons.account_balance_wallet_outlined,
          title: 'ID kurir tidak tersedia',
          message: 'Host aplikasi perlu mengirim courierId ke halaman ini.',
        ),
      );
    }
    return BlocProvider<WalletBloc>(
      create: (_) => sl<WalletBloc>()..add(WalletRequested(courierId)),
      child: _WalletView(uid: courierId),
    );
  }
}

class _WalletView extends StatelessWidget {
  const _WalletView({required this.uid});

  final String uid;

  void _showPayoutInfo(BuildContext context, Wallet wallet) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Penarikan Saldo',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Penarikan minimum ${Formatters.rupiah(AppConstants.minimumPayout)}. '
                'Saldo kamu saat ini ${Formatters.rupiah(wallet.balance)}.',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              const _PayoutStep(
                number: '1',
                text: 'Pastikan saldo tersedia sudah mencapai batas minimum.',
              ),
              const _PayoutStep(
                number: '2',
                text: 'Hubungi admin Jeneponto Kurir untuk mengajukan '
                    'pencairan ke rekening atau e-wallet.',
              ),
              const _PayoutStep(
                number: '3',
                text: 'Admin memproses transfer dan mencatatnya di riwayat '
                    'dompet.',
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'Layanan pelanggan: ${AppConstants.supportPhone}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Tutup',
                onPressed: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WalletBloc, WalletState>(
      listenWhen: (previous, current) => current.message != previous.message,
      listener: (context, state) {
        if (state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
        }
      },
      builder: (context, state) {
        final Wallet wallet = state.wallet ?? Wallet.empty(uid);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Dompet Kurir'),
            actions: [
              IconButton(
                tooltip: 'Muat ulang',
                onPressed: () =>
                    context.read<WalletBloc>().add(WalletRequested(uid)),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: state.status == WalletViewStatus.failure && state.wallet == null
              ? EmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Gagal memuat dompet',
                  message: state.message ?? 'Periksa koneksi lalu coba lagi.',
                  action: FilledButton(
                    onPressed: () =>
                        context.read<WalletBloc>().add(WalletRequested(uid)),
                    child: const Text('Coba Lagi'),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    context.read<WalletBloc>().add(WalletRequested(uid));
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      _BalanceCard(
                        wallet: wallet,
                        onPayout: () => _showPayoutInfo(context, wallet),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Riwayat Transaksi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '${state.transactions.length} transaksi',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if ((state.status == WalletViewStatus.initial ||
                              state.status == WalletViewStatus.loading) &&
                          state.transactions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (state.transactions.isEmpty)
                        const EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'Belum ada transaksi',
                          message:
                              'Pendapatan dari pengiriman yang selesai akan '
                              'muncul di sini.',
                        )
                      else
                        for (final transaction in state.transactions) ...[
                          _TransactionTile(transaction: transaction),
                          const SizedBox(height: 10),
                        ],
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.wallet, required this.onPayout});

  final Wallet wallet;
  final VoidCallback onPayout;

  @override
  Widget build(BuildContext context) {
    final bool canWithdraw = wallet.balance >= AppConstants.minimumPayout;
    final int remaining = AppConstants.minimumPayout - wallet.balance;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Saldo tersedia',
                style: TextStyle(fontSize: 13, color: Colors.white70),
              ),
              const Spacer(),
              if (wallet.pendingBalance > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '+${Formatters.rupiah(wallet.pendingBalance)} tertahan',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            Formatters.rupiah(wallet.balance),
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Total pendapatan',
                  value: Formatters.rupiah(wallet.totalEarnings),
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _MiniStat(
                  label: 'Sudah ditarik',
                  value: Formatters.rupiah(wallet.totalWithdrawn),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton.icon(
              onPressed: onPayout,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryDark,
              ),
              icon: Icon(
                canWithdraw
                    ? Icons.account_balance_outlined
                    : Icons.info_outline,
                size: 18,
              ),
              label: Text(
                canWithdraw
                    ? 'Ajukan Penarikan'
                    : 'Kurang ${Formatters.rupiah(remaining)} untuk menarik',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          if (!canWithdraw) ...[
            const SizedBox(height: 6),
            Text(
              'Minimum penarikan ${Formatters.rupiah(AppConstants.minimumPayout)}.',
              style: const TextStyle(fontSize: 10, color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white70),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _PayoutStep extends StatelessWidget {
  const _PayoutStep({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final WalletTransaction transaction;

  IconData get _icon {
    switch (transaction.type) {
      case WalletTransactionType.earning:
        return Icons.arrow_downward;
      case WalletTransactionType.commission:
        return Icons.percent;
      case WalletTransactionType.withdrawal:
        return Icons.arrow_upward;
      case WalletTransactionType.refund:
        return Icons.undo;
      case WalletTransactionType.adjustment:
        return Icons.tune;
    }
  }

  Color get _color {
    switch (transaction.type) {
      case WalletTransactionType.earning:
        return AppColors.success;
      case WalletTransactionType.commission:
        return AppColors.warning;
      case WalletTransactionType.withdrawal:
        return AppColors.danger;
      case WalletTransactionType.refund:
        return AppColors.primary;
      case WalletTransactionType.adjustment:
        return AppColors.textSecondary;
    }
  }

  Color get _statusColor {
    switch (transaction.status) {
      case WalletTransactionStatus.pending:
        return AppColors.warning;
      case WalletTransactionStatus.available:
        return AppColors.primary;
      case WalletTransactionStatus.paid:
        return AppColors.success;
      case WalletTransactionStatus.failed:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int amount = transaction.amount;
    final String amountText =
        '${amount >= 0 ? '+' : '-'}${Formatters.rupiah(amount.abs())}';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: _color.withValues(alpha: 0.12),
            child: Icon(_icon, size: 18, color: _color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description.trim().isEmpty
                      ? transaction.type.label
                      : transaction.description.trim(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  Formatters.dateTime(transaction.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amountText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: transaction.isCredit
                      ? AppColors.success
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  transaction.status.label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
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
