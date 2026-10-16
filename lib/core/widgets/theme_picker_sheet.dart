import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/core/theme/app_theme_colors.dart';
import 'package:food_app/provider/theme_provider.dart';
import 'package:provider/provider.dart';

Future<void> showThemePickerSheet(
  BuildContext context, {
  required bool isFirstTime,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isDismissible: !isFirstTime,
    enableDrag: !isFirstTime,
    backgroundColor: context.colors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
    ),
    builder: (sheetContext) => _ThemePickerSheet(isFirstTime: isFirstTime),
  );
}

class _ThemePickerSheet extends StatefulWidget {
  const _ThemePickerSheet({required this.isFirstTime});

  final bool isFirstTime;

  @override
  State<_ThemePickerSheet> createState() => _ThemePickerSheetState();
}

class _ThemePickerSheetState extends State<_ThemePickerSheet> {
  ThemeMode? _selected;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _selected = context.read<ThemeProvider>().themeMode;
  }

  Future<void> _apply(ThemeMode mode, {required bool dismiss}) async {
    if (_busy) return;

    if (widget.isFirstTime) {
      setState(() => _selected = mode);
      return;
    }

    setState(() => _busy = true);
    await context.read<ThemeProvider>().setThemeMode(
          mode,
          markSelected: true,
        );
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _onContinue() async {
    final mode = _selected;
    if (mode == null || _busy) return;

    setState(() => _busy = true);
    await context.read<ThemeProvider>().setThemeMode(
          mode,
          markSelected: true,
        );
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final current = widget.isFirstTime
        ? _selected
        : context.watch<ThemeProvider>().themeMode;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.divider,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'theme.title'.tr(),
                style: context.headingMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'theme.subtitle'.tr(),
                style: context.bodyMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: _ThemeOptionCard(
                    label: 'theme.light'.tr(),
                    icon: Icons.wb_sunny_outlined,
                    selected: current == ThemeMode.light,
                    preview: const _LightPreview(),
                    onTap: () => _apply(ThemeMode.light, dismiss: !widget.isFirstTime),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ThemeOptionCard(
                    label: 'theme.dark'.tr(),
                    icon: Icons.dark_mode_outlined,
                    selected: current == ThemeMode.dark,
                    preview: const _DarkPreview(),
                    onTap: () => _apply(ThemeMode.dark, dismiss: !widget.isFirstTime),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ThemeOptionCard(
                    label: 'theme.system'.tr(),
                    icon: Icons.smartphone_outlined,
                    selected: current == ThemeMode.system,
                    preview: const _SystemPreview(),
                    onTap: () => _apply(ThemeMode.system, dismiss: !widget.isFirstTime),
                  ),
                ),
              ],
            ),
            if (widget.isFirstTime) ...[
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selected == null || _busy ? null : _onContinue,
                  child: Text('theme.continueButton'.tr()),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ThemeOptionCard extends StatelessWidget {
  const _ThemeOptionCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.preview,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Widget preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.surfaceGrey,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        splashFactory: NoSplash.splashFactory,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(
              color: selected ? AppColors.primary : colors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  preview,
                  if (selected)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 12,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Icon(icon, size: 18, color: colors.textPrimary),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: context.bodySmall.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LightPreview extends StatelessWidget {
  const _LightPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppThemeColors.light.background,
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: AppThemeColors.light.divider),
      ),
      child: Column(
        children: [
          Container(
            height: 10,
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppThemeColors.light.surfaceGrey,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(6, 0, 6, 6),
              decoration: BoxDecoration(
                color: AppThemeColors.light.primaryLight,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkPreview extends StatelessWidget {
  const _DarkPreview();

  @override
  Widget build(BuildContext context) {
    const dark = AppThemeColors.dark;
    return Container(
      height: 48,
      width: double.infinity,
      decoration: BoxDecoration(
        color: dark.background,
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: dark.divider),
      ),
      child: Column(
        children: [
          Container(
            height: 10,
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: dark.elevatedSurface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: dark.border),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 16,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: dark.primaryOnDark,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(6, 0, 6, 6),
              decoration: BoxDecoration(
                color: dark.primaryLight,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemPreview extends StatelessWidget {
  const _SystemPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: AppThemeColors.dark.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: Container(color: AppThemeColors.light.background),
          ),
          Expanded(
            child: Container(color: AppThemeColors.dark.background),
          ),
        ],
      ),
    );
  }
}
