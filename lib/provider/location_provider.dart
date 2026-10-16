import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _keyLat = 'saved_lat';
const String _keyLng = 'saved_lng';
const String _keyAddress = 'saved_address';

class LocationProvider with ChangeNotifier {
  double? _lat;
  double? _lng;
  String? _address;

  double? get lat => _lat;
  double? get lng => _lng;
  String? get address => _address;

  bool get hasLocation => _lat != null && _lng != null && _address != null;

  Future<void> loadLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_keyLat);
    final lng = prefs.getDouble(_keyLng);
    final address = prefs.getString(_keyAddress);
    _lat = lat;
    _lng = lng;
    _address = address;
    notifyListeners();
  }

  Future<void> saveLocation(double lat, double lng, String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyLat, lat);
    await prefs.setDouble(_keyLng, lng);
    await prefs.setString(_keyAddress, address);
    _lat = lat;
    _lng = lng;
    _address = address;
    notifyListeners();
  }
}
