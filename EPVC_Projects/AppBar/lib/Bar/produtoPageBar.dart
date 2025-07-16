import 'dart:async';
import 'dart:convert';
import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:http/http.dart' as http;
import 'package:appbar_epvc/Bar/drawerBar.dart';
import 'package:appbar_epvc/login.dart';
import 'package:appbar_epvc/models/product.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appbar_epvc/widgets/loading_overlay.dart';
import '../services/base_product_service.dart';
import 'package:appbar_epvc/config/app_config.dart';

List<Product> filteredProducts =
    []; // Assuming this is where filtered products will be stored

class ProdutoPageBar extends StatefulWidget {
  @override
  _ProdutoPageBarState createState() => _ProdutoPageBarState();
}

class _ProdutoPageBarState extends State<ProdutoPageBar> {
  List<Product> products = [];
  List<Product> filteredProducts = []; // Initialize filteredProducts
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  late StreamController<List<dynamic>> _streamController;

  String selectedSortOption = 'Ascending';
  double? minPrice;
  double? maxPrice;
  String normalize(String input) {
    return removeDiacritics(input)
        .toLowerCase(); // Remove diacritics and convert to lowercase
  }

  @override
  void initState() {
    super.initState();
    _streamController =
        StreamController<List<dynamic>>(); // Initialize StreamController
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/appBarAPI_Post.php'),
        body: {'query_param': '4'},
      );

