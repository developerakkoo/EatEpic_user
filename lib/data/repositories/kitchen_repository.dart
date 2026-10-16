import 'package:food_app/core/network/api_client.dart';
import 'package:food_app/core/storage/catalog_cache.dart';
import 'package:food_app/core/utils/media_url.dart';
import 'package:food_app/modal/hotel_modal.dart';

class KitchenRepository {
  KitchenRepository(this._api, this._cache);

  final ApiClient _api;
  final CatalogCache _cache;

  Future<List<HotelModel>> getNearbyKitchens({
    double? latitude,
    double? longitude,
    String? search,
    String? categoryId,
    double radiusKm = 50,
    bool forceRefresh = false,
  }) async {
    final hasCoords = latitude != null && longitude != null;

    if (hasCoords && !forceRefresh) {
      final cached = await _cache.loadKitchens(latitude!, longitude!);
      if (cached != null && cached.isNotEmpty) {
        _fetchKitchens(
          latitude: latitude,
          longitude: longitude,
          search: search,
          categoryId: categoryId,
          radiusKm: radiusKm,
        ).ignore();
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

    if (latitude != null && longitude != null) {
      await _cache.saveKitchens(latitude, longitude, list);
    }
    return list.map(_mapKitchen).toList();
  }

  Future<Map<String, dynamic>> getKitchenMenu(String kitchenId) async {
    final response = await _api.dio.get('/api/user/kitchen/$kitchenId/menu');
    return response.data['data'] as Map<String, dynamic>? ?? {};
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
      rating: 4.2,
      cuisine: address.isNotEmpty ? address : 'Multi cuisine',
      deliveryTime: 30,
      priceForOne: 200,
      distance: distance,
      isVeg: true,
      isOpen: json['status']?.toString() == 'ACTIVE',
      discount: null,
    );
  }
}
