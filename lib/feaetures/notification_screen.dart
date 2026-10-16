import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/core/navigation/shell_navigation.dart';
import 'package:food_app/data/models/app_notification.dart';
import 'package:food_app/feaetures/support/support_chat_screen.dart';
import 'package:food_app/provider/notification_provider.dart';
import 'package:provider/provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().load();
    });
  }

  Future<void> _openNotification(AppNotification notification) async {
    if (!notification.isRead) {
      await context.read<NotificationProvider>().markRead(notification.id);
    }
    if (!mounted) return;
    if (notification.ticketId != null && notification.ticketId!.isNotEmpty) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SupportChatScreen(ticketId: notification.ticketId!),
        ),
      );
      if (mounted) {
        context.read<NotificationProvider>().load();
      }
      return;
    }
    if (notification.isSubscription) {
      // Jump to the Subscriptions tab so the user sees the updated status.
      ShellNavigation.maybeOf(context)?.switchTab(2);
    }
  }

  IconData _iconFor(AppNotification item) {
    if (item.ticketId != null && item.ticketId!.isNotEmpty) {
      return Icons.support_agent_outlined;
    }
    if (item.isSubscription) return Icons.restaurant_menu_outlined;
    if (item.isOffer) return Icons.local_offer_outlined;
    return Icons.notifications_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('notifications.title'.tr()),
        automaticallyImplyLeading: false,
        actions: [
          if (notifications.unreadCount > 0)
            TextButton(
              onPressed: () => notifications.markAllRead(),
              child: Text('notifications.markAllRead'.tr()),
            ),
        ],
      ),
      body: notifications.loading
          ? const Center(child: CircularProgressIndicator())
          : notifications.items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          size: 72,
                          color: context.colors.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'notifications.empty'.tr(),
                          style: context.headingMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'notifications.emptySubtitle'.tr(),
                          style: context.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: notifications.load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: notifications.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = notifications.items[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: item.isRead
                              ? context.colors.surfaceGrey
                              : context.colors.primaryLight,
                          child: Icon(
                            _iconFor(item),
                            color: item.isRead
                                ? context.colors.textSecondary
                                : AppColors.primary,
                          ),
                        ),
                        title: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight:
                                item.isRead ? FontWeight.normal : FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          item.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: item.createdAt != null
                            ? Text(
                                DateFormat.jm().format(item.createdAt!.toLocal()),
                                style: context.bodyMedium.copyWith(
                                  fontSize: 12,
                                  color: context.colors.textSecondary,
                                ),
                              )
                            : null,
                        onTap: () => _openNotification(item),
                      );
                    },
                  ),
                ),
    );
  }
}
