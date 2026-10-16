import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/core/di/app_services.dart';
import 'package:food_app/data/models/app_user.dart';
import 'package:food_app/data/models/subscription_models.dart';
import 'package:food_app/data/repositories/subscription_repository.dart';
import 'package:food_app/feaetures/addresses_screen.dart';
import 'package:food_app/provider/auth_provider.dart';
import 'package:food_app/provider/subscription_provider.dart';
import 'package:provider/provider.dart';

Future<bool?> showSubscriptionQuickCheckoutSheet(
  BuildContext context, {
  String? initialKitchenId,
  String? initialMenuItemId,
  String? initialPlanId,
  SubscriptionPlanDto? lockedPlan,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SubscriptionQuickCheckoutSheet(
      initialKitchenId: initialKitchenId,
      initialMenuItemId: initialMenuItemId,
      initialPlanId: initialPlanId,
      lockedPlan: lockedPlan,
    ),
  );
}

class SubscriptionQuickCheckoutSheet extends StatefulWidget {
  const SubscriptionQuickCheckoutSheet({
    super.key,
    this.initialKitchenId,
    this.initialMenuItemId,
    this.initialPlanId,
    this.lockedPlan,
  });

  final String? initialKitchenId;
  final String? initialMenuItemId;
  final String? initialPlanId;
  final SubscriptionPlanDto? lockedPlan;

  @override
  State<SubscriptionQuickCheckoutSheet> createState() =>
      _SubscriptionQuickCheckoutSheetState();
}

class _SubscriptionQuickCheckoutSheetState extends State<SubscriptionQuickCheckoutSheet> {
  final SubscriptionRepository _repo = AppServices.instance.subscriptionRepository;
  int _step = 0;
  List<SubscriptionPlanDto> _plans = [];
  SubscriptionPlanDto? _selected;
  bool _loadingPlans = true;
  DateTime _startDate = DateTime.now();
  String _payment = 'WALLET';
  bool _autoRenew = false;
  bool _submitting = false;
  List<UserAddress> _addresses = [];
  String? _addressId;

  @override
  void initState() {
    super.initState();
    if (widget.lockedPlan != null) {
      _selected = widget.lockedPlan;
      _plans = [widget.lockedPlan!];
      _loadingPlans = false;
      _step = 1;
    } else {
      _loadPlans();
    }
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
    setState(() => _loadingPlans = true);
    try {
      final plans = await _repo.fetchPlans(
        kitchenId: widget.initialKitchenId,
        menuItemId: widget.initialMenuItemId,
      );
      SubscriptionPlanDto? selected;
      if (widget.initialPlanId != null) {
        selected = plans.cast<SubscriptionPlanDto?>().firstWhere(
              (p) => p?.id == widget.initialPlanId,
              orElse: () => plans.isEmpty ? null : plans.first,
            );
      } else {
        selected = plans.isEmpty ? null : plans.first;
      }
      setState(() {
        _plans = plans;
        _selected = selected;
        _loadingPlans = false;
      });
    } catch (_) {
      setState(() => _loadingPlans = false);
    }
  }

