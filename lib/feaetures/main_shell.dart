import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/core/di/app_services.dart';
import 'package:food_app/core/navigation/shell_navigation.dart';
import 'package:food_app/core/typography/app_text_styles.dart';
import 'package:food_app/core/widgets/cart_summary_bar.dart';
import 'package:food_app/data/models/support_ticket.dart';
import 'package:food_app/feaetures/account_screen.dart';
import 'package:food_app/feaetures/home_screen.dart';
import 'package:food_app/feaetures/notification_screen.dart';
import 'package:food_app/feaetures/search_screen.dart';
import 'package:food_app/feaetures/subscription_screen.dart';
import 'package:food_app/provider/cart_provider.dart';
import 'package:food_app/provider/notification_provider.dart';
import 'package:food_app/provider/subscription_provider.dart';
import 'package:food_app/provider/support_provider.dart';
import 'package:provider/provider.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _wireSocketListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NotificationProvider>().load();
      }
    });
  }

  void _wireSocketListeners() {
    final socket = AppServices.instance.socketService;
    socket.onUserNotification = (payload) {
      if (!mounted) return;
      context.read<NotificationProvider>().addFromSocket(payload);
    };
    socket.onSupportTicketUpdated = (payload) {
      if (!mounted) return;
      context.read<SupportProvider>().upsertTicket(SupportTicket.fromJson(payload));
    };
    socket.onSubscriptionDeliveryUpdate = (payload) {
      if (!mounted) return;
      context.read<SubscriptionProvider>().applyDeliveryUpdate(payload);
    };
    socket.onSubscriptionNotification = (payload) {
      if (!mounted) return;
      // Inbox entry arrives separately via "user_notification"; here we only
      // refresh plan summaries for lifecycle changes (activated/paused/etc).
      context.read<SubscriptionProvider>().refreshOnSubscriptionEvent();
    };
  }

  void _switchTab(int index) {
    if (index < 0 || index > 4) return;
    setState(() => _selectedIndex = index);
  }

  Widget _buildBody() {
    return IndexedStack(
      index: _selectedIndex,
      children: [
        HomeScreen(
          onOpenSearch: () => _switchTab(1),
          onOpenAccount: () => _switchTab(4),
        ),
        const SearchScreen(),
        const SubscriptionScreen(),
        const NotificationScreen(),
        AccountScreen(onOpenSubscriptions: () => _switchTab(2)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final colors = context.colors;
    final unread = context.watch<NotificationProvider>().unreadCount;

    return ShellNavigation(
      switchTab: _switchTab,
      child: Scaffold(
        body: Column(
          children: [
            Expanded(child: _buildBody()),
            SafeArea(
              top: false,
              child: CartSummaryBar(cart: cart),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: colors.elevatedSurface,
            border: Border(top: BorderSide(color: colors.divider, width: 1)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: AppLayout.bottomNavHeight,
              child: Row(
                children: [
                  _NavItem(
                    label: 'nav.home'.tr(),
                    selected: _selectedIndex == 0,
                    selectedIcon: Icons.home_rounded,
                    unselectedIcon: Icons.home_outlined,
                    onTap: () => _switchTab(0),
                  ),
                  _NavItem(
                    label: 'nav.search'.tr(),
                    selected: _selectedIndex == 1,
                    selectedIcon: Icons.search_rounded,
                    unselectedIcon: Icons.search_outlined,
                    onTap: () => _switchTab(1),
                  ),
                  _NavItem(
                    label: 'nav.subscribe'.tr(),
                    selected: _selectedIndex == 2,
                    selectedIcon: Icons.calendar_today_rounded,
                    unselectedIcon: Icons.calendar_today_outlined,
                    onTap: () => _switchTab(2),
                  ),
                  _NavItem(
                    label: 'nav.notification'.tr(),
                    selected: _selectedIndex == 3,
                    selectedIcon: Icons.notifications_rounded,
                    unselectedIcon: Icons.notifications_outlined,
                    onTap: () => _switchTab(3),
                    badgeCount: unread,
                  ),
                  _NavItem(
                    label: 'nav.account'.tr(),
                    selected: _selectedIndex == 4,
                    selectedIcon: Icons.person_rounded,
                    unselectedIcon: Icons.person_outlined,
                    onTap: () => _switchTab(4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.selected,
    required this.selectedIcon,
    required this.unselectedIcon,
    required this.onTap,
    this.badgeCount = 0,
  });

  final String label;
  final bool selected;
  final IconData selectedIcon;
  final IconData unselectedIcon;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = selected
        ? (isDark ? context.colors.primaryOnDark : AppColors.primary)
        : context.colors.navInactive;
    final style = selected
        ? context.bottomNavSelected
        : context.bottomNavUnselected;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    selected ? selectedIcon : unselectedIcon,
                    size: 24,
                    color: color,
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          badgeCount > 9 ? '9+' : '$badgeCount',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(label, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
