import 'package:food_app/core/utils/media_url.dart';

String _mongoId(dynamic v) {
  if (v == null) return '';
  if (v is Map) {
    final id = v['_id'];
    return id?.toString() ?? '';
  }
  return v.toString();
}

class UserOrderSummary {
  const UserOrderSummary({
    required this.id,
    required this.status,
    required this.orderType,
    required this.createdAt,
    required this.partnerName,
    required this.partnerAddress,
    required this.primaryItemName,
    required this.moreItemCount,
    required this.totalAmount,
    this.heroImageUrl,
  });

  final String id;
  final String status;
  final String orderType;
  final DateTime createdAt;
  final String partnerName;
  final String partnerAddress;
  final String primaryItemName;
  /// Lines beyond first (e.g. 2 → "+2 items").
  final int moreItemCount;
  final int totalAmount;
  final String? heroImageUrl;

  bool get isSubscription => orderType.toUpperCase() == 'SUBSCRIPTION';

  bool get isTerminal {
    switch (status.toUpperCase()) {
      case 'DELIVERED':
      case 'CANCELLED':
      case 'REFUNDED':
        return true;
      default:
        return false;
    }
  }

  factory UserOrderSummary.fromOrderJson(Map<String, dynamic> json) {
    final partner = json['partner'];
    String name = '';
    String addr = '';
    if (partner is Map) {
      name = partner['kitchenName']?.toString() ?? '';
      addr = partner['address']?.toString() ?? '';
    }

    final items = json['items'];
    String primaryName = 'Order';
    int more = 0;
    String? hero;
    if (items is List && items.isNotEmpty) {
      final first = items.first;
      if (first is Map) {
        primaryName = first['name']?.toString() ?? '';
        final menuSnap = first['menuItem'];
        if (menuSnap is Map && menuSnap['image'] != null) {
          hero = resolveMediaUrl(menuSnap['image']);
        }
      }
      more = items.length > 1 ? items.length - 1 : 0;
    }

    final pd = json['priceDetails'];
    int total = 0;
    if (pd is Map) {
      final t = pd['totalAmount'];
      if (t is num) total = t.round();
    }

    return UserOrderSummary(
      id: _mongoId(json['_id']),
      status: json['status']?.toString() ?? 'PLACED',
      orderType: json['orderType']?.toString() ?? 'INSTANT',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
              DateTime.now(),
      partnerName: name,
      partnerAddress: addr,
      primaryItemName: primaryName.isNotEmpty ? primaryName : 'Order',
      moreItemCount: more,
      totalAmount: total,
      heroImageUrl: hero,
    );
  }

  String get shortIdChip {
    if (id.length >= 6) return id.substring(id.length - 6).toUpperCase();
    return id.toUpperCase();
  }
}

class OrderLineItem {
  const OrderLineItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.imageUrl,
    this.menuItemDescription,
  });

  final String name;
  final int quantity;
  final int unitPrice;
  final int lineTotal;
  final String? imageUrl;
  final String? menuItemDescription;
}

class UserOrderPricing {
  const UserOrderPricing({
    required this.itemTotal,
    required this.tax,
    required this.deliveryCharge,
    required this.platformFee,
    required this.discount,
    required this.totalAmount,
  });

  final int itemTotal;
  final int tax;
  final int deliveryCharge;
  final int platformFee;
  final int discount;
  final int totalAmount;

  factory UserOrderPricing.fromJson(Map<String, dynamic>? pd) {
    if (pd == null) return const UserOrderPricing.empty();
    int n(dynamic x) => x is num ? x.round() : int.tryParse('$x') ?? 0;

    return UserOrderPricing(
      itemTotal: n(pd['itemTotal']),
      tax: n(pd['tax']),
      deliveryCharge: n(pd['deliveryCharge']),
      platformFee: n(pd['platformFee']),
      discount: n(pd['discount']),
      totalAmount: n(pd['totalAmount']),
    );
  }

  const UserOrderPricing.empty()
      : itemTotal = 0,
        tax = 0,
        deliveryCharge = 0,
        platformFee = 0,
        discount = 0,
        totalAmount = 0;
}

class UserOrderPayment {
  const UserOrderPayment({
    required this.method,
    required this.paymentStatus,
    this.gatewayOrderId,
  });

  final String method;
  final String paymentStatus;
  final String? gatewayOrderId;

