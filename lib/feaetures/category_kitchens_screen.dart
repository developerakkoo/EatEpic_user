import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:food_app/core/design/app_spacing.dart';
import 'package:food_app/core/widgets/home_top_kitchen_card.dart';
import 'package:food_app/feaetures/hotel_details_screen.dart';
import 'package:food_app/provider/hotel_provider.dart';
import 'package:food_app/provider/location_provider.dart';
import 'package:provider/provider.dart';

class CategoryKitchensScreen extends StatefulWidget {
  const CategoryKitchensScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  final String categoryId;
  final String categoryName;

  @override
  State<CategoryKitchensScreen> createState() => _CategoryKitchensScreenState();
}

class _CategoryKitchensScreenState extends State<CategoryKitchensScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool force = false}) async {
    final location = context.read<LocationProvider>();
    await location.loadLocation();
    if (!mounted) return;
    await context.read<HotelProvider>().fetchHotels(
          latitude: location.lat,
          longitude: location.lng,
          categoryId: widget.categoryId,
          forceRefresh: force,
        );
  }

  @override
  Widget build(BuildContext context) {
    final hotelProvider = context.watch<HotelProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryName)),
      body: RefreshIndicator(
        onRefresh: () => _load(force: true),
        child: hotelProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : hotelProvider.hotels.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 120),
                      Center(child: Text('category.noKitchens'.tr())),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: hotelProvider.hotels.length,
                    itemBuilder: (context, index) {
                      final hotel = hotelProvider.hotels[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: HomeTopKitchenCard(
                          hotel: hotel,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HotelDetailScreen(hotel: hotel),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
