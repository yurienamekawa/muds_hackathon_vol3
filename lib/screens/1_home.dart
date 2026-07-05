// ignore_for_file: file_names

import 'package:flutter/material.dart';
import '5_collection.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.savedNote = '',
    this.currentCoins = 128,
  });

  final String savedNote;
  final int currentCoins;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7EE),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text(
                '貯まったコイン',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A4A4A),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.monetization_on,
                    color: Colors.amber,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$currentCoins',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2B2B2B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '枚',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B2B2B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const PiggyBankCard(),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    Text(
                      '今日もポジティブを',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '貯めていこう！',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A4A4A),
                          ),
                        ),
                        Text(
                          ' 💗',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class PiggyBankCard extends StatelessWidget {
  const PiggyBankCard({
    super.key,
    this.currentCoins = 7,
  });

  final int currentCoins;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CollectionScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
        child: SizedBox(
          height: 340,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Image.asset(
                    'assets/piggy_bank.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: Color(0xFFF06292), size: 16),
                      SizedBox(width: 4),
                      Text(
                        'コレクションを見る',
                        style: TextStyle(
                          color: Color(0xFF4A4A4A),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
