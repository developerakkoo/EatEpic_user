import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/core/widgets/theme_picker_sheet.dart';
import 'package:food_app/feaetures/addresses_screen.dart';
import 'package:food_app/feaetures/login_screen.dart';
import 'package:food_app/feaetures/subscription_screen.dart';
import 'package:food_app/feaetures/support/support_tickets_screen.dart';
import 'package:food_app/provider/auth_provider.dart';
import 'package:food_app/provider/location_provider.dart';
import 'package:food_app/provider/theme_provider.dart';
import 'package:provider/provider.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, this.onOpenSubscriptions});

  final VoidCallback? onOpenSubscriptions;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final location = context.watch<LocationProvider>();
    final themeMode = context.watch<ThemeProvider>().themeMode;

    return Scaffold(
      appBar: AppBar(
        title: Text('account.title'.tr()),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        children: [
          _ProfileHeader(
            name: auth.user?.fullName,
            phone: auth.phone,
            email: auth.user?.email,
          ),
          const SizedBox(height: AppSpacing.xxl),
          _SectionTile(
            icon: Icons.location_on_outlined,
            title: 'account.savedAddress'.tr(),
            subtitle: location.address ?? 'account.addAddress'.tr(),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddressesScreen()),
            ),
          ),
          _SectionTile(
            icon: Icons.receipt_long_outlined,
            title: 'account.orders'.tr(),
            subtitle: 'account.ordersSubtitle'.tr(),
            onTap: () {
              if (!auth.isLoggedIn) {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                );
                return;
              }
              Navigator.pushNamed(context, '/orders');
            },
          ),
          _SectionTile(
            icon: Icons.card_membership,
            title: 'account.subscriptions'.tr(),
            subtitle: 'account.subscriptionsSubtitle'.tr(),
            onTap: () {
              if (widget.onOpenSubscriptions != null) {
                widget.onOpenSubscriptions!();
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SubscriptionScreen(),
                ),
              );
            },
          ),
          _SectionTile(
            icon: Icons.language_outlined,
            title: 'account.language'.tr(),
            subtitle: _currentLanguageLabel(context.locale),
            onTap: () => _showLanguageSelector(context),
          ),
          _SectionTile(
            icon: Icons.palette_outlined,
            title: 'account.appearance'.tr(),
            subtitle: ThemeProvider.labelForMode(themeMode).tr(),
            onTap: () => showThemePickerSheet(context, isFirstTime: false),
          ),
          _SectionTile(
            icon: Icons.help_outline,
            title: 'account.help'.tr(),
            subtitle: 'account.helpSubtitle'.tr(),
            onTap: () {
              if (!auth.isLoggedIn) {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SupportTicketsScreen()),
              );
            },
          ),
          const Divider(height: AppSpacing.xxxl),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: Text(
              'account.logout'.tr(),
              style: context.headingSmall.copyWith(color: AppColors.error),
            ),
            onTap: () {
              auth.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  String _currentLanguageLabel(Locale locale) {
    switch (locale.languageCode) {
      case 'hi':
        return 'language.hindi'.tr();
      case 'mr':
        return 'language.marathi'.tr();
      default:
        return 'language.english'.tr();
    }
  }

  void _showLanguageSelector(BuildContext context) {
    const options = <_LangChoice>[
      _LangChoice(Locale('en'), 'English', 'English'),
      _LangChoice(Locale('hi'), 'हिंदी', 'Hindi'),
      _LangChoice(Locale('mr'), 'मराठी', 'Marathi'),
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
      ),
      builder: (sheetContext) {
        final current = sheetContext.locale.languageCode;
        final colors = sheetContext.colors;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Text(
                  'account.selectLanguage'.tr(),
                  style: sheetContext.headingMedium,
                ),
              ),
              for (final option in options)
                ListTile(
                  title: Text(option.nativeName, style: sheetContext.bodyLarge),
                  subtitle: option.nativeName != option.englishName
                      ? Text(option.englishName, style: sheetContext.caption)
                      : null,
                  trailing: option.locale.languageCode == current
                      ? const Icon(Icons.check_rounded, color: AppColors.primary)
                      : null,
                  tileColor: option.locale.languageCode == current
                      ? colors.primaryLight
                      : null,
                  onTap: () {
                    sheetContext.setLocale(option.locale);
                    Navigator.pop(sheetContext);
                  },
                ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
  }
}

class _LangChoice {
  const _LangChoice(this.locale, this.nativeName, this.englishName);
  final Locale locale;
  final String nativeName;
  final String englishName;
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({this.name, this.phone, this.email});

  final String? name;
  final String? phone;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Material(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadius.large),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: colors.primaryLight,
                child: Text(
                  (name?.isNotEmpty == true ? name!.substring(0, 1) : 'U').toUpperCase(),
                  style: context.displayMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? 'account.user'.tr(),
                      style: context.headingLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      phone ?? email ?? 'account.addPhone'.tr(),
                      style: context.bodyMedium.copyWith(
                        color: phone != null ? colors.textSecondary : AppColors.primary,
                        fontWeight: phone != null ? FontWeight.w400 : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: context.headingSmall,
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.bodySmall,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
