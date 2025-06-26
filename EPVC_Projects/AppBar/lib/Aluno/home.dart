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
import 'package:flutter/services.dart';

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

// Make this a top-level function so it can be used in any widget
Future<bool> checkEstablishmentOpen() async {
  try {
    final response = await http.get(
      Uri.parse('https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=37'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      int open = 0;
      if (data is List &&
          data.isNotEmpty &&
          (data[0]['open'] != null || data[0]['Open'] != null)) {
        open =
            int.tryParse((data[0]['open'] ?? data[0]['Open']).toString()) ?? 0;
      } else if (data is Map &&
          (data['open'] != null || data['Open'] != null)) {
        open = int.tryParse((data['open'] ?? data['Open']).toString()) ?? 0;
      }
      return open == 1;
    }
  } catch (e) {}
  return false;
}

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
          systemOverlayStyle: SystemUiOverlayStyle.light, // Adiciona esta linha
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

  bool? isDayOpen; // null = loading, false = closed, true = open

  @override
  void initState() {
    super.initState();
    _checkDayStatus();
    UserInfo();
    _getAllProducts();
  }

  Future<void> _checkDayStatus() async {
    setState(() {
      isDayOpen = null;
      _isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse(
            'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=37'),
      );
      print(response.body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        int open = 0;
        if (data is List && data.isNotEmpty && data[0]['open'] != null) {
          open = int.tryParse(data[0]['open'].toString()) ?? 0;
        } else if (data is Map && data['open'] != null) {
          open = int.tryParse(data['open'].toString()) ?? 0;
        }
        setState(() {
          isDayOpen = open == 1;
          _isLoading = false;
        });
        if (open != 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'O dia ainda está fechado. Tente novamente mais tarde.')),
          );
        }
      } else {
        setState(() {
          isDayOpen = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao verificar o estado do dia.')),
        );
      }
    } catch (e) {
      setState(() {
        isDayOpen = false;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão. Tente novamente.')),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This will refresh the cart count when returning to this page
    // Removed direct setState to prevent unnecessary rebuilds and flickering.
    // The cart count is updated via Navigator.push().then((_){ setState((){}); });
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
              recentBuysMapped = recentBuys.map((product) {
                // Garante que idApp está sempre presente, mesmo que venha como Id ou idapp
                if (product['idApp'] == null || product['idApp'].toString().isEmpty) {
                  if (product['Id'] != null && product['Id'].toString().isNotEmpty) {
                    product['idApp'] = product['Id'].toString();
                  } else if (product['idapp'] != null && product['idapp'].toString().isNotEmpty) {
                    product['idApp'] = product['idapp'].toString();
                  }
                }
                return product as Map<String, dynamic>;
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
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: Text(''),
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              );
            },
          ),
          actions: [
            if (isDayOpen == true)
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
                      );
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
            if (isDayOpen == false)
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: _checkDayStatus,
                tooltip: 'Recarregar',
              ),
          ],
        ),
        drawer: DrawerHome(),
        body: isDayOpen == null
            ? Center(child: CircularProgressIndicator())
            : isDayOpen == false
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, size: 60, color: Colors.orange),
                        SizedBox(height: 24),
                        Text(
                          'As compras estão temporariamente indisponíveis. Por favor, tente mais tarde.',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: _isLoading
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Icon(Icons.refresh),
                          label: Text('Recarregar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                          ),
                          onPressed: _isLoading ? null : _checkDayStatus,
                        ),
                      ],
                    ),
                  )
                : WillPopScope(
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
                              margin: EdgeInsets.only(
                                  left: 16.0,
                                  right: 16.0,
                                  bottom: 8.0,
                                  top: 16.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                          builder: (context) => RecentBuysPage(
                                              recentBuys: recentBuysMapped),
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
                                  final RenderBox? cartIconBox = _cartIconKey
                                      .currentContext
                                      ?.findRenderObject() as RenderBox?;
                                  final Offset cartPosition =
                                      cartIconBox?.localToGlobal(Offset.zero) ??
                                          Offset.zero;

                                  return AddToCartAnimation(
                                    key: ValueKey(product['Descricao']),
                                    cartPosition: cartPosition,
                                    onTap: () async {
                                      if (_isLoading) return;

                                      setState(() {
                                        _isLoading = true;
                                      });

                                      try {
                                        final String productName =
                                            product['Descricao']
                                                .replaceAll('"', '');
                                        int availableQuantity =
                                            await checkQuantidade(productName);
                                        int currentQuantity = cartItems
                                            .where((item) =>
                                                item['Nome'] == productName)
                                            .length;

                                        if (availableQuantity <= 0) {
                                          if (mounted) {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: Text(
                                                      'Produto Indisponível'),
                                                  content: Text(
                                                      'Desculpe, este produto está indisponível no momento.'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      style:
                                                          TextButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.orange,
                                                        foregroundColor:
                                                            Colors.white,
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                horizontal: 16,
                                                                vertical: 8),
                                                      ),
                                                      child: Text('OK'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          }
                                        } else if (currentQuantity >=
                                            availableQuantity) {
                                          if (mounted) {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title:
                                                      Text('Quantidade Máxima'),
                                                  content: Text(
                                                      'Quantidade máxima disponível atingida (Disponível: $availableQuantity)'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      style:
                                                          TextButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.orange,
                                                        foregroundColor:
                                                            Colors.white,
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
                                            product['Prencado']?.toString() ?? '',
                                            product['idApp']?.toString() ?? product['Id']?.toString() ?? '',
                                            product['idApp']?.toString() ?? product['Id']?.toString() ?? '',
                                            ''
                                          ); // Adiciona o idApp e XDReference
                                          if (mounted) {
                                           /* ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content:
                                                    Text('Item adicionado'),
                                                duration:
                                                    Duration(milliseconds: 500),
                                              ),
                                            );*/
                                          }
                                        }
                                      } catch (e) {
                                        print(
                                            'Erro ao verificar quantidade disponível ou adicionar ao carrinho: $e');
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Ocorreu um erro ao adicionar o item ao carrinho.'),
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
                                      margin:
                                          EdgeInsets.symmetric(horizontal: 4.0),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.05),
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            height: 80,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                      top: Radius.circular(12)),
                                              image: DecorationImage(
                                                image: MemoryImage(base64
                                                    .decode(product['Imagem'])),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  product['Descricao']
                                                      .replaceAll('"', ''),
                                                  style: TextStyle(
                                                    fontSize: 12.0,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF333333),
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
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
                                    backgroundImagePath:
                                        'lib/assets/bebida.png',
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
                                    title: 'Cafetaria',
                                    backgroundImagePath: 'lib/assets/cafe.JPG',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CategoryPage(
                                            title: 'Cafetaria',
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
                                    backgroundImagePath:
                                        'lib/assets/comida.jpg',
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
                                    backgroundImagePath:
                                        'lib/assets/snacks.jpg',
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
                                /*case 5:
                                  return buildCategoryCard(
                                    title: 'Restaurante',
                                    backgroundImagePath: 'lib/assets/monteRestaurante.jpg',
                                    isAvailable: false,
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text('Em Desenvolvimento'),
                                          content: Text(
                                              'O Restaurante não está disponível no momento.'),
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
                                  );*/
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
          addToCart(imagePath, title, price, prencado, '0', '', ''); // Adiciona idApp e XDReference vazios
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
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1.0,
              blurRadius: 3.0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagem em cima
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                height: 80.0,
                child: Image.memory(
                  base64.decode(imagePath),
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  cacheWidth: 100,
                  cacheHeight: 100,
                ),
              ),
            ),
            // Caixa de texto abaixo da imagem
            Container(
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.replaceAll('"', ''),
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    "${double.parse(price).toStringAsFixed(2).replaceAll('.', ',')}€",
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
  }

  void addToCart(String imagePath, String title, String price, String prencado,
      String id, String idApp, String xdReference) async {
    try {
      // Check available quantity first
      int availableQuantity = await checkQuantidade(title.replaceAll('"', ''));
      int currentQuantity = cartItems
          .where((item) => item['Nome'] == title.replaceAll('"', ''))
          .length;

      if (currentQuantity < availableQuantity) {
        setState(() {
          cartItems.add({
            'Imagem': imagePath,
            'Nome': title.replaceAll('"', ''),
            'Preco': price,
            'Prencado': prencado,
            'PrepararPrencado': false,
            'Fresh': false,
            'Id': idApp, // Adiciona o ID do produto
            'idApp': (idApp != null && idApp.toString().trim().isNotEmpty) ? idApp : id, // Garante prioridade ao idApp, senão usa Id
            'XDReference': xdReference, // Adiciona o XDReference
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagem da categoria em cima
            if (isAvailable && showImage)
              Expanded(
                flex: 2, // A imagem ocupa 2/3 da altura
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.asset(
                    backgroundImagePath,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
            // Caixa de texto branca abaixo da imagem
            Expanded(
              flex: 1, // O texto ocupa 1/3 da altura
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getCategoryIcon(title),
                      size: 18, // Tamanho do ícone
                      color: Colors.orange, // Cor do ícone
                    ),
                    SizedBox(width: 8), // Espaçamento entre o ícone e o texto
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        fontFamily: 'Roboto',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            if (!isAvailable)
              Positioned.fill(
                child: Container(
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
      case 'cafetaria':
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

  Future<bool> _checkEstablishmentOpen() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=37'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        int open = 0;
        if (data is List &&
            data.isNotEmpty &&
            (data[0]['open'] != null || data[0]['Open'] != null)) {
          open =
              int.tryParse((data[0]['open'] ?? data[0]['Open']).toString()) ??
                  0;
        } else if (data is Map &&
            (data['open'] != null || data['Open'] != null)) {
          open = int.tryParse((data['open'] ?? data['Open']).toString()) ?? 0;
        }
        return open == 1;
      }
    } catch (e) {}
    return false;
  }
}

class CategoryPage extends StatefulWidget {
  final String title;

  const CategoryPage({Key? key, required this.title}) : super(key: key);

  @override
  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  bool _isLoading = false;
  final GlobalKey _cartIconKey = GlobalKey();
  List<dynamic> filteredCategoryItems = [];
  late StreamController<List<dynamic>> _categoryStreamController;
  final TextEditingController _categorySearchController =
      TextEditingController();
  String? _selectedCategorySortOption;
  double? _minCategoryPrice;
  double? _maxCategoryPrice;
  Map<String, bool> _itemLoadingStatus = {};
  Map<String, int> _availableQuantities = {};

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
          return int.tryParse(data[0]['Qtd'].toString()) ?? 0;
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

  Future<int> getAvailableQuantity(String productName) async {
    if (_availableQuantities.containsKey(productName)) {
      return _availableQuantities[productName]!;
    }
    int qtd = await checkQuantidade(productName);
    _availableQuantities[productName] = qtd;
    return qtd;
  }

  void addToCart(Map<String, dynamic> item) async {
    print("[DEBUG] Adicionando ao carrinho: Nome: '${item['Nome']}', idApp: '${item['idApp']}', Id: '${item['Id']}'");
    // Create a new map with the expected keys and format
    Map<String, dynamic> newItem = {
      'Imagem': item['Imagem'] ?? '', // Use empty string if null
      'Nome': (item['Nome'] ?? item['Descricao'] ?? '').replaceAll('"', ''), // Corrigido para evitar null
      'Preco': item['Preco']?.toString() ?? '0.0',
      'Prencado': item['Prencado']?.toString() ?? '0',
      'PrepararPrencado': false, // Initialize to false
      'Fresh': false, // Initialize to false
      'Id': item['Id'], // Adiciona o ID do produto
      'idApp': (item['idApp'] ?? item['IdApp'] ?? item['idapp']) != null && (item['idApp'] ?? item['IdApp'] ?? item['idapp']).toString().trim().isNotEmpty
        ? (item['idApp'] ?? item['IdApp'] ?? item['idapp'])
        : item['Id'], // Garante prioridade ao idApp, senão usa Id
      'XDReference': item['XDReference'] ?? '', // Adiciona o XDReference
    };
    if (newItem['Prencado'] == '1' || newItem['Prencado'] == '2') {
      newItem['PrepararPrencado'] = true;
    } else if (newItem['Prencado'] == '3') {
      newItem['Fresh'] = true;
    }
    final String productName = newItem['Nome'];
    int availableQuantity = await getAvailableQuantity(productName);
    int currentQuantity =
        cartItems.where((cartItem) => cartItem['Nome'] == productName).length;
    if (availableQuantity >= currentQuantity + 1) {
      setState(() {
        cartItems.add(newItem);
        // Remover a linha abaixo para NÃO subtrair do stock apresentado
        // _availableQuantities[productName] = availableQuantity - 1;
      });
      /*ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item adicionado'),
          duration: Duration(milliseconds: 500),
        ),
      );*/
    } else if (availableQuantity <= 0) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Produto Indisponível'),
            content:
                Text('Desculpe, este produto está indisponível no momento.'),
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
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Quantidade Máxima'),
            content: Text(
                'Quantidade máxima disponível atingida (Disponível: $availableQuantity)'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
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
    }
  }

  @override
  void initState() {
    super.initState();
    _categoryStreamController = StreamController<List<dynamic>>();
    filteredCategoryItems =
        allProducts.where((item) => item['Categoria'] == widget.title).toList();
    _categoryStreamController.add(filteredCategoryItems);
    _categorySearchController.addListener(_filterCategoryItems);
  }

  @override
  void dispose() {
    _categoryStreamController.close();
    _categorySearchController.dispose();
    super.dispose();
  }

  void _filterCategoryItems() {
    final query =
        removeDiacritics(_categorySearchController.text.toLowerCase());
    setState(() {
      filteredCategoryItems = allProducts.where((item) {
        if (item['Categoria'] == widget.title &&
            item['Nome'] != null &&
            item['Nome'] is String) {
          final normalizedNome = removeDiacritics(item['Nome'].toLowerCase());
          return normalizedNome.contains(query);
        }
        return false;
      }).toList();
      _categoryStreamController.add(filteredCategoryItems);
    });
  }

  void _sortCategoryItems() {
    setState(() {
      if (_selectedCategorySortOption == 'asc') {
        filteredCategoryItems.sort((a, b) =>
            double.parse(a['Preco']).compareTo(double.parse(b['Preco'])));
      } else if (_selectedCategorySortOption == 'desc') {
        filteredCategoryItems.sort((a, b) =>
            double.parse(b['Preco']).compareTo(double.parse(a['Preco'])));
      }
      _categoryStreamController.add(filteredCategoryItems);
    });
  }

  void _filterCategoryByPrice() {
    setState(() {
      filteredCategoryItems = allProducts.where((item) {
        if (item['Categoria'] == widget.title) {
          double price = double.parse(item['Preco']);
          return (_minCategoryPrice == null || price >= _minCategoryPrice!) &&
              (_maxCategoryPrice == null || price <= _maxCategoryPrice!);
        }
        return false;
      }).toList();
      _categoryStreamController.add(filteredCategoryItems);
    });
  }

  void _showCategoryFilterDialog() {
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
                  value: _selectedCategorySortOption,
                  hint: Text('Selecione uma opção'),
                  items: [
                    DropdownMenuItem(
                        value: 'asc',
                        child: Row(children: [
                          Icon(Icons.arrow_upward, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Preço: Ascendente',
                              style: TextStyle(color: Colors.orange))
                        ])),
                    DropdownMenuItem(
                        value: 'desc',
                        child: Row(children: [
                          Icon(Icons.arrow_downward, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Preço: Descendente',
                              style: TextStyle(color: Colors.orange))
                        ])),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCategorySortOption = newValue;
                        _sortCategoryItems();
                        Navigator.pop(context);
                      });
                    }
                  },
                ),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Preço Mínimo',
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.orange),
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Colors.orange), // Set default border to orange
                    ),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*[,|\.]?\d*')),
                  ],
                  onChanged: (value) {
                    String normalized = value.replaceAll(',', '.');
                    _minCategoryPrice = normalized.isNotEmpty
                        ? double.tryParse(normalized)
                        : null;
                    _filterCategoryByPrice();
                  },
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Preço Máximo',
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.orange),
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Colors.orange), // Set default border to orange
                    ),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*[,|\.]?\d*')),
                  ],
                  onChanged: (value) {
                    String normalized = value.replaceAll(',', '.');
                    _maxCategoryPrice = normalized.isNotEmpty
                        ? double.tryParse(normalized)
                        : null;
                    _filterCategoryByPrice();
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
              style: TextButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
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
        title: Text(widget.title),
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
                  );
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
                    controller: _categorySearchController,
                    decoration: InputDecoration(
                      labelText: 'Procurar...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _filterCategoryItems();
                    },
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.filter_list, color: Colors.orange),
                onPressed: _showCategoryFilterDialog,
              ),
            ],
          ),
          Expanded(
            child: StreamBuilder<List<dynamic>>(
              stream: _categoryStreamController.stream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  List<dynamic> items = snapshot.data!;
                  if (items.isEmpty) {
                    return Center(child: Text('Nenhum produto encontrado'));
                  }
                  return ListView.builder(
                    padding: EdgeInsets.all(16.0),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      var product = items[index];
                      final String productName =
                          product['Nome'].replaceAll('"', '');
                      final int itemCount = cartItems
                          .where((item) => item['Nome'] == productName)
                          .length;

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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      FutureBuilder<int>(
                                        future: getAvailableQuantity(productName),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            if (_availableQuantities.containsKey(productName)) {
                                              // Show cached value while loading
                                              final qtd = _availableQuantities[productName]!;
                                              return Text('Disponível: $qtd', style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold));
                                            }
                                            return Text('A verificar...', style: TextStyle(fontSize: 12, color: Colors.grey));
                                          }
                                          final qtd = snapshot.data ?? 0;
                                          return Text('Disponível: $qtd', style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold));
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 8),
                                cartItems.any((cartItem) =>
                                        cartItem['Nome'] == productName)
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            cartItems
                                                .where((element) =>
                                                    element['Nome'] ==
                                                    productName)
                                                .length
                                                .toString(),
                                            style: TextStyle(fontSize: 15.0),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              addToCart(product);
                                            },
                                            icon: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.orange,
                                                shape: BoxShape.circle,
                                              ),
                                              padding: EdgeInsets.all(4),
                                              child: Icon(Icons.add, color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      )
                                    : StatefulBuilder(
                                        builder: (context, setState) {
                                          return FutureBuilder<int>(
                                            future:
                                                checkQuantidade(productName),
                                            builder: (context, snapshot) {
                                              bool isAvailable =
                                                  snapshot.hasData &&
                                                      snapshot.data! > 0;
                                              return LoadingButton(
                                                onPressed: _itemLoadingStatus[
                                                                productName] ==
                                                            true ||
                                                        !isAvailable
                                                    ? null
                                                    : () async {
                                                        setState(() {
                                                          _itemLoadingStatus[
                                                                  productName] =
                                                              true;
                                                        });
                                                        try {
                                                          await Future.delayed(
                                                              Duration(
                                                                  milliseconds:
                                                                      300));
                                                          int availableQuantity =
                                                              await checkQuantidade(
                                                                  productName);
                                                          if (availableQuantity >
                                                              0) {
                                                            addToCart(product);
                                                          } else {
                                                            showDialog(
                                                              context: context,
                                                              builder:
                                                                  (BuildContext
                                                                      context) {
                                                                return AlertDialog(
                                                                  title: Text(
                                                                      'Produto Indisponível'),
                                                                  content: Text(
                                                                      'Desculpe, este produto está indisponível no momento.'),
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed:
                                                                          () {
                                                                        Navigator.of(context)
                                                                            .pop();
                                                                      },
                                                                      style: TextButton
                                                                          .styleFrom(
                                                                        backgroundColor:
                                                                            Colors.orange,
                                                                        foregroundColor:
                                                                            Colors.white,
                                                                      ),
                                                                      child: Text(
                                                                          'OK'),
                                                                    ),
                                                                  ],
                                                                );
                                                              },
                                                            );
                                                          }
                                                        } finally {
                                                          setState(() {
                                                            _itemLoadingStatus[
                                                                    productName] =
                                                                false;
                                                          });
                                                        }
                                                      },
                                                isLoading: _itemLoadingStatus[
                                                        productName] ==
                                                    true,
                                                child: _itemLoadingStatus[
                                                            productName] ==
                                                        true
                                                    ? SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child:
                                                            CircularProgressIndicator(
                                                          valueColor:
                                                              AlwaysStoppedAnimation<
                                                                      Color>(
                                                                  Colors.white),
                                                          strokeWidth: 2,
                                                        ),
                                                      )
                                                    : Text('Comprar'),
                                                backgroundColor: isAvailable
                                                    ? Colors.orange
                                                    : Colors.grey,
                                              );
                                            },
                                          );
                                        },
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

  Future<void> _refreshCart() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Update the item count map
      updateItemCountMap();

      // Refresh user info
      UserInfo();

      // Check availability of all items in cart
      for (var item in cartItems) {
        String productName = item['Nome'];
        int availableQuantity = await checkQuantidade(productName);
        int currentQuantity = cartItems
            .where((cartItem) => cartItem['Nome'] == productName)
            .length;

        // If current quantity exceeds available quantity, remove excess items
        if (currentQuantity > availableQuantity) {
          int excess = currentQuantity - availableQuantity;
          for (int i = 0; i < excess; i++) {
            int index = cartItems
                .indexWhere((cartItem) => cartItem['Nome'] == productName);
            if (index != -1) {
              cartItems.removeAt(index);
            }
          }
        }
      }

      // Update the UI
      setState(() {
        updateItemCountMap();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Carrinho atualizado'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar carrinho'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
                    leading:
                        const Icon(Icons.check_circle, color: Colors.green),
                    title: const Text('Confirmar',
                        style: TextStyle(color: Colors.green)),
                    onTap: () => Navigator.pop(context, true),
                  ),
                  ListTile(
                    leading: const Icon(Icons.cancel, color: Colors.red),
                    title: const Text('Cancelar',
                        style: TextStyle(color: Colors.red)),
                    onTap: () => Navigator.pop(context, false),
                  ),
                ],
              ),
            );
          },
        ) ??
        false;
  }

  Future<String?> _showUnavaiable() async{
return showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Método de Pagamento Indisponivel'),
          content: Text(
              'O método de pagamento encontra-se indisponível de momento, iremos tentar ser os mais breves possiveis.'),
          actions: [
            TextButton(
              onPressed: () { Navigator.of(context).pop(); /*Navigator.of(context).pop();*/},
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
              leading: Icon(Icons.phone_android,
                  color: /*Color.fromARGB(255, 177, 2, 2)*/Colors.grey),
              title: Text('MBWay',
                  style: TextStyle(color: /*Color.fromARGB(255, 177, 2, 2)*/Colors.grey)),
              onTap: () {
                _setLoading(true, message: 'Processando MBWay...');
                //Navigator.pop(context, 'mbway');
                _showUnavaiable();
              },
            ),
            // Dinheiro Option
            ListTile(
              leading:
                  Icon(Icons.money, color: Color.fromARGB(255, 27, 94, 32)),
              title: Text('Dinheiro',
                  style: TextStyle(color: Color.fromARGB(255, 27, 94, 32))),
              onTap: () async {
                bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Confirmar Pagamento'),
                    content: Text('Tem a certeza que deseja comprar com dinheiro?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('Cancelar', style: TextStyle(color: Colors.black),),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Confirmar'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  _setLoading(true, message: 'Processando pagamento em dinheiro...');
                  Navigator.pop(context, 'dinheiro');
                }
              },
            ),
            // Saldo Option (only shown if authorized)
            if (users != null &&
                users.isNotEmpty &&
                users[0]['AutorizadoSaldo'] == '1')
              ListTile(
                leading: Icon(Icons.account_balance_wallet,
                    color: /*Colors.orange[700]*/Colors.grey),
                title:
                    Text('Saldo', style: TextStyle(color: /*Colors.orange[700]*/Colors.grey)),
                onTap: () {
                  _setLoading(true,
                      message: 'Processando pagamento com saldo...');
                  //Navigator.pop(context, 'saldo');
                  _showUnavaiable();
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

  Future<bool> _showPrencadoConfirmationDialog(
      List<Map<String, dynamic>> prencadoProducts) async {
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
                            leading:
                                Icon(Icons.restaurant, color: Colors.orange),
                            title: Text(product['Nome']),
                            subtitle: Text('Deseja Prensado?'),
                            trailing: Checkbox(
                              value: selectedProducts[product['Nome']],
                              onChanged: (bool? value) {
                                setState(() {
                                  selectedProducts[product['Nome']] =
                                      value ?? false;
                                  product['PrepararPrencado'] = value ?? false;
                                });
                              },
                            ),
                          );
                        } else if (prencado == '2') {
                          return ListTile(
                            leading:
                                Icon(Icons.severe_cold, color: Colors.green),
                            title: Text(product['Nome']),
                            subtitle: Text('Deseja Fresco?'),
                            trailing: Checkbox(
                              value: selectedProducts[product['Nome']],
                              onChanged: (bool? value) {
                                setState(() {
                                  selectedProducts[product['Nome']] =
                                      value ?? false;
                                  product['PrepararPrencado'] = value ?? false;
                                  freshOptionForAquecido[product['Nome']] =
                                      value ?? false;
                                });
                              },
                            ),
                          );
                        } else if (prencado == '3') {
                          return ListTile(
                            leading:
                                Icon(Icons.local_cafe, color: Colors.orange),
                            title: Text(product['Nome']),
                            subtitle: Text('Deseja Fresco?'),
                            trailing: Checkbox(
                              value: selectedProducts[product['Nome']],
                              onChanged: (bool? value) {
                                setState(() {
                                  selectedProducts[product['Nome']] =
                                      value ?? false;
                                  product['PrepararPrencado'] = value ?? false;
                                  freshOptionForAquecido[product['Nome']] =
                                      value ?? false;
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
                        child: Text('Cancelar',
                            style: TextStyle(color: Colors.red)),
                      ),
                      LoadingButton(
                        onPressed: () async {
                          _setLoading(true,
                              message: 'Confirmando preparação...');
                          for (var product in prencadoProducts) {
                            int index = cartItems.indexWhere(
                                (item) => item['Nome'] == product['Nome']);
                            if (index != -1) {
                              cartItems[index]['PrepararPrencado'] =
                                  selectedProducts[product['Nome']];
                              cartItems[index]['Fresh'] =
                                  freshOptionForAquecido[product['Nome']];
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
        ) ??
        false;
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
                  title:
                      const Text('Sim', style: TextStyle(color: Colors.green)),
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
        ) ??
        false;
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
                    double? amount = double.tryParse(
                        moneyController.text.replaceAll(',', '.'));
                    if (amount != null && amount >= total) {
                      Navigator.pop(context, amount);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Valor inválido ou menor que o total')),
                      );
                    }
                  },
                  child:
                      Text('Confirmar', style: TextStyle(color: Colors.green)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> sendOrderToApi() async {
    // Check if establishment is open before proceeding
    bool open = await checkEstablishmentOpen();
    if (!open) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Estabelecimento Fechado'),
          content: Text(
              'O estabelecimento está fechado. Não é possível realizar compras neste momento.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
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
      bool confirmPrencado =
          await _showPrencadoConfirmationDialog(prencadoProducts);
      if (!confirmPrencado) return;
    }

    try {
      // Mostrar diálogo de seleção de método de pagamento
      String? paymentMethod = await _showPaymentMethodDialog();
      if (paymentMethod == null) return;

      // Check if invoice is needed
      bool requestInvoice = false;
      String nif = '';
      if (paymentMethod == 'mbway' || paymentMethod == 'dinheiro') {
        requestInvoice = await _showInvoiceDialog();
        if (requestInvoice) {
          nif = await _showNifInputDialog() ?? '';
          if (nif.isEmpty) {
            return;
          }
        }
      }

      // Extract user information
      var turma = users[0]['Turma'] ?? '';
      var nome = users[0]['Nome'] ?? '';
      var apelido = users[0]['Apelido'] ?? '';
      var permissao = users[0]['Permissao'] ?? '';
      var imagem = users[0]['Imagem'] ?? '';

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
              onResult: (success, newOrderNumber) async {
                if (success) {
                  // Update product quantities after successful purchase
                  // Create lists for IDs and quantities
                  List<String> productIds = [];
                  List<int> quantities = [];

                  // Use the existing itemCountMap which already has the correct quantities
                  for (var entry in itemCountMap.entries) {
                    String productName = entry.key;
                    int quantity = entry.value;

                    // Find the corresponding product ID from cartItems
                    var product = cartItems.firstWhere(
                      (item) => item['Nome'] == productName,
                      orElse: () => {'Id': '0'},
                    );

                    String id = (product['idApp'] != null && product['idApp'].toString().trim().isNotEmpty && product['idApp'].toString() != '0')
                        ? product['idApp'].toString()
                        : (product['Id'] != null && product['Id'].toString().trim().isNotEmpty && product['Id'].toString() != '0')
                            ? product['Id'].toString()
                            : '0';
                    if (id != '0') {
                      productIds.add(id);
                      quantities.add(quantity);
                    }
                  }

                  // Send all quantities in a single API call
                  String idsParam = productIds.join(',');
                  String quantitiesParam = quantities.join(',');

                  print(
                      'Atualizando quantidades dos produtos: IDs $idsParam para quantidades $quantitiesParam');
                  var response = await http.get(
                    Uri.parse(
                        'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=18&op=2&ids=$idsParam&quantities=$quantitiesParam'),
                  );
                  print(
                      'Resposta da API após atualizar quantidades: \\${response.body}');

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
        await _handleCashPayment(total,
            requestInvoice: requestInvoice, nif: nif);
      } else if (paymentMethod == 'saldo') {
        await _handleSaldoPayment(total,
            requestInvoice: requestInvoice, nif: nif);
      }
    } catch (e) {
      print('Erro ao enviar pedido: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao processar pedido: ${e.toString()}')),
      );
    }
  }

  Future<void> sendOrderToWebSocket(
      List<Map<String, dynamic>> cartItems, String total,
      {String? paymentMethod,
      bool requestInvoice = false,
      String nif = '',
      double? dinheiroAtual}) async {
    try {
      // Format item names with preparation preferences
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

      var turma = users[0]['Turma'];
      var nome = users[0]['Nome'];
      var permissao = users[0]['Permissao'];
      var imagem = users[0]['Imagem'];

      // Calcular o troco usando o dinheiroAtual passado como parâmetro
      double troco =
          (dinheiroAtual ?? double.parse(total)) - double.parse(total);
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
        'DinheiroAtual': dinheiroAtual?.toString() ?? total,
      };

      // Add invoice information if requested
      if (requestInvoice) {
        orderData['RequestInvoice'] = '1';
        orderData['NIF'] = nif;
      }

      // Send the order and close the connection immediately
      channel.sink.add(json.encode(orderData));
      channel.sink.close();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pedido enviado com sucesso! Pedido Nº $orderNumber'),
          ),
        );
      }
    } catch (e) {
      print('Erro ao estabelecer conexão WebSocket: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Erro ao enviar o pedido. Contacte o Administrador! Error 01'),
          ),
        );
      }
    }
  }

  Future<void> _handleCashPayment(double total,
      {bool requestInvoice = false, String nif = ''}) async {
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

            // Atualizar quantidade dos produtos na base de dados após compra em dinheiro
            List<String> productIds = [];
            List<int> quantities = [];
            for (var entry in itemCountMap.entries) {
              String productName = entry.key;
              int quantity = entry.value;
              var product = cartItems.firstWhere(
                (item) => item['Nome'] == productName,
                orElse: () => {'Id': '0'},
              );
              String id = (product['idApp'] != null && product['idApp'].toString().trim().isNotEmpty && product['idApp'].toString() != '0')
                  ? product['idApp'].toString()
                  : (product['Id'] != null && product['Id'].toString().trim().isNotEmpty && product['Id'].toString() != '0')
                      ? product['Id'].toString()
                      : '0';
              if (id != '0') {
                productIds.add(id);
                quantities.add(quantity);
              }
            }
            String idsParam = productIds.join(',');
            String quantitiesParam = quantities.join(',');
            print(
                'Atualizando quantidades dos produtos: IDs $idsParam para quantidades $quantitiesParam');
            var response = await http.get(
              Uri.parse(
                  'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=18&op=2&ids=$idsParam&quantities=$quantitiesParam'),
            );
            print(
                'Resposta da API após atualizar quantidades: \\${response.body}');

            // Enviar para o WebSocket com o valor do total
            await sendOrderToWebSocket(cartItems, total.toString(),
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
                  content: Text(
                      'Pedido enviado com sucesso! Pedido Nº $orderNumber')),
            );

            // Navegar para a página de confirmação de pedido
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => CashConfirmationPage(
                  change: 0.0, // No change needed
                  orderNumber: orderNumber,
                  amount: total,
                  paymentMethod: 'dinheiro',
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
          SnackBar(
              content: Text('Erro ao processar pagamento: ${e.toString()}')),
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
      itemCountMap[itemName] =
          cartItems.where((item) => item['Nome'] == itemName).length;
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
        var idApp = order['Id'] ?? ''; // Extrair o idApp
        var xdReference = order['XDReference'] ?? ''; // Extrair o XDReference

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
            'idApp': idApp, // Adicionar o idApp à requisição
            'idXDApp': xdReference, // Adicionar o XDReference à requisição
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
    // Check if establishment is open before proceeding
    bool open = await checkEstablishmentOpen();
    if (!open) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Estabelecimento Fechado'),
          content: Text(
              'O estabelecimento está fechado. Não é possível realizar compras neste momento.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    bool allAvailable = true;
    List<String> unavailableItems = <String>[]; // Explicitly specify the type

    for (var entry in itemCountMap.entries) {
      final itemName = entry.key;
      final cartQuantity = entry.value;

      var quantity = await checkQuantidade(itemName);

      if (quantity == 0) {
        allAvailable = false;
        unavailableItems.add('$itemName (Indisponível)');
      } else if (cartQuantity > quantity) {
        allAvailable = false;
        unavailableItems.add(
            '$itemName (Disponível: $quantity)'); // Include available quantity in message
      }
    }

    if (cartItems.isNotEmpty) {
      if (allAvailable) {
        // Check if user is a professor before proceeding to payment
        String userPermission = users != null && users.isNotEmpty
            ? users[0]['Permissao'] ?? ''
            : '';
        String nif = '';
        bool requestInvoice = false;

        // If the user is a professor, ask if they want an invoice with NIF
        if (userPermission == 'Professor') {
          requestInvoice = await _showInvoiceRequestDialog();

          if (requestInvoice) {
            // Verifica se tem faturação automática ativa
            bool autoBillNIF = users[0]['FaturacaoAutomatica'] == '1' ||
                users[0]['FaturacaoAutomatica'] == 1;

            if (autoBillNIF &&
                users[0]['NIF'] != null &&
                users[0]['NIF'].toString().isNotEmpty) {
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
          await _handleMBWayPayment(total,
              requestInvoice: requestInvoice, nif: nif);
        } else if (paymentMethod == 'dinheiro') {
          await _handleCashPayment(total,
              requestInvoice: requestInvoice, nif: nif);
        } else if (paymentMethod == 'saldo') {
          await _handleSaldoPayment(total,
              requestInvoice: requestInvoice, nif: nif);
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
      }
    }
  }

  Future<bool> _showInvoiceRequestDialog() async {
    // Verifica se o usuário tem faturação automática ativa e NIF cadastrado
    bool autoBillNIF = users[0]['FaturacaoAutomatica'] == '1' ||
        users[0]['FaturacaoAutomatica'] == 1;
    bool hasNIF =
        users[0]['NIF'] != null && users[0]['NIF'].toString().isNotEmpty;

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
                    leading:
                        const Icon(Icons.check_circle, color: Colors.green),
                    title: const Text('Sim',
                        style: TextStyle(color: Colors.green)),
                    onTap: () => Navigator.pop(context, true),
                  ),
                  ListTile(
                    leading: const Icon(Icons.cancel, color: Colors.red),
                    title:
                        const Text('Não', style: TextStyle(color: Colors.red)),
                    onTap: () => Navigator.pop(context, false),
                  ),
                ],
              ),
            );
          },
        ) ??
        false;
  }

  Future<String?> _showNifInputDialog() async {
    final nifController = TextEditingController();

    // Verifica se o usuário tem faturação automática ativa
    bool autoBillNIF = users[0]['FaturacaoAutomatica'] == '1' ||
        users[0]['FaturacaoAutomatica'] == 1;

    // Se tiver faturação automática, retorna o NIF diretamente
    if (autoBillNIF &&
        users[0]['NIF'] != null &&
        users[0]['NIF'].toString().isNotEmpty) {
      return users[0]['NIF'].toString();
    }

    // Se não tiver faturação automática, verifica se já tem NIF cadastrado
    if (users[0]['NIF'] != null && users[0]['NIF'].toString().isNotEmpty) {
      nifController.text = users[0]['NIF'].toString();
    }

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16.0,
          right: 16.0,
          top: 16.0,
        ),
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
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color.fromARGB(255, 246, 141, 45),
                    width: 2.0,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color.fromARGB(255, 246, 141, 45),
                    width: 2.0,
                  ),
                ),
              ),
              cursorColor: Color.fromARGB(255, 246, 141, 45),
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
                      if (users[0]['NIF'] == null ||
                          users[0]['NIF'].toString() != nif) {
                        try {
                          final response = await http.post(
                            Uri.parse(
                                'https://appbar.epvc.pt/API/appBarAPI_Post.php'),
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
                              SnackBar(
                                  content: Text('NIF atualizado com sucesso!')),
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
                        SnackBar(
                            content: Text(
                                'NIF inválido. O NIF deve ter 9 dígitos numéricos.')),
                      );
                    }
                  },
                  child:
                      Text('Confirmar', style: TextStyle(color: Colors.green)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Method for MBWay payment
  Future<void> _handleMBWayPayment(double total,
      {bool requestInvoice = false, String nif = ''}) async {
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
          SnackBar(
              content: Text('Erro ao processar pagamento: ${e.toString()}')),
        );
      }
    }
  }

  // Method for Saldo payment
  Future<void> _handleSaldoPayment(double total,
      {bool requestInvoice = false, String nif = ''}) async {
    // Implement balance check, deduction, and transaction recording here
    if (users == null || users.isEmpty || users[0]['Saldo'] == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao obter saldo do usuário.')),
        );
      }
      return; // Cannot proceed without user data or balance
    }

    double currentBalance =
        double.tryParse(users[0]['Saldo'].toString()) ?? 0.0;

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
                // Atualizar quantidade dos produtos na base de dados após compra com saldo
                List<String> productIds = [];
                List<int> quantities = [];
                for (var entry in itemCountMap.entries) {
                  String productName = entry.key;
                  int quantity = entry.value;
                  var product = cartItems.firstWhere(
                    (item) => item['Nome'] == productName,
                    orElse: () => {'Id': '0'},
                  );
                  String id = (product['idApp'] != null && product['idApp'].toString().trim().isNotEmpty && product['idApp'].toString() != '0')
                      ? product['idApp'].toString()
                      : (product['Id'] != null && product['Id'].toString().trim().isNotEmpty && product['Id'].toString() != '0')
                          ? product['Id'].toString()
                          : '0';
                  if (id != '0') {
                    productIds.add(id);
                    quantities.add(quantity);
                  }
                }
                String idsParam = productIds.join(',');
                String quantitiesParam = quantities.join(',');
                print(
                    'Atualizando quantidades dos produtos: IDs $idsParam para quantidades $quantitiesParam');
                var response = await http.get(
                  Uri.parse(
                      'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=18&op=2&ids=$idsParam&quantities=$quantitiesParam'),
                );
                print(
                    'Resposta da API após atualizar quantidades: \\${response.body}');

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
                  SnackBar(
                      content: Text(
                          'Pedido Nº $orderNumber realizado com sucesso!')),
                );

                // Navegar para a página de confirmação de sucesso
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CashConfirmationPage(
                      change: 0.0, // Não há troco no pagamento com saldo
                      orderNumber: orderNumber,
                      amount: total,
                      paymentMethod: 'saldo',
                    ),
                  ),
                );
              } else {
                String errorMsg = responseData['error'] ??
                    'Erro desconhecido ao processar pagamento com Saldo';
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
                  reason:
                      'Erro ao criar pedido: ${orderData['message'] ?? "Erro desconhecido"}',
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
            reason:
                'Saldo insuficiente. Saldo atual: ${currentBalance.toStringAsFixed(2)}€',
            amount: total,
          ),
        ),
      );
    }
  }

  Future<bool> _showInvoiceDialog() async {
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
                    leading:
                        const Icon(Icons.check_circle, color: Colors.green),
                    title: const Text('Sim',
                        style: TextStyle(color: Colors.green)),
                    onTap: () => Navigator.pop(context, true),
                  ),
                  ListTile(
                    leading: const Icon(Icons.cancel, color: Colors.red),
                    title:
                        const Text('Não', style: TextStyle(color: Colors.red)),
                    onTap: () => Navigator.pop(context, false),
                  ),
                ],
              ),
            );
          },
        ) ??
        false;
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
            onPressed: _isLoading ? null : _refreshCart,
            icon: Icon(Icons.refresh),
          ),
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
          : SingleChildScrollView(
              child: Column(children: [
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
                          'Carrinho',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
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
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                padding: EdgeInsets.only(top: 12),
                itemCount: orderedItems.length,
                itemBuilder: (context, index) {
                  final itemName = orderedItems[index];
                  final itemCount = itemCountMap[itemName] ?? 0;
                  // Safely find the item or use a placeholder if not found
                  final item = cartItems.firstWhere(
                    (element) => element['Nome'] == itemName,
                    orElse: () => {
                      // Provide a default map if the item is not found
                      'Nome': itemName ?? '', // Ensure Nome is not null
                      'Imagem': '', // Provide a default empty image string
                      'Preco': '0.0', // Provide a default price
                      'Prencado': '0', // Provide a default prencado status
                      'PrepararPrencado': false, // Provide a default value
                      'Fresh': false, // Provide a default value
                    },
                  );

                  // Ensure essential properties are not null or of incorrect type after finding the item
                  final String currentItemName =
                      (item['Nome'] is String && item['Nome'] != null)
                          ? item['Nome']
                          : itemName ?? ''; // Use original itemName as fallback
                  final String currentItemPrencado = (item['Prencado'] != null)
                      ? item['Prencado'].toString()
                      : '0';
                  // Explicitly check for boolean type and provide a default
                  bool currentPrepararPrencado =
                      (item['PrepararPrencado'] is bool)
                          ? item['PrepararPrencado']
                          : false;
                  bool currentFresh =
                      (item['Fresh'] is bool) ? item['Fresh'] : false;

                  // If the item name is still empty or does not match, hide the item (in case orElse returned a minimal placeholder)
                  if (currentItemName.isEmpty ||
                      (itemName != null && currentItemName != itemName)) {
                    return Container(); // Hide the item if data is fundamentally missing or mismatched
                  }

                  // Safely decode the image bytes, handling potential errors
                  Uint8List? imageBytes;
                  String? base64Image =
                      (item['Imagem'] is String && item['Imagem'] != null)
                          ? item['Imagem']
                          : null; // Ensure it's a string and not null

                  // Add an additional check: only attempt decode if the string is not null or empty
                  if (base64Image != null && base64Image.isNotEmpty) {
                    try {
                      // Attempt to decode, catch format errors
                      imageBytes = base64.decode(base64Image);
                    } catch (e) {
                      // Log the error but continue, the errorBuilder will show the fallback
                      print(
                          'Error decoding image for item ${currentItemName}: $e');
                      // imageBytes remains null, the errorBuilder will handle this
                    }
                  }

                  final itemPrice =
                      double.tryParse(item['Preco']?.toString() ?? '0') ?? 0;
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
                                            cacheWidth:
                                                100, // Explicitly set cache dimensions
                                            cacheHeight: 100,
                                            filterQuality: FilterQuality.high,
                                            isAntiAlias: true,
                                            key: ValueKey(
                                                currentItemName), // Use currentItemName for key
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              // Fallback widget if image fails to load or decode
                                              return Container(
                                                color: Colors.grey[
                                                    200], // Use a light grey background
                                                child: Icon(
                                                  Icons
                                                      .broken_image_outlined, // Use a broken image icon
                                                  size: 30,
                                                  color: Colors
                                                      .red, // Use red for error
                                                ),
                                              );
                                            },
                                          )
                                        : Container(
                                            color: Colors.grey[
                                                200], // Use a light grey background for missing image
                                            child: Icon(
                                              Icons
                                                  .fastfood, // Generic food icon
                                              size: 30,
                                              color: Colors.grey[
                                                  400], // Use a darker grey for the icon
                                            ),
                                          ), // Fallback for missing or invalid image data
                                  ),
                                ),
                                SizedBox(width: 12),
                                // Title and price
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        currentItemName.isNotEmpty
                                            ? currentItemName
                                            : 'Item Desconhecido', // Provide fallback text
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
                                          color: Colors
                                              .orange, // Orange color for price
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
                                        icon: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.orange,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: EdgeInsets.all(4),
                                          child: Icon(Icons.remove, size: 16, color: Colors.white),
                                        ),
                                        onPressed: _isLoading
                                            ? null
                                            : () async {
                                                if (_isLoading) return;

                                                // Check if this is the last item of this type
                                                final itemCount = cartItems
                                                    .where((element) =>
                                                        element['Nome'] ==
                                                        itemName)
                                                    .length;

                                                if (itemCount == 1) {
                                                  // Show confirmation dialog for last item
                                                  final bool? confirm =
                                                      await showDialog<bool>(
                                                    context: context,
                                                    builder:
                                                        (BuildContext context) {
                                                      return AlertDialog(
                                                        title: Text(
                                                            'Remover Item'),
                                                        content: Text(
                                                            'Deseja remover este item do carrinho?'),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.of(
                                                                        context)
                                                                    .pop(false),
                                                            style: TextButton
                                                                .styleFrom(
                                                              backgroundColor:
                                                                  Colors.grey[
                                                                      300],
                                                              foregroundColor:
                                                                  Colors
                                                                      .black87,
                                                            ),
                                                            child: Text(
                                                                'Cancelar'),
                                                          ),
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.of(
                                                                        context)
                                                                    .pop(true),
                                                            style: TextButton
                                                                .styleFrom(
                                                              backgroundColor:
                                                                  Colors.orange,
                                                              foregroundColor:
                                                                  Colors.white,
                                                            ),
                                                            child: Text(
                                                                'Confirmar'),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );

                                                  if (confirm == true) {
                                                    setState(() {
                                                      _isLoading = true;
                                                    });

                                                    try {
                                                      int index =
                                                          cartItems.indexWhere(
                                                              (element) =>
                                                                  element[
                                                                      'Nome'] ==
                                                                  itemName);
                                                      if (index != -1) {
                                                        cartItems
                                                            .removeAt(index);
                                                        updateItemCountMap();
                                                       /* ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                                'Item removido'),
                                                            duration: Duration(
                                                                milliseconds:
                                                                    500),
                                                          ),
                                                        );*/
                                                      }
                                                    } finally {
                                                      if (mounted) {
                                                        setState(() {
                                                          _isLoading = false;
                                                        });
                                                      }
                                                    }
                                                  }
                                                } else {
                                                  // Remove item directly if not the last one
                                                  setState(() {
                                                    _isLoading = true;
                                                  });

                                                  try {
                                                    int index = cartItems
                                                        .indexWhere((element) =>
                                                            element['Nome'] ==
                                                            itemName);
                                                    if (index != -1) {
                                                      cartItems.removeAt(index);
                                                      updateItemCountMap();
                                                      /*ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                              'Item removido'),
                                                          duration: Duration(
                                                              milliseconds:
                                                                  500),
                                                        ),
                                                      );*/
                                                    }
                                                  } finally {
                                                    if (mounted) {
                                                      setState(() {
                                                        _isLoading = false;
                                                      });
                                                    }
                                                  }
                                                }
                                              },
                                        color: _isLoading
                                            ? Colors.grey[400]
                                            : Colors.grey[700],
                                        padding: EdgeInsets.all(4),
                                        constraints: BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                      ),
                                      Container(
                                        padding:
                                            EdgeInsets.symmetric(horizontal: 4),
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
                                        icon: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.orange,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: EdgeInsets.all(4),
                                          child: Icon(Icons.add, size: 16, color: Colors.white),
                                        ),
                                        onPressed: _isLoading
                                            ? null
                                            : () {
                                                if (_isLoading) return;

                                                setState(() {
                                                  _isLoading = true;
                                                  final newItem =
                                                      Map<String, dynamic>.from(
                                                          item);
                                                  cartItems.add(newItem);
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                          'Item adicionado'),
                                                      duration: Duration(
                                                          milliseconds: 500),
                                                    ),
                                                  );
                                                  updateItemCountMap();
                                                  _isLoading = false;
                                                });
                                              },
                                        color: _isLoading
                                            ? Colors.grey[400]
                                            : Colors.grey[700],
                                        padding: EdgeInsets.all(4),
                                        constraints: BoxConstraints(
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
                            if ((item['Prencado']?.toString() ?? '0') == '1' ||
                                (item['Prencado']?.toString() ?? '0') == '2')
                              Center(
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2), // Menos espaço vertical
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        (item['Prencado']?.toString() ?? '0') ==
                                                '1'
                                            ? Icons.coffee
                                            : Icons.local_cafe,
                                        size: 14, // Ícone menor
                                        color: Colors.orange[700],
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Tipo:',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      ToggleButtons(
                                        constraints: BoxConstraints(
                                            minHeight:
                                                28), // Controla altura dos botões
                                        isSelected: [
                                          currentPrepararPrencado,
                                          !currentPrepararPrencado
                                        ],
                                        onPressed: (index) {
                                          setState(() {
                                            int itemIndex =
                                                cartItems.indexWhere((e) =>
                                                    e['Nome'] == itemName);
                                            if (itemIndex != -1) {
                                              final updatedItem =
                                                  Map<String, dynamic>.from(
                                                      cartItems[itemIndex]);
                                              updatedItem['PrepararPrencado'] =
                                                  index == 0;
                                              cartItems[itemIndex] =
                                                  updatedItem;
                                            }
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(6),
                                        selectedColor: Colors.white,
                                        fillColor: Colors.orange[700],
                                        borderColor: Colors.orange[700],
                                        color: Colors.orange[700],
                                        borderWidth: 1.0,
                                        selectedBorderColor: Colors.orange[700],
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 6),
                                            child: Text(
                                              (item['Prencado']?.toString() ??
                                                          '0') ==
                                                      '1'
                                                  ? 'Prensado'
                                                  : 'Aquecido',
                                              style: TextStyle(
                                                  fontSize:
                                                      11), // Letra mais pequena
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 6),
                                            child: Text(
                                              'Normal',
                                              style: TextStyle(fontSize: 11),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
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
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2), // Menos altura
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.local_drink,
                                        size: 14, // Menor ícone
                                        color: Colors.orange[700],
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Tipo:',
                                        style: TextStyle(
                                          fontSize: 11, // Menor texto
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      ToggleButtons(
                                        constraints: BoxConstraints(
                                            minHeight:
                                                28), // altura mínima controlada
                                        isSelected: [
                                          currentFresh,
                                          !currentFresh
                                        ],
                                        onPressed: (index) {
                                          setState(() {
                                            final i = cartItems.indexWhere(
                                                (e) => e['Nome'] == itemName);
                                            if (i != -1) {
                                              final updated =
                                                  Map<String, dynamic>.from(
                                                      cartItems[i]);
                                              updated['Fresh'] = index == 0;
                                              cartItems[i] = updated;
                                            }
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(6),
                                        selectedColor: Colors.white,
                                        fillColor: Colors.orange[700],
                                        borderColor: Colors.orange[700],
                                        color: Colors.orange[700],
                                        borderWidth: 1.0,
                                        selectedBorderColor: Colors.orange[700],
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 6),
                                            child: Text(
                                              'Fresco',
                                              style: TextStyle(
                                                  fontSize: 11), // Menor fonte
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 6),
                                            child: Text(
                                              'Natural',
                                              style: TextStyle(fontSize: 11),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
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
                          onPressed: _isLoading
                              ? null
                              : () async {
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
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          backgroundColor:
                              _isLoading ? Colors.grey : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ])),
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
            label: Text(
              'Escolher Produtos',
              style: TextStyle(color: Colors.white),
            ),
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
  final TextEditingController _recentBuysSearchController =
      TextEditingController();
  String? _selectedRecentBuysSortOption;
  double? _minRecentBuysPrice;
  double? _maxRecentBuysPrice;
  Map<String, bool> _itemLoadingStatus =
      {}; // New map for per-item loading status

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
      'Nome': (item['Nome'] ?? item['Descricao'] ?? '').replaceAll('"', ''), // Corrigido para evitar null
      'Preco': item['Preco']?.toString() ?? '0.0',
      'Prencado': item['Prencado']?.toString() ?? '0',
      'PrepararPrencado': false, // Initialize to false
      'Fresh': false, // Initialize to false
      'Id': item['idApp'], // Adiciona o ID do produto
      'idApp': (item['idApp'] ?? item['IdApp'] ?? item['idapp']) != null && (item['idApp'] ?? item['IdApp'] ?? item['idapp']).toString().trim().isNotEmpty
        ? (item['idApp'] ?? item['IdApp'] ?? item['idapp'])
        : item['Id'], // Garante prioridade ao idApp, senão usa Id
      'XDReference': item['XDReference'] ?? '', // Adiciona o XDReference
    };

    // Apply default preparation based on Prencado value
    if (newItem['Prencado'] == '1' || newItem['Prencado'] == '2') {
      newItem['PrepararPrencado'] = true;
    } else if (newItem['Prencado'] == '3') {
      newItem['Fresh'] = true;
    }

    // Check available quantity before adding
    final String productName = newItem['Nome']; // Get product name
    int availableQuantity =
        await checkQuantidade(productName); // Check available quantity
    int currentQuantity = cartItems
        .where((cartItem) => cartItem['Nome'] == productName)
        .length; // Get current quantity in cart

    if (availableQuantity >= currentQuantity + 1) {
      setState(() {
        cartItems.add(newItem);
      });
      /*ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item adicionado'),
          duration: Duration(milliseconds: 500),
        ),
      );*/
    } else if (availableQuantity <= 0) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Produto Indisponível'),
            content:
                Text('Desculpe, este produto está indisponível no momento.'),
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
    } else {
      // availableQuantity < desiredQuantity
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Quantidade Máxima'),
            content: Text(
                'Quantidade máxima disponível atingida (Disponível: $availableQuantity)'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
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
    final query =
        removeDiacritics(_recentBuysSearchController.text.toLowerCase());
    setState(() {
      filteredRecentBuys = widget.recentBuys.where((product) {
        if (product['Descricao'] != null && product['Descricao'] is String) {
          final normalizedDescricao =
              removeDiacritics(product['Descricao'].toLowerCase());
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
                    DropdownMenuItem(
                        value: 'asc',
                        child: Row(children: [
                          Icon(Icons.arrow_upward,
                              color: Colors.orange), // Set icon color to orange
                          SizedBox(width: 8),
                          Text('Preço: Ascendente',
                              style: TextStyle(
                                  color: Colors
                                      .orange)), // Set text color to orange
                        ])),
                    DropdownMenuItem(
                        value: 'desc',
                        child: Row(children: [
                          Icon(Icons.arrow_downward,
                              color: Colors.orange), // Set icon color to orange
                          SizedBox(width: 8),
                          Text('Preço: Descendente',
                              style: TextStyle(
                                  color: Colors
                                      .orange)), // Set text color to orange
                        ])),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedRecentBuysSortOption =
                            newValue; // Update the selection
                        _sortRecentBuys(); // Call the sorting function
                        Navigator.pop(context); // Close the dialog
                      });
                    }
                  },
                ),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Preço Mínimo',
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.orange),
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Colors.orange), // Set default border to orange
                    ),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*[,|\.]?\d*')),
                  ],
                  onChanged: (value) {
                    String normalized = value.replaceAll(',', '.');
                    _minRecentBuysPrice = normalized.isNotEmpty
                        ? double.tryParse(normalized)
                        : null;
                    _filterRecentBuysByPrice();
                  },
                ),
                SizedBox(height: 16), // Added SizedBox for consistent spacing
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Preço Máximo',
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.orange),
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Colors.orange), // Set default border to orange
                    ),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*[,|\.]?\d*')),
                  ],
                  onChanged: (value) {
                    String normalized = value.replaceAll(',', '.');
                    _maxRecentBuysPrice = normalized.isNotEmpty
                        ? double.tryParse(normalized)
                        : null;
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
              style: TextButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
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
                    // Removed setState(() {}); to prevent unnecessary rebuilds and flickering
                    // The cart count will be updated through other means if needed, e.g., on cart item changes.
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
          IconButton(
            icon: Icon(Icons.filter_list, color: Colors.orange),
            onPressed: _showRecentBuysFilterDialog,
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
                icon: Icon(Icons.filter_list, color: Colors.orange),
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
                      final String productName =
                          product['Descricao'].replaceAll('"', '');
                      final int itemCount = cartItems
                          .where((item) => item['Nome'] == productName)
                          .length;

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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                cartItems.any((cartItem) =>
                                        cartItem['Nome'] == productName)
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            cartItems
                                                .where((element) =>
                                                    element['Nome'] ==
                                                    productName)
                                                .length
                                                .toString(),
                                            style: TextStyle(fontSize: 15.0),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              addToCart(product);
                                            },
                                            icon: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.orange,
                                                shape: BoxShape.circle,
                                              ),
                                              padding: EdgeInsets.all(4),
                                              child: Icon(Icons.add, size: 16, color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      )
                                    : StatefulBuilder(
                                        builder: (context, setState) {
                                          return FutureBuilder<int>(
                                            future:
                                                checkQuantidade(productName),
                                            builder: (context, snapshot) {
                                              bool isAvailable =
                                                  snapshot.hasData &&
                                                      snapshot.data! > 0;
                                              return LoadingButton(
                                                onPressed: _itemLoadingStatus[
                                                                productName] ==
                                                            true ||
                                                        !isAvailable
                                                    ? null
                                                    : () async {
                                                        setState(() {
                                                          _itemLoadingStatus[
                                                                  productName] =
                                                              true;
                                                        });
                                                        try {
                                                          await Future.delayed(
                                                              Duration(
                                                                  milliseconds:
                                                                      300));
                                                          int availableQuantity =
                                                              await checkQuantidade(
                                                                  productName);
                                                          if (availableQuantity >
                                                              0) {
                                                            addToCart(product);
                                                          } else {
                                                            showDialog(
                                                              context: context,
                                                              builder:
                                                                  (BuildContext
                                                                      context) {
                                                                return AlertDialog(
                                                                  title: Text(
                                                                      'Produto Indisponível'),
                                                                  content: Text(
                                                                      'Desculpe, este produto está indisponível no momento.'),
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed:
                                                                          () {
                                                                        Navigator.of(context)
                                                                            .pop();
                                                                      },
                                                                      style: TextButton
                                                                          .styleFrom(
                                                                        backgroundColor:
                                                                            Colors.orange,
                                                                        foregroundColor:
                                                                            Colors.white,
                                                                      ),
                                                                      child: Text(
                                                                          'OK'),
                                                                    ),
                                                                  ],
                                                                );
                                                              },
                                                            );
                                                          }
                                                        } finally {
                                                          setState(() {
                                                            _itemLoadingStatus[
                                                                    productName] =
                                                                false;
                                                          });
                                                        }
                                                      },
                                                isLoading: _itemLoadingStatus[
                                                        productName] ==
                                                    true,
                                                child: _itemLoadingStatus[
                                                            productName] ==
                                                        true
                                                    ? SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child:
                                                            CircularProgressIndicator(
                                                          valueColor:
                                                              AlwaysStoppedAnimation<
                                                                      Color>(
                                                                  Colors.white),
                                                          strokeWidth: 2,
                                                        ),
                                                      )
                                                    : Text('Comprar'),
                                                backgroundColor: isAvailable
                                                    ? Colors.orange
                                                    : Colors.grey,
                                              );
                                            },
                                          );
                                        },
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
