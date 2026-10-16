import 'package:flutter/foundation.dart';
import 'package:food_app/core/di/app_services.dart';
import 'package:food_app/core/utils/media_url.dart';
import 'package:food_app/modal/category_modal.dart';

class CategoryProvider with ChangeNotifier {
  final _catalog = AppServices.instance.catalogRepository;

  int _selectedIndex = 0;
  bool _isLoading = false;
  final List<CategoryModal> _categories = [];

  int get selectedIndex => _selectedIndex;
  bool get isLoading => _isLoading;
  List<CategoryModal> get categories => _categories;

  CategoryProvider() {
    loadCategories();
  }

  Future<void> loadCategories({bool forceRefresh = false}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _catalog.getCategories(forceRefresh: forceRefresh);
      _categories
        ..clear()
        ..addAll(data.map(_mapCategory));
      if (_selectedIndex >= _categories.length) {
        _selectedIndex = 0;
      }
    } catch (_) {
      if (_categories.isEmpty) {
        _categories.addAll(_fallbackCategories);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  void selectCategory(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  CategoryModal _mapCategory(dynamic raw) {
    final json = raw as Map<String, dynamic>;
    return CategoryModal(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      imageUrl: resolveMediaUrl(json['image']) ?? '',
    );
  }

  static final _fallbackCategories = [
    CategoryModal(id: '1', name: 'Biryani', imageUrl: 'assets/biryani.png'),
    CategoryModal(id: '2', name: 'Pizza', imageUrl: 'assets/pizza.png'),
  ];
}
