import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/core/typography/app_text_styles.dart';
import 'package:food_app/provider/catalog_provider.dart';
import 'package:shimmer/shimmer.dart';

const String kKitchenCardDefaultDiscount = '20% off upto ₹100';

/// Structured promo banner card.
class HomePromoBannerCard extends StatelessWidget {
  const HomePromoBannerCard({
    super.key,
    required this.banner,
    this.onTap,
  });

  final BannerItem banner;
  final VoidCallback? onTap;

  bool get _hasNetworkImage =>
      banner.imageUrl.startsWith('http://') || banner.imageUrl.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.large),
          child: Ink(
            width: double.infinity,
            height: AppLayout.promoBannerHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.large),
              gradient: LinearGradient(
                colors: [
                  context.colors.bannerBackground,
                  context.colors.primaryLight,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'home.specialOffer'.tr(),
                        style: context.headingSmall.copyWith(
                          color: context.colors.bannerText,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        banner.title.isNotEmpty ? banner.title : 'home.promoTitle'.tr(),
                        style: context.bannerTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        banner.subtitle?.isNotEmpty == true
                            ? banner.subtitle!
                            : 'home.promoSubtitle'.tr(),
                        style: context.bannerSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: context.colors.card,
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: context.colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_hasNetworkImage)
                  Positioned(
                    right: AppSpacing.sm,
                    bottom: 0,
                    child: SizedBox(
                      height: 120,
                      width: 120,
                      child: CachedNetworkImage(
                        imageUrl: banner.imageUrl,
                        fit: BoxFit.contain,
                        memCacheWidth: 240,
                        placeholder: (_, __) => Shimmer.fromColors(
                          baseColor: context.colors.surfaceGrey,
                          highlightColor: context.colors.divider,
                          child: Container(color: context.colors.surfaceGrey),
                        ),
                        errorWidget: (_, __, ___) => Icon(
                          Icons.restaurant,
                          size: 48,
                          color: context.colors.textHint,
                        ),
                      ),
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

class HomePromoPageDots extends StatelessWidget {
  const HomePromoPageDots({
    super.key,
    required this.count,
    required this.activeIndex,
  });

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    if (count < 2) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final active = i == activeIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            width: active ? AppSpacing.sm : 6,
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: active ? AppColors.primary : context.colors.textHint,
            ),
          );
        }),
      ),
    );
  }
}
