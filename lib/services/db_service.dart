import 'package:supabase_flutter/supabase_flutter.dart';

class DbService {
  // db_service.dart
  static Future<void> insertCoinData(String memo, Map<String, dynamic> aiData) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      throw Exception("ログインしていません");
    }

    final allowedKeys = [
      'short_title',
      'category',
      'score_wakuwaku',
      'score_tsunagari',
      'score_tassei',
      'score_iyashi',
      'score_kotei',
      'coin_type',
      'ai_comment',
    ];

    final filteredAiData = Map.fromEntries(
      aiData.entries.where((e) => allowedKeys.contains(e.key)).map((e) {
        if (e.key.startsWith('score_')) {
          if (e.value is String) {
            return MapEntry(e.key, int.tryParse(e.value) ?? 1);
          } else if (e.value is num) {
            return MapEntry(e.key, (e.value as num).toInt());
          }
        }
        return e;
      }),
    );

    final data = {
      'user_id': user.id,
      'memo': memo,
      ...filteredAiData,
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