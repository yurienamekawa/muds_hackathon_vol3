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
  bool _isSignUp = false;

  Future<void> _submit() async {
    final client = Supabase.instance.client;
    try {
      if (_isSignUp) {
        final authResult = await client.auth.signUp(
          email: _emailController.text,
          password: _passwordController.text,
        );
        if (authResult.user != null) {
          await client.from('users').insert({
            'id': authResult.user!.id,
            'user_name': _emailController.text,
          });
        }
      } else {
        await client.auth.signInWithPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
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
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            ElevatedButton(onPressed: _submit, child: Text(_isSignUp ? '登録' : 'ログイン')),
            TextButton(onPressed: () => setState(() => _isSignUp = !_isSignUp), child: Text(_isSignUp ? 'ログインへ' : '新規登録へ')),
          ],
        ),
      ),
    );
  }
}