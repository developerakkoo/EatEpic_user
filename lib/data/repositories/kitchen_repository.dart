import 'package:food_app/core/network/api_client.dart';
import 'package:food_app/core/storage/catalog_cache.dart';
import 'package:food_app/core/utils/media_url.dart';
import 'package:food_app/data/models/kitchen_review.dart';
import 'package:food_app/modal/hotel_modal.dart';

class KitchenRepository {
  KitchenRepository(this._api, this._cache);

  final ApiClient _api;
  final CatalogCache _cache;
  int _nearbyEpoch = 0;

  Future<List<HotelModel>> getNearbyKitchens({
    double? latitude,
    double? longitude,
    String? search,
    String? categoryId,
    double radiusKm = 50,
    bool forceRefresh = false,
    void Function(List<HotelModel> kitchens)? onRefreshed,
  }) async {
    final hasCoords = latitude != null && longitude != null;

    if (hasCoords && !forceRefresh) {
      final cached = await _cache.loadKitchens(latitude!, longitude!);
      if (cached != null && cached.isNotEmpty) {
        final epoch = _nearbyEpoch;
        _fetchKitchens(
          latitude: latitude,
          longitude: longitude,
          search: search,
          categoryId: categoryId,
          radiusKm: radiusKm,
        ).then(
          (fresh) {
            if (epoch != _nearbyEpoch) return;
            onRefreshed?.call(fresh);
          },
          onError: (_) {},
        );
        return cached.map(_mapKitchen).toList();
      }
    }

    return _fetchKitchens(
      latitude: latitude,
      longitude: longitude,
      search: search,
      categoryId: categoryId,
      radiusKm: radiusKm,
    );
  }

  Future<List<HotelModel>> _fetchKitchens({
    double? latitude,
    double? longitude,
    String? search,
    String? categoryId,
    double radiusKm = 50,
  }) async {
    final epoch = _nearbyEpoch;
    final response = await _api.dio.get(
      '/api/user/nearby-kitchens',
      queryParameters: {
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'radiusKm': radiusKm,
        if (search != null && search.isNotEmpty) 'search': search,
        if (categoryId != null) 'categoryId': categoryId,
      },
    );

    var list = response.data['data'] as List<dynamic>? ?? [];

    if (list.isEmpty && latitude != null && longitude != null) {
      final fallback = await _api.dio.get(
        '/api/user/nearby-kitchens',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (categoryId != null) 'categoryId': categoryId,
        },
      );
      list = fallback.data['data'] as List<dynamic>? ?? [];
    }

    if (epoch == _nearbyEpoch && latitude != null && longitude != null) {
      await _cache.saveKitchens(latitude, longitude, list);
    }
    return list.map(_mapKitchen).toList();
  }

  Future<void> invalidateNearbyCache() {
    _nearbyEpoch++;
    return _cache.clearKitchens();
  }

  Future<Map<String, dynamic>> getKitchenMenu(String kitchenId) async {
    final response = await _api.dio.get('/api/user/kitchen/$kitchenId/menu');
    return response.data['data'] as Map<String, dynamic>? ?? {};
  }

  Future<KitchenReviewsPage> getKitchenReviews(
    String kitchenId, {
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _api.dio.get(
      '/api/user/kitchen/$kitchenId/reviews',
      queryParameters: {'page': page, 'limit': limit},
    );
    return KitchenReviewsPage.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  HotelModel _mapKitchen(dynamic raw) {
    final json = raw as Map<String, dynamic>;
    final id = json['_id']?.toString() ?? '';
    final name = json['kitchenName']?.toString() ?? 'Kitchen';
    final address = json['address']?.toString() ?? '';
    final distance = (json['distanceKm'] as num?)?.toDouble() ?? 0;
    final image = resolveMediaUrl(json['profileImage']) ??
        resolveMediaUrl(json['image']) ??
        'https://picsum.photos/seed/$id/600/400';

    return HotelModel(
      id: id,
      name: name,
      imageUrl: image,
      rating: _readAverageRating(json),
      reviewCount: _readReviewCount(json),
      cuisine: address.isNotEmpty ? address : 'Multi cuisine',
      deliveryTime: 30,
      priceForOne: 200,
      distance: distance,
      isVeg: true,
      isOpen: json['status']?.toString() == 'ACTIVE',
      discount: null,
    );
  }

  double _readAverageRating(Map<String, dynamic> json) {
    final direct = json['averageRating'];
    if (direct is num) return direct.toDouble();
    final summary = json['ratingSummary'];
    if (summary is Map) {
      final avg = summary['averageRating'];
      if (avg is num) return avg.toDouble();
    }
    return 0;
  }

  int _readReviewCount(Map<String, dynamic> json) {
    final direct = json['totalReviews'];
    if (direct is num) return direct.round();
    final summary = json['ratingSummary'];
    if (summary is Map) {
      final total = summary['totalReviews'];
      if (total is num) return total.round();
    }
    return 0;
  }
}
