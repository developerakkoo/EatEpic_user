import 'package:dio/dio.dart';
import 'package:food_app/core/network/api_client.dart';
import 'package:food_app/data/models/subscription_models.dart';

class SubscriptionPurchaseResult {
  const SubscriptionPurchaseResult({
    required this.subscriptionSnapshot,
    this.razorpayOrder,
    this.stripeClientSecretHint,
    this.gatewayPaymentIntentId,
  });

  final UserSubscriptionSummary subscriptionSnapshot;
  final Map<String, dynamic>? razorpayOrder;
  final String? stripeClientSecretHint;
  final String? gatewayPaymentIntentId;
}

class SubscriptionRepository {
  SubscriptionRepository(this._api);

  final ApiClient _api;

  Future<List<SubscriptionPlanDto>> fetchPlans({
    String? kitchenId,
    String? menuItemId,
    String? mealType,
    String? planType,
  }) async {
    final qp = <String, dynamic>{
      if (kitchenId != null && kitchenId.isNotEmpty) 'kitchenId': kitchenId,
      if (menuItemId != null && menuItemId.isNotEmpty) 'menuItemId': menuItemId,
      if (mealType != null && mealType.isNotEmpty) 'mealType': mealType,
      if (planType != null && planType.isNotEmpty) 'planType': planType,
    };
    final res = await _api.dio.get(
      '/api/user/subscriptions/plans',
      queryParameters: qp,
    );
    final list = res.data['data'] as List<dynamic>? ?? [];
    return list
        .whereType<Map>()
        .map((e) =>
            SubscriptionPlanDto.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<SubscriptionPurchaseResult> purchase({
    required String planId,
    required DateTime startDate,
    required String paymentMethod,
    String? addressId,
    bool autoRenew = false,
    String? idempotencyKey,
  }) async {
    final res = await _api.dio.post(
      '/api/user/subscriptions/purchase',
      data: {
        'planId': planId,
        'startDate': _dateOnly(startDate),
        'paymentMethod': paymentMethod,
        if (addressId != null) 'addressId': addressId,
        'autoRenew': autoRenew,
        if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
      },
    );
    final body = Map<String, dynamic>.from(res.data as Map);
    final row = _unwrapDataRow(body);
    final summary = UserSubscriptionSummary.fromJson(row);
    Map<String, dynamic>? razorpay;
    if (body['razorpayOrder'] is Map) {
      razorpay = Map<String, dynamic>.from(body['razorpayOrder'] as Map);
    }
    String? stripeHint;
    String? intentId;
    if (body['stripePaymentIntent'] is Map) {
      final sp = Map<String, dynamic>.from(body['stripePaymentIntent'] as Map);
      stripeHint = sp['clientSecret']?.toString();
      intentId = sp['id']?.toString();
    }
    return SubscriptionPurchaseResult(
      subscriptionSnapshot: summary,
      razorpayOrder: razorpay,
      stripeClientSecretHint: stripeHint,
      gatewayPaymentIntentId: intentId,
    );
  }

  Future<List<UserSubscriptionSummary>> fetchHistory() async {
    final res = await _api.dio.get('/api/user/subscriptions/history');
    final list = res.data['data'] as List<dynamic>? ?? [];
    return _mapSubscriptions(list);
  }

  Future<List<UserSubscriptionSummary>> fetchActive() async {
    final res = await _api.dio.get('/api/user/subscriptions/active');
    final list = res.data['data'] as List<dynamic>? ?? [];
    return _mapSubscriptions(list);
  }

  List<UserSubscriptionSummary> _mapSubscriptions(List<dynamic> list) {
    return list
        .whereType<Map>()
        .map((e) =>
            UserSubscriptionSummary.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<SubscriptionDeliverySummary>> fetchDeliveriesBetween({
    required DateTime from,
    required DateTime to,
  }) async {
    final res = await _api.dio.get(
      '/api/user/subscriptions/deliveries',
      queryParameters: {
        'from': _dateOnly(from),
        'to': _dateOnly(to),
      },
    );
    final list = res.data['data'] as List<dynamic>? ?? [];
    return list
        .whereType<Map>()
        .map((e) => SubscriptionDeliverySummary.fromJson(
            Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<SubscriptionTransactionDto>> fetchTransactions({
    String? subscriptionId,
  }) async {
    final res = await _api.dio.get(
      '/api/user/subscriptions/transactions',
      queryParameters: {
        if (subscriptionId != null && subscriptionId.isNotEmpty)
          'subscriptionId': subscriptionId,
      },
    );
    final list = res.data['data'] as List<dynamic>? ?? [];
    return list
        .whereType<Map>()
        .map((e) => SubscriptionTransactionDto.fromJson(
            Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<PausePreview> fetchPausePreview(
    String subscriptionId, {
    DateTime? start,
    required DateTime end,
  }) async {
    final res = await _api.dio.get(
      '/api/user/subscriptions/$subscriptionId/pause-preview',
      queryParameters: {
        if (start != null) 'start': start.toIso8601String(),
        'end': end.toIso8601String(),
      },
    );
    final data = Map<String, dynamic>.from(res.data['data'] as Map);
    return PausePreview.fromJson(data);
  }

  Future<CancelPreview> fetchCancelPreview(String subscriptionId) async {
    final res = await _api.dio.get(
      '/api/user/subscriptions/$subscriptionId/cancel-preview',
    );
    final data = Map<String, dynamic>.from(res.data['data'] as Map);
    return CancelPreview.fromJson(data);
  }

  Future<CancelSubscriptionResult> cancelWithResult(String subscriptionId) async {
    final res = await _api.dio.post(
      '/api/user/subscriptions/$subscriptionId/cancel',
    );
    final body = Map<String, dynamic>.from(res.data as Map);
    final sub = UserSubscriptionSummary.fromJson(
      Map<String, dynamic>.from(body['data'] as Map),
    );
    CancelPreview? refund;
    if (body['refund'] is Map) {
      refund = CancelPreview.fromJson(
        Map<String, dynamic>.from(body['refund'] as Map),
      );
    }
    return CancelSubscriptionResult(subscription: sub, refund: refund);
  }

  Future<void> cancel(String subscriptionId) async {
    await cancelWithResult(subscriptionId);
  }

  Future<void> markPaymentComplete(String subscriptionId) async {
    await _api.dio.post(
      '/api/user/subscriptions/$subscriptionId/confirm-payment',
      data: {'gateway': 'MARK_PAID'},
    );
  }

  Future<void> confirmStripe({
    required String subscriptionId,
    required String stripePaymentIntentId,
  }) async {
    await _api.dio.post(
      '/api/user/subscriptions/$subscriptionId/confirm-payment',
      data: {
        'gateway': 'STRIPE',
        'stripe_payment_intent_id': stripePaymentIntentId,
      },
    );
  }

  Future<void> pause(String subscriptionId, {DateTime? start, DateTime? end}) async {
    await _api.dio.post(
      '/api/user/subscriptions/$subscriptionId/pause',
      data: {
        if (start != null) 'start': start.toIso8601String(),
        if (end != null) 'end': end.toIso8601String(),
      },
    );
  }

  Future<void> resume(String subscriptionId) async {
    await _api.dio.post('/api/user/subscriptions/$subscriptionId/resume');
  }

  Future<void> skipDelivery(String subscriptionId, String deliveryId) async {
    await _api.dio.post(
      '/api/user/subscriptions/$subscriptionId/deliveries/$deliveryId/skip',
    );
  }

  Future<void> updateAddress(String subscriptionId, String addressId) async {
    await _api.dio.patch(
      '/api/user/subscriptions/$subscriptionId/address',
      data: {'addressId': addressId},
    );
  }

  Future<void> renew(String subscriptionId) async {
    await _api.dio.post('/api/user/subscriptions/$subscriptionId/renew');
  }

  Future<void> upgrade(String subscriptionId, String planId) async {
    await _api.dio.post(
      '/api/user/subscriptions/$subscriptionId/upgrade',
      data: {'planId': planId},
    );
  }

  String _dateOnly(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  Map<String, dynamic> _unwrapDataRow(dynamic body) {
    if (body is Map && body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    if (body is Map) return Map<String, dynamic>.from(body);
    throw DioException(
      requestOptions: RequestOptions(),
      message: 'Unexpected subscription purchase response shape',
    );
  }
}
