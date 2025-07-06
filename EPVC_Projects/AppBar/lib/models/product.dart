class Product {
  String id;
  String name;
  String description;
  double price;
  int quantity;
  bool available;
  String category;
  String base64Image;
  
  // New fields for base product system
  String? baseProductId; // ID of the base product (null if this is a base product)
  String? baseProductName; // Name of the base product
  bool isBaseProduct; // Whether this product is a base product
  List<String> variationIds; // List of variation product IDs (for base products)
  List<String> variationNames; // List of variation product names (for base products)

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.available,
    required this.category,
    required this.base64Image,
    this.baseProductId,
    this.baseProductName,
    this.isBaseProduct = false,
    this.variationIds = const [],
    this.variationNames = const [],
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
      baseProductId: json['BaseProductId']?.toString(),
      baseProductName: json['BaseProductName']?.toString(),
      isBaseProduct: json['IsBaseProduct'] == '1' || json['IsBaseProduct'] == true,
      variationIds: json['VariationIds'] != null 
          ? (json['VariationIds'] as String).split(',').where((id) => id.isNotEmpty).toList()
          : [],
      variationNames: json['VariationNames'] != null 
          ? (json['VariationNames'] as String).split(',').where((name) => name.isNotEmpty).toList()
          : [],
    );
  }

  // Method to convert to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Nome': name,
      'Descricao': description,
      'Preco': price,
      'Qtd': quantity,
      'Categoria': category,
      'Imagem': base64Image,
      'BaseProductId': baseProductId,
      'BaseProductName': baseProductName,
      'IsBaseProduct': isBaseProduct ? '1' : '0',
      'VariationIds': variationIds.join(','),
      'VariationNames': variationNames.join(','),
    };
  }

  // Method to check if this product is a variation of another product
  bool get isVariation => baseProductId != null && baseProductId!.isNotEmpty;

  // Method to get the effective quantity (for variations, this is the base product quantity)
  int get effectiveQuantity => isVariation ? quantity : quantity;

  // Method to check if this product is available (for variations, check base product availability)
  bool get isEffectivelyAvailable => effectiveQuantity >= 1;

  // Method to get display quantity (for variations, show base product quantity)
  int get displayQuantity => isVariation ? quantity : quantity;

  // Method to get display availability text
  String get displayAvailabilityText {
    if (isVariation && baseProductName != null) {
      return 'Disponível: $quantity (Base: $baseProductName)';
    }
    return 'Disponível: $quantity';
  }
}

// New class to manage base product relationships
class BaseProductManager {
  static final Map<String, Product> _baseProducts = {};
  static final Map<String, List<Product>> _productVariations = {};

  // Initialize the manager with products
  static void initialize(List<Product> products) {
    _baseProducts.clear();
    _productVariations.clear();

    for (Product product in products) {
      if (product.isBaseProduct) {
        _baseProducts[product.id] = product;
        _productVariations[product.id] = [];
      }
    }

    // Group variations under their base products
    for (Product product in products) {
      if (product.isVariation && product.baseProductId != null) {
        if (_productVariations.containsKey(product.baseProductId)) {
          _productVariations[product.baseProductId]!.add(product);
        }
      }
    }
  }

  // Get base product by ID
  static Product? getBaseProduct(String baseProductId) {
    return _baseProducts[baseProductId];
  }

  // Get all variations of a base product
  static List<Product> getVariations(String baseProductId) {
    return _productVariations[baseProductId] ?? [];
  }

  // Get base product for a variation
  static Product? getBaseProductForVariation(String variationId) {
    for (var entry in _productVariations.entries) {
      for (Product variation in entry.value) {
        if (variation.id == variationId) {
          return _baseProducts[entry.key];
        }
      }
    }
    return null;
  }

  // Check if a product name contains base product keywords
  static bool isLikelyVariation(String productName) {
    final baseKeywords = [
      'com', 'com queijo', 'com manteiga', 'com fiambre', 'com presunto',
      'com chouriço', 'com atum', 'com frango', 'com carne', 'com ovo','com panado','com rissol'
    ];
    final lowerName = productName.toLowerCase();
    return baseKeywords.any((keyword) => lowerName.contains(keyword));
  }

  // Suggest base product name from variation name
  static String? suggestBaseProductName(String variationName) {
    final lowerName = variationName.toLowerCase();
    
    // Common patterns for bread variations
    if (lowerName.contains('pão')) {
      if (lowerName.contains('com queijo')) return 'Pão';
      if (lowerName.contains('com manteiga')) return 'Pão';
      if (lowerName.contains('com fiambre')) return 'Pão';
      if (lowerName.contains('com presunto')) return 'Pão';
      if (lowerName.contains('com chouriço')) return 'Pão';
      if (lowerName.contains('com atum')) return 'Pão';
      if (lowerName.contains('com frango')) return 'Pão';
      if (lowerName.contains('com carne')) return 'Pão';
      if (lowerName.contains('com ovo')) return 'Pão';
      if (lowerName.contains('com panado')) return 'Pão';
      if (lowerName.contains('com rissol')) return 'Pão';
    }
    
    // Croissant variations
    if (lowerName.contains('croissant')) {
      if (lowerName.contains('com queijo')) return 'Croissant';
      if (lowerName.contains('com manteiga')) return 'Croissant';
      if (lowerName.contains('com fiambre')) return 'Croissant';
      if (lowerName.contains('com presunto')) return 'Croissant';
      if (lowerName.contains('com doce')) return 'Croissant';
    }
    
    // Bico de Pato variations
    if (lowerName.contains('bico de pato') || lowerName.contains('bico')) {
      if (lowerName.contains('com queijo')) return 'Bico de Pato';
      if (lowerName.contains('com manteiga')) return 'Bico de Pato';
      if (lowerName.contains('com fiambre')) return 'Bico de Pato';
      if (lowerName.contains('com presunto')) return 'Bico de Pato';
      if (lowerName.contains('com chouriço')) return 'Bico de Pato';
      if (lowerName.contains('com atum')) return 'Bico de Pato';
    }

    return null;
  }

  // Get all base products
  static List<Product> getAllBaseProducts() {
    return _baseProducts.values.toList();
  }

  // Get all variations
  static List<Product> getAllVariations() {
    List<Product> allVariations = [];
    for (var variations in _productVariations.values) {
      allVariations.addAll(variations);
    }
    return allVariations;
  }
}
