import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/core/di/app_services.dart';
import 'package:food_app/core/widgets/rate_order_sheet.dart';
import 'package:food_app/data/models/user_order_models.dart';
import 'package:food_app/feaetures/login_screen.dart';
import 'package:food_app/feaetures/order_detail_screen.dart';
import 'package:food_app/provider/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class OrdersListScreen extends StatefulWidget {
  const OrdersListScreen({super.key});

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Map<String, UserOrderSummary> _byId = {};
  int _apiTotal = 0;
  int _page = 0;
  int _limit = 20;
  bool _initialLoading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!context.read<AuthProvider>().isLoggedIn) return;
      _refresh();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<UserOrderSummary> get _sorted {
    final list = _byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<UserOrderSummary> get _ongoing =>
      _sorted.where((o) => !o.isTerminal).toList();

  List<UserOrderSummary> get _past =>
      _sorted.where((o) => o.isTerminal).toList();

  bool get _hasMore =>
      _apiTotal > 0 && _byId.length < _apiTotal && _error == null;

  Future<void> _refresh() async {
    setState(() {
      _error = null;
      _initialLoading = true;
      _byId.clear();
      _page = 0;
      _apiTotal = 0;
    });
    await _fetchNextPage(reset: true);
    if (mounted) setState(() => _initialLoading = false);
  }

  Future<void> _fetchNextPage({bool reset = false}) async {
    if (_loadingMore && !reset) return;
    if (!_hasMore && !reset && _page > 0) return;

    final nextPage = reset ? 1 : _page + 1;

    setState(() {
      _loadingMore = true;
      if (reset) _error = null;
    });

    try {
      final repo = AppServices.instance.orderRepository;
      final result = await repo.fetchMyOrdersPage(page: nextPage, limit: _limit);
      if (!mounted) return;
      setState(() {
        _page = result.page;
        _limit = result.limit;
        _apiTotal = result.total;
        for (final o in result.orders) {
          _byId[o.id] = o;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onScrollNearEnd() {
    if (_initialLoading || _loadingMore) return;
    if (!_hasMore) return;
    _fetchNextPage();
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.watch<AuthProvider>().isLoggedIn;

    if (!loggedIn) {
      return Scaffold(
        appBar: AppBar(title: Text('orders.appBarTitle'.tr())),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: context.colors.textHint),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'orders.loginToSee'.tr(),
                  textAlign: TextAlign.center,
                  style: context.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xxl),
                FilledButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const LoginScreen(),
                    ),
                  ),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  child: Text('orders.login'.tr()),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('orders.title'.tr()),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: context.colors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'orders.ongoing'.tr(namedArgs: {'count': '${_ongoing.length}'})),
            Tab(text: 'orders.past'.tr(namedArgs: {'count': '${_past.length}'})),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Material(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.small),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _error!,
                          style: context.bodyMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                      TextButton(onPressed: _refresh, child: Text('common.retry'.tr())),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.primary,
              child: _initialLoading && _byId.isEmpty
                  ? _buildShimmerList()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOrderTab(
                          _ongoing,
                          emptyHint: 'orders.noActive'.tr(),
                        ),
                        _buildOrderTab(
                          _past,
                          emptyHint: 'orders.noPast'.tr(),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: context.colors.divider,
        highlightColor: context.colors.surfaceGrey,
        child: Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderTab(
    List<UserOrderSummary> items, {
    required String emptyHint,
  }) {
    if (items.isEmpty && !_initialLoading && !_loadingMore) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
          Icon(Icons.receipt_long, size: 56, color: context.colors.textHint),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Text(
              emptyHint,
              style: context.bodyMedium.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ),
        ],
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >
            notification.metrics.maxScrollExtent - 220) {
          _onScrollNearEnd();
        }
        return false;
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          100,
        ),
        itemCount: items.length + (_loadingMore && items.isNotEmpty ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final o = items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _OrderRowCard(
              order: o,
              onRate: o.canRateRestaurant
                  ? () async {
                      final saved = await showRateOrderSheet(
                        context,
                        orderId: o.id,
                        restaurantName: o.partnerName,
                        hasDeliveryAgent: o.hasDeliveryAgent,
                        initialPartnerRating: o.partnerRating,
                        initialDeliveryRating: o.deliveryRating,
                        initialReview: o.review,
                      );
                      if (saved != null && mounted) {
                        setState(() {
                          _byId[o.id] = o.copyWithRating(
                            partnerRating: saved.partnerRating,
                            deliveryRating: saved.deliveryRating,
                            review: saved.review,
                          );
                        });
                      }
                    }
                  : null,
              onTap: () async {
                final changed = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute<bool>(
                    builder: (_) => OrderDetailScreen(orderId: o.id),
                  ),
                );
                if (changed == true && mounted) await _refresh();
              },
            ),
          );
        },
      ),
    );
  }
}

class _OrderRowCard extends StatelessWidget {
  const _OrderRowCard({
    required this.order,
    required this.onTap,
    this.onRate,
  });

  final UserOrderSummary order;
  final VoidCallback onTap;
  final VoidCallback? onRate;

  @override
  Widget build(BuildContext context) {
    final subtitleQty = order.moreItemCount > 0
        ? '${order.primaryItemName} • +${order.moreItemCount} more'
        : order.primaryItemName;

    final img = order.heroImageUrl;

    return Material(
      color: context.colors.background,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium + 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.medium + 2),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: img != null
                    ? CachedNetworkImage(
                        imageUrl: img,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 56,
                          height: 56,
                          color: context.colors.surfaceGrey,
                        ),
                        errorWidget: (_, __, ___) => _tilePlaceholder(context),
                      )
                    : _tilePlaceholder(context),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            order.partnerName.isNotEmpty
                                ? order.partnerName
                                : 'orders.restaurant'.tr(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (order.isSubscription)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs + 2,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: context.colors.bannerBackground,
                            ),
                            child: Text(
                              'orders.sub'.tr(),
                              style: context.caption.copyWith(
                                fontWeight: FontWeight.w600,
                                color: context.colors.bannerText,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitleQty,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.bodyMedium.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        _statusChip(context, order.status),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '#${order.shortIdChip}',
                          style: context.bodySmall.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '₹${order.totalAmount}',
                          style: context.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
          if (onRate != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: onRate,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    order.hasRestaurantRating
                        ? 'rateOrder.yourRating'.tr(namedArgs: {
                            'rating': '${order.partnerRating}',
                          })
                        : 'rateOrder.rateRestaurant'.tr(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tilePlaceholder(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      color: context.colors.surfaceGrey,
      child: Icon(Icons.restaurant_menu, color: context.colors.textHint),
    );
  }

  Widget _statusChip(BuildContext context, String raw) {
    final s = raw.toUpperCase();
    Color fg = const Color(0xFFE65100);
    Color bg = const Color(0xFFFF9800).withValues(alpha: 0.12);
    if (s == 'DELIVERED') {
      fg = AppColors.darkGreen;
      bg = context.colors.primaryLight;
    }
    if (s == 'CANCELLED') {
      fg = context.colors.textSecondary;
      bg = context.colors.divider;
    }

    final label = raw.isEmpty
        ? 'orders.unknown'.tr()
        : '${raw[0].toUpperCase()}${raw.length > 1 ? raw.substring(1).toLowerCase().replaceAll('_', ' ') : ''}';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.small),
        color: bg,
      ),
      child: Text(
        label,
        style: context.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
