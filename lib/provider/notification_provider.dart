import 'package:flutter/foundation.dart';
import 'package:food_app/core/di/app_services.dart';
import 'package:food_app/data/models/app_notification.dart';

class NotificationProvider with ChangeNotifier {
  final _repo = AppServices.instance.notificationRepository;

  bool _loading = false;
  int _unreadCount = 0;
  List<AppNotification> _items = [];

  bool get loading => _loading;
  int get unreadCount => _unreadCount;
  List<AppNotification> get items => _items;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      final result = await _repo.list();
      _items = result.items;
      _unreadCount = result.unreadCount;
    } catch (_) {
      // Keep empty state on error
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void addFromSocket(Map<String, dynamic> payload) {
    final notification = AppNotification.fromJson(payload);
    if (_items.any((n) => n.id == notification.id)) return;
    _items = [notification, ..._items];
    if (!notification.isRead) {
      _unreadCount += 1;
    }
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    await _repo.markRead(id);
    _items = _items
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
    _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
    notifyListeners();
  }

  Future<void> markAllRead() async {
    await _repo.markAllRead();
    _items = _items.map((n) => n.copyWith(isRead: true)).toList();
    _unreadCount = 0;
    notifyListeners();
  }
}
