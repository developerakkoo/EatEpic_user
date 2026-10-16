import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';

class SubscriptionCalendarLegend extends StatelessWidget {
  const SubscriptionCalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        _LegendItem(color: AppColors.primary, label: 'sub.legendDelivered'.tr()),
        _LegendItem(
            color: AppColors.info, label: 'sub.legendUpcoming'.tr(), outline: true),
        _LegendItem(color: AppColors.warning, label: 'sub.legendInProgress'.tr()),
        _LegendItem(
            color: context.colors.textSecondary, label: 'sub.legendSkipped'.tr()),
        _LegendItem(color: AppColors.error, label: 'sub.legendCancelled'.tr()),
        _LegendItem(color: AppColors.pausePurple, label: 'sub.legendPaused'.tr()),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    this.outline = false,
  });

  final Color color;
  final String label;
  final bool outline;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: outline ? Colors.transparent : color,
            shape: BoxShape.circle,
            border: outline ? Border.all(color: color, width: 2) : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: context.caption),
      ],
    );
  }
}
