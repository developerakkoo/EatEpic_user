import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/core/di/app_services.dart';
import 'package:food_app/data/models/support_message.dart';
import 'package:food_app/data/models/support_ticket.dart';
import 'package:food_app/provider/support_provider.dart';
import 'package:provider/provider.dart';

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final _repo = AppServices.instance.supportRepository;
  final _socket = AppServices.instance.socketService;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  SupportTicket? _ticket;
  List<SupportMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  int _rating = 0;
  final _ratingComment = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _socket.joinSupportTicket(widget.ticketId);
    _socket.onSupportMessage = _onSocketMessage;
    _socket.onSupportTicketUpdated = _onTicketUpdated;
  }

  @override
  void dispose() {
    _socket.leaveSupportTicket(widget.ticketId);
    _controller.dispose();
    _ratingComment.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSocketMessage(Map<String, dynamic> payload) {
    if (payload['ticketId']?.toString() != widget.ticketId) return;
    final msg = SupportMessage.fromJson(payload);
    if (_messages.any((m) => m.id == msg.id)) return;
    setState(() => _messages = [..._messages, msg]);
    _scrollToBottom();
  }

  void _onTicketUpdated(Map<String, dynamic> payload) {
    if (payload['_id']?.toString() != widget.ticketId) return;
    final ticket = SupportTicket.fromJson(payload);
    setState(() => _ticket = ticket);
    context.read<SupportProvider>().upsertTicket(ticket);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final ticket = await _repo.getTicket(widget.ticketId);
      final messages = await _repo.getMessages(widget.ticketId);
      await _repo.markRead(widget.ticketId);
      _socket.markSupportRead(widget.ticketId);
      if (mounted) {
        setState(() {
          _ticket = ticket;
          _messages = messages;
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _sending || _ticket == null) return;
    if (_ticket!.status == 'RESOLVED' || _ticket!.status == 'CLOSED') return;

    setState(() => _sending = true);
    _controller.clear();
    try {
      final msg = await _repo.sendMessage(widget.ticketId, body);
      if (!_messages.any((m) => m.id == msg.id)) {
        setState(() => _messages = [..._messages, msg]);
      }
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _resolve() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('support.resolveTitle'.tr()),
        content: Text('support.resolveMessage'.tr()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('common.no'.tr())),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('common.yes'.tr())),
        ],
      ),
    );
    if (confirmed != true) return;

    final ticket = await _repo.resolveTicket(widget.ticketId);
    if (mounted) {
      setState(() => _ticket = ticket);
      context.read<SupportProvider>().upsertTicket(ticket);
      await _load();
    }
  }

  Future<void> _submitRating() async {
    if (_rating < 1) return;
    final ticket = await _repo.submitRating(
      widget.ticketId,
      score: _rating,
      comment: _ratingComment.text.trim(),
    );
    if (mounted) {
      setState(() => _ticket = ticket);
      context.read<SupportProvider>().upsertTicket(ticket);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticket = _ticket;
    final closed = ticket != null &&
        (ticket.status == 'RESOLVED' || ticket.status == 'CLOSED');

    return Scaffold(
      appBar: AppBar(
        title: Text(ticket?.ticketNumber ?? 'support.chat'.tr()),
        actions: [
          if (ticket != null && !closed)
            TextButton(
              onPressed: _resolve,
              child: Text('support.markResolved'.tr()),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (ticket != null)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        ticket.subject,
                        style: context.headingMedium,
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _MessageBubble(message: msg);
                    },
                  ),
                ),
                if (ticket?.status == 'PENDING_RATING') _RatingPanel(
                  rating: _rating,
                  commentController: _ratingComment,
                  onRatingChanged: (v) => setState(() => _rating = v),
                  onSubmit: _submitRating,
                ),
                if (!closed)
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: InputDecoration(
                                hintText: 'support.typeMessage'.tr(),
                              ),
                              onSubmitted: (_) => _send(),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          IconButton.filled(
                            onPressed: _sending ? null : _send,
                            icon: const Icon(Icons.send_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final SupportMessage message;

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    final isSystem = message.isSystem;

    Color bg;
    Color fg;
    CrossAxisAlignment align;

    if (isSystem) {
      bg = context.colors.surfaceGrey;
      fg = context.colors.textSecondary;
      align = CrossAxisAlignment.center;
    } else if (isMine) {
      bg = AppColors.primary;
      fg = AppColors.white;
      align = CrossAxisAlignment.end;
    } else {
      bg = context.colors.surfaceGrey;
      fg = context.colors.textPrimary;
      align = CrossAxisAlignment.start;
    }

    String text = message.body;
    if (message.messageType == 'RATING_SUBMITTED') {
      try {
        final parsed = jsonDecode(message.body) as Map<String, dynamic>;
        text = 'support.ratingSubmitted'.tr(args: ['${parsed['score']}']);
      } catch (_) {
        text = 'support.ratingSubmittedGeneric'.tr();
      }
    }

    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(text, style: TextStyle(color: fg)),
        ),
      ],
    );
  }
}

class _RatingPanel extends StatelessWidget {
  const _RatingPanel({
    required this.rating,
    required this.commentController,
    required this.onRatingChanged,
    required this.onSubmit,
  });

  final int rating;
  final TextEditingController commentController;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: context.colors.surfaceGrey.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('support.ratePrompt'.tr(), style: context.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: List.generate(5, (i) {
              final star = i + 1;
              return IconButton(
                onPressed: () => onRatingChanged(star),
                icon: Icon(
                  star <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: AppColors.primary,
                ),
              );
            }),
          ),
          TextField(
            controller: commentController,
            decoration: InputDecoration(hintText: 'support.ratingComment'.tr()),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            onPressed: rating > 0 ? onSubmit : null,
            child: Text('support.submitRating'.tr()),
          ),
        ],
      ),
    );
  }
}
