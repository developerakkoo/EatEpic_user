import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/core/utils/error_messages.dart';
import 'package:food_app/core/widgets/subscription/subscription_calendar_legend.dart';
import 'package:food_app/core/widgets/subscription/subscription_manage_sheet.dart';
import 'package:food_app/core/widgets/subscription/subscription_plan_card.dart';
import 'package:food_app/core/widgets/subscription/subscription_quick_checkout_sheet.dart';
import 'package:food_app/core/widgets/subscription/subscription_stats_row.dart';
import 'package:food_app/core/widgets/subscription/subscription_status_labels.dart';
import 'package:food_app/feaetures/order_tracking_screen.dart';
import 'package:food_app/provider/auth_provider.dart';
import 'package:food_app/core/di/app_services.dart';
import 'package:food_app/provider/subscription_provider.dart';
import 'package:food_app/data/models/subscription_models.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late DateTime _focused = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = _normalizeDay(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loggedIn = context.read<AuthProvider>().isLoggedIn;
      if (!loggedIn) return;
      context.read<SubscriptionProvider>().bootstrap();
    });
  }

  DateTime _normalizeDay(DateTime d) => DateTime(d.year, d.month, d.day);

  Color _markerColor(SubscriptionDayMarker marker) {
    return switch (marker) {
      SubscriptionDayMarker.delivered => AppColors.primary,
      SubscriptionDayMarker.pending => AppColors.info,
      SubscriptionDayMarker.inProgress => AppColors.warning,
      SubscriptionDayMarker.skipped => context.colors.textSecondary,
      SubscriptionDayMarker.cancelled => AppColors.error,
      SubscriptionDayMarker.paused => AppColors.pausePurple,
      SubscriptionDayMarker.none => Colors.transparent,
    };
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.watch<AuthProvider>().isLoggedIn;
    final provider = context.watch<SubscriptionProvider>();

    if (!loggedIn) {
      return Scaffold(
        appBar: AppBar(title: Text('sub.title'.tr())),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.login, size: 64, color: context.colors.textHint),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'sub.loginPrompt'.tr(),
                  textAlign: TextAlign.center,
                  style: context.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xxl),
                FilledButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  child: Text('sub.goToLogin'.tr()),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (provider.loadingHistory &&
        provider.displaySubscriptions.isEmpty &&
        !provider.loadingCalendar) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final selectedSub = provider.selectedSubscription;
    final eventsOnSelected = provider.deliveriesOn(_selectedDay);
    final plans = provider.displaySubscriptions;

    return Scaffold(
      appBar: AppBar(
        title: Text('sub.title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.bootstrap(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.bootstrap(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            100,
          ),
          children: [
            if (provider.lastError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Material(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.small),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      provider.lastError!,
                      style: context.bodyMedium.copyWith(color: AppColors.error),
                    ),
                  ),
                ),
              ),
            if (selectedSub != null) ...[
              SubscriptionStatsRow(stats: selectedSub.mealStats),
              const SizedBox(height: AppSpacing.lg),
            ],
            Text('sub.calendar'.tr(), style: context.headingMedium),
            const SizedBox(height: AppSpacing.sm),
            const SubscriptionCalendarLegend(),
            const SizedBox(height: AppSpacing.sm),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.medium + 2),
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: TableCalendar<SubscriptionDeliverySummary>(
                  firstDay: DateTime.now().subtract(const Duration(days: 365)),
                  lastDay: DateTime.now().add(const Duration(days: 455)),
                  focusedDay: _focused,
                  selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
                  onDaySelected: (sel, foc) {
                    setState(() {
                      _selectedDay = _normalizeDay(sel);
                      _focused = foc;
                    });
                  },
                  onPageChanged: (foc) {
                    _focused = foc;
                    context.read<SubscriptionProvider>().reloadCalendarAround(foc);
                  },
                  calendarFormat: _calendarFormat,
                  onFormatChanged: (format) {
                    setState(() => _calendarFormat = format);
                  },
                  eventLoader: (day) => provider.deliveriesOn(_normalizeDay(day)),
                  headerStyle: HeaderStyle(
                    titleTextStyle: context.headingSmall,
                    formatButtonTextStyle: context.bodySmall,
                    leftChevronIcon: Icon(
                      Icons.chevron_left,
                      color: context.colors.textPrimary,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: context.bodySmall,
                    weekendStyle: context.bodySmall,
                  ),
                  calendarStyle: CalendarStyle(
                    defaultTextStyle: TextStyle(color: context.colors.textPrimary),
                    weekendTextStyle: TextStyle(color: context.colors.textPrimary),
                    outsideTextStyle: TextStyle(color: context.colors.textHint),
                    selectedTextStyle: const TextStyle(color: AppColors.white),
                    todayTextStyle: TextStyle(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: context.colors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focused) {
                      final marker = provider.calendarMarkerFor(
                        DateTime(day.year, day.month, day.day),
                      );
                      if (marker == SubscriptionDayMarker.none) return null;
                      final color = _markerColor(marker);
                      final outline = marker == SubscriptionDayMarker.pending;
                      return Container(
                        margin: const EdgeInsets.all(AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: outline ? Colors.transparent : color.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                          border: outline ? Border.all(color: color, width: 2) : null,
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              color: context.colors.textPrimary,
                              fontWeight: FontWeight.w600,
                              decoration: marker == SubscriptionDayMarker.skipped
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'sub.selectedDay'.tr(namedArgs: {
                'date':
                    '${_selectedDay.year}-${_selectedDay.month}-${_selectedDay.day}'
              }),
              style: context.headingMedium,
            ),
            ...eventsOnSelected.map((e) => _DeliveryTile(del: e)),
            if (eventsOnSelected.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  'sub.noMealsScheduled'.tr(),
                  style: context.bodyMedium,
                ),
              ),
            if (provider.loadingCalendar)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
            const SizedBox(height: 28),
            Text('sub.myPlans'.tr(), style: context.headingMedium),
            if (plans.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  provider.loadingHistory ? '' : 'sub.noSubscriptions'.tr(),
                  style: context.bodyMedium,
                ),
              )
            else
              ...plans.map(
                (s) => SubscriptionPlanCard(
                  subscription: s,
                  selected: s.id == provider.selectedSubscriptionId,
                  onTap: () {
                    provider.selectSubscription(s.id);
                    showSubscriptionManageSheet(context, subscription: s);
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showSubscriptionQuickCheckoutSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: Text('sub.subscribe'.tr()),
      ),
    );
  }
}

class _DeliveryTile extends StatelessWidget {
  const _DeliveryTile({required this.del});

  final SubscriptionDeliverySummary del;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<SubscriptionProvider>();
    final label = provider.humanDeliveryLabel(del.status);
    final color = switch (del.status.toUpperCase()) {
      'DELIVERED' => AppColors.darkGreen,
      'SKIPPED' || 'CANCELLED' || 'REJECTED' => context.colors.textSecondary,
      _ => context.colors.textPrimary,
    };
    final canTrack = del.linkedOrderId.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
      child: ListTile(
        title: Text(
          del.subscriptionTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.bodyLarge,
        ),
        subtitle: Text(
          '${del.kitchenName} · ${del.menuName}\n$label',
          style: context.bodyMedium.copyWith(color: color, height: 1.35),
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (del.isPending)
              TextButton(
                onPressed: () async {
                  try {
                    await AppServices.instance.subscriptionRepository.skipDelivery(
                      del.userSubscriptionId,
                      del.id,
                    );
                    if (context.mounted) {
                      await context.read<SubscriptionProvider>().reloadCalendarAround(
                            del.deliveryDate,
                          );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('sub.skipFailed'.tr(
                                namedArgs: {'error': friendlyErrorMessage(e)}))),
                      );
                    }
                  }
                },
                child: Text('sub.skip'.tr()),
              ),
            if (canTrack)
              TextButton(
                onPressed: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => OrderTrackingScreen(orderId: del.linkedOrderId),
                    ),
                  );
                },
                child: Text('sub.track'.tr()),
              ),
          ],
        ),
      ),
    );
  }
}
