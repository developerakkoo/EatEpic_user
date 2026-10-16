import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/provider/auth_provider.dart';
import 'package:food_app/provider/location_provider.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _isRequesting = false;

  Future<void> _requestPermissions() async {
    if (_isRequesting) return;
    setState(() => _isRequesting = true);

    try {
      await Permission.locationWhenInUse.request();
      await Permission.notification.request();
    } catch (e, st) {
      debugPrint('Permission request failed: $e');
      debugPrint('Stack trace: $st');
      // Continue flow - user can still use app; permissions may be requested later
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestPermissions());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 80),
              const Icon(Icons.location_on, size: 80, color: AppColors.primary),
              const SizedBox(height: AppSpacing.xxxl),
              Text(
                'permissions.title'.tr(),
                style: context.displayLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'permissions.body'.tr(),
                style: context.bodyLarge.copyWith(color: context.colors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final loggedIn =
                        await context.read<AuthProvider>().restoreSession();
                    if (!context.mounted) return;
                    if (loggedIn) {
                      final location = context.read<LocationProvider>();
                      await location.loadLocation();
                      if (!context.mounted) return;
                      if (location.hasLocation) {
                        Navigator.pushReplacementNamed(context, '/home');
                      } else {
                        Navigator.pushReplacementNamed(context, '/location-picker');
                      }
                    } else {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                  child: Text(_isRequesting
                      ? 'permissions.requesting'.tr()
                      : 'permissions.continueButton'.tr()),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
