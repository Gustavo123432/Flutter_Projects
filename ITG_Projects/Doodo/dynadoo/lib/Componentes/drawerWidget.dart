import 'package:flutter/material.dart';

import '../Responsive/responsive_Layout.dart';
import 'drawer.dart';

class DrawerWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final layoutType = ResponsiveLayoutPage.getLayoutType(MediaQuery.of(context).size.width);

    // Verifica se o tipo de layout é móvel
    if (layoutType == LayoutType.mobile) {
      return MyDrawer(currentLayoutType: 'mobile'); // String correspondente ao valor 'mobile' do enum LayoutType
    } else {
      return MyDrawer(currentLayoutType: 'desktop'); // String correspondente ao valor 'desktop' do enum LayoutType
    }
  }
}
