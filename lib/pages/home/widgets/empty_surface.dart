import 'package:flutter/material.dart';
import '../../home/theme.dart';

class EmptySurface extends StatelessWidget {
  final String message;
  const EmptySurface({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder:
          (context, c) => Container(
            color: Colors.white,
            width: double.infinity,
            height: c.maxHeight,
            child: Center(
              child: Text(message, style: const TextStyle(color: kBgTop)),
            ),
          ),
    );
  }
}
