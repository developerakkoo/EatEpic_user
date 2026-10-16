import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/feaetures/splash_screen.dart';

/// One-time language chooser shown on first launch.
///
/// Can also be reached again, but normally appears once before onboarding.
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageOption {
  const _LanguageOption(this.locale, this.nativeName, this.englishName);
  final Locale locale;
  final String nativeName;
  final String englishName;
}

const List<_LanguageOption> _options = [
  _LanguageOption(Locale('en'), 'English', 'English'),
  _LanguageOption(Locale('hi'), 'हिंदी', 'Hindi'),
  _LanguageOption(Locale('mr'), 'मराठी', 'Marathi'),
];

class _LanguageScreenState extends State<LanguageScreen> {
  Locale? _selected;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Read the active locale here (not in initState) since context.locale
    // depends on an inherited widget.
    _selected ??= context.locale;
  }

  void _onSelect(Locale locale) {
    setState(() => _selected = locale);
    // Apply immediately so this screen's text updates live.
    context.setLocale(locale);
  }

  Future<void> _onContinue() async {
    if (_busy) return;
    setState(() => _busy = true);

    await context.setLocale(_selected ?? context.locale);
    await setLanguageSelected();
    if (!mounted) return;

    final onboardingDone = await isOnboardingComplete();
    if (!mounted) return;

    if (onboardingDone) {
      Navigator.pushReplacementNamed(context, '/');
    } else {
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: colors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.language_rounded,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'language.title'.tr(),
                style: context.displayLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'language.subtitle'.tr(),
                style: context.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xxl),
              Expanded(
                child: ListView.separated(
                  itemCount: _options.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final option = _options[index];
                    final isSelected =
                        option.locale.languageCode == _selected?.languageCode;
                    return _LanguageTile(
                      option: option,
                      selected: isSelected,
                      onTap: () => _onSelect(option.locale),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: _busy ? null : _onContinue,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      )
                    : Text('language.continueButton'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _LanguageOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: selected ? colors.primaryLight : colors.surfaceGrey,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.nativeName,
                    style: context.headingMedium,
                  ),
                  if (option.nativeName != option.englishName) ...[
                    const SizedBox(height: 2),
                    Text(
                      option.englishName,
                      style: context.caption,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? AppColors.primary : colors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}
