import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


import '../Componentes/drawer.dart';
import 'Dimensions.dart';

// Defina a enumeração LayoutType
enum LayoutType {
  mobile,
  tablet,
  desktop,
}

class ResponsiveLayoutPage extends StatelessWidget {
  final Widget mobileBody;
  final Widget tabletBody;
  final Widget desktopBody;
  final MyDrawer Function(BuildContext context, LayoutType layout) builder;

  ResponsiveLayoutPage({
    required this.mobileBody,
    required this.tabletBody,
    required this.desktopBody,
    required this.builder,
  });

  // Método para determinar o tipo de layout com base nas dimensões da tela
  static LayoutType getLayoutType(double width) {
    if (width < mobileWith) {
      return LayoutType.mobile;
    } else if (width < tabletWith) {
      return LayoutType.tablet;
    } else {
      return LayoutType.desktop;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determinar o tipo de layout com base nas dimensões da tela
        LayoutType layoutType = getLayoutType(constraints.maxWidth);

        // Construir e retornar o drawer com base no tipo de layout atual
        final drawer = layoutType != LayoutType.mobile ? builder(context, layoutType) : null;

        // Retornar o corpo apropriado com o drawer criado
        switch (layoutType) {
          case LayoutType.mobile:
            return Scaffold(
              drawer: drawer,
              body: mobileBody,
            );
          case LayoutType.tablet:
            return Scaffold(
              drawer: drawer,
              body: tabletBody,
            );
          case LayoutType.desktop:
          default:
            return Scaffold(
              drawer: drawer,
              body: desktopBody,
            );
        }
      },
    );
  }
}
