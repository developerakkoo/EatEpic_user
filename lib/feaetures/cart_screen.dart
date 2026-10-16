import 'package:add_to_cart_animated_button/add_to_cart_animated_button.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/core/di/app_services.dart';
import 'package:food_app/feaetures/location_picker_screen.dart';
import 'package:food_app/feaetures/order_tracking_screen.dart';
import 'package:food_app/modal/cart_item_modal.dart';
import 'package:food_app/provider/auth_provider.dart';
import 'package:food_app/provider/cart_provider.dart';
import 'package:food_app/provider/location_provider.dart';
import 'package:provider/provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String _paymentMethod = 'COD'; // COD | ONLINE | WALLET
  bool _placing = false;
  String? _appliedOfferId; // mock: which offer is applied
  double? _walletBalance; // null until fetched

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWalletBalance());
  }

  Future<void> _loadWalletBalance() async {
    if (!mounted || !context.read<AuthProvider>().isLoggedIn) return;
    try {
      final balance = await AppServices.instance.userRepository
          .getWalletBalance();
      if (mounted) setState(() => _walletBalance = balance);
    } catch (_) {
      // Balance stays unknown; the place-order check will still catch it.
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final location = context.watch<LocationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('cart.title'.tr()),
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: () => _showClearCartConfirmation(context, cart),
              child: Text('cart.clearCart'.tr()),
            ),
        ],
      ),
      body: cart.isEmpty
          ? _buildEmptyState(context)
          : _buildCartBody(context, cart, location),
      bottomNavigationBar: cart.isEmpty
          ? null
          : _buildPlaceOrderBar(context, cart),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: context.colors.textHint,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'cart.empty'.tr(),
              style: context.headingLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'cart.emptySubtitle'.tr(),
              textAlign: TextAlign.center,
              style: context.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xxl),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text('cart.continueBrowsing'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartBody(
    BuildContext context,
    CartProvider cart,
    LocationProvider location,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.sm,
        bottom: 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCartItems(cart),
          _buildSubscriptionUpsell(cart),
          const SizedBox(height: AppSpacing.lg),
          _buildClearCartButton(cart),
          const SizedBox(height: AppSpacing.xl),
          _buildOffersSection(),
          const SizedBox(height: AppSpacing.xl),
          _buildDeliveryAddress(location),
          const SizedBox(height: AppSpacing.xl),
          _buildOrderSummary(cart),
          const SizedBox(height: AppSpacing.xl),
          _buildPaymentSection(cart),
        ],
      ),
    );
  }

  Widget _buildCartItems(CartProvider cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'cart.items'.tr(),
          style: context.headingMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        ...cart.items.map(
          (item) => _CartItemTile(
            item: item,
            onQuantityChanged: (qty) => cart.updateQuantity(item.id, qty),
            onRemove: () => cart.removeItem(item.id),
          ),
        ),
      ],
    );
  }

  ({String hotelId, String hotelName, String menuItemId})?
  _subscriptionUpsellTarget(CartProvider cart) {
    if (cart.isEmpty) return null;
    final k0 = cart.items.first.hotelId;
    for (final e in cart.items) {
      if (e.hotelId != k0) return null;
    }
    var pick = cart.items.first;
    for (final e in cart.items) {
      if (e.quantity > pick.quantity) pick = e;
    }
    return (
      hotelId: k0,
      hotelName: pick.hotelName,
      menuItemId: pick.menuItem.id,
    );
  }

  Widget _buildSubscriptionUpsell(CartProvider cart) {
    final t = _subscriptionUpsellTarget(cart);
    if (t == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.xs),
      child: Material(
        color: context.colors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          onTap: () async {
            final loggedIn = context.read<AuthProvider>().isLoggedIn;
            if (!mounted) return;
            if (!loggedIn) {
              await Navigator.pushNamed(context, '/login');
              return;
            }
            await Navigator.pushNamed(
              context,
              '/create-subscription',
              arguments: {'kitchenId': t.hotelId, 'menuItemId': t.menuItemId},
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.card_membership, color: AppColors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'cart.mealSubscription'.tr(),
                        style: context.headingSmall,
                      ),
                      Text(
                        'cart.upsellSubtitle'.tr(
                          namedArgs: {'name': _subscriptionUpsellLineLabel(t)},
                        ),
                        style: context.bodyMedium.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _subscriptionUpsellLineLabel(
    ({String hotelId, String hotelName, String menuItemId}) t,
  ) {
    return t.hotelName;
  }

  Widget _buildClearCartButton(CartProvider cart) {
    return Center(
      child: TextButton.icon(
        onPressed: () => _showClearCartConfirmation(context, cart),
        icon: const Icon(Icons.delete_outline, size: 20),
        label: Text('cart.clearCart'.tr()),
      ),
    );
  }

  Widget _buildOffersSection() {
    final mockOffers = [
      _MockOffer(id: '1', title: 'cart.offerPercent'.tr(), minOrder: 500),
      _MockOffer(id: '2', title: 'cart.offerFreeDelivery'.tr(), minOrder: 300),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'cart.offers'.tr(),
          style: context.headingMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        ...mockOffers.map(
          (offer) => _OfferTile(
            offer: offer,
            isApplied: _appliedOfferId == offer.id,
            onApply: () => setState(() => _appliedOfferId = offer.id),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryAddress(LocationProvider location) {
    return Material(
      color: context.colors.background,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  LocationPickerScreen(fromHome: false, fromCart: true),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'cart.deliveryAddress'.tr(),
                      style: context.caption.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      location.address ?? 'cart.addAddress'.tr(),
                      style: context.bodyLarge.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'cart.orderSummary'.tr(),
          style: context.headingMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        _BillRow(label: 'cart.subtotal'.tr(), value: '₹${cart.subtotal}'),
        _BillRow(label: 'cart.deliveryFee'.tr(), value: '₹${cart.deliveryFee}'),
        _BillRow(label: 'cart.tax'.tr(), value: '₹${cart.tax}'),
        if (_appliedOfferId != null)
          _BillRow(
            label: 'cart.discount'.tr(),
            value: '-₹0',
            valueColor: AppColors.primary,
          ),
        const Divider(height: AppSpacing.xxl),
        _BillRow(label: 'cart.total'.tr(), value: '₹${cart.total}', bold: true),
      ],
    );
  }

  bool _walletCoversTotal(CartProvider cart) {
    final balance = _walletBalance;
    return balance == null || balance >= cart.total;
  }

  Widget _buildPaymentSection(CartProvider cart) {
    final walletUsable = _walletCoversTotal(cart);
    if (!walletUsable && _paymentMethod == 'WALLET') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _paymentMethod == 'WALLET') {
          setState(() => _paymentMethod = 'COD');
        }
      });
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'cart.payment'.tr(),
          style: context.headingMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        RadioListTile<String>(
          value: 'COD',
          groupValue: _paymentMethod,
          onChanged: (v) => setState(() => _paymentMethod = v ?? 'COD'),
          title: Text('cart.cod'.tr()),
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<String>(
          value: 'ONLINE',
          groupValue: _paymentMethod,
          onChanged: (v) => setState(() => _paymentMethod = v ?? 'ONLINE'),
          title: Text('cart.online'.tr()),
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<String>(
          value: 'WALLET',
          groupValue: _paymentMethod,
          onChanged: walletUsable
              ? (v) => setState(() => _paymentMethod = v ?? 'WALLET')
              : null,
          title: Text('cart.wallet'.tr()),
          subtitle: _walletBalance == null
              ? null
              : Text(
                  walletUsable
                      ? 'cart.walletBalance'.tr(
                          namedArgs: {
                            'balance': _walletBalance!.toStringAsFixed(0),
                          },
                        )
                      : 'cart.walletInsufficient'.tr(
                          namedArgs: {
                            'balance': _walletBalance!.toStringAsFixed(0),
                          },
                        ),
                  style: context.caption.copyWith(
                    color: walletUsable
                        ? context.colors.textSecondary
                        : AppColors.error,
                  ),
                ),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildPlaceOrderBar(BuildContext context, CartProvider cart) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: FilledButton(
          onPressed: _placing ? null : () => _placeOrder(context, cart),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium + 2),
            ),
          ),
          child: Text('cart.placeOrder'.tr(namedArgs: {'total': '${cart.total}'})),
        ),
      ),
    );
  }

  void _showClearCartConfirmation(BuildContext context, CartProvider cart) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('cart.clearTitle'.tr()),
        content: Text('cart.clearMessage'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              cart.clearCart();
              Navigator.pop(ctx);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text('cart.clear'.tr()),
          ),
        ],
      ),
    );
  }

  void _showCheckoutError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isValidObjectId(String value) {
    return RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(value);
  }

  String _checkoutErrorMessage(Object error, {required String fallback}) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final code = data['code']?.toString();
        final message = data['message']?.toString();
        if (code == 'CART_EMPTY') {
          return 'cart.cartNotSynced'.tr();
        }
        if (code == 'INSUFFICIENT_WALLET_BALANCE') {
          return 'cart.walletInsufficient'.tr(
            namedArgs: {
              'balance': _walletBalance?.toStringAsFixed(0) ?? '0',
            },
          );
        }
        if (message != null && message.trim().isNotEmpty) {
          return message;
        }
      }
      if (data is String && data.trim().isNotEmpty) {
        return data;
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'cart.connectionTimeout'.tr();
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'cart.serverUnreachable'.tr();
      }
    }
    return fallback;
  }

  Future<void> _placeOrder(BuildContext context, CartProvider cart) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('cart.loginToOrder'.tr())),
      );
      return;
    }

    setState(() => _placing = true);
    try {
      final addresses = await AppServices.instance.userRepository
          .getAddresses();
      if (addresses.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('cart.addAddressFirst'.tr())),
          );
        }
        return;
      }
      final addr = addresses.firstWhere(
        (a) => a.isDefault,
        orElse: () => addresses.first,
      );

      if (!_isValidObjectId(addr.id)) {
        if (!context.mounted) return;
        _showCheckoutError(context, 'cart.selectAddress'.tr());
        return;
      }

      if (_paymentMethod == 'ONLINE') {
        if (!context.mounted) return;
        _showCheckoutError(context, 'cart.onlineUnavailable'.tr());
        return;
      }

      if (_paymentMethod == 'WALLET') {
        double? balance;
        try {
          balance = await AppServices.instance.userRepository
              .getWalletBalance();
        } catch (_) {
          balance = _walletBalance;
        }
        if (balance != null && mounted) {
          setState(() => _walletBalance = balance);
        }
        if (balance == null || balance < cart.total) {
          if (!context.mounted) return;
          _showCheckoutError(
            context,
            'cart.walletInsufficient'.tr(
              namedArgs: {'balance': (balance ?? 0).toStringAsFixed(0)},
            ),
          );
          return;
        }
      }

      try {
        await AppServices.instance.cartRepository.syncCart(
          items: cart.items
              .map(
                (item) => {
                  'menuItemId': item.menuItem.id,
                  'quantity': item.quantity,
                },
              )
              .toList(),
        );
        await AppServices.instance.cartRepository.checkout();
      } catch (e) {
        if (!context.mounted) return;
        _showCheckoutError(
          context,
          _checkoutErrorMessage(
            e,
            fallback: 'cart.syncFailed'.tr(),
          ),
        );
        return;
      }

      final res = await AppServices.instance.orderRepository.createOrder(
        addressId: addr.id,
        paymentMethod: _paymentMethod,
        idempotencyKey:
            'mobile-${DateTime.now().microsecondsSinceEpoch}-${addr.id}',
      );
      final order = res['data'] ?? res['order'] ?? res;
      final orderId = order['_id']?.toString() ?? order['id']?.toString();

      cart.clearCart();
      if (context.mounted && orderId != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => OrderTrackingScreen(orderId: orderId),
          ),
        );
      } else if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('cart.orderPlaced'.tr())),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      _showCheckoutError(
        context,
        _checkoutErrorMessage(
          e,
          fallback: 'cart.orderFailed'.tr(),
        ),
      );
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  final CartItemModel item;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isNetwork = item.menuItem.imageUrl.startsWith('http');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 72,
              height: 72,
              child: isNetwork
                  ? Image.network(
                      item.menuItem.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.restaurant,
                        color: context.colors.textHint,
                      ),
                    )
                  : Image.asset(
                      item.menuItem.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.restaurant,
                        color: context.colors.textHint,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        border: Border.all(
                          color: item.menuItem.isVeg
                              ? AppColors.darkGreen
                              : AppColors.error,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: item.menuItem.isVeg
                                ? AppColors.darkGreen
                                : AppColors.error,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.menuItem.name,
                        style: context.headingSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '₹${item.menuItem.price}',
                  style: context.bodySmall.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs + 2),
                Row(
                  children: [
                    AddToCart(
                      value: item.quantity,
                      onIncrement: onQuantityChanged,
                      onDecrement: onQuantityChanged,
                      maxValue: 10,
                      width: 90,
                      height: 32,
                    ),
                    const Spacer(),
                    Text(
                      '₹${item.lineTotal}',
                      style: context.headingSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: context.bodyMedium.copyWith(
              fontWeight: bold ? FontWeight.w600 : null,
              color: context.colors.textPrimary,
            ),
          ),
          Text(
            value,
            style: context.bodyMedium.copyWith(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor ?? context.colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MockOffer {
  const _MockOffer({
    required this.id,
    required this.title,
    required this.minOrder,
  });
  final String id;
  final String title;
  final int minOrder;
}

class _OfferTile extends StatelessWidget {
  const _OfferTile({
    required this.offer,
    required this.isApplied,
    required this.onApply,
  });

  final _MockOffer offer;
  final bool isApplied;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: context.colors.surfaceGrey,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 10,
          ),
          child: Row(
            children: [
              Icon(
                Icons.local_offer_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  offer.title,
                  style: context.bodyMedium.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: isApplied ? null : onApply,
                child: Text(isApplied ? 'cart.applied'.tr() : 'cart.apply'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
