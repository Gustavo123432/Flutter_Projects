import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/base_product_service.dart';

class AutoBaseProductDetector extends StatefulWidget {
  final List<Product> allProducts;
  final Function() onRelationshipsUpdated;

  const AutoBaseProductDetector({
    Key? key,
    required this.allProducts,
    required this.onRelationshipsUpdated,
  }) : super(key: key);

  @override
  _AutoBaseProductDetectorState createState() => _AutoBaseProductDetectorState();
}

class _AutoBaseProductDetectorState extends State<AutoBaseProductDetector> {
  List<Map<String, dynamic>> suggestedRelationships = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _detectRelationships();
  }

  void _detectRelationships() {
    setState(() {
      isLoading = true;
    });

    // Common base product names
    final baseProductNames = [
      'Pão',
      'Croissant',
      'Bico de Pato',
      'Panado',
      'Rissol',
    ];

    Map<String, List<Product>> detectedGroups = {};

    // Group products by potential base names
    for (Product product in widget.allProducts) {
      String productName = product.name.toLowerCase();
      
      // Check if this is a base product
      for (String baseName in baseProductNames) {
        if (productName.contains(baseName.toLowerCase())) {
          if (!detectedGroups.containsKey(baseName)) {
            detectedGroups[baseName] = [];
          }
          detectedGroups[baseName]!.add(product);
          break;
        }
      }
    }

    // Find base products and their variations
    List<Map<String, dynamic>> relationships = [];
    
    for (String baseName in baseProductNames) {
      if (detectedGroups.containsKey(baseName)) {
        List<Product> products = detectedGroups[baseName]!;
        
        // Find the base product (the one without "com" in the name)
        Product? baseProduct;
        List<Product> variations = [];
        
        for (Product product in products) {
          if (BaseProductManager.isLikelyVariation(product.name)) {
            variations.add(product);
          } else {
            // This might be the base product
            baseProduct = product;
          }
        }
        
        // If no clear base product found, use the first one
        if (baseProduct == null && products.isNotEmpty) {
          baseProduct = products.first;
        }
        
        if (baseProduct != null && variations.isNotEmpty) {
          relationships.add({
            'baseProduct': baseProduct,
            'variations': variations,
            'suggested': true,
          });
        }
      }
    }

    setState(() {
      suggestedRelationships = relationships;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detector Automático de Produtos Base'),
        backgroundColor: Color.fromARGB(255, 246, 141, 45),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _detectRelationships,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : suggestedRelationships.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Nenhuma relação detectada',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Verifique se os produtos têm nomes consistentes',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: suggestedRelationships.length,
                  itemBuilder: (context, index) {
                    var relationship = suggestedRelationships[index];
                    Product baseProduct = relationship['baseProduct'];
                    List<Product> variations = relationship['variations'];
                    
                    return Card(
                      margin: EdgeInsets.all(8),
                      child: ExpansionTile(
                        title: Text(
                          '${baseProduct.name} (${variations.length} variações)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Quantidade base: ${baseProduct.quantity}'),
                        children: [
                          // Base product info
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.orange,
                              child: Icon(Icons.inventory, color: Colors.white),
                            ),
                            title: Text(baseProduct.name),
                            subtitle: Text('Produto Base - Quantidade: ${baseProduct.quantity}'),
                            trailing: Icon(Icons.star, color: Colors.orange),
                          ),
                          
                                                     // Variations
                           ...variations.map((variation) {
                             return ListTile(
                               leading: CircleAvatar(
                                 backgroundColor: Colors.blue,
                                 child: Icon(Icons.link, color: Colors.white),
                               ),
                               title: Text(variation.name),
                               subtitle: Text('Variação - Quantidade: ${baseProduct.quantity} (Base: ${baseProduct.name})'),
                               trailing: IconButton(
                                 icon: Icon(Icons.add_link, color: Colors.green),
                                 onPressed: () => _linkVariationToBase(variation, baseProduct),
                               ),
                             );
                           }).toList(),
                          
                          // Action buttons
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _linkAllVariations(variations, baseProduct),
                                  icon: Icon(Icons.link),
                                  label: Text('Ligar Todas'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _makeBaseProduct(baseProduct),
                                  icon: Icon(Icons.star),
                                  label: Text('Definir como Base'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  void _linkVariationToBase(Product variation, Product baseProduct) async {
    try {
      bool success = await BaseProductService.setBaseProductRelationship(
        variationId: variation.id,
        baseProductId: baseProduct.id,
        baseProductName: baseProduct.name,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${variation.name} ligado a ${baseProduct.name}'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onRelationshipsUpdated();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao ligar variação'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error linking variation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _linkAllVariations(List<Product> variations, Product baseProduct) async {
    try {
      int successCount = 0;
      
      for (Product variation in variations) {
        bool success = await BaseProductService.setBaseProductRelationship(
          variationId: variation.id,
          baseProductId: baseProduct.id,
          baseProductName: baseProduct.name,
        );
        
        if (success) successCount++;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$successCount de ${variations.length} variações ligadas com sucesso'),
          backgroundColor: successCount == variations.length ? Colors.green : Colors.orange,
        ),
      );
      
      widget.onRelationshipsUpdated();
    } catch (e) {
      print('Error linking all variations: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _makeBaseProduct(Product product) async {
    try {
      bool success = await BaseProductService.setBaseProductRelationship(
        variationId: product.id,
        baseProductId: product.id,
        baseProductName: product.name,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} definido como produto base'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onRelationshipsUpdated();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao definir produto base'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error making base product: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 