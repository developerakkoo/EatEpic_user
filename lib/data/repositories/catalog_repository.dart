import 'package:food_app/core/network/api_client.dart';
import 'package:food_app/core/storage/catalog_cache.dart';

class CatalogRepository {
  CatalogRepository(this._api, this._cache);

  final ApiClient _api;
  final CatalogCache _cache;

  Future<List<dynamic>> getBanners({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _cache.loadBanners();
      if (cached != null) {
        _fetchBannersInBackground();
        return cached;
      }
    }
    return _fetchBanners();
  }

  Future<List<dynamic>> _fetchBanners() async {
    final response = await _api.dio.get('/api/user/offers');
    final list = response.data['data'] as List<dynamic>? ?? [];
    await _cache.saveBanners(list);
    return list;
  }

  void _fetchBannersInBackground() {
    _fetchBanners().ignore();
  }

  Future<List<dynamic>> getCategories({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _cache.loadCategories();
      if (cached != null) {
        _fetchCategoriesInBackground();
        return cached;
      }
    }
    return _fetchCategories();
  }

  Future<List<dynamic>> _fetchCategories() async {
    final response = await _api.dio.get('/api/user/categories');
    final list = response.data['data'] as List<dynamic>? ?? [];
    await _cache.saveCategories(list);
    return list;
  }

  void _fetchCategoriesInBackground() {
    _fetchCategories().ignore();
  }

  Future<void> invalidateCatalog() => _cache.clearCatalog();
}
