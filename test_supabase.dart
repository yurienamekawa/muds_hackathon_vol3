import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  
  final client = Supabase.instance.client;
  
  try {
    // Attempt to insert dummy data with the same structure
    final data = {
      'user_id': '00000000-0000-0000-0000-000000000000', // dummy UUID
      'memo': 'test',
      'short_title': 'test title',
      'category': '日常・景色',
      'score_wakuwaku': 5,
      'score_tsunagari': 5,
      'score_tassei': 5,
      'score_iyashi': 5,
      'score_kotei': 5,
      'coin_type': 'sunny_blue',
      'ai_comment': 'Great job!',
    };
    
    print('Attempting to insert...');
    await client.from('happy_coins').insert(data);
    print('Insert succeeded!');
  } catch (e) {
    print('Insert failed: $e');
  }
}
