import 'package:flutter/foundation.dart';
import 'package:food_app/core/di/app_services.dart';
import 'package:food_app/data/models/support_ticket.dart';

class SupportProvider with ChangeNotifier {
  final _repo = AppServices.instance.supportRepository;

  bool _loading = false;
  String? _error;
  List<SupportTicket> _openTickets = [];
  List<SupportTicket> _resolvedTickets = [];

  bool get loading => _loading;
  String? get error => _error;
  List<SupportTicket> get openTickets => _openTickets;
  List<SupportTicket> get resolvedTickets => _resolvedTickets;

  Future<void> loadTickets() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final open = await _repo.listTickets(status: 'open');
      final resolved = await _repo.listTickets(status: 'resolved');
      _openTickets = open;
      _resolvedTickets = resolved;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<SupportTicket?> createTicket({
    required String subject,
    required String category,
    required String message,
  }) async {
    try {
      final ticket = await _repo.createTicket(
        subject: subject,
        category: category,
        message: message,
      );
      _openTickets = [ticket, ..._openTickets];
      notifyListeners();
      return ticket;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  void upsertTicket(SupportTicket ticket) {
    final lists = [_openTickets, _resolvedTickets];
    for (final list in lists) {
      final idx = list.indexWhere((t) => t.id == ticket.id);
      if (idx >= 0) {
        list[idx] = ticket;
      }
    }
    if (ticket.isOpen && !_openTickets.any((t) => t.id == ticket.id)) {
      _openTickets = [ticket, ..._openTickets];
      _resolvedTickets.removeWhere((t) => t.id == ticket.id);
    } else if (!ticket.isOpen) {
      _resolvedTickets = [
        ticket,
        ..._resolvedTickets.where((t) => t.id != ticket.id),
      ];
      _openTickets.removeWhere((t) => t.id == ticket.id);
    }
    notifyListeners();
  }
}
