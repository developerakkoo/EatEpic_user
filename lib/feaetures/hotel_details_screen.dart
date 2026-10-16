import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/core/di/app_services.dart';
import 'package:food_app/core/widgets/menu_card.dart';
import 'package:food_app/modal/hotel_modal.dart';
import 'package:food_app/modal/menu_item_modal.dart';
import 'package:food_app/feaetures/subscription_plans_screen.dart';
import 'package:food_app/provider/cart_provider.dart';
import 'package:provider/provider.dart';

class HotelDetailScreen extends StatefulWidget {
  final HotelModel hotel;

  const HotelDetailScreen({super.key, required this.hotel});

  @override
  State<HotelDetailScreen> createState() => _HotelDetailScreenState();
}

class _HotelDetailScreenState extends State<HotelDetailScreen>
    with SingleTickerProviderStateMixin {
  final _kitchenRepo = AppServices.instance.kitchenRepository;
  List<MenuItemModel> _menuItems = [];
  bool _loadingMenu = true;

  AnimationController? _slideController;
  Animation<Offset>? _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController!,
      curve: Curves.easeOutCubic,
    ));
    _loadMenu();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cart = context.read<CartProvider>();
      if (cart.itemCount > 0) _slideController?.forward();
    });
  }

  Future<void> _loadMenu() async {
    try {
      final data = await _kitchenRepo.getKitchenMenu(widget.hotel.id);
      final items = data['items'] as List<dynamic>? ?? [];
      _menuItems = items.map((raw) {
        final json = raw as Map<String, dynamic>;
        return MenuItemModel(
          id: json['_id']?.toString() ?? '',
          name: json['name']?.toString() ?? '',
          description: json['description']?.toString(),
          price: (json['price'] as num?)?.toInt() ?? 0,
          imageUrl: json['image']?.toString() ?? '',
          isVeg: json['isVeg'] == true,
        );
      }).toList();
    } catch (_) {
      _menuItems = [];
    }
    if (mounted) {
      setState(() => _loadingMenu = false);
    }
  }

  @override
  void dispose() {
    _slideController?.dispose();
    super.dispose();
  }

  void _onQuantityChanged(MenuItemModel item, int newValue) {
    final cart = context.read<CartProvider>();
    cart.addItem(widget.hotel, item, newValue);
    if (newValue > 0) {
      _slideController?.forward();
    } else {
      _slideController?.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hotel = widget.hotel;
    final cartProvider = context.watch<CartProvider>();
    final cartItemCount = cartProvider.itemCount;
    final isNetwork = hotel.imageUrl.startsWith('http');

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                title: Text(hotel.name),
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                    tag: 'hotel_${hotel.id}',
                    child: SizedBox(
                      width: double.infinity,
                      height: 220,
                      child: isNetwork
                          ? CachedNetworkImage(
                              imageUrl: hotel.imageUrl,
                              fit: BoxFit.cover,
                              memCacheWidth: 800,
                            )
                          : Image.asset(hotel.imageUrl, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hotel.name,
                        style: context.headingLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(hotel.cuisine, style: context.bodyLarge),
                      const SizedBox(height: AppSpacing.md),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SubscriptionPlansScreen(
                              kitchenId: hotel.id,
                              kitchenName: hotel.name,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.repeat),
                        label: Text('hotelDetail.mealSubscriptions'.tr()),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (_loadingMenu)
                        const Center(child: CircularProgressIndicator())
                      else if (_menuItems.isEmpty)
                        Text('hotelDetail.noMenuItems'.tr(),
                            style: context.bodyMedium)
                      else
                        ..._menuItems.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: MenuCard(
                              item: item,
                              quantity: cartProvider.quantityFor(hotel.id, item.id),
                              onQuantityChanged: (v) => _onQuantityChanged(item, v),
                              maxQuantity: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_slideAnimation != null && cartItemCount > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SlideTransition(
                position: _slideAnimation!,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/cart'),
                      child: Text('hotelDetail.viewCart'
                          .tr(namedArgs: {'count': '$cartItemCount'})),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
