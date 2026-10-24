import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/core/di/app_services.dart';
import 'package:food_app/core/widgets/kitchen_rating_badge.dart';
import 'package:food_app/data/models/kitchen_review.dart';

class KitchenReviewsSection extends StatefulWidget {
  const KitchenReviewsSection({
    super.key,
    required this.kitchenId,
    required this.initialRating,
    required this.initialReviewCount,
    this.onSummary,
  });

  final String kitchenId;
  final double initialRating;
  final int initialReviewCount;
  final void Function(double rating, int reviewCount)? onSummary;

  @override
  State<KitchenReviewsSection> createState() => _KitchenReviewsSectionState();
}

class _KitchenReviewsSectionState extends State<KitchenReviewsSection> {
  final List<KitchenReview> _reviews = [];
  Map<int, int> _distribution = const {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
  late double _rating = widget.initialRating;
  late int _reviewCount = widget.initialReviewCount;
  int _page = 0;
  int _total = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  bool get _hasMore => _reviews.length < _total;

  Future<void> _load({required bool reset}) async {
    if (_loadingMore) return;
    setState(() {
      if (reset) {
        _loading = true;
        _error = null;
      } else {
        _loadingMore = true;
      }
    });

    try {
      final result = await AppServices.instance.kitchenRepository.getKitchenReviews(
        widget.kitchenId,
        page: reset ? 1 : _page + 1,
      );
      if (!mounted) return;
      var count = result.totalReviews > 0 ? result.totalReviews : result.total;
      if (count <= 0 && reset) count = result.reviews.length;
      var rating = result.averageRating;
      if (rating <= 0 && result.reviews.isNotEmpty) {
        final sum = result.reviews.fold<int>(0, (total, review) => total + review.rating);
        rating = sum / result.reviews.length;
      }
      setState(() {
        _rating = rating;
        _reviewCount = count;
        _distribution = result.distribution;
        _page = result.page;
        _total = result.total;
        if (reset) {
          _reviews
            ..clear()
            ..addAll(result.reviews);
        } else {
          _reviews.addAll(result.reviews);
        }
        _loading = false;
        _loadingMore = false;
      });
      widget.onSummary?.call(_rating, _reviewCount);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'rating.loadFailed'.tr();
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'rating.reviews'.tr(),
          style: context.headingMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.md),
        _summary(context),
        const SizedBox(height: AppSpacing.lg),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_error != null && _reviews.isEmpty)
          TextButton(
            onPressed: () => _load(reset: true),
            child: Text('common.retry'.tr()),
          )
        else if (_reviews.isEmpty && _reviewCount <= 0)
          Text(
            'rating.noRatingsYet'.tr(),
            style: context.bodyMedium.copyWith(color: context.colors.textSecondary),
          )
        else ...[
          ..._reviews.map((review) => _reviewTile(context, review)),
          if (_hasMore)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _loadingMore ? null : () => _load(reset: false),
                child: _loadingMore
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('rating.loadMore'.tr()),
              ),
            ),
        ],
      ],
    );
  }

  Widget _summary(BuildContext context) {
    final maxCount = _distribution.values.fold<int>(0, (max, count) => count > max ? count : max);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KitchenRatingBadge(rating: _rating, reviewCount: _reviewCount),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _reviewCount > 0
                  ? 'rating.ratingsCount'.tr(namedArgs: {'count': '$_reviewCount'})
                  : 'rating.noRatingsYet'.tr(),
              style: context.bodySmall.copyWith(color: context.colors.textSecondary),
            ),
          ],
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            children: [
              for (final star in [5, 4, 3, 2, 1])
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _bar(
                    context,
                    star,
                    _distribution[star] ?? 0,
                    maxCount,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bar(BuildContext context, int star, int count, int maxCount) {
    final fraction = maxCount == 0 ? 0.0 : count / maxCount;
    return Row(
      children: [
        SizedBox(
          width: 12,
          child: Text('$star', style: context.caption),
        ),
        const Icon(Icons.star, size: 12, color: AppColors.starColor),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: context.colors.divider,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _reviewTile(BuildContext context, KitchenReview review) {
    final date = review.ratedAt == null
        ? ''
        : DateFormat('d MMM yyyy').format(review.ratedAt!.toLocal());
    final items = review.items.join(', ');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: context.colors.primaryLight,
                child: Text(
                  review.reviewerName.isEmpty
                      ? 'G'
                      : review.reviewerName[0].toUpperCase(),
                  style: context.caption.copyWith(
                    color: AppColors.darkGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  review.reviewerName,
                  style: context.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              KitchenRatingBadge(
                rating: review.rating.toDouble(),
                reviewCount: 1,
              ),
            ],
          ),
          if (review.review.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(review.review, style: context.bodyMedium),
          ],
          if (items.isNotEmpty || date.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              [if (items.isNotEmpty) items, if (date.isNotEmpty) date].join(' · '),
              style: context.bodySmall.copyWith(color: context.colors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
