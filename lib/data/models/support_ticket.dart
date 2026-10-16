class SupportTicket {
  SupportTicket({
    required this.id,
    required this.ticketNumber,
    required this.subject,
    required this.category,
    required this.status,
    required this.lastMessageAt,
    required this.lastMessagePreview,
    required this.unreadByUser,
    required this.unreadByAdmin,
    this.ratingScore,
    this.ratingComment,
  });

  final String id;
  final String ticketNumber;
  final String subject;
  final String category;
  final String status;
  final DateTime? lastMessageAt;
  final String lastMessagePreview;
  final int unreadByUser;
  final int unreadByAdmin;
  final int? ratingScore;
  final String? ratingComment;

  bool get isOpen =>
      status == 'OPEN' || status == 'ACTIVE' || status == 'PENDING_RATING';

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    final rating = json['rating'];
    return SupportTicket(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      ticketNumber: json['ticketNumber']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      category: json['category']?.toString() ?? 'OTHER',
      status: json['status']?.toString() ?? 'OPEN',
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'].toString())
          : null,
      lastMessagePreview: json['lastMessagePreview']?.toString() ?? '',
      unreadByUser: (json['unreadByUser'] as num?)?.toInt() ?? 0,
      unreadByAdmin: (json['unreadByAdmin'] as num?)?.toInt() ?? 0,
      ratingScore: rating is Map ? (rating['score'] as num?)?.toInt() : null,
      ratingComment:
          rating is Map ? rating['comment']?.toString() : null,
    );
  }
}
