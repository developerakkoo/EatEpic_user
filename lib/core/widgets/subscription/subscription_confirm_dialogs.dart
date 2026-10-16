import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/data/models/subscription_models.dart';

Future<bool?> showSubscriptionPauseConfirmDialog(
  BuildContext context, {
  required PausePreview preview,
  required DateTime pauseEnd,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('sub.pauseTitle'.tr()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('sub.pausedUntil'.tr(namedArgs: {'date': _fmt(pauseEnd)})),
          const SizedBox(height: 8),
          Text(
            preview.shiftedMeals > 0
                ? 'sub.mealsWillMove'.tr(namedArgs: {'count': '${preview.shiftedMeals}'})
                : 'sub.noMealsInWindow'.tr(),
          ),
          if (preview.shiftedMeals > 0) ...[
            const SizedBox(height: 8),
            Text('sub.planEnds'.tr(namedArgs: {'date': _fmt(preview.newEndDate)})),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('sub.back'.tr())),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text('sub.confirmPause'.tr())),
      ],
    ),
  );
}

Future<bool?> showSubscriptionCancelConfirmDialog(
  BuildContext context, {
  required CancelPreview preview,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('sub.cancelTitle'.tr()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('sub.undeliveredCancelled'.tr(namedArgs: {'count': '${preview.eligibleMeals}'})),
          const SizedBox(height: 8),
          Text('sub.refund'.tr(namedArgs: {'amount': '${preview.grossRefund}'})),
          if (preview.cancellationFee > 0)
            Text('sub.cancellationFee'.tr(namedArgs: {'amount': '${preview.cancellationFee}'})),
          const SizedBox(height: 8),
          Text(
            preview.netRefund > 0
                ? 'sub.willAddWallet'.tr(namedArgs: {'amount': '${preview.netRefund}'})
                : 'sub.noWalletCredit'.tr(),
            style: ctx.bodyLarge.copyWith(color: AppColors.primary),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('sub.keepPlan'.tr())),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text('sub.cancelPlan'.tr(), style: TextStyle(color: AppColors.error)),
        ),
      ],
    ),
  );
}

String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
