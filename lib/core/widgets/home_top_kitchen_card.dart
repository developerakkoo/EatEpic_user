import 'package:flutter/material.dart';
import 'package:food_app/core/design/home_design_tokens.dart';
import 'package:food_app/core/widgets/home_kitchen_card_parts.dart';
import 'package:food_app/modal/hotel_modal.dart';

class HomeTopKitchenCard extends StatelessWidget {
  const HomeTopKitchenCard({
    super.key,
    required this.hotel,
    this.onTap,
  });

  final HotelModel hotel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = KitchenRestaurantCard(
      imageUrl: hotel.imageUrl,
      name: hotel.name,
      rating: hotel.rating,
      reviewCount: hotel.reviewCount,
      deliveryTimeMinutes: hotel.deliveryTime,
      discountLabel: hotel.discount,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(HomeDesignTokens.kitchenCardRadius),
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: hotel.isOpen ? 1 : 0.55,
            child: card,
          ),
        ),
      );
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: hotel.isOpen ? 1 : 0.55,
      child: card,
    );
  }
}
