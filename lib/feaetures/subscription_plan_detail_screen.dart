import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/data/models/subscription_models.dart';
import 'package:food_app/core/widgets/subscription/subscription_quick_checkout_sheet.dart';

class SubscriptionPlanDetailScreen extends StatelessWidget {
  const SubscriptionPlanDetailScreen({
    super.key,
    required this.plan,
    required this.kitchenId,
  });

  final SubscriptionPlanDto plan;
  final String kitchenId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(plan.title)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (plan.kitchenName != null)
              Text(plan.kitchenName!, style: context.headingMedium),
            const SizedBox(height: AppSpacing.sm),
            Text('₹${plan.displayPrice}', style: context.displayMedium),
            if (plan.discountedPrice != null)
              Text(
                'sub.was'.tr(namedArgs: {'price': '${plan.totalPrice}'}),
                style: context.bodyMedium.copyWith(
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'sub.mealsOverDays'.tr(namedArgs: {
                'count': '${plan.durationInDays}',
                'days': '${plan.durationInDays}',
                'perMeal': '${plan.pricePerMeal}',
              }),
              style: context.bodyLarge,
            ),
            if (plan.planType != null)
              Text('sub.planType'.tr(namedArgs: {'type': '${plan.planType}'}),
                  style: context.bodyMedium),
            if (plan.mealTypes.isNotEmpty)
              Text('sub.mealsList'.tr(namedArgs: {'list': plan.mealTypes.join(", ")}),
                  style: context.bodyMedium),
            Text(plan.isVeg ? 'sub.vegetarian'.tr() : 'sub.nonVegetarian'.tr(),
                style: context.bodyMedium),
            if (plan.description != null && plan.description!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(plan.description!, style: context.bodyLarge),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => showSubscriptionQuickCheckoutSheet(
                  context,
                  initialKitchenId: kitchenId,
                  initialMenuItemId: plan.menuItemId,
                  initialPlanId: plan.id,
                  lockedPlan: plan,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: Text('sub.subscribeToPlan'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
