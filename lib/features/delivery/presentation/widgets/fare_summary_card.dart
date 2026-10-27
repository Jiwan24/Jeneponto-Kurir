import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/delivery_order.dart';
import '../../domain/entities/payment_method.dart';

/// Rincian tarif + status pembayaran.
class FareSummaryCard extends StatelessWidget {
  const FareSummaryCard({
    super.key,
    required this.order,
    this.showPayment = true,
  });

  final DeliveryOrder order;
  final bool showPayment;

  @override
  Widget build(BuildContext context) {
    final FareLines fare = FareLines(order);
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
            'Rincian Biaya',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _row('Tarif dasar', Formatters.rupiah(fare.baseFare)),
          const SizedBox(height: 6),
          _row(
            'Jarak ${Formatters.distance(order.distanceKm)}',
            Formatters.rupiah(fare.distanceCharge),
          ),
          if (fare.roundingAdjustment != 0) ...[
            const SizedBox(height: 6),
            _row(
              'Pembulatan',
              Formatters.rupiah(fare.roundingAdjustment),
            ),
          ],
          const Divider(height: 24),
          Row(
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                Formatters.rupiah(order.price),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          if (order.fare.minimumApplied) ...[
            const SizedBox(height: 8),
            const Text(
              'Tarif minimum berlaku untuk pengiriman dekat.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
          if (showPayment) ...[
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.paymentMethod.label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                PaymentStatusBadge(status: order.paymentStatus),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static Widget _row(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Nilai tarif yang dipakai untuk tampilan (fallback aman).
class FareLines {
  FareLines(this.order);

  final DeliveryOrder order;

  int get baseFare => order.fare.baseFare;
  int get distanceCharge => order.fare.distanceCharge;
  int get roundingAdjustment => order.fare.roundingAdjustment;
}

class PaymentStatusBadge extends StatelessWidget {
  const PaymentStatusBadge({super.key, required this.status});

  final PaymentStatus status;

  static Color _colorFor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return AppColors.success;
      case PaymentStatus.pending:
        return AppColors.warning;
      case PaymentStatus.unpaid:
        return AppColors.textSecondary;
      case PaymentStatus.failed:
      case PaymentStatus.expired:
      case PaymentStatus.refunded:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color color = _colorFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
