import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/0_login.dart';

import 'screens/0_login.dart';
// 各画面のインポート
import 'screens/1_home.dart';
import 'screens/2_input.dart';
import 'screens/4_analytics.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // .envファイルの読み込み
  await dotenv.load(fileName: ".env");

  // Supabaseの初期化
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'muds_hackathon_vol3',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    _isLoggedIn = user != null;
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        final isSignedIn = data.event == AuthChangeEvent.signedIn ||
            Supabase.instance.client.auth.currentUser != null;
        setState(() {
          _isLoggedIn = isSignedIn;
          _isLoading = false;
        });
      },
      // 🌟 ここで「ログインしているか？」を常に監視する仕組みに切り替えます
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          // セッション情報があればログイン済みとみなす
          if (snapshot.hasData && snapshot.data?.session != null) {
            return const RootScreen();
          }
          // なければログイン画面へ
          return const LoginScreen();
        },
      ),
    );
    _isLoading = false;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _onLoginSuccess() {
    setState(() {
      _isLoggedIn = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _isLoggedIn ? const RootScreen() : LoginScreen(onLoginSuccess: _onLoginSuccess);
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
  final int _currentCoins = 128; // constは外しました

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
      const HomeScreen(), // 引数を削除して、const を付けます！
      InputScreen(
        initialText: _savedText,
        onSave: _saveText,
        onBack: _goBack,
      ),
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: '入力'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '分析'),
        ],
      ),
    );
  }
}