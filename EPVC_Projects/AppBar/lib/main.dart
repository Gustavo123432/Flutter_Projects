import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:http/http.dart' as http;
import 'login.dart';

void main() async {
  // Garantir que o Flutter está inicializado
  WidgetsFlutterBinding.ensureInitialized();

  // Carregar variáveis de ambiente com tratamento de erro
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // Se falhar ao carregar o .env, continue sem ele
    debugPrint('Aviso: Arquivo .env não encontrado. Usando valores padrão.');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        scaffoldBackgroundColor: Colors.white,
        primaryColor: Color.fromARGB(255, 246, 141, 45), // Orange color
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color.fromARGB(255, 246, 141, 45), // Orange color
          primary: Color.fromARGB(255, 246, 141, 45), // Orange color
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color.fromARGB(255, 246, 141, 45), // Orange color
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromARGB(255, 246, 141, 45), // Orange color
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: Center(child: const ConnectionCheckScreen()),
    );
  }
}

class ConnectionCheckScreen extends StatefulWidget {
  const ConnectionCheckScreen({Key? key}) : super(key: key);

  @override
  State<ConnectionCheckScreen> createState() => _ConnectionCheckScreenState();
}

class _ConnectionCheckScreenState extends State<ConnectionCheckScreen> {
  bool _isChecking = true;
  String _errorMessage = '';
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();

    // Inicializar listener de conectividade para reagir a mudanças
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        _checkConnectionAndProceed();
      }
    });

    // Verificar conexão inicial
    _checkConnectionAndProceed();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _checkConnectionAndProceed() async {
    setState(() {
      _isChecking = true;
      _errorMessage = '';
    });

    // Verificar internet
    bool hasInternet = false;
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.first != ConnectivityResult.none) {
        hasInternet =
            await InternetConnectionChecker.createInstance().hasConnection;
      }
    } catch (e) {
      hasInternet = false;
    }

    // Se não tem internet, mostrar erro e parar aqui
    if (!hasInternet) {
      setState(() {
        _isChecking = false;
        _errorMessage =
            'Sem conexão com a Internet. Verifique sua rede e tente novamente.';
      });
      return;
    }

    // Verificar conexão com o servidor
    try {
      final response = await http
          .get(Uri.parse(
              'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=ping'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 400) {
        // Conexão bem-sucedida, avançar para o login
        if (mounted) {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginForm()));
        }
      } else {
        setState(() {
          _isChecking = false;
          _errorMessage =
              'Não foi possível conectar ao servidor. Erro: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isChecking = false;
        _errorMessage = 'Servidor não está respondendo: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
      child:
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo ou imagem da app
                Image.asset(
                  'lib/assets/barapp.png',
                  height: 120,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.school,
                      size: 120,
                      color: Colors.orange,
                    );
                  },
                ),
                const SizedBox(height: 30),
                const Text(
                  'AppBar EPVC',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 50),

                // Indicador de carregamento ou erro
                if (_isChecking)
                  const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 20),
                      Text('A verificar ligação...'),
                    ],
                  )
                else
                  Column(
                    children: [
                      Icon(
                        Icons.error,
                        color: Colors.red,
                        size: 50,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _checkConnectionAndProceed,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 10),
                        ),
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
