import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/core/typography/app_text_styles.dart';
import 'package:food_app/core/widgets/kitchen_rating_badge.dart';
import 'package:shimmer/shimmer.dart';

const String kKitchenCardDefaultDiscount = '20% off upto ₹100';

class KitchenRestaurantCard extends StatelessWidget {
  const KitchenRestaurantCard({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.rating,
    this.reviewCount = 0,
    required this.deliveryTimeMinutes,
    this.discountLabel,
    this.width = AppLayout.kitchenCardWidth,
    this.imageHeight = AppLayout.kitchenCardImageHeight,
    this.heroTag,
  });

  final String imageUrl;
  final String name;
  final double rating;
  final int reviewCount;
  final int deliveryTimeMinutes;
  final String? discountLabel;
  final double width;
  final double imageHeight;
  final String? heroTag;

  bool get _isNetwork =>
      imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

  String get _offerText {
    final label = discountLabel?.trim();
    return (label != null && label.isNotEmpty) ? label : kKitchenCardDefaultDiscount;
  }

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: width == double.infinity ? null : width,
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        boxShadow: const [AppShadows.cardShadow],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPhotoSection(context),
          _buildInfoSection(context),
        ],
      ),
    );

    if (width == double.infinity) return card;
    return SizedBox(width: width, child: card);
  }

  Widget _buildPhotoSection(BuildContext context) {
    final photo = Stack(
      fit: StackFit.passthrough,
      children: [
        SizedBox(
          width: width == double.infinity ? double.infinity : width,
          height: imageHeight,
          child: _buildImage(context),
        ),
        Positioned(
          right: AppSpacing.sm,
          top: AppSpacing.sm,
          child: KitchenRatingBadge(
            rating: rating,
            reviewCount: reviewCount,
          ),
        ),
        Positioned(
          left: AppSpacing.sm,
          bottom: AppSpacing.sm,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.overlayDark,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _offerText,
              style: context.discountOverlay,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );

    if (heroTag != null) return Hero(tag: heroTag!, child: photo);
    return photo;
  }

  Widget _buildImage(BuildContext context) {
    if (_isNetwork) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: width == double.infinity ? double.infinity : width,
        height: imageHeight,
        memCacheWidth: width == double.infinity ? 720 : (width * 2).round(),
        placeholder: (_, __) => _placeholder(context),
        errorWidget: (_, __, ___) => _placeholder(context, showIcon: true),
      );
    }

    return Image.asset(
      imageUrl,
      fit: BoxFit.cover,
      width: width == double.infinity ? double.infinity : width,
      height: imageHeight,
      errorBuilder: (_, __, ___) => _placeholder(context, showIcon: true),
    );
  }

  Widget _placeholder(BuildContext context, {bool showIcon = false}) {
    if (showIcon) {
      return ColoredBox(
        color: context.colors.surfaceGrey,
        child: Center(
          child: Icon(Icons.restaurant, color: context.colors.textHint, size: 28),
        ),
      );
    }

    return Shimmer.fromColors(
      baseColor: context.colors.surfaceGrey,
      highlightColor: context.colors.divider,
      child: ColoredBox(color: context.colors.surfaceGrey),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: context.headingSmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            reviewCount > 0
                ? 'rating.meta'.tr(namedArgs: {
                    'rating': rating.toStringAsFixed(1),
                    'count': '$reviewCount',
                    'mins': '$deliveryTimeMinutes',
                  })
                : 'rating.minsOnly'.tr(namedArgs: {
                    'mins': '$deliveryTimeMinutes',
                  }),
            style: context.bodySmall.copyWith(
              color: context.colors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
