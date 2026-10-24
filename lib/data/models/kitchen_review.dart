class KitchenReview {
  const KitchenReview({
    required this.id,
    required this.rating,
    required this.review,
    required this.reviewerName,
    required this.items,
    this.ratedAt,
  });

  final String id;
  final int rating;
  final String review;
  final String reviewerName;
  final List<String> items;
  final DateTime? ratedAt;

  factory KitchenReview.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = <String>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        final name = item?.toString() ?? '';
        if (name.isNotEmpty) items.add(name);
      }
    }
    return KitchenReview(
      id: json['id']?.toString() ?? '',
      rating: (json['rating'] as num?)?.round() ?? 0,
      review: json['review']?.toString() ?? '',
      reviewerName: json['reviewerName']?.toString() ?? 'Guest',
      items: items,
      ratedAt: DateTime.tryParse(json['ratedAt']?.toString() ?? ''),
    );
  }
}

class KitchenReviewsPage {
  const KitchenReviewsPage({
    required this.averageRating,
    required this.totalReviews,
    required this.distribution,
    required this.reviews,
    required this.page,
    required this.limit,
    required this.total,
  });

  final double averageRating;
  final int totalReviews;
  final Map<int, int> distribution;
  final List<KitchenReview> reviews;
  final int page;
  final int limit;
  final int total;

  bool get hasMore => page * limit < total;

  factory KitchenReviewsPage.fromJson(Map<String, dynamic> json) {
    final summary = json['ratingSummary'];
    final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    if (summary is Map) {
      final raw = summary['distribution'];
      if (raw is Map) {
        for (final star in [1, 2, 3, 4, 5]) {
          final value = raw[star] ?? raw['$star'];
          distribution[star] = value is num ? value.round() : 0;
        }
      }
    }

    final rawReviews = json['reviews'];
    final reviews = <KitchenReview>[];
    if (rawReviews is List) {
      for (final raw in rawReviews) {
        if (raw is Map) {
          reviews.add(KitchenReview.fromJson(Map<String, dynamic>.from(raw)));
        }
      }
    }

    final pagination = json['pagination'];
    final average = json['averageRating'] ??
        (summary is Map ? summary['averageRating'] : null);
    final totalReviews = json['totalReviews'] ??
        (summary is Map ? summary['totalReviews'] : null);

    return KitchenReviewsPage(
      averageRating: average is num ? average.toDouble() : 0,
      totalReviews: totalReviews is num ? totalReviews.round() : 0,
      distribution: distribution,
      reviews: reviews,
      page: pagination is Map ? (pagination['page'] as num?)?.round() ?? 1 : 1,
      limit: pagination is Map ? (pagination['limit'] as num?)?.round() ?? 10 : 10,
      total: pagination is Map ? (pagination['total'] as num?)?.round() ?? reviews.length : reviews.length,
    );
  }
}
