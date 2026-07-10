# 🐷 アプリ名 (App Name)
※I♡HAPPY

## 💡 アプリの概要
日々の些細な出来事やモヤモヤをAI（Gemini）がポジティブなコインに変換し、ガラスのブタの貯金箱に貯めていく、心温まる新感覚の日記＆自己肯定感アップアプリです。
スマホを傾けると貯金箱の中のコインが物理演算でリアルに動き、視覚的にも楽しめるインタラクティブなUIを採用しています。

## ✨ 主な機能

- **ポジティブ変換日記 (AI 生成)**
  入力した出来事をGoogle Gemini APIが自動でポジティブな視点に変換し、カラフルな「コイン」として生成します。
- **インタラクティブなガラスの貯金箱 (物理演算)**
  Flame / Forge2Dエンジンを活用し、スマホのジャイロセンサー（傾き）に合わせて貯金箱内のコインがリアルに転がります。
- **愚痴連打モード (ストレス発散機能)**
  どうしてもポジティブになれない時は、専用の「Venting Mode」へ。入力した愚痴がドス黒いコインとして実体化し、ユーザー自身がタップで連打して粉々に打ち砕くことで、ストレスを発散できます。
- **振り返り＆分析 (Analytics & Collection)**
  過去に集めたポジティブなコインを振り返るコレクション画面や、日々の感情の推移を可視化するグラフ機能（FL Chart）を搭載しています。

## 🛠 技術スタック

**【フロントエンド (Framework)】**
- **Flutter** (Dart) - iOS/Android/Web 対応のクロスプラットフォーム開発

**【バックエンド・BaaS】**
- **Supabase** (`supabase_flutter`) - 認証、データベース（日記・ユーザーデータ保存）
- **Firebase Hosting** - Webアプリとしてのデプロイ

**【AI / 物理エンジン】**
- **Google Gemini API** (`google_generative_ai`) - ポジティブ変換AI
- **Flame / Forge2D** (`flame`, `flame_forge2d`) - 2D物理演算エンジン
- **Sensors Plus** (`sensors_plus`) - ジャイロセンサーによる重力制御

**【UI / 機能拡張】**
- **FL Chart** (`fl_chart`) - 分析グラフの描画
- **Share Plus / Screenshot** - 画像シェア機能
- **Shared Preferences** - ローカル状態管理

## 🚀 ローカルでの動かし方

1. リポジトリをクローンします
```bash
git clone https://github.com/yurienamekawa/muds_hackathon_vol3.git
cd muds_hackathon_vol3
```

2. パッケージをインストールします
```bash
flutter pub get
```

3. 環境変数（`.env`）を設定します
プロジェクトのルートディレクトリに `.env` ファイルを作成し、以下のAPIキーを設定してください。
```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
GEMINI_API_KEY=your_gemini_api_key
```

4. アプリを実行します
```bash
flutter run
```
