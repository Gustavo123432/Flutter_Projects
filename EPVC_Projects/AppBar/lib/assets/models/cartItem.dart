class CartItem {
  final int? id;
  final String name;
  final String image;
  final double price;
  final String quantity;

  CartItem({
    this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.quantity,
  });

  // Convert CartItem to Map (for SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'price': price,
      'quantity': quantity,
    };
  }

  // Convert Map to CartItem
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'],
      name: map['name'],
      image: map['image'],
      price: map['price'],
      quantity: map['quantity'],
    );
  }
}