      if (response.statusCode == 200) {
        List<dynamic> responseBody = json.decode(response.body);
        List<Product> fetchedProducts = responseBody.map((productData) {
          return Product.fromJson(productData);
        }).toList();

        setState(() {
          products = fetchedProducts;
          filteredProducts = List.from(products);
          isLoading = false;
        });
      } else {
        throw Exception(
            'Erro ao carregar o produto\nPor favor contacte o responsável!');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error: $e');
    }
  }

  void _showFilterDialog() {
    String? selectedCategory;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filtrar por Categoria'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return DropdownButtonFormField<String>(
                value: selectedCategory,
                onChanged: (newValue) {
                  setState(() {
                    selectedCategory = newValue;
                  });
                },
                items: products
                    .map((product) => product.category)
                    .toSet()
                    .toList()
                    .map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
              );
            },
          ),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              style: TextButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Filtrar'),
              style: TextButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () {
                setState(() {
                  filteredProducts.clear();
                  products.forEach((product) {
                    if (product.category == selectedCategory) {
                      filteredProducts.add(product);
                    }
                  });
                });
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Mostrar Todos'),
              style: TextButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () {
                setState(() {
                  filteredProducts = List.from(products);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void updateProduct(String id, bool newAvailability) async {
    var availableValue = newAvailability ? "1" : "0";
    var response = await http.get(
      Uri.parse(
          '${AppConfig.apiBaseUrl}/appBarAPI_GET.php?query_param=18&op=1&id=$id&qtd=$availableValue'),
    );
    if (response.statusCode == 200) {
      setState(() {
        var index = products.indexWhere((product) => product.id == id);
        if (index != -1) {
          products[index].available = newAvailability;
        }
      });
    } else {
      print('Erro ao atualizar o produto\nPor favor contacte o responsável!');
    }
  }

  void logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Pretende fazer Log Out?'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Confirmar'),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext ctx) => LoginForm(),
                  ),
                );
                ModalRoute.withName('/');
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _onRefresh() async {
    await fetchData();
  }

  void _filterItemsSearch() {
    final query = normalize(_searchController.text);
    setState(() {
      filteredProducts = products.where((item) {
        return normalize(item.name).contains(query);
      }).toList();
    });
  }

  void updateProductQuantity(String id, int quantityToAdd) async {
    try {
      // Show loading indicator
      setState(() {
        isLoading = true;
      });
      
      // First, check if this is a base product
      var product = products.firstWhere((p) => p.id == id);
      
      // Check if this product has variations (is a base product)
      var variations = products.where((p) => p.baseProductId == id).toList();
      bool isBaseProduct = product.isBaseProduct || variations.isNotEmpty;
      
      // Also check if this product name suggests it's a base product
      String productName = product.name.toLowerCase();
      bool isLikelyBaseProduct = (productName.contains('pão') && 
                                 !productName.contains('com') && 
                                 !productName.contains('misto') &&
                                 !productName.contains('fiambre') &&
                                 !productName.contains('presunto') &&
                                 !productName.contains('chouriço') &&
                                 !productName.contains('atum') &&
                                 !productName.contains('salsicha') &&
                                 !productName.contains('frango')) ||
                                (productName.contains('croissant') && !productName.contains('com')) ||
                                (productName.contains('bico') && !productName.contains('com')) ||
                                productName.contains('panado') ||
                                productName.contains('rissol');
      
      if (isBaseProduct || isLikelyBaseProduct) {
        // This is a base product, update it and all its variations
        await _updateBaseProductAndVariations(id, quantityToAdd);
      } else {
        // This is a variation, update the base product instead
        await _updateVariationQuantity(id, quantityToAdd);
      }
    } catch (e) {
      print('Error updating product quantity: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar quantidade: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Hide loading indicator
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateBaseProductAndVariations(String baseProductId, int quantityToAdd) async {
    try {
      // Get the base product
      var baseProduct = products.firstWhere((p) => p.id == baseProductId);
      
      // Get all variations of this base product
      var variations = products.where((p) => p.baseProductId == baseProductId).toList();
      
      // Also find variations by name pattern if no linked variations found
      if (variations.isEmpty) {
        String baseName = baseProduct.name.toLowerCase();
        print('Looking for variations of: $baseName');
        
        if (baseName.contains('pão')) {
          // Find all pão variations (Pão com Queijo, Pão Misto, etc.)
          variations = products.where((p) => 
            p.name.toLowerCase().contains('pão') && 
            p.id != baseProductId &&
            (p.name.toLowerCase().contains('com') || 
             p.name.toLowerCase().contains('misto') ||
             p.name.toLowerCase().contains('fiambre') ||
             p.name.toLowerCase().contains('presunto') ||
             p.name.toLowerCase().contains('chouriço') ||
             p.name.toLowerCase().contains('atum') ||
             p.name.toLowerCase().contains('salsicha') ||
             p.name.toLowerCase().contains('frango'))
          ).toList();
          print('Found pão variations: ${variations.map((v) => v.name).join(', ')}');
        } else if (baseName.contains('croissant')) {
          variations = products.where((p) => 
            p.name.toLowerCase().contains('croissant') && 
            p.name.toLowerCase().contains('com') &&
            p.id != baseProductId
          ).toList();
        } else if (baseName.contains('bico')) {
          variations = products.where((p) => 
            p.name.toLowerCase().contains('bico') && 
            p.name.toLowerCase().contains('com') &&
            p.id != baseProductId
          ).toList();
        } else if (baseName.contains('panado')) {
          variations = products.where((p) => 
            p.name.toLowerCase().contains('panado') &&
            p.id != baseProductId
          ).toList();
        } else if (baseName.contains('rissol')) {
          variations = products.where((p) => 
            p.name.toLowerCase().contains('rissol') &&
            p.id != baseProductId
          ).toList();
        }
      }
      
      // Update base product first
      var baseResponse = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/appBarAPI_GET.php?query_param=18&op=1&ids=$baseProductId&quantities=$quantityToAdd'),
      );
      
      if (baseResponse.statusCode == 200) {
        // Get the new base product quantity
        int newBaseQuantity = baseProduct.quantity + quantityToAdd;
        
        // Update base product in local state
        setState(() {
          var baseIndex = products.indexWhere((product) => product.id == baseProductId);
          if (baseIndex != -1) {
            products[baseIndex].quantity = newBaseQuantity;
            products[baseIndex].available = newBaseQuantity >= 1;
          }
        });
        
        // Update each variation individually in the database
        List<String> updatedVariations = [];
        List<String> alreadyUpdatedVariations = [];
        
        for (var variation in variations) {
          try {
            // Calculate how much to add to this variation to match base product
            int currentVariationQuantity = variation.quantity;
            int quantityToAddToVariation = newBaseQuantity - currentVariationQuantity;
            
            if (quantityToAddToVariation != 0) {
              print('Updating variation ${variation.name}: current=$currentVariationQuantity, target=$newBaseQuantity, adding=$quantityToAddToVariation');
              
              var variationResponse = await http.get(
                Uri.parse('${AppConfig.apiBaseUrl}/appBarAPI_GET.php?query_param=18&op=1&ids=${variation.id}&quantities=$quantityToAddToVariation'),
              );
              
              if (variationResponse.statusCode == 200) {
                // Update variation in local state
                setState(() {
                  var variationIndex = products.indexWhere((product) => product.id == variation.id);
                  if (variationIndex != -1) {
                    products[variationIndex].quantity = newBaseQuantity;
                    products[variationIndex].available = newBaseQuantity >= 1;
                  }
                });
                
                updatedVariations.add(variation.name);
                print('✅ Updated variation in database: ${variation.name}');
              } else {
                print('❌ Failed to update variation in database: ${variation.name}');
              }
            } else {
              // Variation already has the correct quantity
              alreadyUpdatedVariations.add(variation.name);
              print('ℹ️ Variation ${variation.name} already has correct quantity: $currentVariationQuantity');
            }
          } catch (e) {
            print('❌ Error updating variation ${variation.name}: $e');
          }
        }
        
        // Show success message
        String message;
        if (variations.isNotEmpty) {
          if (updatedVariations.isNotEmpty && alreadyUpdatedVariations.isNotEmpty) {
            message = '${baseProduct.name} atualizado. ${updatedVariations.length} variações atualizadas na BD, ${alreadyUpdatedVariations.length} já estavam corretas.';
          } else if (updatedVariations.isNotEmpty) {
            message = '${baseProduct.name} e ${updatedVariations.length} variações atualizadas na base de dados';
          } else {
            message = '${baseProduct.name} atualizado. Todas as variações já estavam corretas.';
          }
        } else {
          message = '${baseProduct.name} atualizado';
        }
            
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
        
        // Debug info
        print('Updated base product: ${baseProduct.name}');
        print('Updated variations in database: ${updatedVariations.join(', ')}');
        print('Already correct variations: ${alreadyUpdatedVariations.join(', ')}');
      } else {
        throw Exception('Erro ao atualizar produto base');
      }
    } catch (e) {
      print('Error updating base product and variations: $e');
      rethrow;
    }
  }

  Future<void> _updateVariationQuantity(String variationId, int quantityToAdd) async {
    try {
      // Get the variation product
      var variation = products.firstWhere((p) => p.id == variationId);
      
      if (variation.baseProductId != null && variation.baseProductId!.isNotEmpty) {
        // Update the base product instead
        await _updateBaseProductAndVariations(variation.baseProductId!, quantityToAdd);
      } else {
        // Fallback to regular update if no base product found
        var response = await http.get(
          Uri.parse('${AppConfig.apiBaseUrl}/appBarAPI_GET.php?query_param=18&op=1&ids=$variationId&quantities=$quantityToAdd'),
        );
        
        if (response.statusCode == 200) {
          setState(() {
            var index = products.indexWhere((product) => product.id == variationId);
            if (index != -1) {
              products[index].quantity += quantityToAdd;
              products[index].available = products[index].quantity >= 1;
            }
          });
        } else {
          throw Exception('Erro ao atualizar variação');
        }
      }
    } catch (e) {
      print('Error updating variation quantity: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: isLoading,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color.fromARGB(255, 246, 141, 45),
          title: Text(
            'Produtos',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            IconButton(
              onPressed: () {
                logout(context);
              },
              icon: Icon(
                Icons.logout,
                color: Colors.white,
              ),
            ),
          ],
        ),
        drawer: DrawerBar(),
        body: isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              )
            : Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              labelText: 'Procurar...',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              _filterItemsSearch(); // Call filter on text change
                            },
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.filter_list, color: Colors.orange),
                        onPressed: _showFilterDialog,
                      ),
                    ],
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _onRefresh,
                      child: GridView.builder(
                        padding: EdgeInsets.all(8),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 2.8,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          return AnimatedScale(
                            scale: 1,
                            duration: Duration(milliseconds: 350),
                            child: ProductCard(
                              product: filteredProducts[index],
                              onUpdate: (newAvailability) {
                                updateProduct(filteredProducts[index].id, newAvailability);
                              },
                              onQuantityChange: (id, quantity) {
                                updateProductQuantity(id, quantity);
                              },
                              modern: true, // novo parâmetro para design moderno
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
        floatingActionButton: SpeedDial(
          icon: Icons.more_horiz,
          iconTheme: IconThemeData(color: Colors.white),
          backgroundColor: Color.fromARGB(255, 130, 201, 189),
          children: [
            SpeedDialChild(
              child: Icon(Icons.filter_list),
              onTap: () async {
                _showFilterDialog();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ProductCard extends StatefulWidget {
  final Product product;
  final Function(bool) onUpdate;
  final Function(String, int) onQuantityChange;
  final bool modern;

  ProductCard({
    required this.product,
    required this.onUpdate,
    required this.onQuantityChange,
    this.modern = false,
  });

  @override
  _ProductCardState createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late TextEditingController _quantityController;
  late TextEditingController _slideQuantityController;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: widget.product.quantity.toString());
    _slideQuantityController = TextEditingController(text: widget.product.quantity.toString());
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _slideQuantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isAvailable = widget.product.quantity >= 1;
    final priceStr = widget.product.price.toStringAsFixed(2).replaceAll('.', ',') + '€';
    if (!widget.modern) {
      return Dismissible(
        key: Key(widget.product.id),
        direction: DismissDirection.endToStart,
        background: Container(
          color: Color.fromARGB(255, 130, 201, 189),
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 20.0),
          child: Icon(
            Icons.swap_horizontal_circle_outlined,
            color: Colors.white,
          ),
        ),
        confirmDismiss: (direction) async {
          int currentQuantity = widget.product.quantity;
          int quantityToAdd = 0;
          return await showDialog(
            context: context,
            builder: (BuildContext context) {
              return StatefulBuilder(
                builder: (context, setState) {
                  return AlertDialog(
                    title: Text("Atualizar Quantidade", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[800])),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Atual:', style: TextStyle(fontSize: 15)),
                            Text(currentQuantity.toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Acrescentar:', style: TextStyle(fontSize: 15)),
                            Container(
                              width: 60,
                              height: 36,
                              alignment: Alignment.center,
                              child: TextField(
                                controller: _slideQuantityController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 15),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.orange, width: 1),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.orange, width: 2),
                                  ),
                                ),
                                onChanged: (value) {
                                  int val = int.tryParse(value) ?? 0;
                                  setState(() {
                                    quantityToAdd = val;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total:', style: TextStyle(fontSize: 15)),
                            Text((currentQuantity + quantityToAdd).toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.orange[800])),
                          ],
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        child: Text("Cancelar", style: TextStyle(color: Colors.grey[700])),
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                      ),
                      ElevatedButton(
                        child: Text("Guardar", style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        ),
                        onPressed: () {
                          int? newQuantity = int.tryParse(_slideQuantityController.text);
                          if (newQuantity != null) {
                            widget.onQuantityChange(widget.product.id, newQuantity);
                            Navigator.of(context).pop(false);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Por favor, insira uma quantidade válida'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
        child: Card(
          margin: EdgeInsets.all(8.0),
          color: widget.product.isBaseProduct ? Colors.orange[50] : 
                 widget.product.isVariation ? Colors.blue[50] : null,
          child: Padding(
            padding: EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.memory(
                      base64Decode(widget.product.base64Image),
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.product.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: widget.product.isBaseProduct ? Colors.orange[800] : 
                                           widget.product.isVariation ? Colors.blue[800] : Colors.black,
                                  ),
                                ),
                              ),
                              if (widget.product.isBaseProduct)
                                Icon(Icons.inventory, color: Colors.orange, size: 16),
                              if (widget.product.isVariation)
                                Icon(Icons.link, color: Colors.blue, size: 16),
                            ],
                          ),
                          Text(
                            'Preço: ${widget.product.price.toStringAsFixed(2).replaceAll('.', ',')}€',
                            style: TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Quantidade: ${widget.product.displayQuantity}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: widget.product.isVariation ? Colors.blue : Colors.black,
                            ),
                          ),
                          Text(
                            'Estado: ${isAvailable ? 'Disponível' : 'Indisponível'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isAvailable ? Colors.green : Colors.red,
                            ),
                          ),
                          Text(
                            'Categoria: ${widget.product.category}',
                            style: TextStyle(fontSize: 14),
                          ),
                          if (widget.product.isBaseProduct)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Produto Base',
                                style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          if (widget.product.isVariation && widget.product.baseProductName != null)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Base: ${widget.product.baseProductName}',
                                style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          // Debug info
                          Text(
                            'ID: ${widget.product.id} | BaseID: ${widget.product.baseProductId ?? "null"}',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        int currentQty = widget.product.quantity;
                        if (currentQty > 0) {
                          // Envia o valor negativo para zerar o stock
                          widget.onQuantityChange(widget.product.id, -currentQty);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Produto já está indisponível!'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Indisponível'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
    // Novo visual moderno:
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem circular
            ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Image.memory(
                base64Decode(widget.product.base64Image),
                width: 64,
                height: 64,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: widget.product.isBaseProduct ? Colors.orange[800] : widget.product.isVariation ? Colors.blue[800] : Colors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.product.isBaseProduct)
                        Chip(
                          label: Text('Base', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          backgroundColor: Colors.orange,
                          visualDensity: VisualDensity.compact,
                        ),
                      if (widget.product.isVariation && widget.product.baseProductName != null)
                        Chip(
                          label: Text('Variação', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          backgroundColor: Colors.blue,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Chip(
                        label: Text(widget.product.category, style: TextStyle(color: Colors.white)),
                        backgroundColor: Colors.deepOrange,
                        visualDensity: VisualDensity.compact,
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: isAvailable ? Colors.green[100] : Colors.red[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(isAvailable ? Icons.check_circle : Icons.cancel, color: isAvailable ? Colors.green : Colors.red, size: 16),
                            SizedBox(width: 4),
                            Text(isAvailable ? 'Disponível' : 'Indisponível', style: TextStyle(fontWeight: FontWeight.bold, color: isAvailable ? Colors.green[800] : Colors.red[800])),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Text('Preço: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(priceStr, style: TextStyle(fontSize: 16)),
                      SizedBox(width: 16),
                      Text('Qtd: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(widget.product.quantity.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[800])),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          int currentQty = widget.product.quantity;
                          if (currentQty > 0) {
                            widget.onQuantityChange(widget.product.id, -currentQty);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Produto já está indisponível!'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        icon: Icon(Icons.block, size: 18),
                        label: Text('Indisponível'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          int? addQtd = await showDialog<int>(
                            context: context,
                            builder: (context) {
                              final controller = TextEditingController();
                              return AlertDialog(
                                title: Text('Atualizar Stock', style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold)),
                                content: TextField(
                                  controller: controller,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Quantidade (+ ou -)',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    child: Text('Cancelar'),
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                  ElevatedButton(
                                    child: Text('Atualizar'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                    onPressed: () {
                                      int? val = int.tryParse(controller.text);
                                      if (val != null && val != 0) {
                                        Navigator.of(context).pop(val);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Insira um valor diferente de zero!'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                          if (addQtd != null && addQtd != 0) {
                            widget.onQuantityChange(widget.product.id, addQtd);
                          }
                        },
                        icon: Icon(Icons.add, size: 18),
                        label: Text('Atualizar Stock'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: ProdutoPageBar(),
  ));
}

class AddProdutoPageBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Implement your add product page UI here
    return Container();
  }
}
