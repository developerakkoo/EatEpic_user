import 'package:shimmer/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';

class HotelShimmerCard extends StatelessWidget {
  const HotelShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Shimmer.fromColors(
        baseColor: context.colors.divider,
        highlightColor: context.colors.surfaceGrey,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: context.colors.surfaceGrey,
            borderRadius: BorderRadius.circular(AppRadius.large),
          ),
        ),
      ),
    );
  }
}