  factory UserOrderPayment.fromJson(Map<String, dynamic>? p) {
    if (p == null) {
      return const UserOrderPayment(method: '', paymentStatus: '');
    }
    return UserOrderPayment(
      method: p['method']?.toString() ?? '',
      paymentStatus: p['paymentStatus']?.toString() ?? '',
      gatewayOrderId: p['gatewayOrderId']?.toString(),
    );
  }

  bool get isPaid => paymentStatus.toUpperCase() == 'PAID';
}

class UserOrderDetail {
  UserOrderDetail({
    required this.summary,
    required this.lineItems,
    required this.pricing,
    required this.payment,
    required this.deliveryFullAddress,
    required this.timeline,
    required this.partnerPhone,
    this.selfDelivery = false,
  });

  final UserOrderSummary summary;
  final List<OrderLineItem> lineItems;
  final UserOrderPricing pricing;
  final UserOrderPayment payment;
  final String deliveryFullAddress;
  final Map<String, dynamic> timeline;
  final String partnerPhone;
  final bool selfDelivery;

  factory UserOrderDetail.fromJson(Map<String, dynamic> json) {
    final summary = UserOrderSummary.fromOrderJson(json);
    final items = json['items'];
    final lines = <OrderLineItem>[];
    if (items is List) {
      for (final raw in items) {
        if (raw is Map) {
          final m = Map<String, dynamic>.from(raw);
          final qty = () {
            final q = m['quantity'];
            if (q is num) return q.round().clamp(1, 9999);
            return int.tryParse('${m['quantity']}') ?? 1;
          }();
          final price = () {
            final p = m['price'];
            if (p is num) return p.round();
            return int.tryParse('${m['price']}') ?? 0;
          }();
          String? hero;
          String? desc;
          final mi = m['menuItem'];
          if (mi is Map) {
            hero = resolveMediaUrl(mi['image']);
            desc = mi['description']?.toString();
          }
          final nm = m['name']?.toString() ?? 'Item';
          lines.add(
            OrderLineItem(
              name: nm,
              quantity: qty,
              unitPrice: price,
              lineTotal: price * qty,
              imageUrl: hero,
              menuItemDescription: desc?.isEmpty == true ? null : desc,
            ),
          );
        }
      }
    }

    final addrRaw = json['deliveryAddress'];
    String fullAddr = '';
    if (addrRaw is Map) {
      fullAddr = addrRaw['fullAddress']?.toString() ?? '';
    }

    final partner = json['partner'];
    String phone = '';
    if (partner is Map) {
      phone = partner['phone']?.toString() ?? '';
    }

    Map<String, dynamic> tl = {};
    if (json['timeline'] is Map) {
      tl = Map<String, dynamic>.from(json['timeline'] as Map);
    }

    return UserOrderDetail(
      summary: summary,
      lineItems: lines,
      pricing: UserOrderPricing.fromJson(
        json['priceDetails'] is Map
            ? Map<String, dynamic>.from(json['priceDetails'] as Map)
            : null,
      ),
      payment: UserOrderPayment.fromJson(
        json['payment'] is Map
            ? Map<String, dynamic>.from(json['payment'] as Map)
            : null,
      ),
      deliveryFullAddress: fullAddr,
      timeline: tl,
      partnerPhone: phone,
      selfDelivery: json['selfDelivery'] == true,
    );
  }

  DateTime? timelineAt(String key) {
    final v = timeline[key];
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  bool get userCanCancel {
    const ok = {'PLACED', 'ACCEPTED', 'PREPARING', 'READY'};
    return ok.contains(summary.status.toUpperCase());
  }

  factory UserOrderDetail.stubFromSummary(UserOrderSummary s) {
    return UserOrderDetail(
      summary: s,
      lineItems: const [],
      pricing: UserOrderPricing(
        totalAmount: s.totalAmount,
        itemTotal: 0,
        tax: 0,
        deliveryCharge: 0,
        platformFee: 0,
        discount: 0,
      ),
      payment: const UserOrderPayment(method: '', paymentStatus: ''),
      deliveryFullAddress: '',
      timeline: {},
      partnerPhone: '',
    );
  }
}

class OrdersPageResult {
  const OrdersPageResult({
    required this.orders,
    required this.page,
    required this.limit,
    required this.total,
  });

  final List<UserOrderSummary> orders;
  final int page;
  final int limit;
  final int total;

  bool get hasMore =>
      orders.isNotEmpty && (page - 1) * limit + orders.length < total;
}
