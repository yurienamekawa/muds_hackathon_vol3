import 'package:flutter/material.dart';
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