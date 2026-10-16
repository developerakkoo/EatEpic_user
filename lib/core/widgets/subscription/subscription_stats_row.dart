import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/data/models/subscription_models.dart';

class SubscriptionStatsRow extends StatelessWidget {
  const SubscriptionStatsRow({super.key, required this.stats});

  final MealStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatChip(label: 'sub.statDelivered'.tr(), value: stats.delivered, color: AppColors.primary)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _StatChip(label: 'sub.statPending'.tr(), value: stats.pending, color: AppColors.info)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _StatChip(label: 'sub.statRemaining'.tr(), value: stats.remaining, color: context.colors.textSecondary)),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: context.headingSmall.copyWith(color: color),
          ),
          Text(label, style: context.caption),
        ],
      ),
    );
  }
}
