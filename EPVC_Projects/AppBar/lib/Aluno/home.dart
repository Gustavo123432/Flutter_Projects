import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:appbar_epvc/Aluno/drawerHome.dart';
import 'package:appbar_epvc/SIBS/Orders/cash_confirmation_page.dart';
import 'package:appbar_epvc/SIBS/Orders/order_declined_page.dart';
import 'package:appbar_epvc/login.dart';
import 'package:appbar_epvc/widgets/add_to_cart_animation.dart';
import 'package:appbar_epvc/widgets/loading_button.dart';
import 'package:appbar_epvc/widgets/loading_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:intl/intl.dart';
import 'package:diacritic/diacritic.dart'; // Import the diacritic package
import 'package:appbar_epvc/SIBS/sibs_service.dart';
import '../SIBS/Orders/mbway_waiting_page.dart';
import '../SIBS/Orders/order_confirmation_page.dart';
import '../SIBS/Orders/mbway_phone_page.dart';
import 'package:flutter/rendering.dart';

void main() {
  runApp(HomeAlunoMain());
}

List<Map<String, dynamic>> cartItems =
    []; // Lista global para armazenar os itens no carrinho
List<Map<String, dynamic>> recentBuysMapped = [];
List<Map<String, dynamic>> data = [];
TextEditingController _searchController = TextEditingController();
List<Map<String, dynamic>> allProducts =
    []; // Lista para armazenar todos os produtos
List<Map<String, dynamic>> filteredProducts = [];

class HomeAlunoMain extends StatelessWidget {
  final String? message; // Mensagem opcional

  HomeAlunoMain({this.message});
  @override
  Widget build(BuildContext context) {
    // Exibe a mensagem, se existir
    if (message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message!)),
        );
      });
    }

    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.orange,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
          ),
        ),
        textTheme: TextTheme(
          headlineLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
            fontFamily: 'Roboto',
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
            fontFamily: 'Roboto',
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Color(0xFF333333),
            fontFamily: 'Roboto',
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
            fontFamily: 'Roboto',
          ),
        ),
        
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
      home: Scaffold(
        backgroundColor: Colors.white,
        body: HomeAluno(),
      ),
    );
  }
}

class HomeAluno extends StatefulWidget {
  @override
  _HomeAlunoState createState() => _HomeAlunoState();
}

class _HomeAlunoState extends State<HomeAluno> {
  List<dynamic> recentBuys = [];
  dynamic checkquantidade;
  var contador = 1;
  bool _isLoading = false;
  bool _isSearching = false;
  dynamic users;
  final GlobalKey _cartIconKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    UserInfo();
    _getAllProducts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {}); // This will refresh the cart count when returning to this page
  }

  void UserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var user = prefs.getString("username");

    final response = await http.post(
      Uri.parse('https://appbar.epvc.pt/API/appBarAPI_Post.php'),
      body: {
        'query_param': '1',
        'user': user,
      },
    );
    if (response.statusCode == 200) {
      setState(() {
        users = json.decode(response.body);
        viewRecent(users);
      });
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
                Navigator.of(context).pop(); // Fecha o AlertDialog
              },
            ),
            LoadingButton(
              onPressed: () async {
                // Show loading state
                setState(() => _isLoading = true);
                
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                
                setState(() => _isLoading = false);

                // ignore: use_build_context_synchronously
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (BuildContext ctx) => const LoginForm()));
                ModalRoute.withName('/');
              },
              child: Text('Confirmar'),
              backgroundColor: Colors.red,
            ),
          ],
        );
      },
    );
  }

  void CheckQuantidade(String productName) async {
    // Remove double quotes from the product name
    String productNamee = productName.replaceAll('"', '');

    var response = await http.get(Uri.parse(
        'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=8&nome=$productNamee'));

    if (response.statusCode == 200) {
      setState(() {
        // Cast the decoded JSON objects to List<Map<String, dynamic>>
        data = json.decode(response.body).cast<Map<String, dynamic>>();
        //print(json.decode(response.body));
        if (data.isNotEmpty) {
          //print(quantidadeDisponivel);
        } else {
          print('Data is empty');
        }
      });
    }
  }

  Future<void> viewRecent(dynamic userr) async {
    try {
      if (userr != null) {
        for (var userData in userr) {
          var user = userData['Email'];
          var response = await http.post(
            Uri.parse('https://appbar.epvc.pt/API/appBarAPI_Post.php'),
            body: {
              'query_param': '7',
              'user': user,
            },
          );

          if (response.statusCode == 200) {
            setState(() {
              recentBuys = json.decode(response.body);
              recentBuysMapped = recentBuys.map((productString) {
                return productString as Map<String, dynamic>;
              }).toList();
            });
          } else {
            throw Exception(
                'Erro ao enviar pedido para a API: ${response.statusCode}');
          }
        }
      } else {
        print('Usuários não carregados ainda');
      }
    } catch (e) {
      print('Erro ao enviar pedidos para a API');
    }
  }

  void _getAllProducts() async {
    try {
      final response = await http.post(
        Uri.parse('https://appbar.epvc.pt/API/appBarAPI_Post.php'),
        body: {
          'query_param': '4',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);

        // Explicitly cast each item to Map<String, dynamic>
        allProducts =
            jsonData.map((item) => item as Map<String, dynamic>).toList();

        setState(() {}); // Trigger UI update
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      print("Erro ao enviar pedidos para a API: $e");
    }
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isNotEmpty) {
        _isSearching = true;
        // Filtra a lista de produtos com base na pesquisa
        filteredProducts = allProducts
            .where((product) => product['Nome']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      } else {
        _isSearching = false;
        filteredProducts = List.from(allProducts);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(''), // Assuming you want the title back
        
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu), // Assuming the leading icon is a menu icon
              onPressed: () { Scaffold.of(context).openDrawer(); },
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            );
          },
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                key: _cartIconKey,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShoppingCartPage(),
                    ),
                  ).then((_) {
                    setState(() {});
                  });
                },
                icon: Icon(Icons.shopping_cart),
              ),
              if (cartItems.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${cartItems.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: DrawerHome(),
      body: WillPopScope(
        onWillPop: () async {
          // Check if user data is available before processing permission
          if (users == null || users.isEmpty) {
            // If user data is not available yet, allow default back behavior (minimize)
            return true;
          }

          // User data is available, proceed with permission check and navigation
          String permission = users[0]['Permissao'] ?? '';

          if (permission == 'Aluno' || permission == 'Professor') {
            // Navigate to HomeAluno and remove all previous routes
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomeAluno()),
              (Route<dynamic> route) => false,
            );
            return false; // Prevent default back behavior
          } else if (permission == 'Bar') {
            // TODO: Navigate to Bar home page and remove all previous routes
            // Replace BarHomePage() with the actual widget for the Bar home page
            /*
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => BarHomePage()),
              (Route<dynamic> route) => false,
            );
            */
            return false; // Prevent default back behavior
          } else {
            // If permission is unknown, allow default back behavior (optional)
            return true;
          }
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(height: 20),
            ),
            if (recentBuysMapped.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0, top: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.history,
                            color: Colors.orange,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                    "Comprados Recentemente",
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RecentBuysPage(recentBuys: recentBuysMapped),
                            ),
                          );
                        },
                        child: Text(
                          'Ver Todos',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 8.0),
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    itemCount: recentBuysMapped.length,
                    itemBuilder: (context, index) {
                      var product = recentBuysMapped[index];
                      final RenderBox? cartIconBox = _cartIconKey.currentContext?.findRenderObject() as RenderBox?;
                      final Offset cartPosition = cartIconBox?.localToGlobal(Offset.zero) ?? Offset.zero;

                      return AddToCartAnimation(
                        key: ValueKey(product['Descricao']),
                        cartPosition: cartPosition,
                        onTap: () async {
                          if (_isLoading) return;

                          setState(() {
                            _isLoading = true;
                          });

                          try {
                            final String productName = product['Descricao'].replaceAll('"', '');
                            int availableQuantity = await checkQuantidade(productName);
                            int currentQuantity = cartItems.where((item) => item['Nome'] == productName).length;

                            if (availableQuantity <= 0) {
                              if (mounted) {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('Produto Indisponível'),
                                      content: Text('Desculpe, este produto está indisponível no momento.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          style: TextButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          ),
                                          child: Text('OK'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            } else if (currentQuantity >= availableQuantity) {
                              if (mounted) {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('Quantidade Máxima'),
                                      content: Text('Quantidade máxima disponível atingida (Disponível: $availableQuantity)'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          style: TextButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          ),
                                          child: Text('OK'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            } else {
                              // Only add to cart and show animation if quantity is available
                              addToCart(
                                product['Imagem'],
                                product['Descricao'],
                                product['Preco'].toString(),
                                product['Prencado']?.toString() ?? ''
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Item adicionado'),
                                    duration: Duration(milliseconds: 500),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            print('Erro ao verificar quantidade disponível ou adicionar ao carrinho: $e');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Ocorreu um erro ao adicionar o item ao carrinho.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
                        },
                        child: Container(
                          width: 120,
                          margin: EdgeInsets.symmetric(horizontal: 4.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                            child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                  image: DecorationImage(
                                    image: MemoryImage(base64.decode(product['Imagem'])),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(
                                  product['Descricao'].replaceAll('"', ''),
                                  style: TextStyle(
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF333333),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "${double.parse(product['Preco'].toString()).toStringAsFixed(2).replaceAll('.', ',')}€",
                                      style: TextStyle(
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: Container(
                margin: EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 16.0,
                ),
                child: Text(
                  "Categorias",
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[900],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: 15),
            ),
            SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  switch (index) {
                    case 0:
                      return buildCategoryCard(
                        title: 'Bebidas',
                        backgroundImagePath: 'lib/assets/bebida.png',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryPage(
                                title: 'Bebidas',
                              ),
                            ),
                          ).then((_) {
                            setState(() {});
                          });
                        },
                      );
                    case 1:
                      return buildCategoryCard(
                        title: 'Quentes',
                        backgroundImagePath: 'lib/assets/cafe.JPG',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryPage(
                                title: 'Quentes',
                              ),
                            ),
                          ).then((_) {
                            setState(() {});
                          });
                        },
                      );
                    case 2:
                      return buildCategoryCard(
                        title: 'Comidas',
                        backgroundImagePath: 'lib/assets/comida.jpg',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryPage(
                                title: 'Comidas',
                              ),
                            ),
                          ).then((_) {
                            setState(() {});
                          });
                        },
                      );
                    case 3:
                      return buildCategoryCard(
                        title: 'Snacks',
                        backgroundImagePath: 'lib/assets/snacks.jpg',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryPage(
                                title: 'Snacks',
                              ),
                            ),
                          ).then((_) {
                            setState(() {});
                          });
                        },
                      );
                    case 4:
                      return buildCategoryCard(
                        title: 'Doces',
                        backgroundImagePath: 'lib/assets/doces.jpg',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryPage(
                                title: 'Doces',
                              ),
                            ),
                          ).then((_) {
                            setState(() {});
                          });
                        },
                      );
                    case 5:
                      return buildCategoryCard(
                        title: 'Restaurante',
                        backgroundImagePath: 'lib/assets/monteRestaurante.jpg',
                        isAvailable: false,
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Em Desenvolvimento'),
                              content: Text('O Restaurante não está disponível no momento.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text('OK'),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    default:
                      return Container();
                  }
                },
                childCount: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildProductSection({
    required String imagePath,
    required String title,
    required String price,
    required String prencado,
  }) {
    if (contador == 1) {
      CheckQuantidade(title.replaceAll('"', ''));
      contador = 0;
    }
    return GestureDetector(
      onTap: () async {
        contador = 1;
        CheckQuantidade(title.replaceAll('"', ''));
        var quantidadeDisponivel = data[0]['Qtd'];

        if (quantidadeDisponivel == 1) {
          addToCart(imagePath, title, price, prencado);
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Produto Indisponível'),
              content: Text('Desculpe, este produto está indisponível.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
      },
      child: Container(
        width: MediaQuery.of(context).size.width / 3.2,
        margin: EdgeInsets.symmetric(horizontal: 2.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 1.0,
              blurRadius: 2.0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 45.0,
                child: Image.memory(
                  base64.decode(imagePath),
                  fit: BoxFit.contain,
                  gaplessPlayback: true, // Prevents image flickering
                  cacheWidth: 100, // Cache width for better performance
                  cacheHeight: 100, // Cache height for better performance
                ),
              ),
              Text(
                title.replaceAll('"', ''),
                style: TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.bold,
                  overflow: TextOverflow.fade,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Preço:',
                    style: TextStyle(fontSize: 8.0),
                  ),
                  Text(
                    "${double.parse(price).toStringAsFixed(2).replaceAll('.', ',')}€",
                    style: TextStyle(fontSize: 10.0),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void addToCart(String imagePath, String title, String price, String prencado) async {
    try {
      // Check available quantity first
      int availableQuantity = await checkQuantidade(title.replaceAll('"', ''));
      int currentQuantity = cartItems.where((item) => item['Nome'] == title.replaceAll('"', '')).length;
      
      if (currentQuantity < availableQuantity) {
        setState(() {
          cartItems.add({
            'Imagem': imagePath,
            'Nome': title.replaceAll('"', ''),
            'Preco': price,
            'Prencado': prencado,
            'PrepararPrencado': false,
            'Fresh': false,
          });
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Quantidade máxima disponível atingida'),
            backgroundColor: Colors.red,
            duration: Duration(milliseconds: 2000),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao verificar quantidade disponível'),
          backgroundColor: Colors.red,
          duration: Duration(milliseconds: 2000),
        ),
      );
    }
  }

  Widget buildCategoryCard({
    required String title,
    required String backgroundImagePath,
    required VoidCallback onTap,
    bool isAvailable = true,
    bool showImage = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150.0,
        margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (isAvailable && showImage)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: AssetImage(backgroundImagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            // Gradient overlay for better text visibility
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            // Category title with icon
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      _getCategoryIcon(title),
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                      color: Colors.white,
                          fontFamily: 'Roboto',
                    ),
                  ),
                ),
                  ],
              ),
            ),
            ),
            if (!isAvailable)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                  color: Colors.black.withOpacity(0.5),
                ),
                child: Center(
                      child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.construction,
                        size: 32,
                            color: Colors.white,
                          ),
                          SizedBox(height: 8),
                      Text(
                              'EM DESENVOLVIMENTO',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'bebidas':
        return Icons.local_drink;
      case 'quentes':
        return Icons.local_cafe;
      case 'comidas':
        return Icons.restaurant;
      case 'snacks':
        return Icons.fastfood;
      case 'doces':
        return Icons.cake;
      case 'restaurante':
        return Icons.restaurant_menu;
      default:
        return Icons.category;
    }
  }

  Future<int> checkQuantidade(String productName) async {
    try {
      // Remove double quotes and trim the product name
      String cleanProductName = productName.replaceAll('"', '').trim();
      
      // Make the API request
      var response = await http.get(Uri.parse(
          'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=8&nome=$cleanProductName'));

      if (response.statusCode == 200) {
        // Parse the response
        var data = json.decode(response.body);
        
        // Check if there's an error in the response
        if (data is Map && data.containsKey('error')) {
          print('Error checking quantity: ${data['error']}');
          return 0; // Return 0 if product not found
        }
        
        // If data is a list and not empty
        if (data is List && data.isNotEmpty) {
          return int.parse(data[0]['Qtd'].toString());
        }
      }
      return 0; // Return 0 if no data or error
    } catch (e) {
      print('Error checking quantity: $e');
      return 0; // Return 0 on error
    }
  }
}

