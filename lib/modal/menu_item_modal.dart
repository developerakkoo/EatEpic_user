class MenuItemModel {
  final String id;
  final String name;
  final String? description;
  final int price;
  final String imageUrl;
  final bool isVeg;

  const MenuItemModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.imageUrl,
    this.isVeg = true,
  });
}
