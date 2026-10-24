import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/utils/error_messages.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/core/di/app_services.dart';
import 'package:food_app/data/models/subscription_models.dart';
import 'package:food_app/data/models/app_user.dart';
import 'package:food_app/data/repositories/subscription_repository.dart';
import 'package:food_app/provider/auth_provider.dart';
import 'package:food_app/provider/subscription_provider.dart';
import 'package:provider/provider.dart';

class CreateSubscriptionScreen extends StatefulWidget {
  const CreateSubscriptionScreen({
    super.key,
    this.initialKitchenId,
    this.initialMenuItemId,
  });

  /// When set from cart upsell, plans are narrowed to one kitchen/menu line.
  final String? initialKitchenId;
  final String? initialMenuItemId;

  @override
  State<CreateSubscriptionScreen> createState() => _CreateSubscriptionScreenState();
}

class _CreateSubscriptionScreenState extends State<CreateSubscriptionScreen> {
  final SubscriptionRepository _repo = AppServices.instance.subscriptionRepository;
  List<SubscriptionPlanDto> _plans = [];
  bool _loadingPlans = true;
  String? _loadError;

  SubscriptionPlanDto? _selected;
  DateTime _startDate = DateTime.now();
  String _payment = 'ONLINE';
  bool _autoRenew = false;
  bool _submitting = false;
  List<UserAddress> _addresses = [];
  String? _addressId;

  @override
  void initState() {
    super.initState();
    _loadPlans();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    try {
      final list = await AppServices.instance.userRepository.getAddresses();
      if (!mounted) return;
      setState(() {
        _addresses = list;
        _addressId = list.isEmpty
            ? null
            : (list.where((a) => a.isDefault).isNotEmpty
                    ? list.where((a) => a.isDefault).first
                    : list.first)
                .id;
      });
    } catch (_) {}
  }

  Future<void> _loadPlans() async {
    setState(() {
      _loadingPlans = true;
      _loadError = null;
    });
    try {
      final plans = await _repo.fetchPlans(
        kitchenId: widget.initialKitchenId,
        menuItemId: widget.initialMenuItemId,
      );
      setState(() {
        _plans = plans;
        _selected = plans.isEmpty ? null : plans.first;
        _loadingPlans = false;
      });
    } catch (e) {
      setState(() {
        _plans = [];
        _selected = null;
        _loadError = 'sub.couldNotLoadPlans'.tr(namedArgs: {'error': e.toString()});
        _loadingPlans = false;
      });
    }
  }

  Future<void> _purchase() async {
    final loggedIn = context.read<AuthProvider>().isLoggedIn;
    if (!mounted) return;
    if (!loggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('sub.loginToSubscribe'.tr())),
      );
      await Navigator.pushNamed(context, '/login');
      if (!mounted) return;
      return;
    }
    final plan = _selected;
    if (plan == null || _submitting) return;

    if (_addressId == null || _addressId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('sub.addAddressAccount'.tr())),
      );
      return;
    }

    if (_payment == 'WALLET') {
      try {
        final balance = await AppServices.instance.userRepository.getWalletBalance();
        if (balance + 0.001 < plan.displayPrice) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('sub.walletInsufficient'.tr(namedArgs: {
                'balance': balance.toStringAsFixed(0),
              })),
            ),
          );
          return;
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyErrorMessage(e))),
        );
        return;
      }
    }

    setState(() => _submitting = true);
    try {
      final result = await _repo.purchase(
        planId: plan.id,
        startDate: DateTime(_startDate.year, _startDate.month, _startDate.day),
        paymentMethod: _payment,
        addressId: _addressId,
        autoRenew: _autoRenew,
      );

      if (_payment == 'ONLINE') {
        await _repo.markPaymentComplete(result.subscriptionSnapshot.id);
      }

      await context.read<SubscriptionProvider>().bootstrap();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('sub.subscriptionActivated'.tr())),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('sub.purchaseFailed'.tr(
              namedArgs: {'error': friendlyErrorMessage(e)},
            )),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = _selected;
    final payLabel = _payment == 'WALLET'
        ? 'sub.subscribeWithWallet'.tr()
        : 'sub.payAndSubscribe'.tr();

    return Scaffold(
      appBar: AppBar(
        title: Text('sub.subscribe'.tr()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.initialKitchenId != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  widget.initialMenuItemId != null
                      ? 'sub.plansForCartKitchen'.tr()
                      : 'sub.plansForSelectedKitchen'.tr(),
                  style: context.bodyMedium.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
            if (_loadingPlans)
              const Center(child: CircularProgressIndicator())
            else if (_loadError != null)
              Text(
                _loadError!,
                style: context.bodyMedium.copyWith(color: AppColors.error),
              )
            else if (_plans.isEmpty)
              Text('sub.noPlansMatch'.tr())
            else
              ..._plans.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: RadioListTile<SubscriptionPlanDto>(
                    value: p,
                    groupValue: _selected,
                    onChanged: (v) => setState(() => _selected = v),
                    title: Text(p.title),
                    subtitle: Text(
                      '₹${p.displayPrice} · ${_fmtDuration(p)} · ₹${p.pricePerMeal}/${'sub.mealUnit'.tr()}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'sub.startDate'.tr(),
              style: context.headingMedium,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(now.year, now.month, now.day),
                  lastDate: DateTime(now.year + 2),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
            ),
            if (_addresses.isNotEmpty) ...[
              Text(
                'sub.deliveryAddress'.tr(),
                style: context.headingMedium,
              ),
              DropdownButtonFormField<String>(
                value: _addressId,
                items: _addresses
                    .map(
                      (a) => DropdownMenuItem(
                        value: a.id,
                        child: Text(a.label, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _addressId = v),
              ),
            ],
            SwitchListTile(
              title: Text('sub.autoRenew'.tr()),
              value: _autoRenew,
              onChanged: (v) => setState(() => _autoRenew = v),
            ),
            const Divider(),
            Text(
              'sub.payment'.tr(),
              style: context.headingMedium,
            ),
            RadioListTile<String>(
              title: Text('sub.payNow'.tr()),
              subtitle: Text('sub.payNowSubtitle'.tr()),
              value: 'ONLINE',
              groupValue: _payment,
              onChanged: (v) => setState(() => _payment = v ?? 'ONLINE'),
            ),
            RadioListTile<String>(
              title: Text('sub.wallet'.tr()),
              subtitle: Text('sub.walletSubtitle'.tr()),
              value: 'WALLET',
              groupValue: _payment,
              onChanged: (v) => setState(() => _payment = v ?? 'ONLINE'),
            ),
            if (plan != null && _payment == 'ONLINE')
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  'sub.amountDue'.tr(namedArgs: {'amount': '${plan.displayPrice}'}),
                  style: context.headingSmall,
                ),
              ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: FilledButton(
            onPressed: (_loadingPlans || _selected == null || _submitting) ? null : _purchase,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.medium + 2),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(payLabel),
          ),
        ),
      ),
    );
  }

  String _fmtDuration(SubscriptionPlanDto p) {
    if (p.durationInDays <= 0) return 'sub.durationUnknown'.tr();
    if (p.durationInDays % 30 == 0) {
      return 'sub.durationMonths'.tr(namedArgs: {'count': '${p.durationInDays ~/ 30}'});
    }
    if (p.durationInDays % 7 == 0) {
      return 'sub.durationWeeks'.tr(namedArgs: {'count': '${p.durationInDays ~/ 7}'});
    }
    return 'sub.durationDays'.tr(namedArgs: {'count': '${p.durationInDays}'});
  }
}