class CategoryPage extends StatefulWidget {
  final String title;

  const CategoryPage({Key? key, required this.title}) : super(key: key);

  @override
  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  List<dynamic> items = [];
  List<dynamic> filteredItems = [];
  late StreamController<List<dynamic>> _streamController;
  final TextEditingController _searchController = TextEditingController();
  String? selectedSortOption;
  double? minPrice;
  double? maxPrice;
  bool _isLoading = false;
  final GlobalKey _cartIconKey = GlobalKey();

  Future<int> checkQuantidade(String productName) async {
    try {
      // Remove double quotes and trim the product name
      String cleanProductName = productName.replaceAll('"', '').trim();
      
      // Make the API request
      var response = await http.get(Uri.parse(
          'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=8&nome=$cleanProductName'));

      if (response.statusCode == 200) {
        // Parse the response
        var data = json.decode(response.body);
        
        // Check if there's an error in the response
        if (data is Map && data.containsKey('error')) {
          print('Error checking quantity: ${data['error']}');
          return 0; // Return 0 if product not found
        }
        
        // If data is a list and not empty
        if (data is List && data.isNotEmpty) {
          return int.parse(data[0]['Qtd'].toString());
        }
      }
      return 0; // Return 0 if no data or error
    } catch (e) {
      print('Error checking quantity: $e');
      return 0; // Return 0 on error
    }
  }

  @override
  void initState() {
    super.initState();
    _streamController = StreamController<List<dynamic>>();
    fetchData(widget.title);
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _streamController.close();
    _searchController.dispose();
    super.dispose();
  }

