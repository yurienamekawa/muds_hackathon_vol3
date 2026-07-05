import 'package:supabase_flutter/supabase_flutter.dart';

class DbService {
  static Future<void> insertCoinData(String memo, Map<String, dynamic> aiData) async {
    final client = Supabase.instance.client;

    // AI分析結果とメモを合体させる
    final data = {
      'memo': memo,
      ...aiData,
    };

    // ログインユーザーのチェックは行わず、そのまま insert する
    await client.from('happy_coins').insert(data);
    
  }
}