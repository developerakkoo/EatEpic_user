import 'package:flutter/foundation.dart';
import 'package:food_app/core/widgets/subscription/subscription_status_labels.dart';
import 'package:food_app/data/models/subscription_models.dart';
import 'package:food_app/data/repositories/subscription_repository.dart';

class SubscriptionProvider with ChangeNotifier {
  SubscriptionProvider(this._repo);

  final SubscriptionRepository _repo;

  bool loadingHistory = false;
  bool loadingCalendar = false;
  String? lastError;

  List<UserSubscriptionSummary> subscriptions = [];
  List<UserSubscriptionSummary> activeSubscriptions = [];
  Map<DateTime, List<SubscriptionDeliverySummary>> deliveriesByDay = {};
  String? selectedSubscriptionId;

  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  UserSubscriptionSummary? get selectedSubscription {
    if (selectedSubscriptionId == null) return null;
    for (final s in subscriptions) {
      if (s.id == selectedSubscriptionId) return s;
    }
    for (final s in activeSubscriptions) {
      if (s.id == selectedSubscriptionId) return s;
    }
    return null;
  }

  List<UserSubscriptionSummary> get displaySubscriptions =>
      subscriptions.isNotEmpty ? subscriptions : activeSubscriptions;

  Future<void> bootstrap() async {
    await Future.wait([
      refreshHistory(),
      reloadCalendarAround(DateTime.now()),
    ]);
  }

  void selectSubscription(String? id) {
    selectedSubscriptionId = id;
    notifyListeners();
  }

  void _ensureDefaultSelection() {
    if (selectedSubscriptionId != null) {
      final exists = displaySubscriptions.any((s) => s.id == selectedSubscriptionId);
      if (exists) return;
    }
    final active = displaySubscriptions.where((s) => s.isActiveLike).toList();
    if (active.isNotEmpty) {
      selectedSubscriptionId = active.first.id;
      return;
    }
    if (displaySubscriptions.isNotEmpty) {
      selectedSubscriptionId = displaySubscriptions.first.id;
    }
  }

  Future<void> refreshHistory() async {
    loadingHistory = true;
    lastError = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repo.fetchHistory(),
        _repo.fetchActive(),
      ]);
      subscriptions = results[0];
      activeSubscriptions = results[1];
      _ensureDefaultSelection();
    } catch (e) {
      lastError = e.toString();
      subscriptions = [];
      activeSubscriptions = [];
    } finally {
      loadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> reloadCalendarAround(DateTime focus) async {
    loadingCalendar = true;
    lastError = null;
    notifyListeners();
    try {
      final from = DateTime(focus.year, focus.month - 1, 1);
      final to = DateTime(focus.year, focus.month + 2, 0, 23, 59, 59);
      final list = await _repo.fetchDeliveriesBetween(from: from, to: to);
      final next = <DateTime, List<SubscriptionDeliverySummary>>{};
      for (final e in list) {
        final k = _dayKey(e.deliveryDate.toLocal());
        next.putIfAbsent(k, () => []).add(e);
      }
      deliveriesByDay = next;
    } catch (e) {
      lastError = e.toString();
      deliveriesByDay = {};
    } finally {
      loadingCalendar = false;
      notifyListeners();
    }
  }

  /// Applies a realtime "subscription_delivery_update" socket payload by
  /// patching the matching delivery in place, so status flips live without a
  /// full reload. Fields already enriched locally (kitchen/menu names) are
  /// preserved when the socket payload lacks them.
  void applyDeliveryUpdate(Map<String, dynamic> payload) {
    final raw = payload['delivery'] ?? payload;
    if (raw is! Map) return;
    final incoming =
        SubscriptionDeliverySummary.fromJson(Map<String, dynamic>.from(raw));
    if (incoming.id.isEmpty) return;

    var changed = false;
    final next = <DateTime, List<SubscriptionDeliverySummary>>{};
    deliveriesByDay.forEach((day, list) {
      next[day] = list.map((d) {
        if (d.id != incoming.id) return d;
        changed = true;
        return SubscriptionDeliverySummary(
          id: d.id,
          userSubscriptionId: d.userSubscriptionId,
          deliveryDate: d.deliveryDate,
          status: incoming.status.isNotEmpty ? incoming.status : d.status,
          linkedOrderId: incoming.linkedOrderId.isNotEmpty
              ? incoming.linkedOrderId
              : d.linkedOrderId,
          subscriptionTitle: d.subscriptionTitle.isNotEmpty
              ? d.subscriptionTitle
              : incoming.subscriptionTitle,
          linkedOrderStatus: incoming.linkedOrderStatus.isNotEmpty
              ? incoming.linkedOrderStatus
              : d.linkedOrderStatus,
          kitchenName:
              d.kitchenName.isNotEmpty ? d.kitchenName : incoming.kitchenName,
          menuName: d.menuName.isNotEmpty ? d.menuName : incoming.menuName,
        );
      }).toList();
    });

    if (changed) {
      deliveriesByDay = next;
      notifyListeners();
    }
  }

  /// Silently refreshes plan summaries when a subscription-level event
  /// (activated, paused, cancelled, renewal) arrives over the socket.
  Future<void> refreshOnSubscriptionEvent() async {
    try {
      final results = await Future.wait([
        _repo.fetchHistory(),
        _repo.fetchActive(),
      ]);
      subscriptions = results[0];
      activeSubscriptions = results[1];
      _ensureDefaultSelection();
      notifyListeners();
    } catch (_) {
      // Keep current state; the next manual refresh will recover.
    }
  }

  List<SubscriptionDeliverySummary> deliveriesOn(DateTime day) {
    final all = deliveriesByDay[_dayKey(day)] ?? const [];
    if (selectedSubscriptionId == null) return all;
    return all.where((d) => d.userSubscriptionId == selectedSubscriptionId).toList();
  }

  List<SubscriptionDeliverySummary> allDeliveriesOn(DateTime day) =>
      deliveriesByDay[_dayKey(day)] ?? const [];

  SubscriptionDayMarker calendarMarkerFor(DateTime day) {
    final sub = selectedSubscription;
    return SubscriptionStatusLabels.dayMarker(
      day: day,
      deliveries: deliveriesOn(day),
      subscription: sub,
    );
  }

  bool hasDeliveredOn(DateTime day) =>
      deliveriesOn(day).any((e) => e.isDelivered);

  bool hasNegativeOn(DateTime day) =>
      deliveriesOn(day).any((e) => e.isNegative);

  String humanStatusLabel(String status) =>
      SubscriptionStatusLabels.subscriptionStatus(status);

  String humanDeliveryLabel(String status) =>
      SubscriptionStatusLabels.deliveryStatus(status);
}
