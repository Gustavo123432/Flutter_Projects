import 'package:bottom_navigacion_teste/mobile/FinishedTar.dart';
import 'package:bottom_navigacion_teste/mobile/StartedtTar.dart';
import 'package:bottom_navigacion_teste/mobile/secondScreen.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int initialIndex;

  CustomBottomNavigationBar({required this.initialIndex});

  Future navigateWithTransition(BuildContext context, Widget page, PageTransitionType transitionType) async {
    await Navigator.pushReplacement(
      context,
      PageTransition(
        type: transitionType,
        child: page,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: initialIndex,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Tarefas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.incomplete_circle),
          label: 'Em Progresso',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.done),
          label: 'Terminadas',
        ),
      ],
      onTap: (index) async {

        if (index == 0) {
          // Navegar para SecondScreen com PageTransition
          await navigateWithTransition(context, SecondScreen(), PageTransitionType.fade);
        } else if (index == 1) {
          // Navegar para StartedTar com PageTransition
          await navigateWithTransition(context, StartedtTar(), PageTransitionType.fade);
        } else if (index == 2) {
          // Navegar para FinishedTar com PageTransition
          await navigateWithTransition(context, FinishedTar(), PageTransitionType.fade);
        }
      },
    );
  }
}
