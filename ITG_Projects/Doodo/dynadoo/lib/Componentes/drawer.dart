import 'package:flutter/material.dart';
import '../Paginas/Desktop/Principais/materiais.dart';
import '../Paginas/Desktop/Principais/dashboard.dart';
import '../Paginas/Desktop/Principais/projetos.dart';
import '../Paginas/Desktop/Principais/servicos.dart';
import '../Paginas/Desktop/Principais/tarefas.dart';
import '../Paginas/Mobile/Principais/dashboard.dart';
import '../Paginas/Mobile/Principais/materiais.dart';
import '../Paginas/Mobile/Principais/projetos.dart';
import '../Paginas/Mobile/Principais/servicos.dart';
import '../Paginas/Mobile/Principais/tarefas.dart';
import '../Paginas/tablet/Principais/dashboard.dart';
import '../Paginas/tablet/Principais/materiais.dart';
import '../Paginas/tablet/Principais/projetos.dart';
import '../Paginas/tablet/Principais/servicos.dart';
import '../Paginas/tablet/Principais/tarefas.dart';

class MyDrawer extends StatelessWidget {
  final String currentLayoutType;
  static List<String> abas = [];
  static Map<String, List<String>> subAbas = {};
  const MyDrawer({Key? key, required this.currentLayoutType}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = currentLayoutType == 'mobile';
    return Drawer(
      width: isMobile ? MediaQuery.of(context).size.width * 0.7 : 250,
      child: Column(
        children: [
          ListTile(
            title: Text('Projetos'),
            onTap: () {
              _navigateToPage(context, 'Projetos');
            },
          ),
          ListTile(
            title: Text('Materiais'),
            onTap: () {
              _navigateToPage(context, 'Materiais');
            },
          ),
          ListTile(
            title: Text('Serviços'),
            onTap: () {
              _navigateToPage(context, 'Serviços');
            },
          ),
          Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: MyDrawer.abas.length,
              itemBuilder: (BuildContext context, int index) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExpansionTile(
                      title: Text(MyDrawer.abas[index]),
                      children: [
                        if (MyDrawer.subAbas.containsKey(MyDrawer.abas[index]))
                          ...MyDrawer.subAbas[MyDrawer.abas[index]]!
                              .map((subAba) {
                            return ListTile(
                              title: Text(subAba),
                              onTap: () {
                                _navigateToPage(context, subAba);
                              },
                              leading: Icon(Icons.arrow_right),
                            );
                          }).toList(),
                      ],
                    ),
                    SizedBox(height: 5),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPage(BuildContext context, String pageName) async {
    Widget nextPage;
    switch (currentLayoutType) {
      case 'desktop':
        switch (pageName) {
          case 'Projetos':
            nextPage = ProjetosDPage();
            break;
          case 'Dashboard':
            nextPage = DashboardDPage();
            break;
          case 'Tarefas':
            nextPage = TarefasDPage();
            break;
          case 'Materiais':
            nextPage = MateriaisD();
            break;
          case 'Serviços':
            nextPage = ServicosD();
            break;
          default:
            nextPage = Container();
        }
        break;
      case 'tablet':
        switch (pageName) {
          case 'Projetos':
            nextPage = ProjetosTPage();
            break;
          case 'Dashboard':
            nextPage = DashboardTPage();
            break;
          case 'Tarefas':
            nextPage = TarefasPageT();
            break;
          case 'Materiais':
            nextPage = MateriaisT();
            break;
          case 'Serviços':
            nextPage = ServicosT();
            break;
          default:
            nextPage = Container();
        }
        break;
      case 'mobile':
      default:
        switch (pageName) {
          case 'Projetos':
            nextPage = ProjetosMPage();
            break;
          case 'Dashboard':
            nextPage = DashboardMPage();
            break;
          case 'Tarefas':
            nextPage = TarefasMPage();
            break;
          case 'Materiais':
            nextPage = MateriaisM();
            break;
          case 'Serviços':
            nextPage = ServicosM();
            break;
          default:
            nextPage = Container();
        }
        break;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextPage,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = 0.0;
          const end = 1.0;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var opacityAnimation = animation.drive(tween);

          return FadeTransition(
            opacity: opacityAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }
}
