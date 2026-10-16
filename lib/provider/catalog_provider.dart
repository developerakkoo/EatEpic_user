import 'package:flutter/foundation.dart';
import 'package:food_app/core/di/app_services.dart';
import 'package:food_app/core/utils/media_url.dart';

class BannerItem {
  final String id;
  final String title;
  final String imageUrl;
  final String? subtitle;
  final String? redirectLink;

  const BannerItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.subtitle,
    this.redirectLink,
  });
}

class CatalogProvider with ChangeNotifier {
  final _catalog = AppServices.instance.catalogRepository;

  bool _loadingBanners = false;
  final List<BannerItem> _banners = [];

  bool get loadingBanners => _loadingBanners;
  List<BannerItem> get banners => _banners;

  void Function()? onHomeInvalidate;

  CatalogProvider() {
    loadBanners();
    AppServices.instance.socketService.onCatalogUpdated = (_) {
      invalidateAndReload();
      onHomeInvalidate?.call();
    };
  }

  Future<void> loadBanners({bool forceRefresh = false}) async {
    _loadingBanners = true;
    notifyListeners();
    try {
      final data = await _catalog.getBanners(forceRefresh: forceRefresh);
      _banners
        ..clear()
        ..addAll(
          data.map((raw) {
            final json = raw as Map<String, dynamic>;
            return BannerItem(
              id: json['_id']?.toString() ?? '',
              title: json['title']?.toString() ?? '',
              imageUrl: resolveMediaUrl(json['image']) ?? '',
              subtitle: json['subtitle']?.toString() ?? json['description']?.toString(),
              redirectLink: json['redirectLink']?.toString(),
            );
          }),
        );
    } catch (_) {
      _banners.clear();
    } finally {
      _loadingBanners = false;
      notifyListeners();
    }
  }

  Future<void> invalidateAndReload() async {
    await _catalog.invalidateCatalog();
    await loadBanners(forceRefresh: true);
  }
}
