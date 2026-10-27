import 'package:flutter/material.dart';

import 'package:jeneponto_kurir/features/common/theme/app_colors.dart';
import 'package:jeneponto_kurir/features/delivery/domain/entities/order_status.dart';

/// Badge status pesanan untuk modul delivery.
class DeliveryStatusBadge extends StatelessWidget {
  const DeliveryStatusBadge({super.key, required this.status});

  final OrderStatus status;

  static Color colorFor(OrderStatus status) {
    switch (status) {
      case OrderStatus.awaitingPayment:
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.accepted:
      case OrderStatus.pickedUp:
        return AppColors.primary;
      case OrderStatus.inTransit:
        return AppColors.accent;
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color color = colorFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
