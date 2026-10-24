import 'package:flutter/material.dart';
import 'package:food_app/core/di/app_services.dart';
import 'package:food_app/modal/hotel_modal.dart';

class HotelProvider extends ChangeNotifier {
  final _kitchens = AppServices.instance.kitchenRepository;

  bool _isLoading = false;
  int _fetchGeneration = 0;
  String? _categoryId;
  String? _errorMessage;
  final List<HotelModel> _hotels = [];
  final Map<String, ({double rating, int count})> _appliedRatings = {};

  bool get isLoading => _isLoading;
  List<HotelModel> get hotels => _hotels;
  String? get categoryId => _categoryId;
  String? get errorMessage => _errorMessage;

  Future<void> refresh({
    double? latitude,
    double? longitude,
    String? categoryId,
    bool forceRefresh = true,
  }) async {
    await fetchHotels(
      latitude: latitude,
      longitude: longitude,
      categoryId: categoryId,
      forceRefresh: forceRefresh,
    );
  }

  Future<void> fetchHotels({
    double? latitude,
    double? longitude,
    String? categoryId,
    bool forceRefresh = false,
  }) async {
    _isLoading = true;
    _categoryId = categoryId;
    _errorMessage = null;
    notifyListeners();

    final generation = ++_fetchGeneration;
    try {
      final list = await _kitchens.getNearbyKitchens(
        latitude: latitude,
        longitude: longitude,
        categoryId: categoryId,
        forceRefresh: forceRefresh,
        onRefreshed: (fresh) {
          if (generation != _fetchGeneration) return;
          _hotels
            ..clear()
            ..addAll(fresh.map(_withAppliedRating));
          notifyListeners();
        },
      );
      if (generation != _fetchGeneration) return;
      _hotels
        ..clear()
        ..addAll(list.map(_withAppliedRating));
    } catch (e, st) {
      if (generation != _fetchGeneration) return;
      debugPrint('fetchHotels failed: $e');
      debugPrint('$st');
      _hotels.clear();
      _errorMessage = e.toString();
    } finally {
      if (generation == _fetchGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void applyKitchenRating({
    required String kitchenId,
    required double averageRating,
    required int totalReviews,
  }) {
    if (totalReviews <= 0) return;
    _appliedRatings[kitchenId] = (rating: averageRating, count: totalReviews);
    final index = _hotels.indexWhere((hotel) => hotel.id == kitchenId);
    if (index < 0) return;
    _hotels[index] = _withAppliedRating(_hotels[index]);
    notifyListeners();
  }

  HotelModel _withAppliedRating(HotelModel hotel) {
    final applied = _appliedRatings[hotel.id];
    if (applied == null || hotel.reviewCount > applied.count) return hotel;
    return hotel.copyWith(rating: applied.rating, reviewCount: applied.count);
  }
}
