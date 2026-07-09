import 'package:flutter/material.dart';

class MindmapScreen extends StatelessWidget {
  const MindmapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7EE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'マインドマップ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        foregroundColor: const Color(0xFF4A4A4A),
      ),
      body: const Center(
        child: Text(
          'マインドマップ画面\n(開発中)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF4A4A4A),
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
