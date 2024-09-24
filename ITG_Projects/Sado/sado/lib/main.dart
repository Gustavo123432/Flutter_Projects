import 'package:flutter/material.dart';
import 'package:sado/Paginas/Login/forgotPasswordFirst.dart';
import 'package:sado/Paginas/Login/signUpCodeSecond.dart';
import 'package:sado/Paginas/Login/signUpFirst.dart';
import 'package:sado/Paginas/Login/signUpThird.dart';
import 'package:sado/Paginas/Principais/Admin/dashboardPage.dart';
import 'package:sado/Paginas/Registo/companiesRegister.dart';
import 'package:sado/drawer/adminDrawer.dart';

import 'Paginas/Login/login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: false,
      ),
      initialRoute: './login',
      routes: {
        '/empresas': (BuildContext context) => const CompaniesRegisterForm(),
        './login': (BuildContext context) => const LoginForm(),
        './dashboard': (BuildContext context) =>  AdminDrawer(currentPage: DashboardPage(), numero: 0,),
        './signup': (BuildContext context) => const SignUpFirstForm(),
        './signup/code': (BuildContext context) => const SignUpCodeSecondForm(
              opcao: '0',
            ),
        './signup/code/data': (BuildContext context) => const SignUpThirdForm(),
        './forgotpass/code': (BuildContext context) =>
            const SignUpCodeSecondForm(
              opcao: '1',
            ),
      },
      home: Scaffold(
        body: LoginForm(),
      ),
    );
  }
}
