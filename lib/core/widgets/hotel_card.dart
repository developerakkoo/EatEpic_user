import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/modal/hotel_modal.dart';

class HotelCard extends StatelessWidget {
  final HotelModel hotel;
  final VoidCallback? onTap;

  const HotelCard({super.key, required this.hotel, this.onTap});

  Widget _buildHotelImage(BuildContext context, String imageUrl) {
    final isNetwork = imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
    return SizedBox(
      height: 160,
      width: double.infinity,
      child: isNetwork
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              height: 160,
              width: double.infinity,
              memCacheWidth: 400,
              placeholder: (_, __) => Container(
                color: context.colors.surfaceGrey,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (_, __, ___) => Container(
                color: context.colors.surfaceGrey,
                child: const Icon(Icons.image_not_supported, size: 48),
              ),
            )
          : Image.asset(imageUrl, height: 160, width: double.infinity, fit: BoxFit.cover),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: hotel.isOpen ? 1 : 0.6,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'hotel_${hotel.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.large + 2),
                child: Stack(
                  children: [
                    _buildHotelImage(context, hotel.imageUrl),

                    /// Discount Ribbon
                    if (hotel.discount != null)
                      Positioned(
                        left: 0,
                        top: AppSpacing.md,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs + 2,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(AppRadius.medium),
                              bottomRight: Radius.circular(AppRadius.medium),
                            ),
                          ),
                          child: Text(
                            hotel.discount!,
                            style: AppTypography.labelBold.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),

                    /// Rating Badge
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.small),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: AppColors.white, size: 14),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              hotel.rating.toString(),
                              style: context.caption.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    /// Open / Closed Badge
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: hotel.isOpen ? AppColors.darkGreen : context.colors.textHint,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          hotel.isOpen ? 'OPEN' : 'CLOSED',
                          style: context.caption.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                /// Veg / Non Veg Indicator
                Container(
                  height: 14,
                  width: 14,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: hotel.isVeg ? AppColors.darkGreen : AppColors.error,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      height: 8,
                      width: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hotel.isVeg ? AppColors.darkGreen : AppColors.error,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: AppSpacing.sm),

                Expanded(
                  child: Text(
                    hotel.name,
                    style: context.headingLarge,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xs),

            Text(
              hotel.cuisine,
              style: context.bodyLarge.copyWith(color: context.colors.textSecondary),
            ),

            const SizedBox(height: AppSpacing.xs + 2),

            Row(
              children: [
                Text('${hotel.deliveryTime} mins', style: context.bodyMedium),
                const SizedBox(width: AppSpacing.md),
                Text('₹${hotel.priceForOne} for one', style: context.bodyMedium),
                const SizedBox(width: AppSpacing.md),
                Text('${hotel.distance} km', style: context.bodyMedium),
              ],
            ),
          ],
        ),
      ),
    );
    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.large + 2),
          child: content,
        ),
      );
    }
    return content;
  }
}