  void addToCart(Map<String, dynamic> item) async {
    // Ensure the item has all required properties and standardize the structure
    // Be very defensive about potential nulls and types from the source item map
    Map<String, dynamic> newItem = {
      'Imagem': (item['Imagem'] is String && item['Imagem'] != null) ? item['Imagem'] : '', // Ensure Imagem is a non-null string
      'Nome': (item['Nome'] is String && item['Nome'] != null) ? item['Nome'].replaceAll('"', '') : '', // Ensure Nome is a non-null string, remove quotes
      'Preco': (item['Preco'] != null) ? item['Preco'].toString() : '0.0', // Ensure Preco is a non-null string representation
      'Prencado': (item['Prencado'] != null) ? item['Prencado'].toString() : '0', // Ensure Prencado is a non-null string representation
      // Initialize preparation flags with default values if not explicitly boolean in the source item
      'PrepararPrencado': (item['PrepararPrencado'] is bool) ? item['PrepararPrencado'] : false,
      'Fresh': (item['Fresh'] is bool) ? item['Fresh'] : false,
    };

    // Apply default preparation based on Prencado value only if the flags were not explicitly set as boolean
    if (newItem['Prencado'] == '1' || newItem['Prencado'] == '2') {
      if (!(item['PrepararPrencado'] is bool)) { // Only set default if original item didn't have a boolean flag
        newItem['PrepararPrencado'] = true; // Default to prensado/aquecido
      }
    } else if (newItem['Prencado'] == '3') {
       if (!(item['Fresh'] is bool)) { // Only set default if original item didn't have a boolean flag
        newItem['Fresh'] = true;  // Default to fresh
       }
    }
    
    // Check available quantity before adding
    // Use the standardized product name
    final String productName = newItem['Nome'];
    int availableQuantity = await checkQuantidade(productName); // Check available quantity
    int currentQuantity = cartItems.where((cartItem) => cartItem['Nome'] == productName).length; // Get current quantity in cart

    if (availableQuantity >= currentQuantity + 1) {
      setState(() {
        cartItems.add(newItem); // Add the standardized item
      });
       // Optionally show a snackbar that item was added
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Item adicionado ao carrinho'),
             duration: Duration(milliseconds: 500),
           ),
         );
       }
    } else {
      // Optionally show a message to the user that max quantity is reached or unavailable
      String message = availableQuantity <= 0
          ? 'Desculpe, este produto está indisponível no momento.'
          : 'Quantidade máxima disponível atingida (Disponível: $availableQuantity)';

      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(availableQuantity <= 0 ? 'Produto Indisponível' : 'Quantidade Máxima'),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  Future<void> fetchData(String categoria) async {
    try {
      final response = await http.post(
        Uri.parse('https://appbar.epvc.pt/API/appBarAPI_Post.php'),
        body: {
          'query_param': '5',
          'categoria': '$categoria',
        },
      );
      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        if (responseData is List<dynamic>) {
          items = responseData.cast<Map<String, dynamic>>();
          filteredItems = items; // Initialize filteredItems
          _streamController.add(filteredItems);
        } else {
          throw Exception('Response data is not a List<dynamic>');
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Erro ao carregar data: $e');
    }
  }

  void _filterItems() {
    final query = removeDiacritics(
        _searchController.text.toLowerCase()); // Normalize query
    print('Search Query: $query'); // Debugging line

    setState(() {
      // Check if items are loaded
      if (items.isEmpty) {
        print('No items to search through.'); // Debugging line
        filteredItems = [];
        return;
      }

      // Filter items based on the search query
      filteredItems = items.where((item) {
        // Ensure 'Nome' exists and is a string
        if (item['Nome'] != null && item['Nome'] is String) {
          // Normalize 'Nome' for comparison
          final normalizedNome = removeDiacritics(item['Nome'].toLowerCase());
          return normalizedNome.contains(query);
        }
        return false; // Exclude items without a valid 'Nome'
      }).toList();

      _streamController.add(filteredItems);
    });
  }

  Future<void> _onRefresh() async {
    // Call fetchData to refresh the data
    await fetchData(widget.title);
  }

  Future<bool> _onWillPop() async {
    // Navigate to home page
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
          builder: (context) =>
              HomeAluno()), // Replace with your Home page widget
      (Route<dynamic> route) => false,
    );
    return false; // Prevent default back navigation
  }

  void _sortItems() {
    setState(() {
      if (selectedSortOption == 'asc') {
        filteredItems.sort((a, b) =>
            double.parse(a['Preco']).compareTo(double.parse(b['Preco'])));
      } else {
        filteredItems.sort((a, b) =>
            double.parse(b['Preco']).compareTo(double.parse(a['Preco'])));
      }
      _streamController.add(filteredItems);
    });
  }

  void _filterByPrice() {
    setState(() {
      filteredItems = items.where((item) {
        double price = double.parse(item['Preco']);
        return (minPrice == null || price >= minPrice!) &&
            (maxPrice == null || price <= maxPrice!);
      }).toList();
      _streamController.add(filteredItems);
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filtro'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: selectedSortOption, // This can be null
                  hint: Text(
                      'Selecione uma opção'), // Hint text when no value is selected
                  items: [
                    DropdownMenuItem(
                      value: 'asc', // Value for ascending
                      child: Row(
                        children: [
                          Icon(Icons.arrow_upward), // Icon for ascending
                          SizedBox(width: 8),
                          Text('Ascendente'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'desc', // Value for descending
                      child: Row(
                        children: [
                          Icon(Icons.arrow_downward), // Icon for descending
                          SizedBox(width: 8),
                          Text('Descendente'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedSortOption = newValue; // Update the selection
                        _sortItems(); // Call the sorting function
                        Navigator.pop(context); // Close the dialog
                      });
                    }
                  },
                ),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Preço Mínimo',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    minPrice = value.isNotEmpty ? double.tryParse(value) : null;
                    _filterByPrice();
                  },
                ),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Preço Máximo',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    maxPrice = value.isNotEmpty ? double.tryParse(value) : null;
                    _filterByPrice();
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeAluno(),
          ),
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => HomeAluno(),
                ),
              );
            },
          ),
          actions: [
            Stack(
              children: [
                IconButton(
                  key: _cartIconKey,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ShoppingCartPage(),
                      ),
                    ).then((_) {
                      setState(() {});
                    });
                  },
                  icon: Icon(Icons.shopping_cart),
                ),
                if (cartItems.isNotEmpty)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${cartItems.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        body: Column(
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
                        _filterItems(); // Call filter on text change
                      },
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.filter_list),
                  onPressed: _showFilterDialog,
                ),
              ],
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child: StreamBuilder<List<dynamic>>(
                  stream: _streamController.stream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      List<dynamic> items = snapshot.data!;
                      return ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final double preco = double.parse(item['Preco']);
                          return Card(
                            key: ValueKey(item['Nome']), // Use a chave para ajudar o Flutter a otimizar a reconstrução
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  leading: Image.memory(
                                    base64.decode(item['Imagem']),
                                    fit: BoxFit.cover,
                                    height: 50,
                                    width: 50,
                                  ),
                                  title: Text(item['Nome']),
                                  subtitle: Text(
                                    item['Qtd'] != null
                                        ? "Disponível: ${item['Qtd']} - ${preco.toStringAsFixed(2).replaceAll('.', ',')}€"
                                        : "Indisponível",
                                  ),
                                  trailing: cartItems.any((cartItem) =>
                                          cartItem['Nome'] == item['Nome'])
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            /*IconButton(
                                              onPressed: () {
                                                removeFromCart(item);
                                              },
                                              icon: Icon(Icons.remove),
                                            ),*/
                                            Text(
                                              cartItems
                                                  .where((element) =>
                                                      element['Nome'] ==
                                                      item['Nome'])
                                                  .length
                                                  .toString(),
                                              style: TextStyle(fontSize: 15.0),
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                addToCart(item);
                                              },
                                              icon: Icon(Icons.add),
                                            ),
                                          ],
                                        )
                                      : Visibility(
                                          visible: (int.tryParse(item['Qtd']?.toString() ?? '0') ?? 0) > 0,
                                          child: LoadingButton(
                                            onPressed: _isLoading ? null : () async {
                                              setState(() => _isLoading = true);
                                              try {
                                                final String productName = item['Nome'];
                                                int availableQuantity = await checkQuantidade(productName);
                                                int currentQuantity = cartItems.where((cartItem) => cartItem['Nome'] == productName).length;
                                                int desiredQuantity = currentQuantity + 1;

                                                if (availableQuantity >= desiredQuantity) {
                                                  addToCart(item);
                                                } else {
                                                  showDialog(
                                                    context: context,
                                                    builder: (BuildContext context) {
                                                      return AlertDialog(
                                                        title: Text('Quantidade Máxima'),
                                                        content: Text('Quantidade máxima disponível atingida (Disponível: $availableQuantity)'),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () => Navigator.of(context).pop(),
                                                            style: TextButton.styleFrom(
                                                              backgroundColor: Colors.orange,
                                                              foregroundColor: Colors.white,
                                                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                            ),
                                                            child: Text('OK'),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                }
                                              } catch (e) {
                                                print('Erro ao verificar quantidade disponível: $e');
                                                showDialog(
                                                  context: context,
                                                  builder: (BuildContext context) {
                                                    return AlertDialog(
                                                      title: Text('Erro'),
                                                      content: Text('Ocorreu um erro ao verificar a quantidade disponível.'),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.of(context).pop(),
                                                          style: TextButton.styleFrom(
                                                            backgroundColor: Colors.orange,
                                                            foregroundColor: Colors.white,
                                                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                          ),
                                                          child: Text('OK'),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              } finally {
                                                setState(() => _isLoading = false);
                                              }
                                            },
                                            child: _isLoading 
                                              ? SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : Text('Comprar'),
                                            backgroundColor: _isLoading ? Colors.grey : Colors.orange,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
//Monte

class CategoryPageMonte extends StatefulWidget {
  final String title;

  const CategoryPageMonte({Key? key, required this.title}) : super(key: key);

  @override
  _CategoryPageMonteState createState() => _CategoryPageMonteState();
}

class _CategoryPageMonteState extends State<CategoryPageMonte> {
  List<dynamic> items = [];
  List<dynamic> filteredItems = [];
  late StreamController<List<dynamic>> _streamController;
  final TextEditingController _searchController = TextEditingController();

  // Reservation fields
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  String? _selectedTime;

  dynamic users;

  @override
  void initState() {
    super.initState();
    _streamController = StreamController<List<dynamic>>();
    fetchData(widget.title);
    _searchController.addListener(_filterItems);
    UserInfo();
  }

  @override
  void dispose() {
    _streamController.close();
    _searchController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void UserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var user = prefs.getString("username");

    final response = await http.post(
      Uri.parse('https://appbar.epvc.pt/API/appBarAPI_Post.php'),
      body: {
        'query_param': '1',
        'user': user,
      },
    );
    if (response.statusCode == 200) {
      setState(() {
        users = json.decode(response.body);
      });
    }
  }

  Future<void> fetchData(String categoria) async {
    try {
      final response = await http.post(
        Uri.parse('https://appbar.epvc.pt/API/appBarMonteAPI_Post.php'),
        body: {
          'query_param': '2',
        },
      );
      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        if (responseData is List<dynamic>) {
          items = responseData.cast<Map<String, dynamic>>();
          filteredItems = items; // Initialize filteredItems
          _streamController.add(filteredItems);
        } else {
          throw Exception(
              'Error 03 - NOT IS DYNAMIC LIST. Contacte o Administrador');
        }
      } else {
        throw Exception('Erro ao carregar dados');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredItems = items.where((item) {
        return item['nome'].toLowerCase().contains(query);
      }).toList();
      _streamController.add(filteredItems);
    });
  }

  Future<void> _makeReservation(
      Map<String, dynamic> item, DateTime date, TimeOfDay time) async {
    // Get the selected time
    var selectedTime =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    // Validate inputs
    if (selectedTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, selecione as horas.')),
      );
      return;
    }

    // Get the current time
    TimeOfDay currentTime = TimeOfDay.now();
    TimeOfDay cutoffTime = TimeOfDay(hour: 11, minute: 0); // 11:00 AM

    // Determine if the current time is after 11:00 AM
    bool isAfterCutoffTime = (currentTime.hour > cutoffTime.hour) ||
        (currentTime.hour == cutoffTime.hour &&
            currentTime.minute > cutoffTime.minute);

    // Set the reservation date based on the current time
    DateTime reservationDate = date;

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('A Reservar...')),
    );

    try {
      final response = await http.post(
        Uri.parse(
            'https://appbar.epvc.pt/API/appBarMonteAPI_Post.php'), // Replace with your API endpoint
        body: {
          'query_param': '1', // Ensure this is a string
          'name': users[0]['Nome'].toString(),
          'hora': selectedTime, // Use the selected time directly
          'people': '1', // Convert to string
          'aluno': users[0]['Email'].toString(),
          'food':
              item['nome'].toString(), // Include item name in the reservation
          'date': reservationDate
              .toIso8601String()
              .split('T')[0], // Add the reservation date
        },
      );

      print(response.body);

      if (response.statusCode == 200) {
        // Handle successful reservation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reservado com sucesso!')),
        );
      } else {
        // Handle server error
        final errorMessage = response.body.isNotEmpty
            ? response.body
            : 'Erro ao fazer a reserva';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      print('Erro ao fazer a reserva: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao fazer a reserva: $e')),
      );
    }
  }

  void _showReservationDialog(Map<String, dynamic> item) {
    DateTime? selectedDate; // Variable to hold the selected date

    // Get the current time
    TimeOfDay currentTime = TimeOfDay.now();
    TimeOfDay cutoffTime = TimeOfDay(hour: 11, minute: 0); // 11:00 AM

    // Check if the current time is after 11:00 AM
    bool isAfterCutoffTime = (currentTime.hour > cutoffTime.hour) ||
        (currentTime.hour == cutoffTime.hour &&
            currentTime.minute > cutoffTime.minute);

    // Set the reservation date based on the current time
    DateTime reservationDate =
        DateTime.now().add(Duration(days: isAfterCutoffTime ? 1 : 0));

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Reservar ${item['nome']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Button to select the time
              TextFormField(
                controller: _timeController,
                decoration: InputDecoration(
                  labelText: 'Hora (HH:MM)',
                ),
                readOnly: true,
                onTap: () {
                  _showTimePicker();
                },
              ),
              SizedBox(height: 20),
              // Display the selected time
              if (_selectedTime != null)
                Text('Horas Selecionadas: $_selectedTime'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (_selectedTime != null) {
                  // Convert selected time string to TimeOfDay
                  List<String> timeParts =
                      _selectedTime!.split(':'); // Use null check here
                  TimeOfDay selectedTime = TimeOfDay(
                    hour: int.parse(timeParts[0]),
                    minute: int.parse(timeParts[1]),
                  );

                  // Show confirmation dialog
                  _showConfirmationDialog(item, reservationDate, selectedTime);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please select a time')),
                  );
                }
              },
              child: Text('Reservar'),
            ),
          ],
        );
      },
    );
  }

  void _showConfirmationDialog(
      Map<String, dynamic> item, DateTime date, TimeOfDay time) {
    // Check if the selected time is after 14:00
    if (time.hour >= 14) {
      date = date.add(Duration(days: 1)); // Move reservation to the next day
    }

    // Create the reservation summary with bold date
    String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    String formattedTime = time.format(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar Reserva'),
          content: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Reservas-te ${item['nome']} para o dia ',
                  style: TextStyle(fontWeight: FontWeight.normal),
                ),
                TextSpan(
                  text: DateFormat('dd/MM/yyyy').format(date), // Bold date
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                TextSpan(
                  text: ' às ',
                  style: TextStyle(fontWeight: FontWeight.normal),
                ),
                TextSpan(
                  text: '$formattedTime.',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _makeReservation(item, date,
                    time); // Call the reservation method with three arguments
                Navigator.of(context).pop(); // Close the confirmation dialog
                Navigator.of(context).pop();
              },
              child: Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  void _showTimePicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Selecione as Horas'),
          content: DropdownButton<String>(
            isExpanded: true,
            hint: Text('Selecione as Horas'),
            value: _selectedTime,
            items: _getValidTimes().map((String time) {
              return DropdownMenuItem<String>(
                value: time,
                child: Text(time),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedTime = newValue;
                _timeController.text = newValue ?? '';
              });
              Navigator.of(context).pop(); // Close the dialog
            },
          ),
        );
      },
    );
  }

  List<String> _getValidTimes() {
    List<String> validTimes = [];
    // Generate valid times between 11:30 and 14:00
    for (int hour = 11; hour <= 14; hour++) {
      for (int minute = 0; minute < 60; minute += 10) {
        if (hour == 11 && minute < 30) continue; // Skip times before 11:30
        if (hour == 14 && minute > 0) continue; // Skip times after 14:00
        validTimes.add(
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
      }
    }
    return validTimes;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeAluno(),
          ),
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(50.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Procurar...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
        ),
        body: StreamBuilder<List<dynamic>>(
          stream: _streamController.stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('Pratos não Encontrados'));
            }

            final items = snapshot.data!;
            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  key: ValueKey(item['Nome']), // Use a chave para ajudar o Flutter a otimizar a reconstrução
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                            leading: Image.memory(
                              base64.decode(item['Imagem']),
                              fit: BoxFit.cover,
                              height: 50,
                              width: 50,
                            ),
                            title: Text(item['nome']),
                            trailing: Visibility(
                              visible: item['estado'] == "1",
                              child: ElevatedButton(
                                onPressed: () {
                                  _showReservationDialog(item);
                                },
                                child: Text('Reservar'),
                              ),
                            ))
                      ]),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class ShoppingCartPage extends StatefulWidget {
  @override
  _ShoppingCartPageState createState() => _ShoppingCartPageState();
}

class _ShoppingCartPageState extends State<ShoppingCartPage> {
  Map<String, int> itemCountMap = {};
  List<String> orderedItems = [];
  dynamic users;
  double dinheiroAtual = 0;
  SibsService? _sibsService;
  int orderNumber = 0;
  bool _isLoading = false;
  String? _loadingMessage;
  void _setLoading(bool loading, {String? message}) {
    setState(() {
      _isLoading = loading;
      _loadingMessage = message;
    });
  }

  @override
  void initState() {
    super.initState();
    updateItemCountMap();
    UserInfo();
    _initializeSibsService();
  }

