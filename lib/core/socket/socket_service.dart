import 'package:food_app/core/config/app_config.dart';
import 'package:food_app/core/storage/token_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

typedef CatalogUpdatedCallback = void Function(Map<String, dynamic> payload);
typedef OrderUpdateCallback = void Function(Map<String, dynamic> payload);
typedef SupportMessageCallback = void Function(Map<String, dynamic> payload);
typedef SupportTicketUpdatedCallback = void Function(Map<String, dynamic> payload);
typedef UserNotificationCallback = void Function(Map<String, dynamic> payload);
typedef SubscriptionDeliveryUpdateCallback = void Function(Map<String, dynamic> payload);
typedef SubscriptionNotificationCallback = void Function(Map<String, dynamic> payload);

class SocketService {
  SocketService(this._tokenStorage);

  final TokenStorage _tokenStorage;
  io.Socket? _socket;
  CatalogUpdatedCallback? onCatalogUpdated;
  OrderUpdateCallback? onOrderUpdate;
  OrderUpdateCallback? onDeliveryLocation;
  SupportMessageCallback? onSupportMessage;
  SupportTicketUpdatedCallback? onSupportTicketUpdated;
  UserNotificationCallback? onUserNotification;
  SubscriptionDeliveryUpdateCallback? onSubscriptionDeliveryUpdate;
  SubscriptionNotificationCallback? onSubscriptionNotification;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    final token = await _tokenStorage.getAccessToken();
    final userId = await _tokenStorage.getUserId();
    if (token == null || userId == null) return;

    _socket?.dispose();
    _socket = io.io(
      AppConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token, 'role': 'USER'})
          .disableAutoConnect()
          .build(),
    );

    _socket!
      ..onConnect((_) {
        _socket?.emit('join_user', userId);
      })
      ..on('catalog_updated', (data) {
        if (data is Map) {
          onCatalogUpdated?.call(Map<String, dynamic>.from(data));
        }
      })
      ..on('order_update', (data) {
        if (data is Map) {
          onOrderUpdate?.call(Map<String, dynamic>.from(data));
        }
      })
      ..on('order_status_update', (data) {
        if (data is Map) {
          onOrderUpdate?.call(Map<String, dynamic>.from(data));
        }
      })
      ..on('delivery-location', (data) {
        if (data is Map) {
          onDeliveryLocation?.call(Map<String, dynamic>.from(data));
        }
      })
      ..on('support_message', (data) {
        if (data is Map) {
          onSupportMessage?.call(Map<String, dynamic>.from(data));
        }
      })
      ..on('support_ticket_updated', (data) {
        if (data is Map) {
          onSupportTicketUpdated?.call(Map<String, dynamic>.from(data));
        }
      })
      ..on('user_notification', (data) {
        if (data is Map) {
          onUserNotification?.call(Map<String, dynamic>.from(data));
        }
      })
      ..on('subscription_delivery_update', (data) {
        if (data is Map) {
          onSubscriptionDeliveryUpdate?.call(Map<String, dynamic>.from(data));
        }
      })
      ..on('subscription_notification', (data) {
        if (data is Map) {
          onSubscriptionNotification?.call(Map<String, dynamic>.from(data));
        }
      });

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  Future<void> reconnect() async {
    disconnect();
    await connect();
  }

  void joinOrder(String orderId) {
    _socket?.emit('join_order', orderId);
  }

  void joinSupportTicket(String ticketId) {
    _socket?.emit('join_support_ticket', ticketId);
  }

  void leaveSupportTicket(String ticketId) {
    _socket?.emit('leave_support_ticket', ticketId);
  }

  void sendSupportMessage(String ticketId, String body) {
    _socket?.emit('support_send_message', {'ticketId': ticketId, 'body': body});
  }

  void emitSupportTyping(String ticketId, bool isTyping) {
    _socket?.emit('support_typing', {'ticketId': ticketId, 'isTyping': isTyping});
  }

  void markSupportRead(String ticketId) {
    _socket?.emit('support_mark_read', {'ticketId': ticketId});
  }
}
