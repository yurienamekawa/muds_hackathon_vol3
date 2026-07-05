import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiService {
  /// ユーザーのメモを読み込み、感情分析とカテゴリ分けを行ったMapデータを返す関数
  static Future<Map<String, dynamic>> analyzeHappyMemo(String userMemo) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      throw Exception('APIキーが見つかりません。.envファイルを確認してください。');
    }

    
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );

    // 3. あやかさんが設計した最強のプロンプト
    final prompt = '''
あなたはユーザーの幸せな出来事を分析する、温かくてポジティブなAIアシスタントです。
ユーザーから提供された「嬉しかったこと」のメモを分析し、以下の指定されたJSONフォーマットでのみ出力してください。
重要: マークダウン（```json など）は一切使わず、必ず { から始まる純粋なJSON文字列だけを出力してください。

【出力JSONのキーと条件】
1. "short_title": メモの内容を要約した10文字以内の具体的なタイトル。
2. "category": [日常・景色, 友達・対人, 家族, 仕事・学校, 食事, 趣味・推し, 運動・健康, お出かけ, 自己成長] から最も適切なものを必ず1つ選択。
3. "score_wakuwaku": ワクワク度（1〜5の整数）
4. "score_tsunagari": つながり度（1〜5の整数）
5. "score_tassei": 達成感（1〜5の整数）
6. "score_iyashi": 癒やし度（1〜5の整数）
7. "score_kotei": 自己肯定感（1〜5の整数）
8. "coin_type": [heart_pink, star_blue, star_yellow, leaf_green, star_purple, flower_orange, flower_pink, note_blue] から最も適切なものを1つ選択。
9. "ai_comment": ユーザーのメモに対する、明日も楽しみになるような共感と肯定のコメント（40文字以内）。

ユーザーのメモ：
「$userMemo」
''';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      final responseText = response.text;

      if (responseText == null) {
        throw Exception('Geminiからの応答が空でした。');
      }

      // 🌟 AIが余計な記号をつけてきた時のための防弾処理（力技で綺麗にする）
      final cleanText = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      
      final Map<String, dynamic> result = jsonDecode(cleanText);
      return result;
      
    } catch (e) {
      print('Gemini API Error: $e');
      rethrow;
    }
  }
}