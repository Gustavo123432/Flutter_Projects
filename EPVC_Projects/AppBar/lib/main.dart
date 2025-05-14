import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
      theme: ThemeData(
        useMaterial3: false,
      ),
      home: LoginForm(),
    );
  }
}