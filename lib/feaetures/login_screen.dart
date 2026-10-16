import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/provider/auth_provider.dart';
import 'package:food_app/provider/location_provider.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  bool isValidNumber = false;

  void validatePhone(String value) {
    setState(() {
      isValidNumber = value.length == 10 && RegExp(r'^[0-9]+$').hasMatch(value);
    });
  }

  void _showError(BuildContext context, String? message) {
    if (message == null || message.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  Future<void> _goHome(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final location = context.read<LocationProvider>();
    final def = auth.user?.defaultAddress;
    if (def?.latitude != null && def?.longitude != null) {
      await location.saveLocation(
        def!.latitude!,
        def.longitude!,
        def.addressLine,
      );
    }
    if (!context.mounted) return;
    if (location.hasLocation) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/location-picker');
    }
  }

  Widget _buildPhoneField(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.medium + 2),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              '+91',
              style: context.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(height: 50, width: 1, color: colors.divider),
          Expanded(
            child: TextField(
              controller: phoneController,
              keyboardType: TextInputType.number,
              maxLength: 10,
              onChanged: validatePhone,
              decoration: InputDecoration(
                counterText: '',
                hintText: 'login.enterMobileHint'.tr(),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleAccountCard(BuildContext context, AuthProvider auth) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.medium + 2),
        color: colors.surfaceGrey,
      ),
      child: Row(
        children: [
          _GoogleLogo(size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.googleFullName ?? '',
                  style: context.headingSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  auth.googleEmail ?? '',
                  style: context.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleButton(BuildContext context, AuthProvider authProvider) {
    final colors = context.colors;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: authProvider.isLoading
            ? null
            : () async {
                authProvider.clearError();
                final ok = await authProvider.signInWithGoogle();
                if (!context.mounted) return;
                if (!ok) {
                  _showError(context, authProvider.lastError);
                  return;
                }
                if (authProvider.requiresRegistration) {
                  setState(() {});
                } else if (authProvider.isLoggedIn) {
                  await _goHome(context);
                }
              },
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: colors.divider),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium + 2),
          ),
        ),
        icon: _GoogleLogo(size: 20),
        label: Text(
          'login.googleButton'.tr(),
          style: context.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final showRegister = authProvider.requiresRegistration;
    final isGoogleRegister = authProvider.isGoogleRegistration;
    final colors = context.colors;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            children: [
              const SizedBox(height: 80),
              Text(
                showRegister
                    ? 'login.completeProfile'.tr()
                    : 'login.loginOrSignup'.tr(),
                style: context.displayLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                showRegister
                    ? (isGoogleRegister
                        ? 'login.googleMobileSubtitle'.tr()
                        : 'login.completeProfileSubtitle'.tr())
                    : 'login.enterMobileSubtitle'.tr(),
                style: context.bodySmall.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: 50),
              if (!showRegister) ...[
                _buildPhoneField(context),
              ] else if (isGoogleRegister) ...[
                _buildGoogleAccountCard(context, authProvider),
                const SizedBox(height: AppSpacing.md),
                _buildPhoneField(context),
              ] else ...[
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'login.fullNameHint'.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.medium + 2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'login.emailHint'.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.medium + 2),
                    ),
                  ),
                ),
              ],
              if (authProvider.lastError != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  authProvider.lastError!,
                  style: context.bodyMedium.copyWith(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () async {
                          if (isGoogleRegister) {
                            if (!isValidNumber) return;
                            final ok = await authProvider.registerWithGoogle(
                              phoneController.text,
                            );
                            if (!context.mounted) return;
                            if (ok && authProvider.isLoggedIn) {
                              await _goHome(context);
                            } else {
                              _showError(context, authProvider.lastError);
                            }
                          } else if (showRegister) {
                            final name = nameController.text.trim();
                            final email = emailController.text.trim();
                            if (name.isEmpty) return;
                            if (email.isEmpty || !email.contains('@')) {
                              _showError(context, 'login.invalidEmail'.tr());
                              return;
                            }
                            final ok = await authProvider.registerAndLogin(
                              fullName: name,
                              email: email,
                            );
                            if (!context.mounted) return;
                            if (ok && authProvider.isLoggedIn) {
                              await _goHome(context);
                            } else {
                              _showError(context, authProvider.lastError);
                            }
                          } else if (isValidNumber) {
                            authProvider.clearError();
                            final ok = await authProvider.loginWithMobile(
                              phoneController.text,
                            );
                            if (!context.mounted) return;
                            if (!ok) {
                              _showError(context, authProvider.lastError);
                              return;
                            }
                            if (authProvider.requiresRegistration) {
                              setState(() {});
                            } else if (authProvider.isLoggedIn) {
                              await _goHome(context);
                            }
                          }
                        },
                  child: authProvider.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(showRegister
                          ? 'login.createAccount'.tr()
                          : 'login.continueButton'.tr()),
                ),
              ),
              if (!showRegister) ...[
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(child: Divider(color: colors.divider)),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Text(
                        'login.orContinueWith'.tr(),
                        style: context.bodySmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: colors.divider)),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                _buildGoogleButton(context, authProvider),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The multicolor Google "G" mark, drawn with text so no image asset is
/// needed.
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo({this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 8,
      height: size + 8,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Text(
        'G',
        style: TextStyle(
          fontSize: size,
          height: 1,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF4285F4),
        ),
      ),
    );
  }
}
