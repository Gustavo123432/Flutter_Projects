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

  // Add a factory constructor to ensure available is set based on quantity
  factory Product.fromJson(Map<String, dynamic> json) {
    int quantity = int.tryParse(json['Qtd']?.toString() ?? '0') ?? 0;
    return Product(
      id: json['Id']?.toString() ?? '',
      name: json['Nome']?.toString() ?? '',
      description: json['Nome']?.toString() ?? '',
      price: double.tryParse(json['Preco']?.toString() ?? '0') ?? 0.0,
      quantity: quantity,
      available: quantity >= 1,
      category: json['Categoria']?.toString() ?? '',
      base64Image: json['Imagem']?.toString() ?? '',
    );
  }
}
