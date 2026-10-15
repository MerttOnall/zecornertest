import 'package:flutter/material.dart';

class ThirdScreen extends StatelessWidget {
  const ThirdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/image/app3.jpg',
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) => Container(
        color: const Color(0xFF234e52),
        child: const Center(
          child: Icon(Icons.rocket_launch, size: 80, color: Colors.white70),
        ),
      ),
    );
  }
}
