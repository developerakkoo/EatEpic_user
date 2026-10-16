import 'package:food_app/core/network/api_client.dart';

class CartRepository {
  CartRepository(this._api);

  final ApiClient _api;

  /// Syncs a line to the server cart. The API only accepts [menuItemId] and
  /// [quantity] (see `POST /api/cart/add`); pricing and kitchen come from the menu item.
  Future<Map<String, dynamic>> addToCart({
    required String menuItemId,
    required int quantity,
  }) async {
    final res = await _api.dio.post(
      '/api/cart/add',
      data: {'menuItemId': menuItemId, 'quantity': quantity},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> syncCart({
    required List<Map<String, dynamic>> items,
  }) async {
    final res = await _api.dio.put('/api/cart/sync', data: {'items': items});
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> checkout({String? couponCode}) async {
    final res = await _api.dio.post(
      '/api/cart/checkout',
      data: {if (couponCode != null) 'couponCode': couponCode},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }
}
