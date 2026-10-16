class AppUser {
  final String id;
  final String fullName;
  final String mobileNumber;
  final String? email;
  final String countryCode;
  final List<UserAddress> addresses;

  AppUser({
    required this.id,
    required this.fullName,
    required this.mobileNumber,
    this.email,
    this.countryCode = '+91',
    this.addresses = const [],
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final addressesRaw = json['addresses'] as List<dynamic>? ?? [];
    return AppUser(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      mobileNumber: json['mobileNumber']?.toString() ?? '',
      email: json['email']?.toString(),
      countryCode: json['countryCode']?.toString() ?? '+91',
      addresses: addressesRaw
          .map((e) => UserAddress.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  UserAddress? get defaultAddress {
    if (addresses.isEmpty) return null;
    return addresses.firstWhere(
      (a) => a.isDefault,
      orElse: () => addresses.first,
    );
  }
}

class UserAddress {
  final String id;
  final String label;
  final String addressLine;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  UserAddress({
    required this.id,
    required this.label,
    required this.addressLine,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      id: json['_id']?.toString() ?? '',
      label: json['label']?.toString() ?? 'Home',
      addressLine: json['fullAddress']?.toString() ??
          json['addressLine']?.toString() ??
          json['address']?.toString() ??
          '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isDefault: json['isDefault'] == true,
    );
  }
}
