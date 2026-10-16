import 'package:flutter/material.dart';
import 'package:food_app/core/di/app_services.dart';
import 'package:food_app/modal/hotel_modal.dart';

class HotelProvider extends ChangeNotifier {
  final _kitchens = AppServices.instance.kitchenRepository;

  bool _isLoading = false;
  String? _categoryId;
  String? _errorMessage;
  final List<HotelModel> _hotels = [];

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

    try {
      final list = await _kitchens.getNearbyKitchens(
        latitude: latitude,
        longitude: longitude,
        categoryId: categoryId,
        forceRefresh: forceRefresh,
      );
      _hotels
        ..clear()
        ..addAll(list);
    } catch (e, st) {
      debugPrint('fetchHotels failed: $e');
      debugPrint('$st');
      _hotels.clear();
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
