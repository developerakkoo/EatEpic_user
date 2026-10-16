import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/core/typography/app_text_styles.dart';
import 'package:food_app/provider/cart_provider.dart';

class CartSummaryBar extends StatelessWidget {
  const CartSummaryBar({super.key, required this.cart});

  final CartProvider cart;

  @override
  Widget build(BuildContext context) {
    if (cart.isEmpty) return const SizedBox.shrink();

    final itemLabel =
        cart.itemCount == 1 ? 'cartBar.item'.tr() : 'cartBar.items'.tr();
    final totalDisplay = '₹${cart.total.toStringAsFixed(2)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/cart'),
          borderRadius: BorderRadius.circular(AppRadius.large),
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          child: Ink(
            height: AppLayout.cartBarHeight,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.large),
              boxShadow: [
                AppShadows.cartBarShadowFor(Theme.of(context).brightness),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.lg),
                    child: Row(
                      children: [
                        Text(
                          '${cart.itemCount} $itemLabel',
                          style: context.cartBarText,
                        ),
                        Container(
                          width: 1,
                          height: 14,
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          color: AppColors.white.withValues(alpha: 0.4),
                        ),
                        Text(totalDisplay, style: context.cartBarText),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.lg),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('cartBar.viewCart'.tr(), style: context.cartBarAction),
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppColors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
