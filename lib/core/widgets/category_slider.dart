import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/core/typography/app_text_styles.dart';
import 'package:food_app/feaetures/category_kitchens_screen.dart';
import 'package:food_app/provider/category_provider.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class CategorySlider extends StatefulWidget {
  const CategorySlider({super.key});

  @override
  State<CategorySlider> createState() => CategorySliderState();
}

class CategorySliderState extends State<CategorySlider> {
  final ScrollController _scrollController = ScrollController();
  String? _highlightedId;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> highlightCategory(String categoryId) async {
    final categories = context.read<CategoryProvider>().categories;
    final index = categories.indexWhere((c) => c.id == categoryId);
    if (index < 0) return;

    if (_scrollController.hasClients) {
      const chipWidth = AppLayout.categoryChipWidth + AppSpacing.sm;
      final offset = (index * chipWidth).toDouble().clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          );
      await _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }

    if (!mounted) return;
    setState(() => _highlightedId = categoryId);
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (mounted) setState(() => _highlightedId = null);
  }

  Widget _buildCategoryImage(BuildContext context, String imageUrl) {
    final isAsset = imageUrl.startsWith('assets/');
    final isNetwork = imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

    if (isNetwork) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.contain,
        memCacheWidth: 96,
        placeholder: (_, __) => _placeholderIcon(context),
        errorWidget: (_, __, ___) => _placeholderIcon(context),
      );
    }
    if (isAsset) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _placeholderIcon(context),
      );
    }
    return _placeholderIcon(context);
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();

    if (categoryProvider.isLoading && categoryProvider.categories.isEmpty) {
      return SizedBox(
        height: 96,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (_, __) => const _CategoryShimmerChip(),
        ),
      );
    }

    return SizedBox(
      height: 96,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categoryProvider.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final category = categoryProvider.categories[index];
          final isHighlighted = _highlightedId == category.id;

          return GestureDetector(
            onTap: () {
              categoryProvider.selectCategory(index);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategoryKitchensScreen(
                    categoryId: category.id,
                    categoryName: category.name,
                  ),
                ),
              );
            },
            child: SizedBox(
              width: AppLayout.categoryChipWidth,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: AppLayout.categoryImageBox,
                    height: AppLayout.categoryImageBox,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: context.colors.surfaceGrey,
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      border: isHighlighted
                          ? Border.all(color: AppColors.primary, width: 2)
                          : null,
                      boxShadow: isHighlighted
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: _buildCategoryImage(context, category.imageUrl),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    category.name,
                    style: context.categoryChipLabel,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _placeholderIcon(BuildContext context) {
    return Icon(Icons.restaurant_menu_rounded, color: context.colors.textHint, size: 24);
  }
}

class _CategoryShimmerChip extends StatelessWidget {
  const _CategoryShimmerChip();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Shimmer.fromColors(
      baseColor: colors.surfaceGrey,
      highlightColor: colors.divider,
      child: SizedBox(
        width: AppLayout.categoryChipWidth,
        child: Column(
          children: [
            Container(
              width: AppLayout.categoryImageBox,
              height: AppLayout.categoryImageBox,
              decoration: BoxDecoration(
                color: colors.surfaceGrey,
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 56,
              height: 10,
              decoration: BoxDecoration(
                color: colors.surfaceGrey,
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
