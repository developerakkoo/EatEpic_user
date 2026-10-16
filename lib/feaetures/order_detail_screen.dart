import 'dart:ui' show FontFeature, ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/core/di/app_services.dart';
import 'package:food_app/data/models/user_order_models.dart';
import 'package:food_app/feaetures/order_tracking_screen.dart';
import 'package:url_launcher/url_launcher.dart';

/// Zomato-style order receipt + timeline (no map).
class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({
    super.key,
    required this.orderId,
  });

  final String orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  UserOrderDetail? _detail;
  bool _loading = true;
  String? _error;
  bool _cancelling = false;

  static const List<(String, String, IconData)> _timelineSpecs = [
    ('placedAt', 'orderStatus.placed', Icons.receipt_long_outlined),
    ('acceptedAt', 'orderStatus.confirmed', Icons.check_circle_outline),
    ('preparingAt', 'orderStatus.preparing', Icons.restaurant_outlined),
    ('readyAt', 'orderStatus.ready', Icons.takeout_dining_outlined),
    ('pickedAt', 'orderStatus.pickedUp', Icons.delivery_dining_outlined),
    ('deliveredAt', 'orderStatus.delivered', Icons.home_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await AppServices.instance.orderRepository
          .fetchMyOrderDetail(widget.orderId);
      if (mounted) {
        setState(() {
          _detail = d;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _maybeCallKitchen(String phoneRaw) async {
    final trimmed = phoneRaw.trim();
    if (trimmed.isEmpty) return;
    final normalized = trimmed.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri(scheme: 'tel', path: normalized);
    if (!await canLaunchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('orderDetail.cannotDial'.tr())),
        );
      }
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _confirmCancel(UserOrderDetail d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('orderDetail.cancelTitle'.tr()),
        content: Text('orderDetail.cancelMessage'.tr()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('orderDetail.keepOrder'.tr())),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('orderDetail.cancelOrder'.tr()),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      await AppServices.instance.orderRepository.cancelOrder(
        widget.orderId,
        reason: 'Cancelled from app',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('orderDetail.orderCancelled'.tr())),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'orderDetail.couldNotCancel'.tr(namedArgs: {'error': '$e'}))),
        );
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  static String _formatDt(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year} · '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _detail == null) {
      return Scaffold(
        appBar: AppBar(title: Text('orderDetail.title'.tr())),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _detail == null) {
      return Scaffold(
        appBar: AppBar(title: Text('orderDetail.title'.tr())),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _load,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  child: Text('common.retry'.tr()),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final d = _detail!;
    final heroImg = _firstItemImageUrl(d);
    final s = d.summary;

    final canTrack = s.status.toUpperCase() != 'CANCELLED';

    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Row(
            children: [
              Expanded(
                flex: d.userCanCancel ? 5 : 1,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.65)),
                  ),
                  onPressed: canTrack
                      ? () {
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  OrderTrackingScreen(orderId: widget.orderId),
                            ),
                          ).then((_) => _load());
                        }
                      : null,
                  child: Text(
                    s.status.toUpperCase() == 'DELIVERED'
                        ? 'orderDetail.viewProgress'.tr()
                        : 'orderDetail.trackLive'.tr(),
                  ),
                ),
              ),
              if (d.userCanCancel) ...[
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 3,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          !_cancelling ? AppColors.error : context.colors.textHint,
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed:
                        (!d.userCanCancel || _cancelling) ? null : () => _confirmCancel(d),
                    child: _cancelling
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : Text('orderDetail.cancel'.tr()),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(start: 52, bottom: 14),
              title: Text(
                s.partnerName.isNotEmpty ? s.partnerName : 'orderDetail.title'.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.headingMedium.copyWith(
                  color: AppColors.white,
                  shadows: const [
                    Shadow(color: AppColors.overlayDark, blurRadius: 10),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  heroImg != null
                      ? CachedNetworkImage(imageUrl: heroImg, fit: BoxFit.cover)
                      : DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withValues(alpha: 0.55),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.overlayDark,
                          context.colors.textPrimary.withValues(alpha: 0.75),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  if (heroImg != null)
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: Container(color: AppColors.overlayDark.withValues(alpha: 0.45)),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _headerMetaRow(d)),
          SliverToBoxAdapter(child: _restaurantTile(d)),
          if (d.partnerPhone.trim().isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                child: OutlinedButton.icon(
                  onPressed: () => _maybeCallKitchen(d.partnerPhone),
                  icon: const Icon(Icons.call_outlined, size: 18),
                  label: Text('orderDetail.callRestaurant'.tr()),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary),
                ),
              ),
            ),
          SliverToBoxAdapter(child: _addressCard(d)),
          if (d.selfDelivery)
            SliverToBoxAdapter(child: _selfDeliveryBanner()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xxl,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: Text(
                'orderDetail.items'.tr(),
                style: context.headingMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _buildLineTile(d.lineItems[i]),
                childCount: d.lineItems.length,
              ),
            ),
          ),
          SliverToBoxAdapter(child: _pricingCard(context, d.pricing)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xxl,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: Text(
                'orderDetail.payment'.tr(),
                style: context.headingMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _paymentRow(d.payment)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xxl,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: Text(
                'orderDetail.timeline'.tr(),
                style: context.headingMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _timelineCard(d)),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _headerMetaRow(UserOrderDetail d) {
    final s = d.summary;
    final st = s.status.isEmpty ? 'UNKNOWN' : s.status;
    final statusPretty =
        '${st.substring(0, 1)}${st.length > 1 ? st.substring(1).toLowerCase().replaceAll('_', ' ') : ''}';
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'orderDetail.orderChip'.tr(namedArgs: {'id': s.shortIdChip}),
                      style: context.headingMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (s.isSubscription)
                      Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.sm),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: context.colors.bannerBackground,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            'orderDetail.subscriptionMeal'.tr(),
                            style: context.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: context.colors.bannerText,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${_statusLabelEmoji(s.status)} $statusPretty',
                  style: context.bodyLarge.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                Text(
                  'orderDetail.ordered'
                      .tr(namedArgs: {'date': _formatDt(s.createdAt)}),
                  style: context.bodyMedium,
                ),
              ],
            ),
          ),
          Text(
            '₹${d.pricing.totalAmount}',
            style: context.displayMedium.copyWith(
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabelEmoji(String raw) {
    switch (raw.toUpperCase()) {
      case 'DELIVERED':
        return '✔';
      case 'CANCELLED':
        return '⊘';
      case 'OUT_FOR_DELIVERY':
        return '🛵';
      default:
        return '●';
    }
  }

  String? _firstItemImageUrl(UserOrderDetail d) {
    for (final i in d.lineItems) {
      if (i.imageUrl != null && i.imageUrl!.isNotEmpty) return i.imageUrl;
    }
    return null;
  }

  Widget _restaurantTile(UserOrderDetail d) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Material(
        color: context.colors.background,
        borderRadius: BorderRadius.circular(AppRadius.medium + 2),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: context.colors.primaryLight,
                child: Icon(Icons.storefront_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.summary.partnerName,
                      style: context.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (d.summary.partnerAddress.trim().isNotEmpty)
                      Text(
                        d.summary.partnerAddress.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.bodyMedium,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selfDeliveryBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Material(
        color: context.colors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.medium + 2),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.store_mall_directory_outlined, color: AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'orderDetail.selfDeliveryHandled'.tr(),
                  style: context.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addressCard(UserOrderDetail d) {
    final addr = d.deliveryFullAddress.trim();
    if (addr.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Material(
        color: context.colors.background,
        borderRadius: BorderRadius.circular(AppRadius.medium + 2),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_outlined, color: context.colors.textSecondary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'orderDetail.deliveringTo'.tr(),
                      style: context.headingSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      addr,
                      style: context.bodyLarge.copyWith(
                        height: 1.35,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'orderDetail.copyAddress'.tr(),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: addr));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('orderDetail.addressCopied'.tr())),
                  );
                },
                icon: Icon(Icons.copy, color: context.colors.textSecondary, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLineTile(OrderLineItem i) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        color: context.colors.background,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (i.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.small),
                  child: CachedNetworkImage(
                    imageUrl: i.imageUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _miniPlaceholder(),
                  ),
                )
              else
                _miniPlaceholder(),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(i.name, style: context.headingSmall),
                    Text(
                      '₹${i.unitPrice} × ${i.quantity}',
                      style: context.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                '₹${i.lineTotal}',
                style: context.headingSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniPlaceholder() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: Container(
        width: 48,
        height: 48,
        color: context.colors.surfaceGrey,
        alignment: Alignment.center,
        child: Icon(Icons.fastfood_outlined, size: 22, color: context.colors.textHint),
      ),
    );
  }

  Widget _pricingCard(BuildContext context, UserOrderPricing p) {
    Widget row(String k, String v, {bool strong = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
        child: Row(
          children: [
            Expanded(
              child: Text(k, style: context.bodyMedium.copyWith(
                color: context.colors.textSecondary,
              )),
            ),
            Text(
              v,
              style: context.bodyLarge.copyWith(
                fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Material(
        color: context.colors.background,
        borderRadius: BorderRadius.circular(AppRadius.medium + 2),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'orderDetail.billDetails'.tr(),
                style: context.headingMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Divider(height: AppSpacing.xxl),
              row('orderDetail.itemTotal'.tr(), '₹${p.itemTotal}'),
              row('orderDetail.gstCharges'.tr(), '₹${p.tax}'),
              row('orderDetail.deliveryPartnerFee'.tr(), '₹${p.deliveryCharge}'),
              row('orderDetail.platformFee'.tr(), '₹${p.platformFee}'),
              if (p.discount > 0) row('orderDetail.discount'.tr(), '- ₹${p.discount}'),
              const Divider(height: AppSpacing.xxl),
              row('orderDetail.grandTotal'.tr(), '₹${p.totalAmount}', strong: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paymentRow(UserOrderPayment pay) {
    final methodLabel = switch (pay.method.toUpperCase()) {
      'COD' => 'orderDetail.cod'.tr(),
      'ONLINE' => 'orderDetail.paidOnline'.tr(),
      'WALLET' => 'orderDetail.paidWallet'.tr(),
      _ => pay.method.isNotEmpty ? pay.method : '—',
    };
    Color bg = pay.isPaid
        ? context.colors.primaryLight
        : const Color(0xFFFF9800).withValues(alpha: 0.12);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Material(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        color: bg,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                pay.isPaid ? Icons.verified_outlined : Icons.hourglass_bottom_outlined,
                color: pay.isPaid ? AppColors.darkGreen : const Color(0xFFE65100),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      methodLabel,
                      style: context.headingSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      pay.isPaid
                          ? 'orderDetail.paymentSuccessful'.tr()
                          : 'orderDetail.paymentPending'
                              .tr(namedArgs: {'status': pay.paymentStatus}),
                      style: context.bodySmall.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timelineCard(UserOrderDetail d) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Material(
        color: context.colors.background,
        borderRadius: BorderRadius.circular(AppRadius.medium + 2),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              for (var i = 0; i < _timelineSpecs.length; i++)
                _timelineRow(
                  d,
                  _timelineSpecs[i].$1,
                  _timelineSpecs[i].$2,
                  _timelineSpecs[i].$3,
                  isLast: i == _timelineSpecs.length - 1,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timelineRow(
    UserOrderDetail d,
    String key,
    String label,
    IconData icon, {
    required bool isLast,
  }) {
    final ts = d.timelineAt(key);
    final done = ts != null;
    final lineColor = done ? AppColors.primary : context.colors.divider;

    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs + 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? context.colors.primaryLight
                      : context.colors.surfaceGrey,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: done ? AppColors.primary : context.colors.textHint,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 36,
                  color: lineColor.withValues(alpha: done ? 0.9 : 0.35),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.tr(),
                    style: context.bodyLarge.copyWith(
                      fontWeight: done ? FontWeight.w700 : FontWeight.w500,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  Text(
                    ts == null ? 'orderStatus.pending'.tr() : _formatDt(ts),
                    style: context.bodySmall,
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
