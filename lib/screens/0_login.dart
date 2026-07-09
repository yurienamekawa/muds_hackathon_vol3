// ignore_for_file: file_names

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
  bool _isLoading = false;
  String? _errorText;
  String? _infoText;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorText = 'メールアドレスとパスワードを入力してください。';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
      _infoText = null;
    });

    try {
      final response = _isSignUp
          ? await Supabase.instance.client.auth.signUp(
              email: email,
              password: password,
            )
          : await Supabase.instance.client.auth.signInWithPassword(
              email: email,
              password: password,
            );

      // デバッグ: Supabaseのレスポンスをコンソールに出力
      // 実行端末のログ（flutter run）で確認してください。
      // ignore: avoid_print
      print('Supabase auth response: $response');

      if (response.session != null) {
        // セッションが取得できればログイン成功
        if (mounted) {
          setState(() {
            _errorText = null;
          });
        }
        return;
      }
      final client = Supabase.instance.client;

      if (_isSignUp) {
        final response = await client.auth.signUp(
          email: email,
          password: password,
        );

        if (response.user != null) {
          try {
            await client.from('users').insert({
              'id': response.user!.id,
              'user_name': email,
            });
          } catch (e) {
            debugPrint('usersテーブルへの保存に失敗: $e');
          }
        }

        if (mounted) {
          setState(() {
            _infoText = '認証メールを送信しました。メールボックスをご確認ください。';
            _errorText = null;
            _isSignUp = false;
          });
        }
      } else {
        await client.auth.signInWithPassword(email: email, password: password);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorText = _messageFromException(e);
          _infoText = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _messageFromException(Object e) {
    final message = e.toString().toLowerCase();

    if (message.contains('invalid login credentials') ||
        message.contains('invalid_credentials')) {
      return 'メールアドレスまたはパスワードが正しくありません。';
    }

    if (message.contains('email not confirmed') ||
        message.contains('email_not_confirmed')) {
      return 'メール認証が完了していません。受信箱をご確認ください。';
    }

    if (message.contains('user already registered') ||
        message.contains('user_already_exists')) {
      return 'このメールアドレスはすでに登録されています。';
    }

    if (message.contains('password') && message.contains('weak')) {
      return 'パスワードは6文字以上で設定してください。';
    }

    return 'ログインに失敗しました。入力内容を確認してください。';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;
    final horizontalPadding = isCompact ? 20.0 : 24.0;
    final maxWidth = screenWidth < 520 ? screenWidth : 480.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7EE),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: isCompact ? 24 : 40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: isCompact ? 8 : 24),
                  Text(
                    _isSignUp ? '新規登録' : 'ログイン',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isCompact ? 28 : 32,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  SizedBox(height: isCompact ? 8 : 12),
                  Text(
                    'ポジティブメモを保存して、分析とコインを貯めよう。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isCompact ? 13.5 : 15,
                      color: const Color(0xFF6B6B6B),
                      height: 1.6,
                    ),
                  ),
                  SizedBox(height: isCompact ? 24 : 40),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'メールアドレス',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'パスワード',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_errorText != null || _infoText != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorText ?? _infoText ?? '',
                      style: TextStyle(
                        color: _errorText != null
                            ? Colors.redAccent
                            : const Color(0xFF2E7D32),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5A79),
                      padding: EdgeInsets.symmetric(
                        vertical: isCompact ? 14 : 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _isSignUp ? '登録する' : 'ログインする',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isCompact ? 15 : 16,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _isSignUp = !_isSignUp;
                              _errorText = null;
                              _infoText = null;
                            });
                          },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: isCompact ? 14 : 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _isSignUp ? 'ログインへ' : '新規登録へ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isCompact ? 15 : 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
