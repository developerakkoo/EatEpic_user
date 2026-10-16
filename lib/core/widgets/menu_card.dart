import 'package:add_to_cart_animated_button/add_to_cart_animated_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/modal/menu_item_modal.dart';

const double _kImageSize = 105;
const double _kImageRadius = 14;

class MenuCard extends StatelessWidget {
  final MenuItemModel item;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final int maxQuantity;
  final bool isBestseller;

  const MenuCard({
    super.key,
    required this.item,
    required this.quantity,
    required this.onQuantityChanged,
    this.maxQuantity = 10,
    this.isBestseller = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNetwork = item.imageUrl.startsWith('http://') ||
        item.imageUrl.startsWith('https://');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: context.colors.background,
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(AppRadius.medium),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md + 1,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _LeftContent(
                      item: item,
                      isBestseller: isBestseller,
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: _kImageSize,
                    height: _kImageSize,
                    child: _ImageWithAddToCart(
                      item: item,
                      quantity: quantity,
                      onQuantityChanged: onQuantityChanged,
                      maxQuantity: maxQuantity,
                      isNetwork: isNetwork,
                      theme: theme,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Divider(
          height: 1,
          thickness: 1,
          indent: AppSpacing.lg,
          endIndent: AppSpacing.lg,
          color: context.colors.divider,
        ),
      ],
    );
  }
}

class _LeftContent extends StatelessWidget {
  const _LeftContent({
    required this.item,
    required this.isBestseller,
    required this.theme,
  });

  final MenuItemModel item;
  final bool isBestseller;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _VegIndicator(isVeg: item.isVeg),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isBestseller) ...[
                    Text(
                      'menuCard.bestseller'.tr(),
                      style: context.caption.copyWith(
                        color: const Color(0xFFE85D04),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs + 3),
                  ],
                  Text(
                    item.name,
                    style: context.headingMedium.copyWith(
                      letterSpacing: -0.2,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs + 3),
                  Text(
                    '₹${item.price}',
                    style: context.headingSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  if (item.description != null &&
                      item.description!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs + 3),
                    Text(
                      item.description!,
                      style: context.bodySmall.copyWith(
                        color: context.colors.textSecondary,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _VegIndicator extends StatelessWidget {
  const _VegIndicator({required this.isVeg});

  final bool isVeg;

  @override
  Widget build(BuildContext context) {
    final color = isVeg ? AppColors.darkGreen : AppColors.error;
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.xs),
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

class _ImageWithAddToCart extends StatelessWidget {
  const _ImageWithAddToCart({
    required this.item,
    required this.quantity,
    required this.onQuantityChanged,
    required this.maxQuantity,
    required this.isNetwork,
    required this.theme,
  });

  final MenuItemModel item;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final int maxQuantity;
  final bool isNetwork;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(_kImageRadius),
          child: SizedBox(
            width: _kImageSize,
            height: _kImageSize,
            child: isNetwork
                ? Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: context.colors.surfaceGrey,
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, url, error) => _ErrorPlaceholder(
                      theme: theme,
                    ),
                  )
                : Image.asset(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _ErrorPlaceholder(
                      theme: theme,
                    ),
                  ),
          ),
        ),
        Positioned(
          bottom: -6,
          left: 0,
          right: 0,
          child: Center(
            child: AddToCart(
              value: quantity,
              onIncrement: onQuantityChanged,
              onDecrement: onQuantityChanged,
              maxValue: maxQuantity,
              width: 100,
              height: 36,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  const _ErrorPlaceholder({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.surfaceGrey,
      child: Icon(
        Icons.restaurant,
        size: 36,
        color: context.colors.textHint,
      ),
    );
  }
}
