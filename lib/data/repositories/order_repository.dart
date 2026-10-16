import 'package:dio/dio.dart';
import 'package:food_app/core/network/api_client.dart';
import 'package:food_app/data/models/user_order_models.dart';

class OrderRepository {
  OrderRepository(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> createOrder({
    required String addressId,
    required String paymentMethod,
    String? idempotencyKey,
  }) async {
    final res = await _api.dio.post(
      '/api/order/create',
      data: {
        'addressId': addressId,
        'paymentMethod': paymentMethod,
        if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
      },
      options: idempotencyKey == null
          ? null
          : Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> confirmPayment({
    required String orderId,
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) async {
    final res = await _api.dio.post(
      '/api/order/confirm-payment',
      data: {
        'orderId': orderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_order_id': razorpayOrderId,
        'razorpay_signature': razorpaySignature,
      },
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<List<Map<String, dynamic>>> myOrders({
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _api.dio.get(
      '/api/order/my-orders',
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = res.data['data'];
    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  Future<OrdersPageResult> fetchMyOrdersPage({
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _api.dio.get(
      '/api/order/my-orders',
      queryParameters: {'page': page, 'limit': limit},
    );

    final data = res.data['data'];
    final pg = res.data['pagination'];

    final pageNum = pg is Map ? (pg['page'] as num?)?.round() ?? page : page;
    final limitNum = pg is Map
        ? (pg['limit'] as num?)?.round() ?? limit
        : limit;
    final total = pg is Map ? (pg['total'] as num?)?.round() ?? 0 : 0;

    final list = <UserOrderSummary>[];
    if (data is List) {
      for (final e in data) {
        if (e is Map) {
          list.add(
            UserOrderSummary.fromOrderJson(Map<String, dynamic>.from(e)),
          );
        }
      }
    }

    return OrdersPageResult(
      orders: list,
      page: pageNum,
      limit: limitNum,
      total: total,
    );
  }

  Future<UserOrderDetail> fetchMyOrderDetail(String orderId) async {
    final raw = await orderDetails(orderId);
    return UserOrderDetail.fromJson(raw);
  }

  Future<Map<String, dynamic>> orderDetails(String orderId) async {
    final res = await _api.dio.get('/api/order/my-orders/$orderId');
    return Map<String, dynamic>.from(
      res.data['data'] as Map? ?? res.data as Map,
    );
  }

  Future<void> cancelOrder(String orderId, {String? reason}) async {
    await _api.dio.patch(
      '/api/order/cancel/$orderId',
      data: {if (reason != null) 'reason': reason},
    );
  }
}
