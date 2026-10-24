import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CatalogCache {
  static const _bannersKey = 'cache_banners';
  static const _categoriesKey = 'cache_categories';
  static const _bannersTsKey = 'cache_banners_ts';
  static const _categoriesTsKey = 'cache_categories_ts';

  static const Duration bannersTtl = Duration(minutes: 15);
  static const Duration categoriesTtl = Duration(minutes: 15);
  static const Duration kitchensTtl = Duration(minutes: 5);

  Future<void> setJson(String key, String tsKey, dynamic data, Duration ttl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(data));
    await prefs.setInt(tsKey, DateTime.now().add(ttl).millisecondsSinceEpoch);
  }

  Future<dynamic> getJsonIfFresh(String key, String tsKey) async {
    final prefs = await SharedPreferences.getInstance();
    final expires = prefs.getInt(tsKey);
    if (expires == null || DateTime.now().millisecondsSinceEpoch > expires) {
      return null;
    }
    final raw = prefs.getString(key);
    if (raw == null) return null;
    return jsonDecode(raw);
  }

  Future<void> saveBanners(List<dynamic> data) =>
      setJson(_bannersKey, _bannersTsKey, data, bannersTtl);

  Future<List<dynamic>?> loadBanners() =>
      getJsonIfFresh(_bannersKey, _bannersTsKey).then((v) => v as List<dynamic>?);

  Future<void> saveCategories(List<dynamic> data) =>
      setJson(_categoriesKey, _categoriesTsKey, data, categoriesTtl);

  Future<List<dynamic>?> loadCategories() =>
      getJsonIfFresh(_categoriesKey, _categoriesTsKey).then((v) => v as List<dynamic>?);

  String kitchensKey(double lat, double lng) {
    final rLat = (lat * 100).round() / 100;
    final rLng = (lng * 100).round() / 100;
    return 'cache_kitchens_${rLat}_$rLng';
  }

  String kitchensTsKey(double lat, double lng) => '${kitchensKey(lat, lng)}_ts';

  Future<void> saveKitchens(double lat, double lng, List<dynamic> data) async {
    await setJson(kitchensKey(lat, lng), kitchensTsKey(lat, lng), data, kitchensTtl);
  }

  Future<List<dynamic>?> loadKitchens(double lat, double lng) async {
    final v = await getJsonIfFresh(kitchensKey(lat, lng), kitchensTsKey(lat, lng));
    return v as List<dynamic>?;
  }

  Future<void> clearKitchens() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('cache_kitchens'));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  Future<void> clearCatalog() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where(
      (k) =>
          k.startsWith('cache_banners') ||
          k.startsWith('cache_categories') ||
          k.startsWith('cache_kitchens'),
    );
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  Future<void> clearAll() => clearCatalog();
}
