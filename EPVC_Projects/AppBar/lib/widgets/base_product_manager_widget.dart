import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/base_product_service.dart';
import 'auto_base_product_detector.dart';

class BaseProductManagerWidget extends StatefulWidget {
  final List<Product> allProducts;

  const BaseProductManagerWidget({
    Key? key,
    required this.allProducts,
  }) : super(key: key);

  @override
  _BaseProductManagerWidgetState createState() => _BaseProductManagerWidgetState();
}

class _BaseProductManagerWidgetState extends State<BaseProductManagerWidget> {
  List<Product> baseProducts = [];
  List<Product> variations = [];
  Map<String, List<Product>> baseProductVariations = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBaseProducts();
  }

  Future<void> _loadBaseProducts() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Initialize the base product manager
      BaseProductManager.initialize(widget.allProducts);
      
      // Get base products and variations
      baseProducts = BaseProductManager.getAllBaseProducts();
      variations = BaseProductManager.getAllVariations();
      
      // Group variations by base product
      for (Product baseProduct in baseProducts) {
        baseProductVariations[baseProduct.id] = BaseProductManager.getVariations(baseProduct.id);
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error loading base products: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestão de Produtos Base'),
        backgroundColor: Color.fromARGB(255, 246, 141, 45),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildBaseProductsSection(),
                Expanded(child: _buildVariationsSection()),
              ],
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => _showAutoDetector(),
            backgroundColor: Colors.blue,
            child: Icon(Icons.auto_awesome, color: Colors.white),
            heroTag: "autoDetector",
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () => _showAddBaseProductDialog(),
            backgroundColor: Color.fromARGB(255, 246, 141, 45),
            child: Icon(Icons.add, color: Colors.white),
            heroTag: "addBase",
          ),
        ],
      ),
    );
  }

  Widget _buildBaseProductsSection() {
    return Card(
      margin: EdgeInsets.all(8),
      child: ExpansionTile(
        title: Text(
          'Produtos Base (${baseProducts.length})',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        children: baseProducts.map((baseProduct) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange,
              child: Text(
                baseProduct.name.substring(0, 1).toUpperCase(),
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(baseProduct.name),
            subtitle: Text('Quantidade: ${baseProduct.quantity}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${baseProductVariations[baseProduct.id]?.length ?? 0} variações'),
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _showEditBaseProductDialog(baseProduct),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVariationsSection() {
    return Card(
      margin: EdgeInsets.all(8),
      child: ExpansionTile(
        title: Text(
          'Variações (${variations.length})',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
                 children: variations.map((variation) {
           Product? baseProduct = BaseProductManager.getBaseProductForVariation(variation.id);
           return ListTile(
             leading: CircleAvatar(
               backgroundColor: Colors.blue,
               child: Text(
                 variation.name.substring(0, 1).toUpperCase(),
                 style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
               ),
             ),
             title: Text(variation.name),
             subtitle: Text('Base: ${baseProduct?.name ?? 'Não definido'} - Quantidade: ${baseProduct?.quantity ?? variation.quantity}'),
             trailing: IconButton(
               icon: Icon(Icons.link),
               onPressed: () => _showLinkVariationDialog(variation),
             ),
           );
         }).toList(),
      ),
    );
  }

  void _showAddBaseProductDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Adicionar Produto Base'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Selecione um produto para torná-lo base:'),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.allProducts.length,
                  itemBuilder: (context, index) {
                    Product product = widget.allProducts[index];
                    bool isAlreadyBase = baseProducts.any((bp) => bp.id == product.id);
                    
                    return ListTile(
                      title: Text(product.name),
                      subtitle: Text('Quantidade: ${product.quantity}'),
                      trailing: isAlreadyBase 
                          ? Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: isAlreadyBase ? null : () {
                        _makeProductBase(product);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void _showEditBaseProductDialog(Product baseProduct) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Editar Produto Base'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Produto: ${baseProduct.name}'),
              SizedBox(height: 8),
              Text('Quantidade: ${baseProduct.quantity}'),
              SizedBox(height: 16),
              Text('Variações:'),
              ...(baseProductVariations[baseProduct.id] ?? []).map((variation) {
                return ListTile(
                  title: Text(variation.name),
                  trailing: IconButton(
                    icon: Icon(Icons.link_off, color: Colors.red),
                    onPressed: () => _unlinkVariation(variation.id),
                  ),
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  void _showLinkVariationDialog(Product variation) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ligar Variação'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Variação: ${variation.name}'),
              SizedBox(height: 16),
              Text('Selecione o produto base:'),
              SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: baseProducts.length,
                  itemBuilder: (context, index) {
                    Product baseProduct = baseProducts[index];
                    return ListTile(
                      title: Text(baseProduct.name),
                      subtitle: Text('Quantidade: ${baseProduct.quantity}'),
                      onTap: () {
                        _linkVariationToBase(variation, baseProduct);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void _makeProductBase(Product product) async {
    try {
      // Update the product to be a base product
      var response = await BaseProductService.setBaseProductRelationship(
        variationId: product.id,
        baseProductId: product.id,
        baseProductName: product.name,
      );

      if (response) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product.name} agora é um produto base')),
        );
        _loadBaseProducts(); // Reload the data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao definir produto base'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print('Error making product base: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _linkVariationToBase(Product variation, Product baseProduct) async {
    try {
      var response = await BaseProductService.setBaseProductRelationship(
        variationId: variation.id,
        baseProductId: baseProduct.id,
        baseProductName: baseProduct.name,
      );

      if (response) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${variation.name} ligado a ${baseProduct.name}')),
        );
        _loadBaseProducts(); // Reload the data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao ligar variação'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print('Error linking variation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _unlinkVariation(String variationId) async {
    try {
      var response = await BaseProductService.setBaseProductRelationship(
        variationId: variationId,
        baseProductId: '',
        baseProductName: '',
      );

      if (response) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Variação desligada')),
        );
        _loadBaseProducts(); // Reload the data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao desligar variação'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print('Error unlinking variation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showAutoDetector() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AutoBaseProductDetector(
          allProducts: widget.allProducts,
          onRelationshipsUpdated: _loadBaseProducts,
        ),
      ),
    );
  }
} 