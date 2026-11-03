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
  final String flatNo;
  final String floor;
  final String areaName;
  final String pincode;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  UserAddress({
    required this.id,
    required this.label,
    required this.addressLine,
    this.flatNo = '',
    this.floor = '',
    this.areaName = '',
    this.pincode = '',
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  bool get isComplete =>
      flatNo.trim().isNotEmpty &&
      floor.trim().isNotEmpty &&
      areaName.trim().isNotEmpty &&
      addressLine.trim().isNotEmpty &&
      RegExp(r'^\d{6}$').hasMatch(pincode.trim());

  String get displayLine {
    final street = addressLine.trim();
    final flat = flatNo.trim();
    if (flat.isNotEmpty && street.startsWith('Flat $flat')) return street;
    final parts = <String>[
      if (flat.isNotEmpty) 'Flat $flat',
      if (floor.trim().isNotEmpty) 'Floor ${floor.trim()}',
      if (street.isNotEmpty) street,
      if (areaName.trim().isNotEmpty) areaName.trim(),
      if (pincode.trim().isNotEmpty) pincode.trim(),
    ];
    return parts.join(', ');
  }

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      id: json['_id']?.toString() ?? '',
      label: json['label']?.toString() ?? 'Home',
      addressLine: json['fullAddress']?.toString() ??
          json['addressLine']?.toString() ??
          json['address']?.toString() ??
          '',
      flatNo: json['flatNo']?.toString() ?? '',
      floor: json['floor']?.toString() ?? '',
      areaName: json['areaName']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isDefault: json['isDefault'] == true,
    );
  }
}
