import 'package:flutter/widgets.dart';

typedef LayoutBuilderFn = Widget Function(BuildContext, BoxConstraints);

class ResponsiveLayout extends StatelessWidget {
  final LayoutBuilderFn builder;
  const ResponsiveLayout({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: builder);
  }
}
