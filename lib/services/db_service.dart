import 'package:supabase_flutter/supabase_flutter.dart';

class DbService {
  // db_service.dart
  static Future<void> insertCoinData(String memo, Map<String, dynamic> aiData) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser; // 🌟 ログイン中のユーザー情報を取得

    if (user == null) {
      throw Exception("ログインしていません"); // 必要に応じてログインへ促す
    }

    final data = {
      'user_id': user.id, // 🌟 ここで紐付け！
      'memo': memo,
      ...aiData,
    };

    await client.from('happy_coins').insert(data);
  }
}