import 'package:flutter/material.dart';

import 'package:jeneponto_kurir/features/common/theme/app_colors.dart';
import '../../domain/entities/delivery_order.dart';
import 'delivery_status_badge.dart';

/// Kartu ringkas pesanan untuk riwayat dan beranda pelanggan.
class DeliveryOrderCard extends StatelessWidget {
  const DeliveryOrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.footer,
  });

  final DeliveryOrder order;
  final VoidCallback? onTap;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
              _Line(
                icon: Icons.trip_origin,
                color: AppColors.primary,
                text: order.pickup.fullAddress,
              ),
              const SizedBox(height: 8),
              _Line(
                icon: Icons.location_on,
                color: AppColors.danger,
                text: order.dropoff.fullAddress,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    order.paymentMethod.label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    order.fare.total == 0 ? '-' : _rupiah(order.fare.total),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (order.courierName != null &&
                  order.courierName!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Kurir: ${order.courierName}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (footer != null) ...[
                const Divider(height: 24),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _rupiah(int value) {
    final String digits = value.toString();
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return 'Rp $buffer';
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
