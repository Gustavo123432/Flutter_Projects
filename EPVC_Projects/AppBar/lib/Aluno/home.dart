import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

void main() {
  runApp(HomeAlunoMain());
}

List<Map<String, dynamic>> cartItems =
    []; // Lista global para armazenar os itens no carrinho

class HomeAlunoMain extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Comprado Recentemente',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: HomeAluno(),
    );
  }
}

class HomeAluno extends StatefulWidget {
  @override
  _HomeAlunoState createState() => _HomeAlunoState();
}

class _HomeAlunoState extends State<HomeAluno> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        title: Text(
          '',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            margin: EdgeInsets.only(
                left: 16.0, right: 16.0, top: 25.0, bottom: 32.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50.0),
                ),
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
            child: Text(
              "Comprados Recentemente",
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[900],
              ),
            ),
          ),
          Container(
            height: 150.0,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                return buildProductSection(
                  imagePath: 'path/to/image_$index.jpg',
                  title: 'Product $index',
                  price: '5.55',
                );
              },
            ),
          ),
          SizedBox(height: 50.0),
          Container(
            margin: EdgeInsets.only(left: 16.0, right: 16.0, top: 32),
            child: Text(
              "Categorias",
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[900],
              ),
            ),
          ),
          Expanded(
            child: Container(
              child: ListView(
                children: [
                  buildCategoryCard(
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
                      );
                    },
                  ),
                  buildCategoryCard(
                    title: 'Café',
                    backgroundImagePath: 'lib/assets/cafe.JPG',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryPage(
                            title: 'Café',
                          ),
                        ),
                      );
                    },
                  ),
                  buildCategoryCard(
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
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Color.fromARGB(255, 246, 141, 45),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.home, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeAlunoMain(),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.notifications, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.shopping_cart, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShoppingCartPage(),
                  ),
                );
              },
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
  }) {
    return Container(
      width: MediaQuery.of(context).size.width / 2,
      margin: EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2.0,
            blurRadius: 4.0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(imagePath, height: 80.0),
            Text(
              title,
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'R\$',
                  style: TextStyle(fontSize: 14.0),
                ),
                Text(
                  price,
                  style: TextStyle(fontSize: 16.0),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCategoryCard({
    required String title,
    required String backgroundImagePath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150.0,
        margin: EdgeInsets.symmetric(vertical: 8.0),
        padding: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(backgroundImagePath),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 32.0,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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
  

  @override
  void initState() {
    super.initState();
    fetchData(widget.title);
    Timer.periodic(Duration(seconds: 1), (timer) {
      fetchData(widget.title);
    });
  }

  Future<void> fetchData(String categoria) async {
    try {
      final response = await http.post(
        Uri.parse('http://api.gfserver.pt/appBarAPI_Post.php'),
        body: {
          'query_param': '5',
          'categoria': '$categoria',
        },
      );
      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        if (responseData is List<dynamic>) {
          setState(() {
            items = responseData.cast<Map<String, dynamic>>();
          });
        } else {
          throw Exception('Response data is not a List<dynamic>');
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final double preco = double.parse(item['Preco']);
          
          return Card(
            child: ListTile(
              leading: Image.memory(
                base64.decode(item['Imagem']),
                fit: BoxFit.cover,
                height: 50,
                width: 50,
              ),
              title: Text(item['Nome']),
              subtitle: Text(
                items[index]['Qtd'] == "1" ? "Disponível - ${preco.toStringAsFixed(2).replaceAll('.', ',')}€" : "Indisponível",
              ),
              trailing: Visibility(
                visible: items[index]['Qtd'] == "1",
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      cartItems.add(item);
                    });
                  },
                  child: Text('Comprar'),
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        color: Color.fromARGB(255, 246, 141, 45),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.home, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeAlunoMain(),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.notifications, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.shopping_cart, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShoppingCartPage(),
                  ),
                );
              },
            ),
          ],
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
  dynamic users;

  @override
  void initState() {
    super.initState();
    updateItemCountMap();
    UserInfo();
  }

  void UserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var user = prefs.getString("username");

    final response = await http.post(
      Uri.parse('http://api.gfserver.pt/appBarAPI_Post.php'),
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

  int generateRandomNumber(int min, int max) {
    // Initialize the random number generator
    var rng = Random();

    // Generate a random number between min and max (inclusive)
    return min + rng.nextInt(max - min + 1);
  }

 

  void sendOrderToApi(List<Map<String, dynamic>> cartItems, String total) async {
  // Generate a random order number
  int orderNumber = generateRandomNumber(1000, 9999);

  try {
    // Extracting names from cart items
    List<String> itemNames = cartItems.map((item) => item['Nome'] as String).toList();
    
    // Extract user information
    var turma = users[0]['Turma'];
    var nome = users[0]['Nome'];
    var apelido = users[0]['Apelido'];
    var permissao = users[0]['Permissao'];

    // Encode cartItems to JSON string
    String cartItemsJson = json.encode(cartItems);

    // Send GET request to API
    var response = await http.get(Uri.parse(
      'http://api.gfserver.pt/appBarAPI_GET.php?query_param=5&nome=$nome&apelido=$apelido&orderNumber=$orderNumber&turma=$turma&permissao=$permissao&descricao=$itemNames&total=$total',
    ));

    if (response.statusCode == 200) {
      // If the request is successful, show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pedido enviado com sucesso para a API'),
        ),
      );
    } else {
      // If there's an error, show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar o pedido para a API'),
        ),
      );
    }
  } catch (e) {
    print('Erro ao fazer a requisição GET: $e');
    // Show error message if request fails
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erro ao enviar o pedido para a API'),
      ),
    );
  }
}
  void updateItemCountMap() {
    itemCountMap.clear();
    for (var item in cartItems) {
      final itemName = item['Nome'];
      // Verifica se o itemName não é nulo antes de tentar incrementar o contador
      if (itemName != null) {
        // Se o itemName já estiver no mapa, incrementa o contador; senão, define o contador como 1
        itemCountMap[itemName] = (itemCountMap[itemName] ?? 0) + 1;
      }
    }
  }

  double calculateTotal() {
  double total = 0.0;
  for (var item in cartItems) {
    double preco = double.parse(item['Preco']);
    total += preco;
  }
  return total;
}


  @override
  Widget build(BuildContext context) {
    double total = calculateTotal();
    return Scaffold(
      appBar: AppBar(
        title: Text('Carrinho Compras'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: itemCountMap.length,
              itemBuilder: (context, index) {
                final itemName = itemCountMap.keys.toList()[index];
                final itemCount = itemCountMap[itemName] ??
                    0; // Garante que itemCount não seja nulo
                // Encontra o primeiro item no carrinho que corresponde ao nome do produto
                final item = cartItems.firstWhere(
                  (element) => element['Nome'] == itemName,
                );
                // Extrai a imagem do produto do item, ou define uma imagem padrão se não houver imagem
                final image =
                    item != null ? base64.decode(item['Imagem']) : null;
                return Card(
                  child: ListTile(
                    leading: image != null
                        ? Image.memory(
                            image,
                            fit: BoxFit.cover,
                            height: 50,
                            width: 50,
                          )
                        : SizedBox
                            .shrink(), // Se não houver imagem, não exibe nada
                    title: Text('$itemName'),
                    subtitle: Text('Quantidade: $itemCount'),
                    trailing: IconButton(
                      icon: Icon(Icons.remove_circle),
                      onPressed: () {
                        setState(() {
                          // Remove apenas um item de mesmo nome
                          for (int i = 0; i < cartItems.length; i++) {
                            if (cartItems[i]['Nome'] == itemName) {
                              cartItems.removeAt(i);
                              break;
                            }
                          }
                          updateItemCountMap();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Item removido do carrinho')),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          
          Container(
          margin: EdgeInsets.only(
              bottom: 16.0), // Define a margem na parte inferior
          child: Column(
            children: [
              Text(
                'Total: ${total.toStringAsFixed(2).replaceAll('.', ',')}€',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
              ElevatedButton(
                onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Confirmação do Pedido'),
                      content: Text('Deseja confirmar o pedido?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Confirmação de Pedido com Sucesso')),
                            );

                            sendOrderToApi(cartItems, total.toString());

                            cartItems.clear(); // Clear the cart after confirming the order
                            updateItemCountMap();
                          },
                          child: Text('Confirmar'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('Cancelar'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text('Fazer Pedido'),
              ),
            ],
          ),
        ),
      ],
    ),
      bottomNavigationBar: BottomAppBar(
        color: Color.fromARGB(255, 246, 141, 45),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.home, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeAlunoMain(),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.notifications, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.shopping_cart, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShoppingCartPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
