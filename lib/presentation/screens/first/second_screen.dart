import 'package:flutter/material.dart';

class SecondScreen extends StatelessWidget {
  const SecondScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/image/app2.jpg',
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) => Container(
        color: const Color(0xFF553c9a),
        child: const Center(
          child: Icon(Icons.compare_arrows, size: 80, color: Colors.white70),
        ),
      ),
    );
  }
}