  Future<void> _submit() async {
    final plan = _selected;
    if (plan == null) return;
    if (_addressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('sub.selectAddress'.tr())),
      );
      return;
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
      if (!mounted) return;
      await context.read<SubscriptionProvider>().bootstrap();
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('sub.subscriptionActivated'.tr())),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.watch<AuthProvider>().isLoggedIn;
    if (!loggedIn) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xxl,
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('sub.loginToSubscribe'.tr(), style: context.headingMedium),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/login');
              },
              child: Text('sub.goToLogin'.tr()),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (context, controller) {
          return ListView(
            controller: controller,
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text('sub.subscribe'.tr(), style: context.headingMedium),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _StepDot(active: _step >= 0, label: 'sub.stepPlan'.tr()),
                  Expanded(child: Divider(color: _step >= 1 ? AppColors.primary : context.colors.divider)),
                  _StepDot(active: _step >= 1, label: 'sub.stepDetails'.tr()),
                  Expanded(child: Divider(color: _step >= 2 ? AppColors.primary : context.colors.divider)),
                  _StepDot(active: _step >= 2, label: 'sub.stepPay'.tr()),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_step == 0) _buildPlanStep(),
              if (_step == 1) _buildDetailsStep(),
              if (_step == 2) _buildPayStep(),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  if (_step > 0 && widget.lockedPlan == null)
                    TextButton(
                      onPressed: _submitting ? null : () => setState(() => _step -= 1),
                      child: Text('sub.back'.tr()),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _submitting
                        ? null
                        : () {
                            if (_step < 2) {
                              if (_step == 0 && _selected == null) return;
                              if (_step == 1 && _addressId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('sub.selectAddressShort'.tr())),
                                );
                                return;
                              }
                              setState(() => _step += 1);
                              return;
                            }
                            _submit();
                          },
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                          )
                        : Text(_step < 2
                            ? 'sub.continueBtn'.tr()
                            : 'sub.subscribeAmount'.tr(namedArgs: {'amount': '${_selected?.displayPrice ?? 0}'})),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlanStep() {
    if (_loadingPlans) return const Center(child: CircularProgressIndicator());
    if (_plans.isEmpty) {
      return Text('sub.noPlansAvailable'.tr(), style: context.bodyMedium);
    }
    return Column(
      children: _plans.map((p) {
        final selected = _selected?.id == p.id;
        return RadioListTile<SubscriptionPlanDto>(
          value: p,
          groupValue: _selected,
          onChanged: (v) => setState(() => _selected = v),
          title: Text(p.title),
          subtitle: Text(
            '₹${p.displayPrice} · ${'sub.durationDays'.tr(namedArgs: {'count': '${p.durationInDays}'})} · ₹${p.pricePerMeal}/${'sub.mealUnit'.tr()}',
          ),
          selected: selected,
        );
      }).toList(),
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('sub.startDate'.tr()),
          subtitle: Text('${_startDate.day}/${_startDate.month}/${_startDate.year}'),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _startDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 60)),
            );
            if (picked != null) setState(() => _startDate = picked);
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('sub.deliveryAddress'.tr(), style: context.headingSmall),
        if (_addresses.isEmpty)
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddressesScreen()),
            ).then((_) => _loadAddresses()),
            child: Text('sub.addAddress'.tr()),
          )
        else
          DropdownButtonFormField<String>(
            value: _addressId,
            items: _addresses
                .map((a) => DropdownMenuItem(value: a.id, child: Text(a.label)))
                .toList(),
            onChanged: (v) => setState(() => _addressId = v),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('sub.autoRenew'.tr()),
          value: _autoRenew,
          onChanged: (v) => setState(() => _autoRenew = v),
        ),
      ],
    );
  }

  Widget _buildPayStep() {
    final plan = _selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RadioListTile<String>(
          value: 'WALLET',
          groupValue: _payment,
          onChanged: (v) => setState(() => _payment = v!),
          title: Text('sub.payWithWallet'.tr()),
        ),
        RadioListTile<String>(
          value: 'ONLINE',
          groupValue: _payment,
          onChanged: (v) => setState(() => _payment = v!),
          title: Text('sub.payOnline'.tr()),
        ),
        if (plan != null) ...[
          const Divider(),
          Text(
            'sub.planMeals'.tr(namedArgs: {
              'title': plan.title,
              'count': '${plan.durationInDays}'
            }),
            style: context.bodyMedium,
          ),
          Text('sub.total'.tr(namedArgs: {'amount': '${plan.displayPrice}'}),
              style: context.headingSmall),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.active, required this.label});

  final bool active;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : context.colors.surfaceGrey,
            shape: BoxShape.circle,
          ),
          child: active
              ? const Icon(Icons.check, size: 14, color: AppColors.white)
              : null,
        ),
        Text(label, style: context.caption),
      ],
    );
  }
}
