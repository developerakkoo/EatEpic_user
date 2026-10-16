class AppNotification {
  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    this.ticketId,
    this.subscriptionId,
    this.deliveryId,
    this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final String? ticketId;
  final String? subscriptionId;
  final String? deliveryId;
  final DateTime? createdAt;

  bool get isSubscription =>
      type == 'SUBSCRIPTION' ||
      (subscriptionId != null && subscriptionId!.isNotEmpty) ||
      (deliveryId != null && deliveryId!.isNotEmpty);

  bool get isOffer => type == 'OFFER';

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      message: message,
      isRead: isRead ?? this.isRead,
      ticketId: ticketId,
      subscriptionId: subscriptionId,
      deliveryId: deliveryId,
      createdAt: createdAt,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    String? ticketId;
    String? subscriptionId;
    String? deliveryId;
    if (data is Map) {
      ticketId = data['ticketId']?.toString();
      subscriptionId = data['subscriptionId']?.toString();
      deliveryId = data['deliveryId']?.toString();
    }
    return AppNotification(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'SYSTEM',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      isRead: json['isRead'] == true,
      ticketId: ticketId,
      subscriptionId: subscriptionId,
      deliveryId: deliveryId,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
