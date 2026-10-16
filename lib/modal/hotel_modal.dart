class HotelModel {
  final String id;
  final String name;
  final String imageUrl;
  final double rating;
  final String cuisine;
  final int deliveryTime;
  final int priceForOne;
  final double distance;
  final bool isVeg;
  final bool isOpen;
  final String? discount;

  HotelModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.cuisine,
    required this.deliveryTime,
    required this.priceForOne,
    required this.distance,
    required this.isVeg,
    required this.isOpen,
    this.discount,
  });
}