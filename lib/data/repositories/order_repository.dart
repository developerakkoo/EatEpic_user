import 'package:dio/dio.dart';
import 'package:food_app/core/network/api_client.dart';
import 'package:food_app/data/models/user_order_models.dart';

class OrderRatingResult {
  const OrderRatingResult({
    required this.partnerRating,
    this.deliveryRating,
    required this.review,
    this.kitchenId,
    this.averageRating = 0,
    this.totalReviews = 0,
  });

  final int partnerRating;
  final int? deliveryRating;
  final String review;
  final String? kitchenId;
  final double averageRating;
  final int totalReviews;
}

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

  Future<OrderRatingResult> rateOrder({
    required String orderId,
    required int partnerRating,
    int? deliveryRating,
    String review = '',
  }) async {
    final response = await _api.dio.post(
      '/api/order/$orderId/rate',
      data: {
        'partnerRating': partnerRating,
        if (deliveryRating != null) 'deliveryRating': deliveryRating,
        'review': review,
      },
    );
    final body = response.data;
    final map = body is Map ? Map<String, dynamic>.from(body) : <String, dynamic>{};
    final summary = map['ratingSummary'];
    final summaryMap = summary is Map
        ? Map<String, dynamic>.from(summary)
        : const <String, dynamic>{};
    final data = map['data'];
    final dataMap = data is Map ? Map<String, dynamic>.from(data) : const <String, dynamic>{};
    final savedStars = dataMap['partnerRating'];
    final savedReview = dataMap['review'];
    final average = summaryMap['averageRating'];
    final total = summaryMap['totalReviews'];
    return OrderRatingResult(
      partnerRating: savedStars is num ? savedStars.round() : partnerRating,
      deliveryRating: deliveryRating,
      review: savedReview is String ? savedReview : review,
      kitchenId: map['partnerId']?.toString(),
      averageRating: average is num ? average.toDouble() : 0,
      totalReviews: total is num ? total.round() : 0,
    );
  }
}
