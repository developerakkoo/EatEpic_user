import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/core/widgets/subscription/subscription_status_labels.dart';
import 'package:food_app/data/models/subscription_models.dart';

class SubscriptionPlanCard extends StatelessWidget {
  const SubscriptionPlanCard({
    super.key,
    required this.subscription,
    required this.onTap,
    this.selected = false,
  });

  final UserSubscriptionSummary subscription;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final stats = subscription.mealStats;
    final total = stats.totalMeals > 0 ? stats.totalMeals : subscription.durationInDays;
    final progress = total > 0 ? stats.delivered / total : 0.0;
    final statusLabel = SubscriptionStatusLabels.subscriptionStatus(subscription.status);
    final statusColor = switch (subscription.status.toUpperCase()) {
      'ACTIVE' => AppColors.primary,
      'PAUSED' => AppColors.pausePurple,
      'CANCELLED' => AppColors.error,
      _ => context.colors.textSecondary,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium + 2),
        side: selected
            ? const BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.medium + 2),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(subscription.title, style: context.headingSmall),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.small),
                    ),
                    child: Text(
                      statusLabel,
                      style: context.caption.copyWith(color: statusColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${subscription.partnerName} · ${subscription.menuName}',
                style: context.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.small),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: context.colors.surfaceGrey,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'sub.mealsDelivered'.tr(namedArgs: {
                  'delivered': '${stats.delivered}',
                  'total': '$total',
                }),
                style: context.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
