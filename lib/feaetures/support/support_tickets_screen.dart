import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/data/models/support_ticket.dart';
import 'package:food_app/feaetures/support/support_chat_screen.dart';
import 'package:food_app/feaetures/support/support_new_ticket_sheet.dart';
import 'package:food_app/provider/support_provider.dart';
import 'package:provider/provider.dart';

class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupportProvider>().loadTickets();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _openNewTicket() async {
    final ticket = await showModalBottomSheet<SupportTicket>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const SupportNewTicketSheet(),
    );
    if (ticket != null && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SupportChatScreen(ticketId: ticket.id),
        ),
      );
      if (mounted) {
        context.read<SupportProvider>().loadTickets();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final support = context.watch<SupportProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('support.title'.tr()),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: 'support.openTab'.tr()),
            Tab(text: 'support.resolvedTab'.tr()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewTicket,
        icon: const Icon(Icons.add_comment_outlined),
        label: Text('support.newTicket'.tr()),
      ),
      body: support.loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _TicketList(tickets: support.openTickets, emptyKey: 'support.emptyOpen'),
                _TicketList(
                  tickets: support.resolvedTickets,
                  emptyKey: 'support.emptyResolved',
                ),
              ],
            ),
    );
  }
}

class _TicketList extends StatelessWidget {
  const _TicketList({required this.tickets, required this.emptyKey});

  final List<SupportTicket> tickets;
  final String emptyKey;

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Text(
            emptyKey.tr(),
            style: context.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: tickets.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: context.colors.divider),
          ),
          title: Text(ticket.subject, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${ticket.ticketNumber} · ${ticket.lastMessagePreview}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: ticket.unreadByUser > 0
              ? CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    '${ticket.unreadByUser}',
                    style: const TextStyle(color: AppColors.white, fontSize: 11),
                  ),
                )
              : Icon(Icons.chevron_right, color: context.colors.textSecondary),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SupportChatScreen(ticketId: ticket.id),
              ),
            );
          },
        );
      },
    );
  }
}
