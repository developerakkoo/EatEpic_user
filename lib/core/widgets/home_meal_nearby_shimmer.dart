import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:shimmer/shimmer.dart';

class HomeMealNearbyShimmer extends StatelessWidget {
  const HomeMealNearbyShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shimmerColor = colors.surfaceGrey;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Shimmer.fromColors(
        baseColor: colors.surfaceGrey,
        highlightColor: colors.divider,
        child: Container(
          width: double.infinity,
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
              Container(height: 160, color: shimmerColor),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 200,
                      height: 13,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(AppRadius.small),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      width: 110,
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
      ),
    );
  }
}
