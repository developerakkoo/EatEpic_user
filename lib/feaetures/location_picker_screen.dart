import 'dart:io' show Platform;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/config/api_keys.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/core/di/app_services.dart';
import 'package:food_app/provider/auth_provider.dart';
import 'package:food_app/provider/location_provider.dart';
import 'package:map_location_picker/map_location_picker.dart';
import 'package:provider/provider.dart';

/// Headers for Geocoding API when the API key is restricted by app (iOS bundle ID / Android package).
Map<String, String> get geoCodingApiHeaders {
  final headers = <String, String>{};
  if (Platform.isIOS || Platform.isMacOS) {
    headers['X-Ios-Bundle-Identifier'] = iosBundleId;
  }
  if (Platform.isAndroid) {
    headers['X-Android-Package'] = androidPackageName;
    if (androidSha1Cert.isNotEmpty) {
      headers['X-Android-Cert'] = androidSha1Cert;
    }
  }
  return headers;
}

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.fromHome = false, this.fromCart = false});

  final bool fromHome;
  final bool fromCart;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng? _lastPosition;

  Future<void> _openLocationPicker() async {
    final locationProvider = context.read<LocationProvider>();
    await locationProvider.loadLocation();
    if (!mounted) return;

    final LatLng initialPosition;
    if (locationProvider.lat != null && locationProvider.lng != null) {
      initialPosition = LatLng(locationProvider.lat!, locationProvider.lng!);
    } else if (_lastPosition != null) {
      initialPosition = _lastPosition!;
    } else {
      initialPosition = const LatLng(28.8993468, 76.6250249);
    }

    var didConfirmLocation = false;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationPicker(
          searchConfig: SearchConfig(
            apiKey: googleMapsApiKey,
            searchHintText: 'locationPicker.searchHint'.tr(),
          ),
          config: MapLocationPickerConfig(
            apiKey: googleMapsApiKey,
            geocodingApiHeaders: geoCodingApiHeaders,
            initialPosition: initialPosition,
            onNext: (GeocodingResult? result) {
              if (result != null) {
                didConfirmLocation = true;
                final lat = result.geometry?.location.lat ?? 0.0;
                final lng = result.geometry?.location.lng ?? 0.0;
                final address = result.formattedAddress ??
                    'locationPicker.addressNotAvailable'.tr();

                debugPrint('Location picked: lat=$lat, lng=$lng');
                debugPrint('Address: $address');

                locationProvider.saveLocation(lat, lng, address);
                setState(() => _lastPosition = LatLng(lat, lng));
                final auth = context.read<AuthProvider>();
                if (auth.isLoggedIn) {
                  AppServices.instance.userRepository.addAddress({
                    'label': 'Home',
                    'fullAddress': address,
                    'latitude': lat,
                    'longitude': lng,
                    'isDefault': true,
                  }).then((_) => auth.refreshProfile()).ignore();
                }
              }
              if (context.mounted) {
                Navigator.pop(context, result);
              }
            },
          ),
        ),
      ),
    );

    if (mounted && didConfirmLocation) {
      if (widget.fromCart || widget.fromHome) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openLocationPicker());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('locationPicker.appBarTitle'.tr()),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'locationPicker.title'.tr(),
                style: context.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'locationPicker.subtitle'.tr(),
                style: context.bodyLarge.copyWith(color: context.colors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxxl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openLocationPicker,
                  icon: const Icon(Icons.map),
                  label: Text('locationPicker.pickButton'.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
