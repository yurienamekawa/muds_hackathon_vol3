import 'package:flutter/material.dart';

import 'screens/1_home.dart';
import 'screens/2_input.dart';
import 'screens/4_analytics.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/ai_service.dart';
import 'services/db_service.dart'; // 🌟 これを追加！

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // .envファイルの読み込み
  await dotenv.load(fileName: ".env");

  // 🌟 Supabaseの初期化
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
      home: const RootScreen(),
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
  int _currentCoins = 128;

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
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            label: '入力',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: '分析',
          ),
        ],
      ),
    );
  }
}

      title: 'Gemini API Test',
      home: Scaffold(
        appBar: AppBar(title: const Text('AI分析 ＆ データベース保存テスト')),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              print('🌟 処理開始！');
              try {
                // テスト用のメモ
                String memo = '今日は天気が良くて、お気に入りの服を着てお出かけできたので最高の気分でした！';
                
                // 1. AIに分析してもらう
                final result = await AiService.analyzeHappyMemo(memo);
                print('✅ AI分析成功！結果：');
                print(result); 
                
                // 2. その結果と元のメモをSupabaseに保存する！
                await DbService.insertCoinData(memo, result);
                
              } catch (e) {
                print('❌ エラーが発生しました：$e');
              }
            },
            child: const Text('AI分析 ＆ DBに保存する！'),
          ),
        ),
      ),
    );
  }
}
