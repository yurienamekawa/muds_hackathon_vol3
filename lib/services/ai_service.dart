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

  /// AIコーチング（自己分析チャット）用の関数
  static Future<String> chatCoaching(List<Map<String, String>> messages, String mindmapData) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      throw Exception('APIキーが見つかりません。');
    }

    // システムインストラクション（役割定義）を設定
    final model = GenerativeModel(
      model: _modelName, 
      apiKey: apiKey,
      systemInstruction: Content.system('''
あなたはユーザーの自己分析をサポートする優しいコーチ（ブタの貯金箱のキャラクター「ハピブー」）です。
以下のマインドマップデータをもとに、ユーザーの幸せの傾向を分析し、対話を通して深掘りを手伝ってください。
親しみやすい言葉遣いを使用し、絵文字をたくさん使ってください。

【重要ルール】
・スマートフォンで読みやすいように、1回の返信は最大でも150文字〜200文字程度と「非常に短く、簡潔に」してください。
・長文の解説や箇条書きの羅列は避け、チャットらしい短いキャッチボールを心がけてください。
・毎回、最後に自己分析を深める「問い」を1つだけ投げかけてください。

【ユーザーの幸せマインドマップデータ（時間帯 -> 出来事 -> なぜ幸せに感じたか）】
$mindmapData
'''),
    );

    // 履歴メッセージをContentオブジェクトに変換
    final contents = messages.map((m) {
      return Content(m['role'] == 'user' ? 'user' : 'model', [TextPart(m['content']!)]);
    }).toList();

    try {
      final response = await model.generateContent(contents);
      return response.text?.trim() ?? '';
    } catch (e) {
      print('Gemini Chat Error: $e');
      rethrow;
    }
  }

  /// チャット履歴から「マインドマップに追加する気づき」を抽出する関数
  static Future<String> summarizeChatToNodes(List<Map<String, String>> messages) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) throw Exception('APIキーが見つかりません。');

    final model = GenerativeModel(
      model: _modelName, 
      apiKey: apiKey,
      systemInstruction: Content.system('''
あなたは自己分析の要約AIです。
提供されるコーチングの対話履歴から、ユーザーが最終的にたどり着いた「幸せの新しい気づき」や「コアバリュー」を、
マインドマップの1つのノード（枝）として追加できるような【20文字以内の短い1文】で抽出してください。
出力は抽出したテキストのみとし、それ以外の文字や解説は一切含めないでください。
例：「一人静かな時間が心の支え」「美味しいご飯で全てリセット」
'''),
    );

    final contents = messages.map((m) {
      return Content(m['role'] == 'user' ? 'user' : 'model', [TextPart(m['content']!)]);
    }).toList();

    try {
      final response = await model.generateContent(contents);
      return response.text?.trim() ?? '自己分析の新たな気づき';
    } catch (e) {
      print('Gemini Chat Error: $e');
      return 'AIとの対話の気づき';
    }
  }
}