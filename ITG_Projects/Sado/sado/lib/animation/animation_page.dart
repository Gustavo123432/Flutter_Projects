import 'package:flutter/material.dart';

class CustomHeroPageRoute extends PageRouteBuilder {
  final Widget page;

  CustomHeroPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Define the Hero tag for the animation
            const begin = Offset(0.0, 0.0); // Start position
            const end = Offset.zero; // End position
            const curve = Curves.easeInOut; // Curve for the transition

            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            // Transition duration can be adjusted here
            const transitionDuration = Duration(milliseconds: 1200);

            return SlideTransition(position: offsetAnimation, child: child);
          },
          transitionDuration:
              const Duration(milliseconds: 1200), // Adjust the duration here
          reverseTransitionDuration:
              const Duration(milliseconds: 1200), // Adjust the duration here
        );
}

class SlideTransitionPageRoute extends PageRouteBuilder {
  final Widget page;

  SlideTransitionPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin =
                Offset(0.1, 0.0); // Start position (right side of the screen)
            const end = Offset.zero; // End position (final position)
            const curve = Curves.easeInOut; // Animation curve

            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(position: offsetAnimation, child: child);
          },
        );
}
