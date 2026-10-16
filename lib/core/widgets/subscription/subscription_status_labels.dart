import 'package:easy_localization/easy_localization.dart';
import 'package:food_app/data/models/subscription_models.dart';

enum SubscriptionDayMarker {
  none,
  delivered,
  pending,
  inProgress,
  skipped,
  cancelled,
  paused,
}

class SubscriptionStatusLabels {
  static String subscriptionStatus(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return 'subStatus.active'.tr();
      case 'PAUSED':
        return 'subStatus.paused'.tr();
      case 'CANCELLED':
        return 'subStatus.cancelled'.tr();
      case 'COMPLETED':
        return 'subStatus.completed'.tr();
      case 'EXPIRED':
        return 'subStatus.expired'.tr();
      case 'PENDING_PAYMENT':
        return 'subStatus.paymentPending'.tr();
      default:
        return status;
    }
  }

  static String deliveryStatus(String status) {
    switch (status.toUpperCase()) {
      case 'DELIVERED':
        return 'deliveryStatus.delivered'.tr();
      case 'PENDING':
        return 'deliveryStatus.scheduled'.tr();
      case 'PENDING_PARTNER':
        return 'deliveryStatus.awaitingKitchen'.tr();
      case 'ACCEPTED':
        return 'deliveryStatus.accepted'.tr();
      case 'PREPARING':
        return 'deliveryStatus.preparing'.tr();
      case 'READY':
        return 'deliveryStatus.ready'.tr();
      case 'OUT_FOR_DELIVERY':
        return 'deliveryStatus.outForDelivery'.tr();
      case 'SKIPPED':
        return 'deliveryStatus.skipped'.tr();
      case 'CANCELLED':
        return 'deliveryStatus.cancelled'.tr();
      case 'REJECTED':
        return 'deliveryStatus.rejected'.tr();
      default:
        return status;
    }
  }

  static SubscriptionDayMarker dayMarker({
    required DateTime day,
    required List<SubscriptionDeliverySummary> deliveries,
    required UserSubscriptionSummary? subscription,
  }) {
    if (subscription != null && _isDayInPause(subscription, day)) {
      return SubscriptionDayMarker.paused;
    }
    if (deliveries.isEmpty) return SubscriptionDayMarker.none;

    if (deliveries.any((d) => d.isDelivered)) {
      return SubscriptionDayMarker.delivered;
    }
    if (deliveries.any((d) => d.isInProgress)) {
      return SubscriptionDayMarker.inProgress;
    }
    if (deliveries.any((d) => d.isPending)) {
      return SubscriptionDayMarker.pending;
    }
    if (deliveries.every((d) => d.status.toUpperCase() == 'SKIPPED')) {
      return SubscriptionDayMarker.skipped;
    }
    if (deliveries.any((d) => d.isNegative)) {
      return SubscriptionDayMarker.cancelled;
    }
    return SubscriptionDayMarker.pending;
  }

  static bool _isDayInPause(UserSubscriptionSummary sub, DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    for (final p in sub.pausePeriods) {
      final start = DateTime(p.start.year, p.start.month, p.start.day);
      final end = p.end != null
          ? DateTime(p.end!.year, p.end!.month, p.end!.day)
          : start;
      if (!d.isBefore(start) && !d.isAfter(end)) return true;
    }
    return false;
  }
}
