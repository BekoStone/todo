import 'package:flutter/material.dart';

class BlockSlot extends StatelessWidget {
  final int value;
  final VoidCallback onTap;

  const BlockSlot({super.key, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('$value'),
      ),
    );
  }
}
