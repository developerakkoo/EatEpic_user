import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/core/di/app_services.dart';
import 'package:food_app/core/utils/error_messages.dart';
import 'package:food_app/core/widgets/subscription/subscription_confirm_dialogs.dart';
import 'package:food_app/core/widgets/subscription/subscription_stats_row.dart';
import 'package:food_app/core/widgets/subscription/subscription_status_labels.dart';
import 'package:food_app/data/models/app_user.dart';
import 'package:food_app/data/models/subscription_models.dart';
import 'package:food_app/provider/subscription_provider.dart';
import 'package:provider/provider.dart';

Future<void> showSubscriptionManageSheet(
  BuildContext context, {
  required UserSubscriptionSummary subscription,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SubscriptionManageSheet(subscription: subscription),
  );
}

class SubscriptionManageSheet extends StatefulWidget {
  const SubscriptionManageSheet({super.key, required this.subscription});

  final UserSubscriptionSummary subscription;

  @override
  State<SubscriptionManageSheet> createState() => _SubscriptionManageSheetState();
}

class _SubscriptionManageSheetState extends State<SubscriptionManageSheet> {
  final _repo = AppServices.instance.subscriptionRepository;
  List<SubscriptionTransactionDto> _txns = [];
  List<UserAddress> _addresses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _txns = await _repo.fetchTransactions(subscriptionId: widget.subscription.id);
      _addresses = await AppServices.instance.userRepository.getAddresses();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pause() async {
    final start = DateTime.now();
    final end = await showDatePicker(
      context: context,
      initialDate: start.add(const Duration(days: 7)),
      firstDate: start,
      lastDate: start.add(const Duration(days: 365)),
    );
    if (end == null) return;

    try {
      final preview = await _repo.fetchPausePreview(
        widget.subscription.id,
        start: start,
        end: end,
      );
      if (!mounted) return;
      final ok = await showSubscriptionPauseConfirmDialog(
        context,
        preview: preview,
        pauseEnd: end,
      );
      if (ok != true) return;

      await _repo.pause(widget.subscription.id, start: start, end: end);
      if (!mounted) return;
      await context.read<SubscriptionProvider>().bootstrap();
      Navigator.pop(context);
      final pauseDate = '${end.day}/${end.month}/${end.year}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            preview.shiftedMeals > 0
                ? 'sub.pausedUntilRescheduled'.tr(namedArgs: {'date': pauseDate})
                : 'sub.pausedUntil'.tr(namedArgs: {'date': pauseDate}),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
      }
    }
  }

  Future<void> _resume() async {
    try {
      await _repo.resume(widget.subscription.id);
      if (!mounted) return;
      await context.read<SubscriptionProvider>().bootstrap();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('sub.subscriptionResumed'.tr())));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
      }
    }
  }

  Future<void> _cancel() async {
    try {
      final preview = await _repo.fetchCancelPreview(widget.subscription.id);
      if (!mounted) return;
      final ok = await showSubscriptionCancelConfirmDialog(context, preview: preview);
      if (ok != true) return;

      final result = await _repo.cancelWithResult(widget.subscription.id);
      if (!mounted) return;
      await context.read<SubscriptionProvider>().bootstrap();
      Navigator.pop(context);
      final refund = result.refund?.netRefund ?? preview.netRefund;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            refund > 0
                ? 'sub.cancelledRefund'.tr(namedArgs: {'amount': '$refund'})
                : 'sub.subscriptionCancelled'.tr(),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
      }
    }
  }

  Future<void> _renew() async {
    try {
      await _repo.renew(widget.subscription.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('sub.renewalInitiated'.tr())));
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
      }
    }
  }

  Future<void> _changeAddress() async {
    if (_addresses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('sub.addAddressAccount'.tr())),
      );
      return;
    }
    final picked = await showModalBottomSheet<UserAddress>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _addresses
              .map(
                (a) => ListTile(
                  title: Text(a.label),
                  subtitle: Text(a.addressLine, maxLines: 2),
                  onTap: () => Navigator.pop(ctx, a),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (picked == null) return;
    try {
      await _repo.updateAddress(widget.subscription.id, picked.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('sub.addressUpdated'.tr())));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.subscription;
    final statusLabel = SubscriptionStatusLabels.subscriptionStatus(s.status);
    final pause = s.activePause;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  controller: scrollController,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.colors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(s.title, style: context.headingMedium),
                    Text(
                      '$statusLabel · ${s.partnerName}',
                      style: context.bodyMedium.copyWith(color: context.colors.textSecondary),
                    ),
                    if (pause?.end != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          'sub.pausedUntilLabel'.tr(namedArgs: {
                            'date':
                                '${pause!.end!.day}/${pause.end!.month}/${pause.end!.year}'
                          }),
                          style: context.bodyMedium.copyWith(color: AppColors.pausePurple),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    SubscriptionStatsRow(stats: s.mealStats),
                    const SizedBox(height: AppSpacing.lg),
                    if (s.status == 'ACTIVE') ...[
                      ListTile(
                        leading: const Icon(Icons.pause_circle_outline),
                        title: Text('sub.pauseSubscription'.tr()),
                        onTap: _pause,
                      ),
                      ListTile(
                        leading: const Icon(Icons.location_on_outlined),
                        title: Text('sub.changeAddress'.tr()),
                        onTap: _changeAddress,
                      ),
                    ],
                    if (s.status == 'PAUSED')
                      ListTile(
                        leading: const Icon(Icons.play_circle_outline),
                        title: Text('sub.resumeSubscription'.tr()),
                        onTap: _resume,
                      ),
                    if (s.isActiveLike) ...[
                      ListTile(
                        leading: const Icon(Icons.autorenew),
                        title: Text('sub.renewNow'.tr()),
                        onTap: _renew,
                      ),
                      ListTile(
                        leading: Icon(Icons.cancel_outlined, color: AppColors.error),
                        title: Text(
                          'sub.cancelSubscription'.tr(),
                          style: context.bodyLarge.copyWith(color: AppColors.error),
                        ),
                        onTap: _cancel,
                      ),
                    ],
                    const Divider(),
                    Text('sub.invoices'.tr(), style: context.headingMedium),
                    if (_txns.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Text('sub.noTransactions'.tr(), style: context.bodyMedium),
                      )
                    else
                      ..._txns.map(
                        (t) => ListTile(
                          title: Text('${t.type} · ₹${t.amount}'),
                          subtitle: Text(t.paymentStatus),
                          trailing: Text(
                            t.createdAt.toLocal().toString().split(' ').first,
                            style: context.bodySmall,
                          ),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}
