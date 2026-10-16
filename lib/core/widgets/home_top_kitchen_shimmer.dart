import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:shimmer/shimmer.dart';

class HomeTopKitchenShimmer extends StatelessWidget {
  const HomeTopKitchenShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shimmerColor = colors.surfaceGrey;

    return Shimmer.fromColors(
      baseColor: colors.surfaceGrey,
      highlightColor: colors.divider,
      child: Container(
        width: AppLayout.kitchenCardWidth,
        height: AppLayout.kitchenCardHeight,
        decoration: BoxDecoration(
          color: shimmerColor,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          boxShadow: [
            AppShadows.softShadowFor(Theme.of(context).brightness),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: AppLayout.kitchenCardImageHeight,
              color: shimmerColor,
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 13,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(AppRadius.small),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: 80,
                    height: 11,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(AppRadius.small),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
