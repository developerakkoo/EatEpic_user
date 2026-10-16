import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';

class OrderTrackingProvider with ChangeNotifier {
  String? activeOrderId;
  String internalStatus = 'PLACED';
  String displayStatus = 'ORDER_RECEIVED';
  String title = 'orderStatus.placed'.tr();
  String subtitle = 'trackSubtitle.placed'.tr();
  int progressIndex = 0;
  final int progressTotal = 6;
  Map<String, dynamic> timeline = {};
  bool selfDelivery = false;

  void applySocketUpdate(Map<String, dynamic> payload) {
    activeOrderId = payload['orderId']?.toString();
    internalStatus = payload['internalStatus']?.toString() ?? internalStatus;
    displayStatus = payload['displayStatus']?.toString() ?? displayStatus;
    title = payload['title']?.toString() ?? title;
    subtitle = payload['subtitle']?.toString() ?? subtitle;
    if (payload['selfDelivery'] == true) {
      selfDelivery = true;
    }
    progressIndex = payload['progressIndex'] is int
        ? payload['progressIndex'] as int
        : progressIndex;
    if (payload['timeline'] is Map) {
      timeline = Map<String, dynamic>.from(payload['timeline'] as Map);
    }
    notifyListeners();
  }

  void setActiveOrder(String orderId) {
    if (activeOrderId != orderId) {
      internalStatus = 'PLACED';
      displayStatus = 'ORDER_RECEIVED';
      title = 'orderStatus.placed'.tr();
      subtitle = 'trackSubtitle.placed'.tr();
      progressIndex = 0;
      timeline = {};
      selfDelivery = false;
    }
    activeOrderId = orderId;
    notifyListeners();
  }

  void seedFromOrder(Map<String, dynamic> order) {
    final status = order['status']?.toString() ?? 'PLACED';
    final isSelfDelivery = order['selfDelivery'] == true;
    activeOrderId = order['_id']?.toString() ?? activeOrderId;
    internalStatus = status;
    selfDelivery = isSelfDelivery;
    displayStatus = _displayStatus(status);
    title = _title(status);
    subtitle = _subtitle(status, selfDelivery: isSelfDelivery);
    progressIndex = _progressIndex(status);
    if (order['timeline'] is Map) {
      timeline = Map<String, dynamic>.from(order['timeline'] as Map);
    }
    notifyListeners();
  }

  void clear() {
    activeOrderId = null;
    notifyListeners();
  }

  String _displayStatus(String status) {
    const map = {
      'PLACED': 'ORDER_RECEIVED',
      'ACCEPTED': 'ACCEPTED',
      'PREPARING': 'PROCESSING',
      'READY': 'READY_FOR_PICKUP',
      'OUT_FOR_DELIVERY': 'ON_ROUTE',
      'DELIVERED': 'DELIVERED',
      'CANCELLED': 'CANCELLED',
    };
    return map[status] ?? status;
  }

  String _title(String status) {
    const map = {
      'PLACED': 'orderStatus.placed',
      'ACCEPTED': 'orderStatus.confirmed',
      'PREPARING': 'orderStatus.preparing',
      'READY': 'orderStatus.ready',
      'OUT_FOR_DELIVERY': 'orderStatus.onTheWay',
      'DELIVERED': 'orderStatus.delivered',
      'CANCELLED': 'deliveryStatus.cancelled',
    };
    final key = map[status];
    return key != null ? key.tr() : status;
  }

  String _subtitle(String status, {bool selfDelivery = false}) {
    const map = {
      'PLACED': 'trackSubtitle.placed',
      'ACCEPTED': 'trackSubtitle.accepted',
      'PREPARING': 'trackSubtitle.preparing',
      'READY': 'trackSubtitle.ready',
      'OUT_FOR_DELIVERY': 'trackSubtitle.outForDelivery',
      'DELIVERED': 'trackSubtitle.delivered',
      'CANCELLED': 'trackSubtitle.cancelled',
    };
    const selfDeliveryMap = {
      'READY': 'trackSubtitle.readySelfDelivery',
      'OUT_FOR_DELIVERY': 'trackSubtitle.outForDeliverySelfDelivery',
    };
    if (selfDelivery && selfDeliveryMap.containsKey(status)) {
      return selfDeliveryMap[status]!.tr();
    }
    final key = map[status];
    return key != null ? key.tr() : '';
  }

  int _progressIndex(String status) {
    const map = {
      'PLACED': 0,
      'ACCEPTED': 1,
      'PREPARING': 2,
      'READY': 3,
      'OUT_FOR_DELIVERY': 4,
      'DELIVERED': 5,
      'CANCELLED': -1,
    };
    return map[status] ?? 0;
  }
}
