class Product {
  String id;
  String name;
  String description;
  double price;
  int quantity;
  bool available;
  String category;
  String base64Image;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.available,
    required this.category,
    required this.base64Image,
  });
}
