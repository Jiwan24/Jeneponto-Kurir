import 'package:flutter/material.dart';

import 'package:jeneponto_kurir/features/common/theme/app_colors.dart';
import 'package:jeneponto_kurir/features/common/utils/formatters.dart';
import 'package:jeneponto_kurir/features/delivery/domain/entities/order_status.dart';
import '../../domain/entities/delivery_order.dart';
import '../../domain/entities/payment_method.dart';

/// Timeline status pengiriman.
class DeliveryTimeline extends StatelessWidget {
  const DeliveryTimeline({super.key, required this.order});

  final DeliveryOrder order;

  @override
  Widget build(BuildContext context) {
    if (order.status == OrderStatus.cancelled) {
      return _CancellationCard(order: order);
    }

    final bool isCod = order.paymentMethod == PaymentMethod.cod;
    final List<_TimelineStep> steps = <_TimelineStep>[
      _TimelineStep(
        title: 'Pesanan dibuat',
        time: order.createdAt,
        icon: Icons.receipt_long_outlined,
      ),
      if (!isCod)
        _TimelineStep(
          title: 'Pembayaran',
          time: order.paidAt,
          icon: Icons.payments_outlined,
        ),
      _TimelineStep(
        title: 'Mencari kurir',
        time: order.acceptedAt,
        icon: Icons.person_search_outlined,
      ),
      _TimelineStep(
        title: 'Kurir menerima',
        time: order.acceptedAt,
        icon: Icons.person_pin_circle_outlined,
      ),
      _TimelineStep(
        title: 'Paket diambil',
        time: order.pickedUpAt,
        icon: Icons.inventory_2_outlined,
      ),
      _TimelineStep(
        title: 'Dalam perjalanan',
        time: order.inTransitAt,
        icon: Icons.delivery_dining_outlined,
      ),
      _TimelineStep(
        title: 'Terkirim',
        time: order.deliveredAt,
        icon: Icons.check_circle_outline,
      ),
    ];

    final int activeIndex = _activeIndex(isCod);
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
            'Status Pengiriman',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < steps.length; i++)
            _TimelineTile(
              step: steps[i],
              done: activeIndex > i || activeIndex == steps.length,
              active: activeIndex == i,
              showLine: i < steps.length - 1,
              isLast: i == steps.length - 1,
            ),
        ],
      ),
    );
  }

  int _activeIndex(bool isCod) {
    switch (order.status) {
      case OrderStatus.awaitingPayment:
        return 1;
      case OrderStatus.pending:
        return isCod ? 1 : 2;
      case OrderStatus.accepted:
        return isCod ? 2 : 3;
      case OrderStatus.pickedUp:
        return isCod ? 3 : 4;
      case OrderStatus.inTransit:
        return isCod ? 4 : 5;
      case OrderStatus.delivered:
        return isCod ? 6 : 7;
      case OrderStatus.cancelled:
        return -1;
    }
  }
}

class _TimelineStep {
  const _TimelineStep({
    required this.title,
    required this.icon,
    this.time,
  });

  final String title;
  final IconData icon;
  final DateTime? time;
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.step,
    required this.done,
    required this.active,
    required this.showLine,
    required this.isLast,
  });

  final _TimelineStep step;
  final bool done;
  final bool active;
  final bool showLine;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final Color color = done
        ? AppColors.primary
        : active
            ? AppColors.accent
            : AppColors.border;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: done || active ? 0.15 : 0.06),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color,
                    width: active ? 2 : 1,
                  ),
                ),
                child: Icon(
                  done ? Icons.check : step.icon,
                  size: 14,
                  color: done || active ? color : AppColors.textSecondary,
                ),
              ),
              if (showLine)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: done ? AppColors.primary : AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          active || done ? FontWeight.w700 : FontWeight.w500,
                      color: active || done
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (active)
                    const Text(
                      'Sedang berlangsung',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else if (step.time != null)
                    Text(
                      Formatters.dateTime(step.time!),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CancellationCard extends StatelessWidget {
  const _CancellationCard({required this.order});

  final DeliveryOrder order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cancel_outlined, color: AppColors.danger),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pesanan dibatalkan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.danger,
                  ),
                ),
                if (order.cancelledAt != null)
                  Text(
                    Formatters.dateTime(order.cancelledAt!),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (order.cancelledReason != null &&
                    order.cancelledReason!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    order.cancelledReason!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
