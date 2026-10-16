String _mongoId(dynamic v) {
  if (v == null) return '';
  if (v is Map) {
    final id = v['_id'] ?? v['id'];
    return id?.toString() ?? '';
  }
  return v.toString();
}

class SubscriptionPlanDto {
  const SubscriptionPlanDto({
    required this.id,
    required this.title,
    required this.partnerId,
    required this.menuItemId,
    required this.durationInDays,
    required this.pricePerMeal,
    required this.totalPrice,
    this.kitchenName,
    this.menuName,
    this.menuImage,
    this.price,
    this.discountedPrice,
    this.planType,
    this.mealTypes = const [],
    this.isVeg = true,
    this.description,
  });

  int get displayPrice => discountedPrice ?? totalPrice;

  final String id;
  final String title;
  final String partnerId;
  final String menuItemId;
  final int durationInDays;
  final int pricePerMeal;
  final int totalPrice;
  final String? kitchenName;
  final String? menuName;
  final String? menuImage;
  /// Menu item baseline price when present (marketing only).
  final int? price;
  final int? discountedPrice;
  final String? planType;
  final List<String> mealTypes;
  final bool isVeg;
  final String? description;

  factory SubscriptionPlanDto.fromJson(Map<String, dynamic> json) {
    final partner = json['partnerId'];
    final menuItem = json['menuItemId'];
    return SubscriptionPlanDto(
      id: _mongoId(json['_id']),
      title: json['title']?.toString() ?? 'Plan',
      partnerId: _mongoId(partner),
      menuItemId: _mongoId(menuItem),
      durationInDays: (json['durationInDays'] is num)
          ? (json['durationInDays'] as num).round()
          : int.tryParse('${json['durationInDays']}') ?? 0,
      pricePerMeal: _toMoneyInt(json['pricePerMeal']),
      totalPrice: _toMoneyInt(json['totalPrice']),
      kitchenName: partner is Map ? partner['kitchenName']?.toString() : null,
      menuName: menuItem is Map ? menuItem['name']?.toString() : null,
      menuImage: menuItem is Map ? menuItem['image']?.toString() : null,
      price: menuItem is Map ? _toMoneyIntNullable(menuItem['price']) : null,
      discountedPrice: _toMoneyIntNullable(json['discountedPrice']),
      planType: json['planType']?.toString(),
      mealTypes: (json['mealTypes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isVeg: json['isVeg'] != false,
      description: json['description']?.toString(),
    );
  }

  static int _toMoneyInt(dynamic v) {
    if (v is num) return v.round();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static int? _toMoneyIntNullable(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.round();
    return int.tryParse(v.toString());
  }
}

class MealStats {
  const MealStats({
    this.delivered = 0,
    this.pending = 0,
    this.skipped = 0,
    this.cancelled = 0,
    this.remaining = 0,
    this.totalMeals = 0,
  });

  final int delivered;
  final int pending;
  final int skipped;
  final int cancelled;
  final int remaining;
  final int totalMeals;

  factory MealStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MealStats();
    int n(dynamic v) =>
        v is num ? v.round() : int.tryParse(v?.toString() ?? '') ?? 0;
    return MealStats(
      delivered: n(json['delivered']),
      pending: n(json['pending']),
      skipped: n(json['skipped']),
      cancelled: n(json['cancelled']),
      remaining: n(json['remaining']),
      totalMeals: n(json['totalMeals']),
    );
  }
}

class PausePeriod {
  const PausePeriod({required this.start, this.end, this.reason});

  final DateTime start;
  final DateTime? end;
  final String? reason;

  factory PausePeriod.fromJson(Map<String, dynamic> json) {
    return PausePeriod(
      start: DateTime.tryParse(json['start']?.toString() ?? '') ?? DateTime.now(),
      end: json['end'] != null
          ? DateTime.tryParse(json['end']?.toString() ?? '')
          : null,
      reason: json['reason']?.toString(),
    );
  }
}

class PausePreview {
  const PausePreview({
    required this.shiftedMeals,
    required this.newEndDate,
    required this.pauseDaysUsed,
    required this.maxPauseDays,
  });

  final int shiftedMeals;
  final DateTime newEndDate;
  final int pauseDaysUsed;
  final int maxPauseDays;

  factory PausePreview.fromJson(Map<String, dynamic> json) {
    return PausePreview(
      shiftedMeals: (json['shiftedMeals'] is num)
          ? (json['shiftedMeals'] as num).round()
          : int.tryParse('${json['shiftedMeals']}') ?? 0,
      newEndDate: DateTime.tryParse(json['newEndDate']?.toString() ?? '') ??
          DateTime.now(),
      pauseDaysUsed: (json['pauseDaysUsed'] is num)
          ? (json['pauseDaysUsed'] as num).round()
          : int.tryParse('${json['pauseDaysUsed']}') ?? 0,
      maxPauseDays: (json['maxPauseDays'] is num)
          ? (json['maxPauseDays'] as num).round()
          : int.tryParse('${json['maxPauseDays']}') ?? 30,
    );
  }
}

class CancelPreview {
  const CancelPreview({
    required this.eligibleMeals,
    required this.grossRefund,
    required this.cancellationFee,
    required this.netRefund,
    this.cancellationFeePercent = 0,
    this.alreadyRefunded = false,
  });

  final int eligibleMeals;
  final int grossRefund;
  final int cancellationFee;
  final int netRefund;
  final int cancellationFeePercent;
  final bool alreadyRefunded;

  factory CancelPreview.fromJson(Map<String, dynamic> json) {
    int n(dynamic v) =>
        v is num ? v.round() : int.tryParse(v?.toString() ?? '') ?? 0;
    return CancelPreview(
      eligibleMeals: n(json['eligibleMeals']),
      grossRefund: n(json['grossRefund']),
      cancellationFee: n(json['cancellationFee']),
      netRefund: n(json['netRefund']),
      cancellationFeePercent: n(json['cancellationFeePercent']),
      alreadyRefunded: json['alreadyRefunded'] == true,
    );
  }
}

class CancelSubscriptionResult {
  const CancelSubscriptionResult({
    required this.subscription,
    this.refund,
  });

  final UserSubscriptionSummary subscription;
  final CancelPreview? refund;
}

class UserSubscriptionSummary {
  const UserSubscriptionSummary({
    required this.id,
    required this.title,
    required this.status,
    required this.partnerName,
    required this.menuName,
    required this.pricePerMeal,
    required this.totalPrice,
    required this.durationInDays,
    required this.startDate,
    required this.endDate,
    this.autoRenew = false,
    this.paymentStatus,
    this.mealStats = const MealStats(),
    this.pausePeriods = const [],
  });

  final String id;
  final String title;
  final String status;
  final String partnerName;
  final String menuName;
  final int pricePerMeal;
  final int totalPrice;
  final int durationInDays;
  final DateTime startDate;
  final DateTime endDate;
  final bool autoRenew;
  final String? paymentStatus;
  final MealStats mealStats;
  final List<PausePeriod> pausePeriods;

  bool get isActiveLike =>
      status == 'ACTIVE' || status == 'PAUSED' || status == 'PENDING_PAYMENT';

  PausePeriod? get activePause {
    if (status != 'PAUSED') return null;
    if (pausePeriods.isEmpty) return null;
    return pausePeriods.last;
  }

  factory UserSubscriptionSummary.fromJson(Map<String, dynamic> json) {
    final partner = json['partnerId'];
    final menuItem = json['menuItemId'];
    final payment = json['payment'];
    final pauseRaw = json['pausePeriods'] as List<dynamic>? ?? [];
    return UserSubscriptionSummary(
      id: _mongoId(json['_id']),
      title: json['title']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      partnerName:
          partner is Map ? partner['kitchenName']?.toString() ?? '' : '',
      menuName: menuItem is Map ? menuItem['name']?.toString() ?? '' : '',
      pricePerMeal: SubscriptionPlanDto._toMoneyInt(json['pricePerMeal']),
      totalPrice: SubscriptionPlanDto._toMoneyInt(json['totalPrice']),
      durationInDays: (json['durationInDays'] is num)
          ? (json['durationInDays'] as num).round()
          : int.tryParse('${json['durationInDays']}') ?? 0,
      startDate: DateTime.tryParse(json['startDate']?.toString() ?? '') ??
          DateTime.now(),
      endDate:
          DateTime.tryParse(json['endDate']?.toString() ?? '') ?? DateTime.now(),
      autoRenew: json['autoRenew'] == true,
      paymentStatus: payment is Map ? payment['paymentStatus']?.toString() : null,
      mealStats: MealStats.fromJson(
        json['mealStats'] is Map
            ? Map<String, dynamic>.from(json['mealStats'] as Map)
            : null,
      ),
      pausePeriods: pauseRaw
          .whereType<Map>()
          .map((e) => PausePeriod.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

/// Linked snapshot from Order when populated.
class LinkedOrderSnapshot {
  const LinkedOrderSnapshot({required this.id, required this.status});

  final String id;
  final String status;

  factory LinkedOrderSnapshot.fromMaybe(dynamic raw) {
    if (raw == null) return const LinkedOrderSnapshot(id: '', status: '');
    if (raw is String) {
      return LinkedOrderSnapshot(id: raw, status: '');
    }
    if (raw is Map) {
      return LinkedOrderSnapshot(
        id: _mongoId(raw['_id']),
        status: raw['status']?.toString() ?? '',
      );
    }
    return const LinkedOrderSnapshot(id: '', status: '');
  }
}

class SubscriptionDeliverySummary {
  const SubscriptionDeliverySummary({
    required this.id,
    required this.userSubscriptionId,
    required this.deliveryDate,
    required this.status,
    required this.linkedOrderId,
    required this.subscriptionTitle,
    required this.linkedOrderStatus,
    required this.kitchenName,
    required this.menuName,
  });

  final String id;
  final String userSubscriptionId;
  final DateTime deliveryDate;
  final String status;
  final String linkedOrderId;
  final String subscriptionTitle;
  final String linkedOrderStatus;
  final String kitchenName;
  final String menuName;

  factory SubscriptionDeliverySummary.fromJson(Map<String, dynamic> json) {
    final linked = LinkedOrderSnapshot.fromMaybe(json['linkedOrderId']);
    final subRaw = json['userSubscriptionId'];
    var title = '';
    var kit = '';
    var menuName = '';
    var subId = _mongoId(subRaw);
    if (subRaw is Map) {
      title = subRaw['title']?.toString() ?? '';
      subId = _mongoId(subRaw['_id']);
      final p = subRaw['partnerId'];
      if (p is Map) {
        kit = p['kitchenName']?.toString() ?? '';
      }
      final m = subRaw['menuItemId'];
      if (m is Map) {
        menuName = m['name']?.toString() ?? '';
      }
    }
    return SubscriptionDeliverySummary(
      id: _mongoId(json['_id']),
      userSubscriptionId: subId,
      deliveryDate:
          DateTime.tryParse(json['deliveryDate']?.toString() ?? '') ??
              DateTime.now(),
      status: json['status']?.toString() ?? '',
      linkedOrderId: linked.id,
      subscriptionTitle: title,
      linkedOrderStatus: linked.status,
      kitchenName: kit,
      menuName: menuName,
    );
  }

  bool get isDelivered => status == 'DELIVERED';

  bool get isNegative =>
      {'SKIPPED', 'CANCELLED', 'REJECTED'}.contains(status.toUpperCase());

  bool get isPending =>
      {'PENDING', 'PENDING_PARTNER'}.contains(status.toUpperCase());

  bool get isInProgress => {
        'ACCEPTED',
        'PREPARING',
        'READY',
        'OUT_FOR_DELIVERY',
      }.contains(status.toUpperCase());
}

class SubscriptionTransactionDto {
  const SubscriptionTransactionDto({
    required this.id,
    required this.type,
    required this.amount,
    required this.paymentStatus,
    required this.createdAt,
  });

  final String id;
  final String type;
  final int amount;
  final String paymentStatus;
  final DateTime createdAt;

  factory SubscriptionTransactionDto.fromJson(Map<String, dynamic> json) {
    return SubscriptionTransactionDto(
      id: _mongoId(json['_id']),
      type: json['type']?.toString() ?? '',
      amount: SubscriptionPlanDto._toMoneyInt(json['amount']),
      paymentStatus: json['paymentStatus']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
