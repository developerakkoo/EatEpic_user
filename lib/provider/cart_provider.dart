import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:food_app/modal/cart_item_modal.dart';
import 'package:food_app/modal/hotel_modal.dart';
import 'package:food_app/modal/menu_item_modal.dart';

final _random = Random();

class CartProvider with ChangeNotifier {
  final List<CartItemModel> _items = [];

  List<CartItemModel> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, e) => sum + e.quantity);

  bool get isEmpty => _items.isEmpty;

  int get subtotal => _items.fold(0, (sum, e) => sum + e.lineTotal);

  static const int deliveryFeeFixed = 40;
  int get deliveryFee => isEmpty ? 0 : deliveryFeeFixed;

  double get taxPercent => 0.05;
  int get tax => (subtotal * taxPercent).round();

  int get total => subtotal + deliveryFee + tax;

  int quantityFor(String hotelId, String menuItemId) {
    for (final e in _items) {
      if (e.hotelId == hotelId && e.menuItem.id == menuItemId) return e.quantity;
    }
    return 0;
  }

  void addItem(HotelModel hotel, MenuItemModel menuItem, int quantity) {
    if (quantity <= 0) {
      updateOrRemove(hotel.id, menuItem.id, quantity);
      return;
    }
    final existingIndex = _items.indexWhere(
      (e) => e.hotelId == hotel.id && e.menuItem.id == menuItem.id,
    );
    if (existingIndex >= 0) {
      final existing = _items[existingIndex];
      if (quantity == 0) {
        _items.removeAt(existingIndex);
      } else {
        _items[existingIndex] = existing.copyWith(quantity: quantity);
      }
    } else {
      _items.add(CartItemModel(
        id: '${hotel.id}_${menuItem.id}_${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(999999)}',
        menuItem: menuItem,
        quantity: quantity,
        hotelId: hotel.id,
        hotelName: hotel.name,
      ));
    }
    notifyListeners();
  }

  void updateQuantity(String cartItemId, int quantity) {
    if (quantity <= 0) {
      removeItem(cartItemId);
      return;
    }
    final index = _items.indexWhere((e) => e.id == cartItemId);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(quantity: quantity);
      notifyListeners();
    }
  }

  void updateOrRemove(String hotelId, String menuItemId, int quantity) {
    final index = _items.indexWhere(
      (e) => e.hotelId == hotelId && e.menuItem.id == menuItemId,
    );
    if (index < 0) return;
    if (quantity <= 0) {
      _items.removeAt(index);
    } else {
      _items[index] = _items[index].copyWith(quantity: quantity);
    }
    notifyListeners();
  }

  void removeItem(String cartItemId) {
    _items.removeWhere((e) => e.id == cartItemId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
