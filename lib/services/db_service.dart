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

  static Future<int> getTodayCoinCount() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return 0;

    final data = await client
        .from('happy_coins')
        .select('created_at')
        .eq('user_id', user.id);

    int count = 0;
    final today = DateTime.now();
    for (var record in data as List) {
      final createdStr = record['created_at'];
      if (createdStr != null) {
        final created = DateTime.tryParse(createdStr.toString())?.toLocal();
        if (created != null &&
            created.year == today.year &&
            created.month == today.month &&
            created.day == today.day) {
          count++;
        }
      }
    }
    return count;
  }

  static Future<List<Map<String, dynamic>>> getRecentCoinRecords() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return [];

    final data = await client
        .from('happy_coins')
        .select('id, coin_type, created_at')
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(30);

    return (data as List<dynamic>?)?.cast<Map<String, dynamic>>().toList() ?? [];
  }
}