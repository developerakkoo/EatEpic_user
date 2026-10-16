import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/app_theme.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/core/typography/app_text_styles.dart';
import 'package:food_app/core/navigation/app_link_router.dart';
import 'package:food_app/core/navigation/shell_navigation.dart';
import 'package:food_app/core/widgets/category_slider.dart';
import 'package:food_app/core/widgets/home_meal_nearby_shimmer.dart';
import 'package:food_app/core/widgets/home_meal_nearby_tile.dart';
import 'package:food_app/core/widgets/home_promo_banner_card.dart';
import 'package:food_app/core/widgets/home_top_kitchen_card.dart';
import 'package:food_app/core/widgets/home_top_kitchen_shimmer.dart';
import 'package:food_app/core/widgets/theme_picker_sheet.dart';
import 'package:food_app/feaetures/hotel_details_screen.dart';
import 'package:food_app/provider/catalog_provider.dart';
import 'package:food_app/provider/category_provider.dart';
import 'package:food_app/provider/hotel_provider.dart';
import 'package:food_app/provider/location_provider.dart';
import 'package:food_app/provider/theme_provider.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.onOpenSearch,
    this.onOpenAccount,
  });

  final VoidCallback? onOpenSearch;
  final VoidCallback? onOpenAccount;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController(viewportFraction: 1);
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _categoriesSectionKey = GlobalKey();
  final GlobalKey _topKitchensSectionKey = GlobalKey();
  final GlobalKey _mealNearbySectionKey = GlobalKey();
  final GlobalKey<CategorySliderState> _categorySliderKey = GlobalKey<CategorySliderState>();
  int _currentPage = 0;
  Timer? _autoPlayTimer;
  String? _highlightedSection;

  late final HomeLinkActions _homeLinkActions = HomeLinkActions(
    scrollToSection: _scrollToSection,
    highlightCategory: _highlightCategory,
  );

  @override
  void initState() {
    super.initState();
    context.read<CatalogProvider>().onHomeInvalidate = () {
      if (mounted) _loadHomeData(force: true);
    };
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadHomeData();
      if (!mounted) return;
      final themeProvider = context.read<ThemeProvider>();
      if (!themeProvider.hasSelectedTheme) {
        await showThemePickerSheet(context, isFirstTime: true);
      }
    });
  }

  Future<void> _loadHomeData({bool force = false}) async {
    final location = context.read<LocationProvider>();
    await location.loadLocation();
    if (!mounted) return;
    await context.read<CatalogProvider>().loadBanners(forceRefresh: force);
    if (!mounted) return;
    await context.read<CategoryProvider>().loadCategories(forceRefresh: force);
    if (!mounted) return;
    await context.read<HotelProvider>().fetchHotels(
          latitude: location.lat,
          longitude: location.lng,
          forceRefresh: force,
        );
    if (!mounted) return;
    final banners = context.read<CatalogProvider>().banners;
    if (banners.isNotEmpty) {
      _startAutoPlay(banners.length);
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _scrollToSection(String sectionKey) async {
    GlobalKey? key;
    switch (sectionKey) {
      case 'categories':
        key = _categoriesSectionKey;
        break;
      case 'top-kitchens':
      case 'topKitchens':
        key = _topKitchensSectionKey;
        break;
      case 'meal-nearby':
      case 'mealNearby':
        key = _mealNearbySectionKey;
        break;
      default:
        key = _categoriesSectionKey;
    }

    final ctx = key.currentContext;
    if (ctx != null) {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
        alignment: 0.08,
      );
    }

    if (!mounted) return;
    setState(() => _highlightedSection = sectionKey);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => _highlightedSection = null);
  }

  Future<void> _highlightCategory(String categoryId) async {
    await _categorySliderKey.currentState?.highlightCategory(categoryId);
  }

  void _startAutoPlay(int count) {
    _autoPlayTimer?.cancel();
    if (count < 2) return;
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pageController.hasClients) return;
      final next = (_currentPage + 1) % count;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onBannerTap(BannerItem banner) {
    final link = banner.redirectLink?.trim();
    if (link == null || link.isEmpty) return;
    AppLinkRouter.navigate(context, link, home: _homeLinkActions);
  }

  Widget _wrapSection({
    required GlobalKey sectionKey,
    required String sectionId,
    required Widget child,
  }) {
    final highlighted = _highlightedSection == sectionId ||
        (sectionId == 'categories' &&
            (_highlightedSection == 'category' || _highlightedSection?.startsWith('category/') == true));

    return Container(
      key: sectionKey,
      decoration: highlighted
          ? BoxDecoration(
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 2),
              borderRadius: BorderRadius.circular(AppRadius.medium),
            )
          : null,
      child: child,
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onOpenSearch,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          child: Ink(
            height: AppLayout.searchBarHeight,
            decoration: BoxDecoration(
              color: context.colors.surfaceGrey,
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: context.colors.textHint, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'home.searchPlaceholder'.tr(),
                    style: context.searchPlaceholder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Text(text, style: context.sectionHeading),
    );
  }

  Widget _buildPromoSection(List<BannerItem> banners) {
    final items = banners.isEmpty
        ? [
            BannerItem(
              id: '',
              title: 'home.promoTitle'.tr(),
              subtitle: 'home.promoSubtitle'.tr(),
              imageUrl: '',
            ),
          ]
        : banners;

    return Column(
      children: [
        SizedBox(
          height: AppLayout.promoBannerHeight,
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: items.length,
            itemBuilder: (context, i) => HomePromoBannerCard(
              banner: items[i],
              onTap: () => _onBannerTap(items[i]),
            ),
          ),
        ),
        HomePromoPageDots(count: items.length, activeIndex: _currentPage),
      ],
    );
  }

  Widget _buildHotelListSliver() {
    final hotelProvider = context.watch<HotelProvider>();

    if (hotelProvider.isLoading) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => const HomeMealNearbyShimmer(),
            childCount: 4,
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final hotel = hotelProvider.hotels[index];
            return HomeMealNearbyTile(
              hotel: hotel,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HotelDetailScreen(hotel: hotel),
                  ),
                );
              },
            );
          },
          childCount: hotelProvider.hotels.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final hotelProvider = context.watch<HotelProvider>();
    final catalogProvider = context.watch<CatalogProvider>();
    final banners = catalogProvider.banners;
    final addressText =
        locationProvider.address ?? 'home.addDeliveryAddress'.tr();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        toolbarHeight: AppLayout.appBarHeight,
        title: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.lg),
          child: InkWell(
            onTap: () => Navigator.pushNamed(
              context,
              '/location-picker',
              arguments: {'fromHome': true},
            ),
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            child: Row(
              children: [
                Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('home.locationTitle'.tr(),
                              style: context.homeLocationTitle),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: context.colors.textSecondary,
                          ),
                        ],
                      ),
                      Text(
                        addressText,
                        style: context.homeAddressSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: InkWell(
              onTap: widget.onOpenAccount,
              customBorder: const CircleBorder(),
              splashFactory: NoSplash.splashFactory,
              highlightColor: Colors.transparent,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: context.colors.surfaceGrey,
                child: Icon(
                  Icons.person_outline_rounded,
                  color: context.colors.textSecondary,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _loadHomeData(force: true),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          cacheExtent: 500,
          slivers: [
            SliverToBoxAdapter(child: _buildSearchBar()),
            SliverToBoxAdapter(child: _buildPromoSection(banners)),
            SliverToBoxAdapter(
              child: _wrapSection(
                sectionKey: _categoriesSectionKey,
                sectionId: 'categories',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionTitle('home.whatsOnYourMind'.tr()),
                    CategorySlider(key: _categorySliderKey),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _wrapSection(
                sectionKey: _topKitchensSectionKey,
                sectionId: 'top-kitchens',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionTitle('home.topKitchen'.tr()),
                    SizedBox(
                      height: AppLayout.kitchenCardHeight,
                      child: hotelProvider.isLoading
                          ? ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                              scrollDirection: Axis.horizontal,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: 3,
                              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                              itemBuilder: (_, __) => const HomeTopKitchenShimmer(),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: hotelProvider.hotels.length,
                              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                              itemBuilder: (context, index) {
                                final hotel = hotelProvider.hotels[index];
                                return HomeTopKitchenCard(
                                  hotel: hotel,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => HotelDetailScreen(hotel: hotel),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _wrapSection(
                sectionKey: _mealNearbySectionKey,
                sectionId: 'meal-nearby',
                child: _buildSectionTitle('home.mealNearby'.tr()),
              ),
            ),
            _buildHotelListSliver(),
            SliverToBoxAdapter(
              child: SizedBox(height: AppLayout.scrollBottomInset),
            ),
          ],
        ),
      ),
    );
  }
}
