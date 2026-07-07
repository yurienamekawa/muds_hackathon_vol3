import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/0_login.dart';
import 'screens/1_home.dart';
import 'screens/2_input.dart';
import 'screens/4_analytics.dart';
import 'services/ai_service.dart';
import 'services/db_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  StreamSubscription? _authSubscription;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _isLoggedIn = client.auth.currentUser != null;
    _isLoading = false;
    _authSubscription = client.auth.onAuthStateChange.listen((event) {
      if (!mounted) return;
      setState(() {
        _isLoggedIn = event.session != null;
      });
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'muds_hackathon_vol3',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: _isLoading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : (_isLoggedIn ? const RootScreen() : const LoginScreen()),
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _selectedIndex = 0;
  String _savedText = '';
  int _currentCoins = 7;

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _saveText(String text) {
    setState(() {
      _savedText = text;
      _selectedIndex = 0;
    });
  }

  void _goBack() {
    setState(() {
      _selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(savedNote: _savedText, currentCoins: _currentCoins),
      InputScreen(initialText: _savedText, onSave: _saveText, onBack: _goBack),
      const AnalyticsScreen(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        selectedItemColor: const Color(0xFFFF5A79),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: '入力'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '分析'),
        ],
      ),
    );
  }
}
