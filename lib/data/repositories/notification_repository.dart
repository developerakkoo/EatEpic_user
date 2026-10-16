import 'package:food_app/core/network/api_client.dart';
import 'package:food_app/data/models/app_notification.dart';

class NotificationRepository {
  NotificationRepository(this._api);

  final ApiClient _api;

  Future<({List<AppNotification> items, int unreadCount})> list({
    int page = 1,
    int limit = 30,
  }) async {
    final res = await _api.dio.get(
      '/api/user/notifications',
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = res.data['data'];
    final unread = (res.data['unreadCount'] as num?)?.toInt() ?? 0;
    if (data is List) {
      return (
        items: data
            .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        unreadCount: unread,
      );
    }
    return (items: <AppNotification>[], unreadCount: unread);
  }

  Future<void> markRead(String id) async {
    await _api.dio.patch('/api/user/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _api.dio.patch('/api/user/notifications/read-all');
  }
}
