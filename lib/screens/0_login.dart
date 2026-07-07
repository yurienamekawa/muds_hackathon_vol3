import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false; // 登録モードかログインモードかを切り替えるスイッチ

  Future<void> _submit() async {
    final client = Supabase.instance.client;
    try {
      if (_isSignUp) {
        // 新規登録を実行
        final authResult = await client.auth.signUp(
          email: _emailController.text,
          password: _passwordController.text,
        );

        // 登録成功かつユーザー情報が取得できたら、usersテーブルにも行を追加
        if (authResult.user != null) {
          await client.from('users').insert({
            'id': authResult.user!.id,
            'user_name': _emailController.text,
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('登録完了！確認メールをチェックしてください')));
        }
      } else {
        // ログインを実行
        await client.auth.signInWithPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
      // 成功したら main.dart の StreamBuilder が自動で画面を RootScreen に切り替えます
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラー: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isSignUp ? '新規登録' : 'ログイン')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController, 
              decoration: const InputDecoration(labelText: 'Email')
            ),
            TextField(
              controller: _passwordController, 
              decoration: const InputDecoration(labelText: 'Password'), 
              obscureText: true
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: Text(_isSignUp ? '登録する' : 'ログインする'),
            ),
            TextButton(
              onPressed: () => setState(() => _isSignUp = !_isSignUp),
              child: Text(_isSignUp ? 'すでに登録済みの方はこちら' : '初めての方はこちら（新規登録）'),
            ),
          ],
        ),
      ),
    );
  }
}