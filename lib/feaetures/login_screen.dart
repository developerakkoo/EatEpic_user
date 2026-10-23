import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/theme/login_tokens.dart';
import 'package:food_app/feaetures/login/login_visuals.dart';
import 'package:food_app/provider/auth_provider.dart';
import 'package:food_app/provider/location_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();

  bool isValidNumber = false;
  bool _primaryPressed = false;

  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;

  @override
  void initState() {
    super.initState();
    _phoneFocus.addListener(() => setState(() {}));
    _nameFocus.addListener(() => setState(() {}));
    _emailFocus.addListener(() => setState(() {}));
    nameController.addListener(() => setState(() {}));
    emailController.addListener(() => setState(() {}));
    _termsTap = TapGestureRecognizer()
      ..onTap = () => _openUrl(LoginTokens.termsUrl);
    _privacyTap = TapGestureRecognizer()
      ..onTap = () => _openUrl(LoginTokens.privacyUrl);
  }

  @override
  void dispose() {
    phoneController.dispose();
    nameController.dispose();
    emailController.dispose();
    _phoneFocus.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  bool get _isValidEmail {
    final email = emailController.text.trim();
    return email.contains('@') && email.contains('.');
  }

  bool _canSubmit({
    required bool showRegister,
    required bool isGoogleRegister,
  }) {
    if (isGoogleRegister || !showRegister) return isValidNumber;
    return nameController.text.trim().isNotEmpty && _isValidEmail;
  }

  String? _inlineHint({
    required bool showRegister,
    required bool isGoogleRegister,
  }) {
    if (isGoogleRegister || !showRegister) {
      if (phoneController.text.isEmpty) return null;
      if (!isValidNumber) return 'login.invalidPhoneHint'.tr();
      return null;
    }
    if (emailController.text.isEmpty) return null;
    if (!_isValidEmail) return 'login.invalidEmail'.tr();
    return null;
  }

  void validatePhone(String value) {
    setState(() {
      isValidNumber = value.length == 10 && RegExp(r'^[0-9]+$').hasMatch(value);
    });
  }

  Future<void> _goHome() async {
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
    if (!mounted) return;
    if (location.hasLocation) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/location-picker');
    }
  }

  Future<void> _onContinue(
    AuthProvider authProvider, {
    required bool showRegister,
    required bool isGoogleRegister,
  }) async {
    if (isGoogleRegister) {
      final ok = await authProvider.registerWithGoogle(phoneController.text);
      if (!mounted) return;
      if (ok && authProvider.isLoggedIn) await _goHome();
      return;
    }
    if (showRegister) {
      final ok = await authProvider.registerAndLogin(
        fullName: nameController.text.trim(),
        email: emailController.text.trim(),
      );
      if (!mounted) return;
      if (ok && authProvider.isLoggedIn) await _goHome();
      return;
    }
    authProvider.clearError();
    final ok = await authProvider.loginWithMobile(phoneController.text);
    if (!mounted) return;
    if (ok && authProvider.isLoggedIn) {
      await _goHome();
    }
  }

  Future<void> _onGoogle(AuthProvider authProvider) async {
    authProvider.clearError();
    final ok = await authProvider.signInWithGoogle();
    if (!mounted) return;
    if (ok && authProvider.isLoggedIn) {
      await _goHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final showRegister = authProvider.requiresRegistration;
    final isGoogleRegister = authProvider.isGoogleRegistration;
    final palette = LoginPalette.of(context);
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final canSubmit = _canSubmit(
      showRegister: showRegister,
      isGoogleRegister: isGoogleRegister,
    );
    final hint = authProvider.lastError == null
        ? _inlineHint(
            showRegister: showRegister,
            isGoogleRegister: isGoogleRegister,
          )
        : null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            palette.isDark ? Brightness.light : Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: palette.pageBg,
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: palette.isDark
                  ? _DarkHero(topInset: topInset)
                  : _LightHero(topInset: topInset),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  28,
                  24,
                  24 + bottomInset + keyboard,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      showRegister
                          ? 'login.completeProfile'.tr()
                          : (palette.isDark
                              ? 'login.headlineDark'.tr()
                              : 'login.headline'.tr()),
                      style: LoginType.headline(
                        palette.textPrimary,
                        size: palette.isDark && !showRegister ? 34 : 30,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      showRegister
                          ? (isGoogleRegister
                              ? 'login.googleMobileSubtitle'.tr()
                              : 'login.completeProfileSubtitle'.tr())
                          : 'login.enterMobileSubtitle'.tr(),
                      style: LoginType.subtitle(palette.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    if (!showRegister) ...[
                      _FieldLabel(
                        label: 'login.mobileLabel'.tr(),
                        palette: palette,
                      ),
                      const SizedBox(height: 8),
                      _PhoneField(
                        controller: phoneController,
                        focusNode: _phoneFocus,
                        palette: palette,
                        onChanged: validatePhone,
                      ),
                    ] else if (isGoogleRegister) ...[
                      _GoogleAccountCard(
                        auth: authProvider,
                        palette: palette,
                      ),
                      const SizedBox(height: 16),
                      _FieldLabel(
                        label: 'login.mobileLabel'.tr(),
                        palette: palette,
                      ),
                      const SizedBox(height: 8),
                      _PhoneField(
                        controller: phoneController,
                        focusNode: _phoneFocus,
                        palette: palette,
                        onChanged: validatePhone,
                      ),
                    ] else ...[
                      _FieldLabel(
                        label: 'login.fullNameHint'.tr(),
                        palette: palette,
                      ),
                      const SizedBox(height: 8),
                      _ThemedField(
                        controller: nameController,
                        focusNode: _nameFocus,
                        palette: palette,
                        hint: 'login.fullNameHint'.tr(),
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      _FieldLabel(
                        label: 'login.emailHint'.tr(),
                        palette: palette,
                      ),
                      const SizedBox(height: 8),
                      _ThemedField(
                        controller: emailController,
                        focusNode: _emailFocus,
                        palette: palette,
                        hint: 'login.emailHint'.tr(),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.email],
                      ),
                    ],
                    if (authProvider.lastError != null) ...[
                      const SizedBox(height: 12),
                      _ErrorBanner(message: authProvider.lastError!),
                    ],
                    if (hint != null) ...[
                      const SizedBox(height: 8),
                      Text(hint, style: LoginType.label(palette.textMuted)),
                    ],
                    const SizedBox(height: 16),
                    _PrimaryButton(
                      enabled: canSubmit && !authProvider.isLoading,
                      loading: authProvider.isLoading,
                      pressed: _primaryPressed,
                      palette: palette,
                      label: showRegister
                          ? 'login.createAccount'.tr()
                          : 'login.getOtp'.tr(),
                      onHighlightChanged: (value) {
                        setState(() => _primaryPressed = value);
                      },
                      onPressed: () => _onContinue(
                        authProvider,
                        showRegister: showRegister,
                        isGoogleRegister: isGoogleRegister,
                      ),
                    ),
                    if (showRegister) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: authProvider.isLoading
                            ? null
                            : () {
                                authProvider.cancelRegistration();
                                setState(() {});
                              },
                        child: Text(
                          isGoogleRegister
                              ? 'login.useDifferentAccount'.tr()
                              : 'login.useDifferentNumber'.tr(),
                          style: LoginType.body(palette.accent, size: 14),
                        ),
                      ),
                    ],
                    if (!showRegister) ...[
                      const SizedBox(height: 20),
                      _OrDivider(palette: palette),
                      const SizedBox(height: 16),
                      _GoogleButton(
                        palette: palette,
                        loading: authProvider.isLoading,
                        onPressed: () => _onGoogle(authProvider),
                      ),
                    ],
                    const Spacer(),
                    const SizedBox(height: 20),
                    _LegalFooter(
                      palette: palette,
                      termsTap: _termsTap,
                      privacyTap: _privacyTap,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EatEpicLogo extends StatelessWidget {
  const _EatEpicLogo({this.size = 176});

  static const _asset = 'assets/icon/app_icon.png';

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'EatEpic',
      image: true,
      child: Image.asset(
        _asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) {
          return SizedBox(
            width: size,
            height: size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  'EatEpic',
                  style: LoginType.logo(Colors.white),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BrandWordmark extends StatelessWidget {
  const _BrandWordmark({this.nameColor});

  final Color? nameColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _EatEpicLogo(size: 36),
        const SizedBox(width: 10),
        Text(
          'splash.appName'.tr(),
          style: LoginType.logo(nameColor ?? Colors.white),
        ),
      ],
    );
  }
}

class _LightHero extends StatelessWidget {
  const _LightHero({required this.topInset});

  final double topInset;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: LoginTokens.heroHeight + topInset,
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        color: LoginTokens.primary,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(LoginTokens.radiusHero),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -36,
            child: IgnorePointer(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.055),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -28,
            left: -30,
            child: IgnorePointer(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, topInset + 12, 24, 16),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: _BrandWordmark(),
                ),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const _EatEpicLogo(size: 176),
                      Positioned(
                        top: 4,
                        right: 0,
                        child: LoginHeroBadge(
                          icon: Icons.home_rounded,
                          iconColor: LoginTokens.primary,
                          label: 'login.badgeHomeKitchens'.tr(),
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        left: 0,
                        child: LoginHeroBadge(
                          icon: Icons.schedule_rounded,
                          iconColor: LoginTokens.deepOrange,
                          label: 'login.badgeFresh30'.tr(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkHero extends StatelessWidget {
  const _DarkHero({required this.topInset});

  final double topInset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, topInset + 16, 24, 0),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _BrandWordmark(nameColor: LoginTokens.darkText),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _FeatureTile(
                  icon: Icons.home_rounded,
                  label: 'login.badgeHomeKitchens'.tr(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FeatureTile(
                  icon: Icons.schedule_rounded,
                  label: 'login.badgeHot30'.tr(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FeatureTile(
                  icon: Icons.star_rounded,
                  label: 'login.badgeRatedCooks'.tr(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: LoginTokens.darkCard,
        borderRadius: BorderRadius.circular(LoginTokens.radiusFeature),
        border: Border.all(color: LoginTokens.darkTileBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: LoginTokens.darkAccent),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: LoginType.badge(LoginTokens.darkText),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.palette});

  final String label;
  final LoginPalette palette;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: LoginType.label(palette.textLabel));
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({
    required this.controller,
    required this.focusNode,
    required this.palette,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final LoginPalette palette;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final focused = focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: LoginTokens.fieldHeight,
      decoration: BoxDecoration(
        color: palette.inputBg,
        borderRadius: BorderRadius.circular(LoginTokens.radiusControl),
        border: Border.all(
          color: focused ? palette.fieldFocus : palette.border,
          width: 1.5,
        ),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: palette.fieldFocus.withValues(alpha: 0.15),
                  blurRadius: 0,
                  spreadRadius: 3,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(LoginTokens.radiusControl - 1.5),
        child: Row(
        children: [
          Semantics(
            button: true,
            label: 'login.countryCodeIndia'.tr(),
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Row(
                children: [
                  const LoginIndiaFlag(),
                  const SizedBox(width: 8),
                  Text('+91', style: LoginType.body(palette.textPrimary, size: 15)),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: palette.textMuted,
                  ),
                ],
              ),
            ),
          ),
          VerticalDivider(
            width: 1.5,
            thickness: 1.5,
            color: palette.border,
          ),
          Expanded(
            child: TextField(
              focusNode: focusNode,
              controller: controller,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.telephoneNumberNational],
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: onChanged,
              style: LoginType.phone(palette.textPrimary),
              cursorColor: palette.accent,
              decoration: InputDecoration(
                counterText: '',
                hintText: 'login.mobilePlaceholder'.tr(),
                hintStyle: LoginType.phone(LoginTokens.textPlaceholder),
                filled: true,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _ThemedField extends StatelessWidget {
  const _ThemedField({
    required this.controller,
    required this.focusNode,
    required this.palette,
    required this.hint,
    required this.keyboardType,
    required this.textInputAction,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final LoginPalette palette;
  final String hint;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final focused = focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: LoginTokens.fieldHeight,
      decoration: BoxDecoration(
        color: palette.inputBg,
        borderRadius: BorderRadius.circular(LoginTokens.radiusControl),
        border: Border.all(
          color: focused ? palette.fieldFocus : palette.border,
          width: 1.5,
        ),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: palette.fieldFocus.withValues(alpha: 0.15),
                  blurRadius: 0,
                  spreadRadius: 3,
                ),
              ]
            : null,
      ),
      child: TextField(
        focusNode: focusNode,
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        autofillHints: autofillHints,
        textCapitalization: textCapitalization,
        style: LoginType.phone(palette.textPrimary),
        cursorColor: palette.accent,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: LoginType.phone(LoginTokens.textPlaceholder),
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }
}

class _GoogleAccountCard extends StatelessWidget {
  const _GoogleAccountCard({required this.auth, required this.palette});

  final AuthProvider auth;
  final LoginPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.inputBg,
        borderRadius: BorderRadius.circular(LoginTokens.radiusControl),
        border: Border.all(color: palette.border, width: 1.5),
      ),
      child: Row(
        children: [
          const LoginGoogleMark(size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.googleFullName ?? '',
                  style: LoginType.body(palette.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  auth.googleEmail ?? '',
                  style: LoginType.subtitle(palette.textSecondary),
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
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(LoginTokens.radiusControl),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: LoginType.label(AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.enabled,
    required this.loading,
    required this.pressed,
    required this.palette,
    required this.label,
    required this.onPressed,
    required this.onHighlightChanged,
  });

  final bool enabled;
  final bool loading;
  final bool pressed;
  final LoginPalette palette;
  final String label;
  final VoidCallback onPressed;
  final ValueChanged<bool> onHighlightChanged;

  @override
  Widget build(BuildContext context) {
    final bg = enabled ? palette.accent : LoginTokens.disabledFill;
    final fg = enabled ? palette.onAccent : LoginTokens.textPlaceholder;
    return AnimatedScale(
      scale: enabled && pressed ? 0.98 : 1,
      duration: const Duration(milliseconds: 120),
      child: Material(
        color: bg,
        elevation: 0,
        shadowColor: Colors.transparent,
        borderRadius: BorderRadius.circular(LoginTokens.radiusControl),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          onHighlightChanged: enabled ? onHighlightChanged : null,
          borderRadius: BorderRadius.circular(LoginTokens.radiusControl),
          child: Ink(
            height: LoginTokens.fieldHeight,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(LoginTokens.radiusControl),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: LoginTokens.primary.withValues(alpha: 0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: loading
                  ? SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: palette.onAccent,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label, style: LoginType.button(fg)),
                        if (enabled) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 18, color: fg),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.palette});

  final LoginPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: palette.divider, thickness: 1, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'login.orContinueWith'.tr(),
            style: LoginType.divider(palette.textMuted),
          ),
        ),
        Expanded(child: Divider(color: palette.divider, thickness: 1, height: 1)),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({
    required this.palette,
    required this.loading,
    required this.onPressed,
  });

  final LoginPalette palette;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.isDark ? palette.card : Colors.white,
      borderRadius: BorderRadius.circular(LoginTokens.radiusControl),
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(LoginTokens.radiusControl),
        child: Container(
          height: LoginTokens.googleHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LoginTokens.radiusControl),
            border: Border.all(color: palette.border, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const LoginGoogleMark(size: 20),
              const SizedBox(width: 10),
              Text(
                'login.googleButton'.tr(),
                style: LoginType.body(palette.textPrimary, size: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalFooter extends StatelessWidget {
  const _LegalFooter({
    required this.palette,
    required this.termsTap,
    required this.privacyTap,
  });

  final LoginPalette palette;
  final TapGestureRecognizer termsTap;
  final TapGestureRecognizer privacyTap;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: LoginType.footer(palette.textMuted),
        children: [
          TextSpan(text: 'login.legalBefore'.tr()),
          TextSpan(
            text: 'login.terms'.tr(),
            style: LoginType.footer(palette.accent).copyWith(
              fontWeight: FontWeight.w600,
            ),
            recognizer: termsTap,
          ),
          TextSpan(text: 'login.legalAnd'.tr()),
          TextSpan(
            text: 'login.privacy'.tr(),
            style: LoginType.footer(palette.accent).copyWith(
              fontWeight: FontWeight.w600,
            ),
            recognizer: privacyTap,
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
