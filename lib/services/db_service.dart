import 'package:supabase_flutter/supabase_flutter.dart';

class DbService {
  /// AIの分析結果と元のメモをSupabaseに保存する関数
  static Future<void> insertCoinData(String memo, Map<String, dynamic> aiData) async {
    // 1. Supabaseのクライアント（通信機）を呼び出す
    final supabase = Supabase.instance.client;

    try {
      // 2. happy_coins テーブルにデータを挿入（Insert）
      await supabase.from('happy_coins').insert({
        'memo': memo, // ユーザーが入力した元のメモ
        'short_title': aiData['short_title'],
        'category': aiData['category'],
        'score_wakuwaku': aiData['score_wakuwaku'],
        'score_tsunagari': aiData['score_tsunagari'],
        'score_tassei': aiData['score_tassei'],
        'score_iyashi': aiData['score_iyashi'],
        'score_kotei': aiData['score_kotei'],
        'coin_type': aiData['coin_type'],
        'ai_comment': aiData['ai_comment'],
        // ※ もしSupabase側で created_at などのカラムを作っていれば、自動で日時が入ります
      });
      
      print('✅ Supabaseへのデータ保存（Insert）大成功！');
    } catch (e) {
      print('❌ Supabase保存エラー: $e');
      rethrow;
    }
  }
}