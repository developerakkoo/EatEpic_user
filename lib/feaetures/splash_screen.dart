import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/provider/auth_provider.dart';
import 'package:food_app/provider/location_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _keyOnboardingComplete = 'onboarding_complete';
const String _keyLanguageSelected = 'language_selected';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _navigateNext());
  }

  Future<void> _navigateNext() async {
    final auth = context.read<AuthProvider>();
    final location = context.read<LocationProvider>();

    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    await location.loadLocation();
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final languageSelected = prefs.getBool(_keyLanguageSelected) ?? false;

    if (!languageSelected) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/language');
      return;
    }

    final onboardingComplete = prefs.getBool(_keyOnboardingComplete) ?? false;

    if (!onboardingComplete) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/onboarding');
      return;
    }

    final loggedIn = await auth.restoreSession();
    if (!mounted) return;

    if (loggedIn) {
      final def = auth.user?.defaultAddress;
      if (def?.latitude != null && def?.longitude != null && !location.hasLocation) {
        await location.saveLocation(
          def!.latitude!,
          def.longitude!,
          def.addressLine,
        );
      }
      if (!mounted) return;
      if (location.hasLocation) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/location-picker');
      }
      return;
    }

    Navigator.pushReplacementNamed(context, '/permissions');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    AppShadows.softShadow,
                  ],
                ),
                child: Icon(
                  Icons.restaurant_rounded,
                  size: 72,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'splash.appName'.tr(),
                style: context.displayMedium.copyWith(
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> setOnboardingComplete() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_keyOnboardingComplete, true);
}

Future<bool> isLanguageSelected() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_keyLanguageSelected) ?? false;
}

Future<void> setLanguageSelected() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_keyLanguageSelected, true);
}

Future<bool> isOnboardingComplete() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_keyOnboardingComplete) ?? false;
}
