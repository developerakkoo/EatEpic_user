import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';

class KitchenRatingBadge extends StatelessWidget {
  const KitchenRatingBadge({
    super.key,
    required this.rating,
    required this.reviewCount,
  });

  final double rating;
  final int reviewCount;

  bool get _isNew => reviewCount <= 0;

  Color get _color {
    if (_isNew) return AppColors.textHint;
    if (rating >= 4) return AppColors.primary;
    if (rating >= 3) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: AppColors.white, size: 14),
          const SizedBox(width: AppSpacing.xs),
          Text(
            _isNew ? 'rating.new'.tr() : rating.toStringAsFixed(1),
            style: context.caption.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
