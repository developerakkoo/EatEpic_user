import 'package:food_app/core/network/api_client.dart';
import 'package:food_app/data/models/support_message.dart';
import 'package:food_app/data/models/support_ticket.dart';

class SupportRepository {
  SupportRepository(this._api);

  final ApiClient _api;

  Future<SupportTicket> createTicket({
    required String subject,
    required String category,
    required String message,
  }) async {
    final res = await _api.dio.post(
      '/api/user/support/tickets',
      data: {
        'subject': subject,
        'category': category,
        'message': message,
      },
    );
    final data = res.data['data'] as Map;
    return SupportTicket.fromJson(Map<String, dynamic>.from(data['ticket'] as Map));
  }

  Future<List<SupportTicket>> listTickets({String? status}) async {
    final res = await _api.dio.get(
      '/api/user/support/tickets',
      queryParameters: {
        if (status != null) 'status': status,
      },
    );
    final data = res.data['data'];
    if (data is List) {
      return data
          .map((e) => SupportTicket.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return [];
  }

  Future<SupportTicket> getTicket(String id) async {
    final res = await _api.dio.get('/api/user/support/tickets/$id');
    final data = res.data['data'] as Map;
    return SupportTicket.fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<SupportMessage>> getMessages(String ticketId) async {
    final res = await _api.dio.get('/api/user/support/tickets/$ticketId/messages');
    final data = res.data['data'];
    if (data is List) {
      return data
          .map((e) => SupportMessage.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return [];
  }

  Future<SupportMessage> sendMessage(String ticketId, String body) async {
    final res = await _api.dio.post(
      '/api/user/support/tickets/$ticketId/messages',
      data: {'body': body},
    );
    final data = res.data['data'] as Map;
    return SupportMessage.fromJson(Map<String, dynamic>.from(data));
  }

  Future<SupportTicket> resolveTicket(String ticketId) async {
    final res = await _api.dio.patch('/api/user/support/tickets/$ticketId/resolve');
    final data = res.data['data'] as Map;
    return SupportTicket.fromJson(Map<String, dynamic>.from(data));
  }

  Future<SupportTicket> submitRating(
    String ticketId, {
    required int score,
    String? comment,
  }) async {
    final res = await _api.dio.post(
      '/api/user/support/tickets/$ticketId/rating',
      data: {
        'score': score,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
    );
    final data = res.data['data'] as Map;
    return SupportTicket.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> markRead(String ticketId) async {
    await _api.dio.patch('/api/user/support/tickets/$ticketId/read');
  }
}
