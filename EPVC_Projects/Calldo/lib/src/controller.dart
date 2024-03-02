//part of 'Calldo/flutter_advanced_drawer';
import 'package:flutter/material.dart';
import 'package:Calldo/src/widget.dart';
import 'package:Calldo/src/value.dart';

/// Advanced Drawer Controller that manage drawer state.
class AdvancedDrawerController extends ValueNotifier<AdvancedDrawerValue> {
  /// Creates controller with initial drawer state. (Hidden by default)
  AdvancedDrawerController([AdvancedDrawerValue? value])
      : super(value ?? AdvancedDrawerValue.hidden());

  /// Shows drawer.
  void showDrawer() {
    value = AdvancedDrawerValue.visible();
    notifyListeners();
  }

  /// Hides drawer.
  void hideDrawer() {
    value = AdvancedDrawerValue.hidden();
    notifyListeners();
  }

  /// Toggles drawer.
  void toggleDrawer() {
    if (value.visible) {
      return hideDrawer();
    }

    return showDrawer();
  }
}
