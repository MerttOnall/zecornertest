import 'package:flutter/material.dart';

class FirstScreen extends StatelessWidget {
  const FirstScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/image/app1.jpg',
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) => Container(
        color: const Color(0xFF1a365d),
        child: const Center(
          child: Icon(Icons.home_work, size: 80, color: Colors.white70),
        ),
      ),
    );
  }
}
