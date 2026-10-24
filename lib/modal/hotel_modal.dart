class HotelModel {
  final String id;
  final String name;
  final String imageUrl;
  final double rating;
  final int reviewCount;
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
    this.reviewCount = 0,
    required this.cuisine,
    required this.deliveryTime,
    required this.priceForOne,
    required this.distance,
    required this.isVeg,
    required this.isOpen,
    this.discount,
  });

  bool get hasRatings => reviewCount > 0;

  HotelModel copyWith({
    double? rating,
    int? reviewCount,
  }) {
    return HotelModel(
      id: id,
      name: name,
      imageUrl: imageUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      cuisine: cuisine,
      deliveryTime: deliveryTime,
      priceForOne: priceForOne,
      distance: distance,
      isVeg: isVeg,
      isOpen: isOpen,
      discount: discount,
    );
  }
}