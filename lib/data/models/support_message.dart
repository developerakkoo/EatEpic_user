class SupportMessage {
  SupportMessage({
    required this.id,
    required this.ticketId,
    required this.senderType,
    required this.messageType,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String ticketId;
  final String senderType;
  final String messageType;
  final String body;
  final DateTime? createdAt;

  bool get isMine => senderType == 'USER';
  bool get isSystem => senderType == 'SYSTEM';
  bool get isRatingRequest => messageType == 'RATING_REQUEST';

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      ticketId: json['ticketId']?.toString() ?? '',
      senderType: json['senderType']?.toString() ?? 'SYSTEM',
      messageType: json['messageType']?.toString() ?? 'TEXT',
      body: json['body']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
