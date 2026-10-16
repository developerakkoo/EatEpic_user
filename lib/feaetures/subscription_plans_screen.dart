import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/core/di/app_services.dart';
import 'package:food_app/data/models/subscription_models.dart';
import 'package:food_app/core/widgets/subscription/subscription_quick_checkout_sheet.dart';
import 'package:food_app/feaetures/subscription_plan_detail_screen.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({
    super.key,
    required this.kitchenId,
    required this.kitchenName,
  });

  final String kitchenId;
  final String kitchenName;

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  final _repo = AppServices.instance.subscriptionRepository;
  List<SubscriptionPlanDto> _plans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _plans = await _repo.fetchPlans(kitchenId: widget.kitchenId);
    } catch (_) {
      _plans = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
              'sub.plansTitle'.tr(namedArgs: {'kitchen': widget.kitchenName}))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _plans.isEmpty
              ? Center(child: Text('sub.noPlans'.tr()))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: _plans.length,
                    itemBuilder: (_, i) {
                      final p = _plans[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: ListTile(
                          title: Text(p.title),
                          subtitle: Text(
                            'sub.planSubtitle'.tr(namedArgs: {
                              'price': '${p.displayPrice}',
                              'days': '${p.durationInDays}',
                              'diet': p.isVeg
                                  ? 'sub.veg'.tr()
                                  : 'sub.nonVeg'.tr(),
                            }),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => showSubscriptionQuickCheckoutSheet(
                            context,
                            initialKitchenId: widget.kitchenId,
                            lockedPlan: p,
                          ),
                          onLongPress: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SubscriptionPlanDetailScreen(
                                plan: p,
                                kitchenId: widget.kitchenId,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: _plans.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => showSubscriptionQuickCheckoutSheet(
                context,
                initialKitchenId: widget.kitchenId,
              ),
              backgroundColor: AppColors.primary,
              label: Text('sub.subscribe'.tr()),
            ),
    );
  }
}
