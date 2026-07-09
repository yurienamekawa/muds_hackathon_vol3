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
- "category": 次の9つから最も適切な1つを選んでください。
  [日常・景色]: 毎日のちいさな景色や日常の幸せ（散歩、青空など）
  [友達・対人]: 友達や大切な人との交流（カフェ、会話など）
  [家族]: 家族とのあたたかい時間（家族団らん、手伝いなど）
  [仕事・学校]: 日々の頑張りや達成感（褒められた、テストなど）
  [食事]: 美味しい食事やごはんの時間（美味しいもの、自炊など）
  [趣味・推し]: 好きなことに触れる時間（音楽、読書、映画など）
  [運動・健康]: 体を動かしたときのすっきり感（筋トレ、ランニングなど）
  [お出かけ]: 新しい風景や外出でのリフレッシュ（旅行、買い物など）
  [自己成長]: 挑戦や学びを通じた成長（新しい発見、挑戦など）
- "score_wakuwaku", "score_tsunagari", "score_tassei", "score_iyashi", "score_kotei": 各1〜5の整数
- "coin_type": 選択したカテゴリに対応する以下のIDを1つ出力してください。
  日常・景色 -> sunny_blue, 友達・対人 -> heart_pink, 家族 -> home_orange, 仕事・学校 -> star_yellow, 食事 -> food_green, 趣味・推し -> music_purple, 運動・健康 -> run_teal, お出かけ -> car_indigo, 自己成長 -> bulb_red
- "ai_comment": 40文字以内の肯定コメント

メモ: "$userMemo"
''';
  }
}