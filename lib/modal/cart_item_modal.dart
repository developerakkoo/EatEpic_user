import 'package:food_app/modal/menu_item_modal.dart';

class CartItemModel {
  final String id;
  final MenuItemModel menuItem;
  final int quantity;
  final String hotelId;
  final String hotelName;

  const CartItemModel({
    required this.id,
    required this.menuItem,
    required this.quantity,
    required this.hotelId,
    required this.hotelName,
  });

  int get unitPrice => menuItem.price;
  int get lineTotal => menuItem.price * quantity;

  CartItemModel copyWith({int? quantity}) {
    return CartItemModel(
      id: id,
      menuItem: menuItem,
      quantity: quantity ?? this.quantity,
      hotelId: hotelId,
      hotelName: hotelName,
    );
  }
}
