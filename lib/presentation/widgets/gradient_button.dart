import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;

  const GradientButton({super.key, required this.child, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF6A5AE0), Color(0xFF19C5D8)]),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: Padding(padding: const EdgeInsets.all(12), child: Center(child: child)),
      ),
    );
  }
}
