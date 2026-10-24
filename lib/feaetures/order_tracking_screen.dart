import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/core/di/app_services.dart';
import 'package:food_app/core/widgets/rate_order_sheet.dart';
import 'package:food_app/data/models/user_order_models.dart';
import 'package:food_app/provider/order_tracking_provider.dart';
import 'package:provider/provider.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Map<String, dynamic>? _order;
  bool _loading = true;
  bool _promptedRating = false;
  Timer? _pollTimer;
  Map<String, dynamic>? _lastLocation;

  static const _steps = [
    ('PLACED', 'orderStatus.placed'),
    ('ACCEPTED', 'orderStatus.confirmed'),
    ('PREPARING', 'orderStatus.preparing'),
    ('READY', 'orderStatus.ready'),
    ('OUT_FOR_DELIVERY', 'orderStatus.onTheWay'),
    ('DELIVERED', 'orderStatus.delivered'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppServices.instance.socketService.onOrderUpdate = _onSocket;
      AppServices.instance.socketService.onDeliveryLocation =
          _onDeliveryLocation;
      AppServices.instance.socketService.joinOrder(widget.orderId);
      context.read<OrderTrackingProvider>().setActiveOrder(widget.orderId);
    });
    _pollTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    AppServices.instance.socketService.onOrderUpdate = null;
    AppServices.instance.socketService.onDeliveryLocation = null;
    _pollTimer?.cancel();
    super.dispose();
  }

  void _onSocket(Map<String, dynamic> p) {
    if (p['orderId']?.toString() != widget.orderId) return;
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<OrderTrackingProvider>().applySocketUpdate(p);
      final internal = p['internalStatus']?.toString() ?? p['status']?.toString();
      if (internal == 'DELIVERED' || internal == 'CANCELLED') {
        _load(silent: true);
      }
    });
  }

  void _onDeliveryLocation(Map<String, dynamic> p) {
    if (p['orderId']?.toString() != widget.orderId) return;
    if (!mounted) return;
    setState(() => _lastLocation = p);
  }

  Future<void> _load({bool silent = false}) async {
    try {
      final data = await AppServices.instance.orderRepository.orderDetails(
        widget.orderId,
      );
      if (mounted) {
        setState(() {
          _order = data;
          _loading = false;
        });
        context.read<OrderTrackingProvider>().seedFromOrder(data);
        final status = data['status']?.toString();
        if (status == 'DELIVERED' || status == 'CANCELLED') {
          _pollTimer?.cancel();
        }
        if (status == 'DELIVERED') {
          _maybePromptRating(data);
        }
      }
    } catch (_) {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  void _maybePromptRating(Map<String, dynamic> data) {
    if (_promptedRating || !mounted) return;
    final summary = UserOrderSummary.fromOrderJson(data);
    if (!summary.canRateRestaurant || summary.hasRestaurantRating) return;
    _promptedRating = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final saved = await showRateOrderSheet(
        context,
        orderId: widget.orderId,
        restaurantName: summary.partnerName,
        hasDeliveryAgent: summary.hasDeliveryAgent,
      );
      if (saved != null && mounted) {
        await _load(silent: true);
      }
    });
  }

  int _indexFor(String status) {
    final i = _steps.indexWhere((s) => s.$1 == status);
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final track = context.watch<OrderTrackingProvider>();
    final status = track.internalStatus.isNotEmpty
        ? track.internalStatus
        : (_order?['status']?.toString() ?? 'PLACED');
    final current = _indexFor(status);
    final terminal = status == 'DELIVERED' || status == 'CANCELLED';
    final isSelfDelivery =
        _order?['selfDelivery'] == true || track.selfDelivery;

    return Scaffold(
      appBar: AppBar(title: Text('orderTracking.title'.tr())),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title.isNotEmpty
                        ? track.title
                        : 'orderTracking.orderNumber'.tr(namedArgs: {
                            'id': widget.orderId.substring(
                                widget.orderId.length > 6
                                    ? widget.orderId.length - 6
                                    : 0)
                          }),
                    style: context.headingLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    track.subtitle,
                    style: context.bodyMedium.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                  if (_lastLocation != null && !isSelfDelivery) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'orderTracking.driverLocationUpdated'.tr(),
                      style: context.bodyLarge.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  ...List.generate(_steps.length, (i) {
                    final done = i <= current;
                    final active = i == current;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: done
                                ? AppColors.primary
                                : context.colors.divider,
                            child: Icon(
                              done ? Icons.check : Icons.circle,
                              size: 16,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              _steps[i].$2.tr(),
                              style: context.bodyLarge.copyWith(
                                fontWeight: active
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                                color: active
                                    ? AppColors.primary
                                    : context.colors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (terminal) ...[
                    const Spacer(),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: Text(
                        status == 'DELIVERED'
                            ? 'orderTracking.done'.tr()
                            : 'orderTracking.backToOrders'.tr(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
