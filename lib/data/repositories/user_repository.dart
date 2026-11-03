import 'package:food_app/core/network/api_client.dart';
import 'package:food_app/data/models/app_user.dart';

class UserRepository {
  UserRepository(this._api);

  final ApiClient _api;

  Future<AppUser> getProfile() async {
    final response = await _api.dio.get('/api/user/profile');
    final data = response.data['data'] ?? response.data['user'] ?? response.data;
    return AppUser.fromJson(data as Map<String, dynamic>);
  }

  Future<AppUser> updateProfile({String? fullName, String? email}) async {
    final response = await _api.dio.patch(
      '/api/user/profile',
      data: {
        if (fullName != null) 'fullName': fullName,
        if (email != null) 'email': email,
      },
    );
    final data = response.data['data'] ?? response.data['user'] ?? response.data;
    return AppUser.fromJson(data as Map<String, dynamic>);
  }

  Future<double> getWalletBalance() async {
    final response = await _api.dio.get('/api/user/wallet');
    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    return (data['walletBalance'] as num?)?.toDouble() ?? 0;
  }

  Future<List<UserAddress>> getAddresses() async {
    final response = await _api.dio.get('/api/user/addresses');
    final list = response.data['data'] as List<dynamic>? ?? [];
    return list.map((e) => UserAddress.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<UserAddress> addAddress(Map<String, dynamic> body) async {
    final response = await _api.dio.post('/api/user/add-address', data: body);
    return _addressFromResponse(response.data, preferLast: true);
  }

  Future<UserAddress> updateAddress(String addressId, Map<String, dynamic> body) async {
    final response = await _api.dio.put('/api/user/address/$addressId', data: body);
    return _addressFromResponse(response.data, preferId: addressId);
  }

  UserAddress _addressFromResponse(
    dynamic payload, {
    bool preferLast = false,
    String? preferId,
  }) {
    final data = payload is Map ? payload['data'] ?? payload['address'] ?? payload : payload;
    if (data is List) {
      final maps = data.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
      if (maps.isEmpty) {
        throw StateError('Address response was empty');
      }
      if (preferId != null) {
        for (final row in maps) {
          if (row['_id']?.toString() == preferId) return UserAddress.fromJson(row);
        }
      }
      return UserAddress.fromJson(preferLast ? maps.last : maps.first);
    }
    return UserAddress.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> deleteAddress(String addressId) async {
    await _api.dio.delete('/api/user/address/$addressId');
  }

  Future<void> setDefaultAddress(String addressId) async {
    await _api.dio.patch('/api/user/address/$addressId/default');
  }
}
