import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiService {
  static const _modelName = 'gemini-2.5-flash';

  /// ユーザーのメモを分析し、Mapデータを返す関数
  static Future<Map<String, dynamic>> analyzeHappyMemo(String userMemo) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      throw Exception('APIキーが見つかりません。');
    }

    final model = GenerativeModel(model: _modelName, apiKey: apiKey);

    try {
      final response = await model.generateContent([Content.text(_buildPrompt(userMemo))]);
      final responseText = response.text?.trim();

      if (responseText == null || responseText.isEmpty) {
        throw Exception('Geminiからの応答が空でした。');
      }

      // JSON以外の不要な文字を除去
      final cleanText = responseText
          .replaceAll(RegExp(r'```json|```', caseSensitive: false), '')
          .trim();
      
      return jsonDecode(cleanText) as Map<String, dynamic>;
    } catch (e) {
      print('Gemini API Error: $e');
      rethrow;
    }
  }

  /// プロンプト生成用のヘルパーメソッド
  static String _buildPrompt(String userMemo) {
    return '''
あなたはユーザーの幸せな出来事を分析する、温かくてポジティブなAIアシスタントです。
提供されたメモを分析し、以下の指定JSONフォーマットのみで出力してください。
マークダウン記法(```)は使わず、{ から始まる純粋なJSON文字列だけを出力してください。

【出力キー条件】
- "short_title": 10文字以内のタイトル
- "category": [日常・景色, 友達・対人, 家族, 仕事・学校, 食事, 趣味・推し, 運動・健康, お出かけ, 自己成長] から1つ
- "score_wakuwaku", "score_tsunagari", "score_tassei", "score_iyashi", "score_kotei": 各1〜5の整数
- "coin_type": [heart_pink, star_blue, star_yellow, leaf_green, star_purple, flower_orange, flower_pink, note_blue] から1つ
- "ai_comment": 40文字以内の肯定コメント

メモ: "$userMemo"
''';
  }
}