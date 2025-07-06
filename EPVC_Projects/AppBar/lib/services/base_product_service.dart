import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class BaseProductService {
  static const String baseUrl = 'https://appbar.epvc.pt/API';

  // Get available quantity for a product (considering base product if it's a variation)
  static Future<int> getAvailableQuantity(String productName, {String? productId}) async {
    try {
      String cleanProductName = productName.replaceAll('"', '').trim();
      
      // First, get the product details to check if it's a variation
      var productResponse = await http.get(
        Uri.parse('$baseUrl/appBarAPI_GET.php?query_param=8&nome=$cleanProductName'),
      );
      
      if (productResponse.statusCode == 200) {
        var data = json.decode(productResponse.body);
        if (data is List && data.isNotEmpty) {
          var productData = data[0];
          
          // Check if this is a variation
          String? baseProductId = productData['BaseProductId']?.toString();
          bool isBaseProduct = productData['IsBaseProduct'] == '1' || productData['IsBaseProduct'] == true;
          
          if (baseProductId != null && baseProductId.isNotEmpty && !isBaseProduct) {
            // This is a variation, get the base product quantity
            return await _getBaseProductQuantity(baseProductId);
          } else {
            // This is a base product or standalone product
            return int.tryParse(productData['Qtd'].toString()) ?? 0;
          }
        }
      }
      return 0;
    } catch (e) {
      print('Error getting available quantity: $e');
      return 0;
    }
  }

  // Get effective quantity for display (for variations, show base product quantity)
  static Future<int> getEffectiveQuantity(String productName, {String? productId}) async {
    return await getAvailableQuantity(productName, productId: productId);
  }

  // Get base product name for a variation
  static Future<String?> getBaseProductName(String productName) async {
    try {
      String cleanProductName = productName.replaceAll('"', '').trim();
      
      var productResponse = await http.get(
        Uri.parse('$baseUrl/appBarAPI_GET.php?query_param=8&nome=$cleanProductName'),
      );
      
      if (productResponse.statusCode == 200) {
        var data = json.decode(productResponse.body);
        if (data is List && data.isNotEmpty) {
          var productData = data[0];
          return productData['BaseProductName']?.toString();
        }
      }
      return null;
    } catch (e) {
      print('Error getting base product name: $e');
      return null;
    }
  }

  // Get base product quantity
  static Future<int> _getBaseProductQuantity(String baseProductId) async {
    try {
      var response = await http.get(
        Uri.parse('$baseUrl/appBarAPI_GET.php?query_param=8&id=$baseProductId'),
      );
      
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          return int.tryParse(data[0]['Qtd'].toString()) ?? 0;
        }
      }
      return 0;
    } catch (e) {
      print('Error getting base product quantity: $e');
      return 0;
    }
  }

  // Update quantity for a product (if it's a variation, update the base product)
  static Future<bool> updateProductQuantity(String productId, int quantityToSubtract) async {
    try {
      // First, get the product details to check if it's a variation
      var productResponse = await http.get(
        Uri.parse('$baseUrl/appBarAPI_GET.php?query_param=8&id=$productId'),
      );
      
      if (productResponse.statusCode == 200) {
        var data = json.decode(productResponse.body);
        if (data is List && data.isNotEmpty) {
          var productData = data[0];
          
          // Check if this is a variation
          String? baseProductId = productData['BaseProductId']?.toString();
          bool isBaseProduct = productData['IsBaseProduct'] == '1' || productData['IsBaseProduct'] == true;
          
          String targetProductId = productId;
          
          if (baseProductId != null && baseProductId.isNotEmpty && !isBaseProduct) {
            // This is a variation, update the base product instead
            targetProductId = baseProductId;
          }
          
          // Update the quantity
          var updateResponse = await http.get(
            Uri.parse('$baseUrl/appBarAPI_GET.php?query_param=18&op=2&ids=$targetProductId&quantities=-$quantityToSubtract'),
          );
          
          return updateResponse.statusCode == 200;
        }
      }
      return false;
    } catch (e) {
      print('Error updating product quantity: $e');
      return false;
    }
  }

  // Update quantities for multiple products (considering base products)
  static Future<bool> updateMultipleProductQuantities(Map<String, int> productQuantities) async {
    try {
      Map<String, int> baseProductQuantities = {};
      
      // Group quantities by base products
      for (var entry in productQuantities.entries) {
        String productId = entry.key;
        int quantity = entry.value;
        
        // Get product details to check if it's a variation
        var productResponse = await http.get(
          Uri.parse('$baseUrl/appBarAPI_GET.php?query_param=8&id=$productId'),
        );
        
        if (productResponse.statusCode == 200) {
          var data = json.decode(productResponse.body);
          if (data is List && data.isNotEmpty) {
            var productData = data[0];
            
            // Check if this is a variation
            String? baseProductId = productData['BaseProductId']?.toString();
            bool isBaseProduct = productData['IsBaseProduct'] == '1' || productData['IsBaseProduct'] == true;
            
            String targetProductId = productId;
            
            if (baseProductId != null && baseProductId.isNotEmpty && !isBaseProduct) {
              // This is a variation, use the base product
              targetProductId = baseProductId;
            }
            
            // Add to base product quantities
            baseProductQuantities[targetProductId] = (baseProductQuantities[targetProductId] ?? 0) + quantity;
          }
        }
      }
      
      // Update all base products at once
      if (baseProductQuantities.isNotEmpty) {
        List<String> productIds = baseProductQuantities.keys.toList();
        List<int> quantities = baseProductQuantities.values.toList();
        
        String idsParam = productIds.join(',');
        String quantitiesParam = quantities.map((q) => -q).join(','); // Negative for subtraction
        
        var updateResponse = await http.get(
          Uri.parse('$baseUrl/appBarAPI_GET.php?query_param=18&op=2&ids=$idsParam&quantities=$quantitiesParam'),
        );
        
        return updateResponse.statusCode == 200;
      }
      
      return true;
    } catch (e) {
      print('Error updating multiple product quantities: $e');
      return false;
    }
  }

  // Create or update base product relationship
  static Future<bool> setBaseProductRelationship({
    required String variationId,
    required String baseProductId,
    required String baseProductName,
  }) async {
    try {
      var response = await http.get(
        Uri.parse('$baseUrl/appBarAPI_GET.php?query_param=19&variationId=$variationId&baseProductId=$baseProductId&baseProductName=$baseProductName'),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error setting base product relationship: $e');
      return false;
    }
  }

  // Get all base products
  static Future<List<Product>> getBaseProducts() async {
    try {
      var response = await http.get(
        Uri.parse('$baseUrl/appBarAPI_GET.php?query_param=20'),
      );
      
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data is List) {
          return data.map((json) => Product.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting base products: $e');
      return [];
    }
  }

  // Get all variations for a base product
  static Future<List<Product>> getVariationsForBaseProduct(String baseProductId) async {
    try {
      var response = await http.get(
        Uri.parse('$baseUrl/appBarAPI_GET.php?query_param=21&baseProductId=$baseProductId'),
      );
      
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data is List) {
          return data.map((json) => Product.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting variations for base product: $e');
      return [];
    }
  }

  // Check if a product is available (considering base product inventory)
  static Future<bool> isProductAvailable(String productName, {String? productId}) async {
    int quantity = await getAvailableQuantity(productName, productId: productId);
    return quantity > 0;
  }


} 