  void UserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var user = prefs.getString("username");

    final response = await http.post(
      Uri.parse('https://appbar.epvc.pt/API/appBarAPI_Post.php'),
      body: {
        'query_param': '1',
        'user': user,
      },
    );
    if (response.statusCode == 200) {
      setState(() {
        users = json.decode(response.body);
      });
    }
  }

  Future<void> _initializeSibsService() async {
    try {
      _sibsService = SibsService(
        accessToken:
            '0267adfae94c224be1b374be2ce7b298f0.eyJlIjoiMjA1NzkzODk3NTc1MSIsInJvbGVzIjoiTUFOQUdFUiIsInRva2VuQXBwRGF0YSI6IntcIm1jXCI6XCI1MDYzNTBcIixcInRjXCI6XCI4MjE0NFwifSIsImkiOiIxNzQyNDA2MTc1NzUxIiwiaXMiOiJodHRwczovL3FseS5zaXRlMS5zc28uc3lzLnNpYnMucHQvYXV0aC9yZWFsbXMvREVWLlNCTy1JTlQuUE9SVDEiLCJ0eXAiOiJCZWFyZXIiLCJpZCI6IjVXcjN5WkZCSERmNzE4MDgxMGYxYjA0YTg2OTE4OTEwZDBjYzM2ZTRiMSJ9.6a6179e2d76dbe03f41f8252510dcb8a7056d9132a034c26174a6cf5c2ce75b3b5052d85f38fdd8b8765b7dfeb42e2d8aae898dfea1893b217856ef0794ee2f1',
        merchantId: '506350',
        merchantName: 'AppBar',
      );
      print('Serviço SIBS inicializado com sucesso');
    } catch (e) {
      print('Erro ao inicializar serviço SIBS: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao inicializar serviço de pagamento')),
      );
    }
  }

  Future<bool> _showOrderConfirmationDialog() async {
    return await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Confirmar Pedido',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Confirmar', style: TextStyle(color: Colors.green)),
                onTap: () => Navigator.pop(context, true),
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('Cancelar', style: TextStyle(color: Colors.red)),
                onTap: () => Navigator.pop(context, false),
              ),
            ],
          ),
        );
      },
    ) ?? false;
  }

  Future<String?> _showPaymentMethodDialog() async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'Método de Pagamento',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // MBWay Option
            ListTile(
              leading: Icon(Icons.phone_android, color: Color.fromARGB(255, 177, 2, 2)),
              title: Text('MBWay', style: TextStyle(color: Color.fromARGB(255, 177, 2, 2))),
              onTap: () {
                _setLoading(true, message: 'Processando MBWay...');
                Navigator.pop(context, 'mbway');
              },
            ),
            // Dinheiro Option
            ListTile(
              leading: Icon(Icons.money, color: Color.fromARGB(255, 27, 94, 32)),
              title: Text('Dinheiro', style: TextStyle(color: Color.fromARGB(255, 27, 94, 32))),
              onTap: () {
                _setLoading(true, message: 'Processando pagamento em dinheiro...');
                Navigator.pop(context, 'dinheiro');
              },
            ),
            // Saldo Option (only shown if authorized)
            if (users != null && users.isNotEmpty && users[0]['AutorizadoSaldo'] == '1')
              ListTile(
                leading: Icon(Icons.account_balance_wallet, color: Colors.orange[700]),
                title: Text('Saldo', style: TextStyle(color: Colors.orange[700])),
                onTap: () {
                  _setLoading(true, message: 'Processando pagamento com saldo...');
                  Navigator.pop(context, 'saldo');
                },
              ),
            SizedBox(height: 8),
            // Cancel Button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showPrencadoConfirmationDialog(List<Map<String, dynamic>> prencadoProducts) async {
    Map<String, bool> selectedProducts = {};
    Map<String, bool> freshOptionForAquecido = {};
    
    return await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Preparação dos Produtos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...prencadoProducts.map((product) {
                String prencado = product['Prencado'] ?? '0';
                selectedProducts[product['Nome']] = false;
                freshOptionForAquecido[product['Nome']] = false;
                
                return StatefulBuilder(
                  builder: (context, setState) {
                    if (prencado == '1') {
                      return ListTile(
                        leading: Icon(Icons.restaurant, color: Colors.orange),
                        title: Text(product['Nome']),
                        subtitle: Text('Deseja Prensado?'),
                        trailing: Checkbox(
                          value: selectedProducts[product['Nome']],
                          onChanged: (bool? value) {
                            setState(() {
                              selectedProducts[product['Nome']] = value ?? false;
                              product['PrepararPrencado'] = value ?? false;
                            });
                          },
                        ),
                      );
                    } else if (prencado == '2') {
                      return ListTile(
                        leading: Icon(Icons.severe_cold, color: Colors.green),
                        title: Text(product['Nome']),
                        subtitle: Text('Deseja Fresco?'),
                        trailing: Checkbox(
                          value: selectedProducts[product['Nome']],
                          onChanged: (bool? value) {
                            setState(() {
                              selectedProducts[product['Nome']] = value ?? false;
                              product['PrepararPrencado'] = value ?? false;
                              freshOptionForAquecido[product['Nome']] = value ?? false;
                            });
                          },
                        ),
                      );
                    } else if (prencado == '3') {
                      return ListTile(
                        leading: Icon(Icons.local_cafe, color: Colors.brown),
                        title: Text(product['Nome']),
                        subtitle: Text('Deseja Fresco?'),
                        trailing: Checkbox(
                          value: selectedProducts[product['Nome']],
                          onChanged: (bool? value) {
                            setState(() {
                              selectedProducts[product['Nome']] = value ?? false;
                              product['PrepararPrencado'] = value ?? false;
                              freshOptionForAquecido[product['Nome']] = value ?? false;
                            });
                          },
                        ),
                      );
                    }
                    return Container();
                  },
                );
              }).toList(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Cancelar', style: TextStyle(color: Colors.red)),
                  ),
                  LoadingButton(
                    onPressed: () async {
                      _setLoading(true, message: 'Confirmando preparação...');
                      for (var product in prencadoProducts) {
                        int index = cartItems.indexWhere((item) => item['Nome'] == product['Nome']);
                        if (index != -1) {
                          cartItems[index]['PrepararPrencado'] = selectedProducts[product['Nome']];
                          cartItems[index]['Fresh'] = freshOptionForAquecido[product['Nome']];
                        }
                      }
                      Navigator.pop(context, true);
                    },
                    child: Text('Confirmar'),
                    backgroundColor: Colors.green,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ) ?? false;
  }

  Future<bool> _showNeedsChangeDialog() async {
    return await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'Troco',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Sim', style: TextStyle(color: Colors.green)),
              onTap: () => Navigator.pop(context, true),
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('Não', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    ) ?? false;
  }

  Future<double?> _showMoneyAmountDialog(double total) async {
    final moneyController = TextEditingController();
    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'Valor Entregue',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Total a pagar: ${total.toStringAsFixed(2).replaceAll('.', ',')}€',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: moneyController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Digite o valor que será entregue',
                suffixText: '€',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar', style: TextStyle(color: Colors.red)),
                ),
                TextButton(
                  onPressed: () {
                    double? amount = double.tryParse(moneyController.text.replaceAll(',', '.'));
                    if (amount != null && amount >= total) {
                      Navigator.pop(context, amount);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Valor inválido ou menor que o total')),
                      );
                    }
                  },
                  child: Text('Confirmar', style: TextStyle(color: Colors.green)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> sendOrderToApi() async {
    if (itemCountMap.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('O carrinho está vazio')),
      );
      return;
    }

    // First confirmation dialog
    bool confirmOrder = await _showOrderConfirmationDialog();
    if (!confirmOrder) return;

    // Check for products with Prencado != 0
    List<Map<String, dynamic>> prencadoProducts = cartItems.where((item) {
      String prencado = item['Prencado'] ?? '0';
      return prencado != '0';
    }).toList();

    // If there are products with Prencado != 0, show the confirmation dialog
    if (prencadoProducts.isNotEmpty) {
      bool confirmPrencado = await _showPrencadoConfirmationDialog(prencadoProducts);
      if (!confirmPrencado) return;
    }

    // Mostrar diálogo de seleção de método de pagamento
    final paymentMethod = await _showPaymentMethodDialog();
    if (paymentMethod == null) return;

    // Initialize payment-related variables
    String nif = '';
    bool requestInvoice = false;

    // Check if user is a professor and handle invoice request
    if (users != null && users.isNotEmpty && users[0]['Permissao'] == 'Professor') {
      requestInvoice = await _showInvoiceRequestDialog();
      
      if (requestInvoice) {
        bool autoBillNIF = users[0]['FaturacaoAutomatica'] == '1' || users[0]['FaturacaoAutomatica'] == 1;
        
        if (autoBillNIF && users[0]['NIF'] != null && users[0]['NIF'].toString().isNotEmpty) {
          nif = users[0]['NIF'].toString();
        } else {
          nif = await _showNifInputDialog() ?? '';
          if (nif.isEmpty) {
            return;
          }
        }
      }
    }

    try {
      // Create the description string with proper formatting
      List<String> formattedNames = cartItems.map((item) {
        String name = item['Nome'] as String;
        bool prepararPrencado = item['PrepararPrencado'] ?? false;
        String prencado = item['Prencado'] ?? '0';
        bool isFresh = item['Fresh'] ?? false;
        
        String suffix = '';
        
        if (prencado == '1' && prepararPrencado) {
          suffix = ' - Prensado';
        } else if (prencado == '2' && prepararPrencado) {
          suffix = ' - Aquecido';
        } else if (prencado == '3' && isFresh) {
          suffix = ' - Fresco';
        }
        
        return '$name$suffix';
      }).toList();

      String descricao = formattedNames.join(', ');

      // Extract user information
      var turma = users[0]['Turma'] ?? '';
      var nome = users[0]['Nome'] ?? '';
      var apelido = users[0]['Apelido'] ?? '';
      var permissao = users[0]['Permissao'] ?? '';
      var imagem = users[0]['Imagem'] ?? '';
      double total = calculateTotal();

      if (paymentMethod == 'mbway') {
        // Preparar os dados do pedido
        Map<String, dynamic> orderData = {
          'nome': nome,
          'apelido': apelido,
          'turma': turma,
          'descricao': descricao,
          'permissao': permissao,
          'imagem': imagem,
          'total': total.toString(),
          'MetodoDePagamento': paymentMethod,
          'cartItems': json.encode(cartItems),
          'requestInvoice': requestInvoice ? '1' : '0',
          'nif': nif,
        };
        
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MBWayPhoneNumberPage(
              amount: total,
              orderData: orderData,
              sibsService: _sibsService!,
              onResult: (success, newOrderNumber) {
                if (success) {
                  setState(() {
                    orderNumber = newOrderNumber;
                    cartItems.clear();
                    updateItemCountMap();
                  });
                }
              },
              onCancel: () {
                Navigator.pop(context);
              },
            ),
          ),
        );
      } else if (paymentMethod == 'dinheiro') {
        await _handleCashPayment(total, requestInvoice: requestInvoice, nif: nif);
      } else if (paymentMethod == 'saldo') {
        await _handleSaldoPayment(total, requestInvoice: requestInvoice, nif: nif);
      }
    } catch (e) {
      print('Erro ao enviar pedido: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao processar pedido: ${e.toString()}')),
      );
    }
  }

  Future<void> sendOrderToWebSocket(
      List<Map<String, dynamic>> cartItems, 
      String total, 
      {String? paymentMethod, 
      bool requestInvoice = false, 
      String nif = '',
      double? dinheiroAtual}) async {
    try {
      // Format item names with preparation preferences
      List<String> formattedNames = cartItems.map((item) {
        String name = item['Nome'] as String;
        bool prepararPrencado = item['PrepararPrencado'] ?? false; // Indica se alguma opção de preparação foi marcada no diálogo (usado para tipos 1 e 2)
        String prencado = item['Prencado'] ?? '0';
        bool isFresh = item['Fresh'] ?? false; // Usado para a opção "Fresco" (tipo 3)
        
        String suffix = '';
        
        if (prencado == '1' && prepararPrencado) {
          suffix = ' - Prensado';
        } else if (prencado == '2' && prepararPrencado) {
          suffix = ' - Aquecido';
        } else if (prencado == '3' && isFresh) {
          suffix = ' - Fresco';
        }
        
        return '$name$suffix';

      }).toList();
      
      String descricao = formattedNames.join(', ');

      var turma = users[0]['Turma'];
      var nome = users[0]['Nome'];
      var permissao = users[0]['Permissao'];
      var imagem = users[0]['Imagem'];
      
      // Calcular o troco usando o dinheiroAtual passado como parâmetro
      double troco = (dinheiroAtual ?? double.parse(total)) - double.parse(total);
      String trocos = troco.toStringAsFixed(2);

      final channel = WebSocketChannel.connect(
        Uri.parse('ws://websocket.appbar.epvc.pt'),
      );

      // Send order data
      Map<String, dynamic> orderData = {
        'QPediu': nome,
        'NPedido': orderNumber,
        'Troco': trocos,
        'Turma': turma,
        'Permissao': permissao,
        'Estado': 0,
        'Descricao': descricao,
        'Total': total,
        'Imagem': imagem,
        'MetodoDePagamento': paymentMethod,
        'DinheiroAtual': dinheiroAtual?.toString() ?? total, // Incluir o valor do dinheiro atual
      };

      // Add invoice information if requested
      if (requestInvoice) {
        orderData['RequestInvoice'] = '1';
        orderData['NIF'] = nif;
      }

      channel.sink.add(json.encode(orderData));

      channel.stream.listen(
        (message) {
          // Add a basic check to see if the message looks like JSON
          if (message != null && message.startsWith('{') && message.endsWith('}')) {
            try {
              var serverResponse = json.decode(message);
              if (serverResponse['status'] == 'success') {
                if (mounted) { // Check if the widget is still mounted
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Pedido enviado com sucesso! Pedido Nº $orderNumber'),
                    ),
                  );
                }
              } else {
                 if (mounted) { // Check if the widget is still mounted
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Erro ao enviar o pedido. Contacte o Administrador! Error 02'),
                    ),
                  );
                 }
              }
            } catch (e) {
              print('Erro ao processar a mensagem WebSocket: $e');
              if (mounted) { // Check if the widget is still mounted
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Erro ao processar resposta do WebSocket. Contacte o Administrador!'),
                  ),
                );
              }
            }
          } else {
             print('Received non-JSON message from WebSocket: $message');
             // Optionally, you can show a different message to the user for non-JSON responses
          }
          channel.sink.close();
        },
        onError: (error) {
          print('Erro ao fazer a requisição WebSocket: $error');
          if (mounted) { // Check if the widget is still mounted
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Erro ao enviar o pedido. Contacte o Administrador! Error 01'),
              ),
            );
          }
        },
      );
    } catch (e) {
      print('Erro ao estabelecer conexão WebSocket: $e');
      if (mounted) { // Check if the widget is still mounted
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Erro ao enviar o pedido. Contacte o Administrador! Error 01'),
          ),
        );
      }
    }
  }

  Future<void> _handleCashPayment(double total, {bool requestInvoice = false, String nif = ''}) async {
    try {
      // Create the description string with proper formatting
      List<String> formattedNames = cartItems.map((item) {
        String name = item['Nome'] as String;
        bool prepararPrencado = item['PrepararPrencado'] ?? false;
        String prencado = item['Prencado'] ?? '0';
        bool isFresh = item['Fresh'] ?? false;
        String suffix = '';
        
        if (prencado == '1' && prepararPrencado) {
          suffix = ' - Prensado';
        } else if (prencado == '2' && prepararPrencado) {
          suffix = ' - Aquecido';
        } else if (prencado == '3' && isFresh) {
          suffix = ' - Fresco';
        }
        
        return '$name$suffix';
      }).toList();

      String descricao = formattedNames.join(', ');

      // Extract user information
      var turma = users[0]['Turma'] ?? '';
      var nome = users[0]['Nome'] ?? '';
      var apelido = users[0]['Apelido'] ?? '';
      var permissao = users[0]['Permissao'] ?? '';
      var imagem = users[0]['Imagem'] ?? '';

      // Criar o pedido com as informações de pagamento em dinheiro
      final response = await http.post(
        Uri.parse('https://appbar.epvc.pt/API/appBarAPI_GET.php'),
        body: {
          'query_param': '5',
          'nome': nome,
          'apelido': apelido,
          'orderNumber': '0',
          'turma': turma,
          'descricao': descricao,
          'permissao': permissao,
          'total': total.toString(),
          'valor': total.toString(), // Use total as the payment amount
          'imagem': imagem,
          'payment_method': 'dinheiro',
          'phone_number': '--',
          'requestInvoice': requestInvoice ? '1' : '0',
          'nif': nif,
        },
      );

      print(response);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception('Empty response from server');
        }

        try {
          final data = json.decode(response.body);

          if (data['status'] == 'success') {
            orderNumber = int.parse(data['orderNumber'].toString());
            
            // Enviar para o WebSocket com o valor do total
            await sendOrderToWebSocket(
              cartItems,
              total.toString(),
              paymentMethod: 'dinheiro',
              requestInvoice: requestInvoice,
              nif: nif,
              dinheiroAtual: total // Pass the total as the payment amount
            );
            
            // Envia os itens do pedido para adicionar aos recentes
            await sendRecentOrderToApi(cartItems);

            setState(() {
              cartItems.clear();
              updateItemCountMap();
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Pedido enviado com sucesso! Pedido Nº $orderNumber')),
            );

            // Navegar para a página de confirmação de pedido
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => CashConfirmationPage(
                  change: 0.0, // No change needed
                  orderNumber: orderNumber,
                  amount: total,
                ),
              ),
            );
          } else {
            throw Exception(data['message'] ?? 'Unknown error');
          }
        } catch (e) {
          print('Error parsing response: $e');
          throw Exception('Error processing server response');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao processar pagamento em dinheiro: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao processar pagamento: ${e.toString()}')),
        );
      }
    }
  }

  void updateItemCountMap() {
    itemCountMap.clear();
    orderedItems.clear(); // Clear the ordered items list first
    
    // Create a map to track unique items and their counts
    Map<String, Map<String, dynamic>> uniqueItems = {};
    
    for (var item in cartItems) {
      final itemName = item['Nome'] as String;
      if (!uniqueItems.containsKey(itemName)) {
        uniqueItems[itemName] = item;
        orderedItems.add(itemName);
      }
    }
    
    // Update the count map
    for (var itemName in orderedItems) {
      itemCountMap[itemName] = cartItems.where((item) => item['Nome'] == itemName).length;
    }
  }

  double calculateTotal() {
    double total = 0.0;
    for (var item in cartItems) {
      try {
        String precoStr = item['Preco'].toString().replaceAll(',', '.');
        double preco = double.parse(precoStr);
        total += preco;
      } catch (e) {
        print('Error parsing price for item ${item['Nome']}: $e');
      }
    }
    return double.parse(total.toStringAsFixed(2));
  }

  String getLocalDate() {
    DateTime now = DateTime.now();
    String formattedDateTime = DateFormat('yyyy-MM-dd').format(now);
    return formattedDateTime;
  }

  Future<void> sendRecentOrderToApi(
      List<Map<String, dynamic>> recentOrders) async {
    try {
      for (var order in recentOrders) {
        // Concatenar informações do usuário para formar o identificador do usuário
        var user = users[0]['Email'];
        var localData = getLocalDate();

        // Extrair a imagem se não for nula, caso contrário, use uma string vazia
        var imagem = order['Imagem'] ?? '';
        var preco = order['Preco'] ?? '';
        var prencado = order['Prencado'] ?? '0';
        var prepararPrencado = order['PrepararPrencado'] ?? false;
        
        // Convert boolean to string representation for API
        String prepararPrencadoValue = prepararPrencado ? '1' : '0';

        // Enviar solicitação POST para a API para cada pedido
        var response = await http.post(
          Uri.parse('https://appbar.epvc.pt/API/appBarAPI_Post.php'),
          body: {
            'query_param': '6',
            'user': user,
            'orderDetails': json.encode(order['Nome']),
            'data': localData.toString(),
            'imagem': imagem,
            'preco': preco,
            'prencado': prencado.toString(),
            'prepararPrencado': prepararPrencadoValue,
          },
        );

        if (response.statusCode == 200) {
          // Se a solicitação for bem-sucedida, mostrar uma mensagem de sucesso
          print('Pedido enviado com sucesso para a API');
        } else {
          // Se houver um erro, mostrar uma mensagem de erro
          print('Erro ao enviar pedido para a API');
        }
      }
    } catch (e) {
      print('Erro ao enviar pedidos para a API: $e');
    }
  }

  Future<int> checkQuantidade(String productName) async {
    try {
      // Remove double quotes and trim the product name
      String cleanProductName = productName.replaceAll('"', '').trim();
      
      // Make the API request
      var response = await http.get(Uri.parse(
          'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=8&nome=$cleanProductName'));

      if (response.statusCode == 200) {
        // Parse the response
        var data = json.decode(response.body);
        
        // Check if there's an error in the response
        if (data is Map && data.containsKey('error')) {
          print('Error checking quantity: ${data['error']}');
          return 0; // Return 0 if product not found
        }
        
        // If data is a list and not empty
        if (data is List && data.isNotEmpty) {
          return int.parse(data[0]['Qtd'].toString());
        }
      }
      return 0; // Return 0 if no data or error
    } catch (e) {
      print('Error checking quantity: $e');
      return 0; // Return 0 on error
    }
  }

  Future<void> checkAvailabilityBeforeOrder(double total) async {
    bool allAvailable = true;
    List<String> unavailableItems = <String>[];  // Explicitly specify the type

    for (var entry in itemCountMap.entries) {
      final itemName = entry.key;
      final cartQuantity = entry.value;

      var quantity = await checkQuantidade(itemName);

      if (quantity == 0) {
        allAvailable = false;
        unavailableItems.add('$itemName (Indisponível)');
      } else if (cartQuantity > quantity) {
        allAvailable = false;
        unavailableItems.add('$itemName (Disponível: $quantity)'); // Include available quantity in message
      }
    }

    if (cartItems.isNotEmpty) {
      if (allAvailable) {
        // Check if user is a professor before proceeding to payment
        String userPermission = users != null && users.isNotEmpty ? users[0]['Permissao'] ?? '' : '';
        String nif = '';
        bool requestInvoice = false;
        
        // If the user is a professor, ask if they want an invoice with NIF
        if (userPermission == 'Professor') {
          requestInvoice = await _showInvoiceRequestDialog();
          
          if (requestInvoice) {
            // Verifica se tem faturação automática ativa
            bool autoBillNIF = users[0]['FaturacaoAutomatica'] == '1' || users[0]['FaturacaoAutomatica'] == 1;
            
            if (autoBillNIF && users[0]['NIF'] != null && users[0]['NIF'].toString().isNotEmpty) {
              // Se tiver faturação automática e NIF, usa o NIF cadastrado
              nif = users[0]['NIF'].toString();
            } else {
              // Se não tiver faturação automática ou NIF, pede para inserir
              nif = await _showNifInputDialog() ?? '';
              if (nif.isEmpty) {
                // User cancelled NIF input
                return;
              }
            }
          }
        }
        
        // Show payment method selection dialog
        final paymentMethod = await _showPaymentMethodDialog();
        if (paymentMethod == null) return;
        
        if (paymentMethod == 'mbway') {
          await _handleMBWayPayment(total, requestInvoice: requestInvoice, nif: nif);
        } else if (paymentMethod == 'dinheiro') {
          await _handleCashPayment(total, requestInvoice: requestInvoice, nif: nif);
        } else if (paymentMethod == 'saldo') {
          await _handleSaldoPayment(total, requestInvoice: requestInvoice, nif: nif);
        }
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Itens Indisponíveis'),
              content: Text(
                  'Os seguintes itens não estão disponíveis: ${unavailableItems.join(", ")}'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  Future<bool> _showInvoiceRequestDialog() async {
    // Verifica se o usuário tem faturação automática ativa e NIF cadastrado
    bool autoBillNIF = users[0]['FaturacaoAutomatica'] == '1' || users[0]['FaturacaoAutomatica'] == 1;
    bool hasNIF = users[0]['NIF'] != null && users[0]['NIF'].toString().isNotEmpty;

    // Se tiver faturação automática e NIF, retorna true diretamente
    if (autoBillNIF && hasNIF) {
      return true;
    }

    return await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Fatura com NIF',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Sim', style: TextStyle(color: Colors.green)),
                onTap: () => Navigator.pop(context, true),
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('Não', style: TextStyle(color: Colors.red)),
                onTap: () => Navigator.pop(context, false),
              ),
            ],
          ),
        );
      },
    ) ?? false;
  }

  Future<String?> _showNifInputDialog() async {
    final nifController = TextEditingController();
    
    // Verifica se o usuário tem faturação automática ativa
    bool autoBillNIF = users[0]['FaturacaoAutomatica'] == '1' || users[0]['FaturacaoAutomatica'] == 1;
    
    // Se tiver faturação automática, retorna o NIF diretamente
    if (autoBillNIF && users[0]['NIF'] != null && users[0]['NIF'].toString().isNotEmpty) {
      return users[0]['NIF'].toString();
    }

    // Se não tiver faturação automática, verifica se já tem NIF cadastrado
    if (users[0]['NIF'] != null && users[0]['NIF'].toString().isNotEmpty) {
      nifController.text = users[0]['NIF'].toString();
    }

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'Inserir NIF',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nifController,
              keyboardType: TextInputType.number,
              maxLength: 9,
              decoration: InputDecoration(
                hintText: 'Digite o NIF',
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar', style: TextStyle(color: Colors.red)),
                ),
                TextButton(
                  onPressed: () async {
                    String nif = nifController.text.trim();
                    if (nif.length == 9 && int.tryParse(nif) != null) {
                      // Se o NIF for diferente do cadastrado, atualiza na base de dados
                      if (users[0]['NIF'] == null || users[0]['NIF'].toString() != nif) {
                        try {
                          final response = await http.post(
                            Uri.parse('https://appbar.epvc.pt/API/appBarAPI_Post.php'),
                            body: {
                              'query_param': 'update_nif',
                              'user_id': users[0]['IdUser'].toString(),
                              'nif': nif,
                            },
                          );

                          if (response.statusCode == 200) {
                            // Atualiza o NIF localmente
                            setState(() {
                              users[0]['NIF'] = nif;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('NIF atualizado com sucesso!')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erro ao atualizar NIF')),
                            );
                          }
                        } catch (e) {
                          print('Erro ao atualizar NIF: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erro ao atualizar NIF')),
                          );
                        }
                      }
                      Navigator.pop(context, nif);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('NIF inválido. O NIF deve ter 9 dígitos numéricos.')),
                      );
                    }
                  },
                  child: Text('Confirmar', style: TextStyle(color: Colors.green)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Method for MBWay payment
  Future<void> _handleMBWayPayment(double total, {bool requestInvoice = false, String nif = ''}) async {
    try {
      // Create the description string with proper formatting
      List<String> formattedNames = cartItems.map((item) {
        String name = item['Nome'] as String;
        bool prepararPrencado = item['PrepararPrencado'] ?? false;
        String prencado = item['Prencado'] ?? '0';
        bool isFresh = item['Fresh'] ?? false;
        
        String suffix = '';
        
        if (prencado == '1' && prepararPrencado) {
          suffix = ' - Prensado';
        } else if (prencado == '2' && prepararPrencado) {
          suffix = ' - Aquecido';
        } else if (prencado == '3' && isFresh) {
          suffix = ' - Fresco';
        }
        
        return '$name$suffix';
      }).toList();

      String descricao = formattedNames.join(', ');

      // Extract user information
      var turma = users[0]['Turma'] ?? '';
      var nome = users[0]['Nome'] ?? '';
      var apelido = users[0]['Apelido'] ?? '';
      var permissao = users[0]['Permissao'] ?? '';
      var imagem = users[0]['Imagem'] ?? '';

      // Preparar os dados do pedido
      Map<String, dynamic> orderData = {
        'nome': nome,
        'apelido': apelido,
        'turma': turma,
        'descricao': descricao,
        'permissao': permissao,
        'imagem': imagem,
        'total': total.toString(),
        'payment_method': 'mbway',
        'cartItems': json.encode(cartItems),
        'requestInvoice': requestInvoice ? '1' : '0',
        'nif': nif,
      };
      
      // Ir para a página de telefone MBWay com a lógica de pagamento
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MBWayPhoneNumberPage(
            amount: total,
            orderData: orderData,
            sibsService: _sibsService!,
            onResult: (success, newOrderNumber) {
              if (success) {
                setState(() {
                  orderNumber = newOrderNumber;
                  // Envia os itens do pedido para adicionar aos recentes ANTES de limpar
                  sendRecentOrderToApi(cartItems);
                  // Clear cart items after all processing is complete
                  cartItems.clear();
                  updateItemCountMap();
                });
              }
            },
            onCancel: () {
              Navigator.pop(context);
            },
          ),
        ),
      );
    } catch (e) {
      print('Erro ao processar pagamento MBWay: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao processar pagamento: ${e.toString()}')),
        );
      }
    }
  }

  // Method for Saldo payment
  Future<void> _handleSaldoPayment(double total, {bool requestInvoice = false, String nif = ''}) async {
    // Implement balance check, deduction, and transaction recording here
    if (users == null || users.isEmpty || users[0]['Saldo'] == null) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Erro ao obter saldo do usuário.')),
         );
       }
       return; // Cannot proceed without user data or balance
    }

    double currentBalance = double.tryParse(users[0]['Saldo'].toString()) ?? 0.0;

    if (currentBalance >= total) {
        // Sufficient balance, proceed with payment
         try {
            // Create the description string with proper formatting
            List<String> formattedNames = cartItems.map((item) {
              String name = item['Nome'] as String;
              bool prepararPrencado = item['PrepararPrencado'] ?? false;
              String prencado = item['Prencado'] ?? '0';
              bool isFresh = item['Fresh'] ?? false;

              String suffix = '';
              
              if (prencado == '1' && prepararPrencado) {
                suffix = ' - Prensado';
              } else if (prencado == '2' && prepararPrencado) {
                suffix = ' - Aquecido';
              } else if (prencado == '3' && isFresh) {
                suffix = ' - Fresco';
              }
              
              return '$name$suffix';
            }).toList();

            String descricao = formattedNames.join(', ');

            // Extract user information
            var turma = users[0]['Turma'] ?? '';
            var nome = users[0]['Nome'] ?? '';
            var apelido = users[0]['Apelido'] ?? '';
            var permissao = users[0]['Permissao'] ?? '';
            var imagem = users[0]['Imagem'] ?? '';
            var userEmail = users[0]['Email'] ?? '';

            // Primeiro, criar o pedido para obter o número do pedido
            final orderResponse = await http.post(
              Uri.parse('https://appbar.epvc.pt/API/appBarAPI_GET.php'),
              body: {
                'query_param': '5',
                'nome': nome,
                'apelido': apelido,
                'orderNumber': '0',
                'turma': turma,
                'descricao': descricao,
                'permissao': permissao,
                'total': total.toString(),
                'valor': total.toString(),
                'imagem': imagem,
                'payment_method': 'saldo',
                'phone_number': '--',
                'requestInvoice': requestInvoice ? '1' : '0',
                'nif': nif,
              },
            );

            if (orderResponse.statusCode == 200 && orderResponse.body.isNotEmpty) {
              final orderData = json.decode(orderResponse.body);
              if (orderData['status'] == 'success') {
                orderNumber = int.parse(orderData['orderNumber'].toString());
                
                // Agora que temos o número do pedido, usar apenas ele na descrição
                String descricaoComPedido = 'Pedido Nº$orderNumber';

                // Call API to deduct balance and record transaction
                final response = await http.post(
                  Uri.parse('https://appbar.epvc.pt/API/appBarAPI_Post.php'),
                  body: {
                    'query_param': '9.1',
                    'email': userEmail,
                    'amount': total.toString(),
                    'description': descricaoComPedido,
                    'type': '2', // 2 for used
                  },
                );

                print('Saldo payment API response status: ${response.statusCode}');
                print('Saldo payment API response body: ${response.body}');

                if (response.statusCode == 200) {
                  final responseData = json.decode(response.body);
                  if (responseData['success'] == true) {
                    // Enviar para o WebSocket
                    await sendOrderToWebSocket(
                      cartItems,
                      total.toString(),
                      paymentMethod: 'saldo',
                      requestInvoice: requestInvoice,
                      nif: nif,
                    );

                    // Envia os itens do pedido para adicionar aos recentes ANTES de limpar
                    await sendRecentOrderToApi(cartItems);

                    // Limpar o carrinho e atualizar a UI
                    setState(() {
                      cartItems.clear();
                      updateItemCountMap();
                    });

                    // Mostrar mensagem de sucesso
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Pedido Nº $orderNumber realizado com sucesso!')),
                    );

                    // Navegar para a página de confirmação de sucesso
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CashConfirmationPage(
                          change: 0.0, // Não há troco no pagamento com saldo
                          orderNumber: orderNumber,
                          amount: total,
                        ),
                      ),
                    );
                  } else {
                    String errorMsg = responseData['error'] ?? 'Erro desconhecido ao processar pagamento com Saldo';
                    // Navegar para a página de declínio com a mensagem de erro
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderDeclinedPage(
                          reason: errorMsg,
                          amount: total,
                        ),
                      ),
                    );
                  }
                } else {
                  // Navegar para a página de declínio com erro de comunicação
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderDeclinedPage(
                        reason: 'Erro na comunicação com o servidor',
                        amount: total,
                      ),
                    ),
                  );
                }
              } else {
                // Navegar para a página de declínio com erro ao criar pedido
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderDeclinedPage(
                      reason: 'Erro ao criar pedido: ${orderData['message'] ?? "Erro desconhecido"}',
                      amount: total,
                    ),
                  ),
                );
              }
            } else {
              // Navegar para a página de declínio com erro ao criar pedido
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderDeclinedPage(
                    reason: 'Erro ao criar pedido',
                    amount: total,
                  ),
                ),
              );
            }
         } catch (e) {
            print('Error processing Saldo payment: $e');
            // Navegar para a página de declínio com erro de processamento
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => OrderDeclinedPage(
                  reason: 'Erro ao processar pagamento: ${e.toString()}',
                  amount: total,
                ),
              ),
            );
         }
    } else {
        // Saldo insuficiente - navegar para a página de declínio
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDeclinedPage(
              reason: 'Saldo insuficiente. Saldo atual: ${currentBalance.toStringAsFixed(2)}€',
              amount: total,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    double total = calculateTotal();
    final rootContext = context;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Carrinho de Compras',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeAlunoMain(),
                ),
              );
            },
            icon: Icon(Icons.home),
          ),
        ],
      ),
      drawer: DrawerHome(),
      body: cartItems.isEmpty 
        ? _buildEmptyCart() 
        : Column(
          children: [
            // Resumo do carrinho
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.orange.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meu Carrinho', 
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${itemCountMap.length} ${itemCountMap.length == 1 ? 'produto' : 'produtos'} diferentes',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Lista de produtos
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(top: 12),
                itemCount: orderedItems.length,
                itemBuilder: (context, index) {
                  final itemName = orderedItems[index];
                  final itemCount = itemCountMap[itemName] ?? 0;
                  // Safely find the item or use a placeholder if not found
                  final item = cartItems.firstWhere(
                    (element) => element['Nome'] == itemName,
                    orElse: () => { // Provide a default map if the item is not found
                      'Nome': itemName ?? '', // Ensure Nome is not null
                      'Imagem': '', // Provide a default empty image string
                      'Preco': '0.0', // Provide a default price
                      'Prencado': '0', // Provide a default prencado status
                      'PrepararPrencado': false, // Provide a default value
                      'Fresh': false, // Provide a default value
                    },
                  );

                  // Ensure essential properties are not null or of incorrect type after finding the item
                  final String currentItemName = (item['Nome'] is String && item['Nome'] != null) ? item['Nome'] : itemName ?? ''; // Use original itemName as fallback
                  final String currentItemPrencado = (item['Prencado'] != null) ? item['Prencado'].toString() : '0';
                  // Explicitly check for boolean type and provide a default
                  bool currentPrepararPrencado = (item['PrepararPrencado'] is bool) ? item['PrepararPrencado'] : false; 
                  bool currentFresh = (item['Fresh'] is bool) ? item['Fresh'] : false;

                  // If the item name is still empty or does not match, hide the item (in case orElse returned a minimal placeholder)
                  if (currentItemName.isEmpty || (itemName != null && currentItemName != itemName)) {
                     return Container(); // Hide the item if data is fundamentally missing or mismatched
                  }

                  // Safely decode the image bytes, handling potential errors
                  Uint8List? imageBytes;
                  String? base64Image = (item['Imagem'] is String && item['Imagem'] != null) ? item['Imagem'] : null; // Ensure it's a string and not null

                  // Add an additional check: only attempt decode if the string is not null or empty
                  if (base64Image != null && base64Image.isNotEmpty) {
                    try {
                      // Attempt to decode, catch format errors
                      imageBytes = base64.decode(base64Image);
                    } catch (e) {
                      // Log the error but continue, the errorBuilder will show the fallback
                      print('Error decoding image for item ${currentItemName}: $e');
                      // imageBytes remains null, the errorBuilder will handle this
                    }
                  }

                  final itemPrice = double.tryParse(item['Preco']?.toString() ?? '0') ?? 0;
                  final itemTotal = itemPrice * itemCount;
                  
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            Colors.grey[50]!,
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top row with image, title and quantity
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Imagem do produto
                                Container(
                                  width: 50, // Ensure width is sufficient
                                  height: 50, // Ensure height is sufficient
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: imageBytes != null
                                        ? Image.memory(
                                            imageBytes,
                                            fit: BoxFit.cover,
                                            gaplessPlayback: true,
                                            cacheWidth: 100, // Explicitly set cache dimensions
                                            cacheHeight: 100,
                                            filterQuality: FilterQuality.high,
                                            isAntiAlias: true,
                                            key: ValueKey(currentItemName), // Use currentItemName for key
                                            errorBuilder: (context, error, stackTrace) {
                                              // Fallback widget if image fails to load or decode
                                              return Container(
                                                color: Colors.grey[200], // Use a light grey background
                                                child: Icon(
                                                  Icons.broken_image_outlined, // Use a broken image icon
                                                  size: 30,
                                                  color: Colors.red, // Use red for error
                                                ),
                                              );
                                            },
                                          )
                                        : Container(
                                            color: Colors.grey[200], // Use a light grey background for missing image
                                            child: Icon(
                                              Icons.fastfood, // Generic food icon
                                              size: 30,
                                              color: Colors.grey[400], // Use a darker grey for the icon
                                            ),
                                          ), // Fallback for missing or invalid image data
                                  ),
                                ),
                                SizedBox(width: 12),
                                // Title and price
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        currentItemName.isNotEmpty ? currentItemName : 'Item Desconhecido', // Provide fallback text
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[800],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '${itemPrice.toStringAsFixed(2).replaceAll('.', ',')}€', // Use itemPrice, already defaulted to 0 if parsing failed
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange, // Orange color for price
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Quantity controls
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.remove, size: 16),
                                        onPressed: _isLoading ? null : () async {
                                          if (_isLoading) return;
                                          
                                          // Check if this is the last item of this product
                                          if (itemCount == 1) {
                                            // Show confirmation dialog
                                            bool? confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: Text('Remover Item'),
                                                  content: Text('Tem certeza que deseja remover ${currentItemName.isNotEmpty ? currentItemName : 'este item'} do carrinho?'), // Use currentItemName with fallback
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.of(context).pop(false),
                                                      style: TextButton.styleFrom(
                                                        backgroundColor: Colors.orange,
                                                        foregroundColor: Colors.white,
                                                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                      ),
                                                      child: Text('Cancelar'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () => Navigator.of(context).pop(true),
                                                      style: TextButton.styleFrom(
                                                        backgroundColor: Colors.orange,
                                                        foregroundColor: Colors.white,
                                                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                      ),
                                                      child: Text('Remover'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                            
                                            if (confirm != true) return; // User cancelled
                                          }
                                          
                                          setState(() {
                                            _isLoading = true;
                                            int index = cartItems.indexWhere((element) => element['Nome'] == itemName); // Use original itemName for finding index
                                            if (index != -1) {
                                              cartItems.removeAt(index);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Item removido'),
                                                  duration: Duration(milliseconds: 500),
                                                ),
                                              );
                                            }
                                            updateItemCountMap();
                                            _isLoading = false;
                                          });
                                        },
                                        color: _isLoading ? Colors.grey[400] : Colors.grey[700],
                                        padding: EdgeInsets.all(4),
                                        constraints: BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 4),
                                        child: Text(
                                          itemCount.toString(),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.add, size: 16),
                                        onPressed: _isLoading ? null : () async {
                                          if (_isLoading) return;
                                          
                                          setState(() => _isLoading = true);
                                          
                                          try {
                                            // Check available quantity
                                            final String productName = currentItemName; // Use standardized product name
                                            int availableQuantity = await checkQuantidade(productName); // Use product name
                                            int currentQuantity = cartItems.where((cartItem) => (cartItem['Nome'] is String ? cartItem['Nome'] : '') == productName).length; // Explicitly check type
                                            int desiredQuantity = currentQuantity + 1; // Calculate desired quantity

                                            if (availableQuantity >= desiredQuantity) {
                                              // Create a new map to avoid reference issues and ensure correct properties
                                              final newItem = Map<String, dynamic>.from(item);
                                              // Ensure all required properties are present, similar to addToCart logic
                                              if (!newItem.containsKey('Prencado')) newItem['Prencado'] = "0";
                                              if (!newItem.containsKey('PrepararPrencado')) newItem['PrepararPrencado'] = false;
                                              if (!newItem.containsKey('Fresh')) newItem['Fresh'] = false;
                                              // Apply default preparation based on Prencado value if not already set
                                              if ((newItem['Prencado'] == '1' || newItem['Prencado'] == '2') && !(newItem['PrepararPrencado'] is bool ? newItem['PrepararPrencado'] : false)) { // Explicit type check
                                                 newItem['PrepararPrencado'] = true;
                                              } else if (newItem['Prencado'] == '3' && !(newItem['Fresh'] is bool ? newItem['Fresh'] : false)) { // Explicit type check
                                                 newItem['Fresh'] = true;
                                              }

                                              setState(() {
                                                cartItems.add(newItem); // Add the new item map
                                              });

                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Item adicionado'),
                                                  duration: Duration(milliseconds: 500),
                                                ),
                                              );
                                            } else if (availableQuantity <= 0) {
                                               showDialog(
                                                context: context,
                                                builder: (BuildContext context) {
                                                  return AlertDialog(
                                                    title: Text('Produto Indisponível'),
                                                    content: Text('Desculpe, este produto está indisponível no momento.'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.of(context).pop();
                                                        },
                                                        style: TextButton.styleFrom(
                                                          backgroundColor: Colors.orange,
                                                          foregroundColor: Colors.white,
                                                        ),
                                                        child: Text('OK'),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            } else { // availableQuantity < desiredQuantity
                                              showDialog(
                                                context: context,
                                                builder: (BuildContext context) {
                                                  return AlertDialog(
                                                    title: Text('Quantidade Máxima'),
                                                    content: Text('Quantidade máxima disponível atingida (Disponível: $availableQuantity)'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.of(context).pop(),
                                                        style: TextButton.styleFrom(
                                                          backgroundColor: Colors.orange,
                                                          foregroundColor: Colors.white,
                                                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                        ),
                                                        child: Text('OK'),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            }
                                          } catch (e) {
                                            print('Erro ao verificar quantidade disponível ou adicionar ao carrinho: $e');
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: Text('Erro'),
                                                  content: Text('Ocorreu um erro ao adicionar o item ao carrinho.'), // Generic error message
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.of(context).pop(),
                                                      style: TextButton.styleFrom(
                                                        backgroundColor: Colors.orange,
                                                        foregroundColor: Colors.white,
                                                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                      ),
                                                      child: Text('OK'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          } finally {
                                            if (mounted) { // Check if the widget is still mounted before calling setState
                                              setState(() => _isLoading = false); // End loading
                                            }
                                          }
                                        },
                                        color: _isLoading ? Colors.grey[400] : Colors.grey[700], // Added color based on loading state
                                        padding: EdgeInsets.all(4), // Adjusted padding
                                        constraints: BoxConstraints( // Added constraints
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            // Preparation options at the bottom
                            // Add robust checks before accessing item['Prencado']
                            if ((item['Prencado']?.toString() ?? '0') == '1' || (item['Prencado']?.toString() ?? '0') == '2')
                              Center(
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        // Add robust check here as well
                                        (item['Prencado']?.toString() ?? '0') == '1' ? Icons.coffee : Icons.local_cafe,
                                        size: 16,
                                        color: Colors.orange[700],
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Selecione o Tipo: ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      SizedBox(
                                        width: 150, // Explicit width for ToggleButtons container
                                        child: Flexible( // Changed from Expanded
                                          child: ToggleButtons(
                                            // Ensure isSelected list is always valid with boolean values
                                            isSelected: [
                                            currentPrepararPrencado, // currentPrepararPrencado is already safely derived
                                            !currentPrepararPrencado, // Ensure negation is safe
                                          ],
                                          onPressed: (index) {
                                            setState(() {
                                               // Find the index of the item in the main list based on the unique itemName
                                              int itemIndex = cartItems.indexWhere((element) => element['Nome'] == itemName);
                                              if (itemIndex != -1) {
                                                // Create a copy of the item
                                                Map<String, dynamic> updatedItem = Map<String, dynamic>.from(cartItems[itemIndex]);
                                                // Update the property on the copy
                                                updatedItem['PrepararPrencado'] = index == 0; // Assign boolean directly
                                                // Replace the item in the main list with the updated copy
                                                cartItems[itemIndex] = updatedItem;
                                              }
                                            });
                                          },
                                          borderRadius: BorderRadius.circular(6),
                                          selectedColor: Colors.white,
                                          fillColor: Colors.orange[700],
                                          borderColor: Colors.orange[700],
                                          color: Colors.grey[700],
                                          borderWidth: 1.0,
                                          selectedBorderColor: Colors.orange[700],
                                          children: [
                                            Expanded(
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 4),
                                                child: Text(
                                                  // Add robust check here as well
                                                  (item['Prencado']?.toString() ?? '0') == '1' ? 'Prensado' : 'Aquecido',
                                                  style: TextStyle(fontSize: 12),
                                                  textAlign: TextAlign.center,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 4),
                                                child: Text(
                                                  'Normal',
                                                  style: TextStyle(fontSize: 12),
                                                  textAlign: TextAlign.center,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  )],
                                  ),
                                ),
                              ),
                            // Add robust checks before accessing item['Prencado'] for this condition
                            if ((item['Prencado']?.toString() ?? '0') == '3')
                              Center(
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.local_drink,
                                        size: 16,
                                        color: Colors.orange[700],
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Selecione o Tipo: ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      SizedBox(
                                        width: 150, // Explicit width for ToggleButtons container
                                        child: Flexible( // Changed from Expanded
                                          child: ToggleButtons(
                                            // Ensure isSelected list is always valid with boolean values
                                            isSelected: [
                                            currentFresh, // currentFresh is already safely derived
                                            !currentFresh, // Ensure negation is safe
                                          ],
                                          onPressed: (index) {
                                            setState(() {
                                               // Find the index of the item in the main list based on the unique itemName
                                              int itemIndex = cartItems.indexWhere((element) => element['Nome'] == itemName);
                                              if (itemIndex != -1) {
                                                // Create a copy of the item
                                                Map<String, dynamic> updatedItem = Map<String, dynamic>.from(cartItems[itemIndex]);
                                                // Update the property on the copy
                                                updatedItem['Fresh'] = index == 0; // Assign boolean directly
                                                // Replace the item in the main list with the updated copy
                                                cartItems[itemIndex] = updatedItem;
                                              }
                                            });
                                          },
                                          borderRadius: BorderRadius.circular(6),
                                          selectedColor: Colors.white,
                                          fillColor: Colors.orange[700],
                                          borderColor: Colors.orange[700],
                                          color: Colors.grey[700],
                                          borderWidth: 1.0,
                                          selectedBorderColor: Colors.orange[700],
                                          children: [
                                            Expanded(
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 4),
                                                child: Text(
                                                  'Fresco',
                                                  style: TextStyle(fontSize: 12),
                                                  textAlign: TextAlign.center,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 4),
                                                child: Text(
                                                  'Natural',
                                                  style: TextStyle(fontSize: 12),
                                                  textAlign: TextAlign.center,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                   ) ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Rodapé com total e botão
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: Offset(0, -2),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Resumo de valores
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total a pagar:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${total.toStringAsFixed(2).replaceAll('.', ',')}€',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    
                    // Botão de confirmar pedido
                    SizedBox(
                      width: double.infinity,
                      child: LoadingButton(
                        onPressed: _isLoading ? null : () async {
                          if (cartItems.isEmpty) {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Carrinho Vazio'),
                                  content: Text(
                                      'Carrinho Vazio.\nPara continuar adicione produtos.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text('OK'),
                                    ),
                                  ],
                                );
                              },
                            );
                          } else {
                            setState(() => _isLoading = true);
                            try {
                              await checkAvailabilityBeforeOrder(total);
                            } finally {
                              setState(() => _isLoading = false);
                            }
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Confirmar Pedido',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_isLoading)
                              Padding(
                                padding: EdgeInsets.only(left: 10),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        backgroundColor: _isLoading ? Colors.grey : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
  }

  // Widget para estado vazio do carrinho
  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey[300],
          ),
          SizedBox(height: 24),
          Text(
            'O carrinho está vazio',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Adicione produtos para fazer o pedido',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeAlunoMain(),
                ),
              );
            },
            icon: Icon(Icons.add_shopping_cart, color: Colors.white),
            label: Text('Escolher Produtos', style: TextStyle(color: Colors.white),),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RecentBuysPage extends StatefulWidget {
  final List<Map<String, dynamic>> recentBuys;

  const RecentBuysPage({Key? key, required this.recentBuys}) : super(key: key);

  @override
  _RecentBuysPageState createState() => _RecentBuysPageState();
}

class _RecentBuysPageState extends State<RecentBuysPage> {
  bool _isLoading = false;
  final GlobalKey _cartIconKey = GlobalKey();
  List<dynamic> filteredRecentBuys = [];
  late StreamController<List<dynamic>> _recentBuysStreamController;
  final TextEditingController _recentBuysSearchController = TextEditingController();
  String? _selectedRecentBuysSortOption;
  double? _minRecentBuysPrice;
  double? _maxRecentBuysPrice;

  Future<int> checkQuantidade(String productName) async {
    try {
      String cleanProductName = productName.replaceAll('"', '').trim();
      
      var response = await http.get(Uri.parse(
          'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=8&nome=$cleanProductName'));

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        
        if (data is Map && data.containsKey('error')) {
          print('Error checking quantity: ${data['error']}');
          return 0;
        }
        
        if (data is List && data.isNotEmpty) {
          return data[0]['Qtd'] ?? 0;
        }
        
        return 0;
      } else {
        print('Error checking quantity: HTTP ${response.statusCode}');
        return 0;
      }
    } catch (e) {
      print('Exception checking quantity: $e');
      return 0;
    }
  }

  void addToCart(Map<String, dynamic> item) async {
    // Create a new map with the expected keys and format
    Map<String, dynamic> newItem = {
      'Imagem': item['Imagem'] ?? '', // Use empty string if null
      'Nome': item['Descricao'].replaceAll('"', '') ?? '', // Use Descricao and remove quotes
      'Preco': item['Preco']?.toString() ?? '0.0', // Ensure price is string, default to '0.0'
      'Prencado': item['Prencado']?.toString() ?? '0', // Ensure prencado is string, default to '0'
      'PrepararPrencado': false, // Initialize to false
      'Fresh': false, // Initialize to false
    };
    
    // Apply default preparation based on Prencado value
    if (newItem['Prencado'] == '1' || newItem['Prencado'] == '2') {
      newItem['PrepararPrencado'] = true;
    } else if (newItem['Prencado'] == '3') {
      newItem['Fresh'] = true;
    }

    // Check available quantity before adding
    final String productName = newItem['Nome']; // Get product name
    int availableQuantity = await checkQuantidade(productName); // Check available quantity
    int currentQuantity = cartItems.where((cartItem) => cartItem['Nome'] == productName).length; // Get current quantity in cart

    if (availableQuantity >= currentQuantity + 1) {
      setState(() {
        cartItems.add(newItem);
      });
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item adicionado'),
          duration: Duration(milliseconds: 500),
        ),
      );
    } else if (availableQuantity <= 0) {
       showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Produto Indisponível'),
            content: Text('Desculpe, este produto está indisponível no momento.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } else { // availableQuantity < desiredQuantity
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Quantidade Máxima'),
            content: Text('Quantidade máxima disponível atingida (Disponível: $availableQuantity)'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _recentBuysStreamController = StreamController<List<dynamic>>();
    filteredRecentBuys = widget.recentBuys;
    _recentBuysStreamController.add(filteredRecentBuys);
    _recentBuysSearchController.addListener(_filterRecentBuys);
  }

  @override
  void dispose() {
    _recentBuysStreamController.close();
    _recentBuysSearchController.dispose();
    super.dispose();
  }

  void _filterRecentBuys() {
    final query = removeDiacritics(_recentBuysSearchController.text.toLowerCase());
    setState(() {
      filteredRecentBuys = widget.recentBuys.where((product) {
        if (product['Descricao'] != null && product['Descricao'] is String) {
          final normalizedDescricao = removeDiacritics(product['Descricao'].toLowerCase());
          return normalizedDescricao.contains(query);
        }
        return false;
      }).toList();
      _recentBuysStreamController.add(filteredRecentBuys);
    });
  }

  void _sortRecentBuys() {
    setState(() {
      if (_selectedRecentBuysSortOption == 'asc') {
        filteredRecentBuys.sort((a, b) =>
            double.parse(a['Preco']).compareTo(double.parse(b['Preco'])));
      } else if (_selectedRecentBuysSortOption == 'desc') {
        filteredRecentBuys.sort((a, b) =>
            double.parse(b['Preco']).compareTo(double.parse(a['Preco'])));
      }
      _recentBuysStreamController.add(filteredRecentBuys);
    });
  }

  void _filterRecentBuysByPrice() {
     setState(() {
       filteredRecentBuys = widget.recentBuys.where((product) {
         double price = double.parse(product['Preco']);
         return (_minRecentBuysPrice == null || price >= _minRecentBuysPrice!) &&
                (_maxRecentBuysPrice == null || price <= _maxRecentBuysPrice!);
       }).toList();
       _recentBuysStreamController.add(filteredRecentBuys);
     });
  }

  void _showRecentBuysFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filtro'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: _selectedRecentBuysSortOption, // This can be null
                  hint: Text(
                      'Selecione uma opção'), // Hint text when no value is selected
                  items: [
                    DropdownMenuItem(value: 'asc', child: Row(children: [Icon(Icons.arrow_upward), SizedBox(width: 8), Text('Preço: Ascendente')])), // Changed Text
                    DropdownMenuItem(value: 'desc', child: Row(children: [Icon(Icons.arrow_downward), SizedBox(width: 8), Text('Preço: Descendente')])), // Changed Text
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedRecentBuysSortOption = newValue; // Update the selection
                        _sortRecentBuys(); // Call the sorting function
                        Navigator.pop(context); // Close the dialog
                      });
                    }
                  },
                ),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Preço Mínimo',
                  ),
                  keyboardType: TextInputType.number, // Ensure numeric keyboard
                  onChanged: (value) {
                    _minRecentBuysPrice = value.isNotEmpty ? double.tryParse(value) : null;
                    _filterRecentBuysByPrice();
                  },
                ),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Preço Máximo',
                  ),
                  keyboardType: TextInputType.number, // Ensure numeric keyboard
                  onChanged: (value) {
                    _maxRecentBuysPrice = value.isNotEmpty ? double.tryParse(value) : null;
                    _filterRecentBuysByPrice();
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comprados Recentemente'),
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                key: _cartIconKey,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShoppingCartPage(),
                    ),
                  ).then((_) {
                    setState(() {});
                  });
                },
                icon: Icon(Icons.shopping_cart),
              ),
              if (cartItems.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${cartItems.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _recentBuysSearchController,
                    decoration: InputDecoration(
                      labelText: 'Procurar...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _filterRecentBuys(); // Call filter on text change
                    },
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.filter_list),
                onPressed: _showRecentBuysFilterDialog,
              ),
            ],
          ),
          Expanded(
            child: StreamBuilder<List<dynamic>>(
              stream: _recentBuysStreamController.stream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  List<dynamic> items = snapshot.data!;
                  if (items.isEmpty) {
                    return Center(child: Text('Nenhum produto encontrado'));
                  }
                  return ListView.builder(
                    padding: EdgeInsets.all(16.0), // Adjusted padding
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      var product = items[index];
                      final String productName = product['Descricao'].replaceAll('"', '');
                      final int itemCount = cartItems.where((item) => item['Nome'] == productName).length;

                      return Card(
                        margin: EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                Colors.grey[50]!,
                              ],
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.memory(
                                      base64.decode(product['Imagem']),
                                      fit: BoxFit.cover,
                                      gaplessPlayback: true,
                                      cacheWidth: 160,
                                      cacheHeight: 160,
                                      filterQuality: FilterQuality.high,
                                      isAntiAlias: true,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        productName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[800],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        "${double.parse(product['Preco'].toString()).toStringAsFixed(2).replaceAll('.', ',')}€",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 8),
                                cartItems.any((cartItem) => cartItem['Nome'] == productName)
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            cartItems
                                                .where((element) =>
                                                    element['Nome'] == productName)
                                                .length
                                                .toString(),
                                            style: TextStyle(fontSize: 15.0),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              addToCart(product);
                                            },
                                            icon: Icon(Icons.add),
                                          ),
                                        ],
                                      )
                                    : LoadingButton(
                                        onPressed: _isLoading ? null : () async {
                                          setState(() => _isLoading = true);
                                          try {
                                            await Future.delayed(Duration(milliseconds: 300));
                                            int availableQuantity = await checkQuantidade(productName);
                                            if (availableQuantity > 0) {
                                              addToCart(product);
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Produto indisponível no momento'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          } finally {
                                            setState(() => _isLoading = false);
                                          }
                                        },
                                        child: _isLoading
                                          ? SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text('Comprar'),
                                        backgroundColor: _isLoading ? Colors.grey : Colors.orange,
                                      ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }
                return Center(
                  child: CircularProgressIndicator(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}



