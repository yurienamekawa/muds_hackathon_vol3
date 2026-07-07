import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
  });

  final VoidCallback onLoginSuccess;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  Future<void> _signIn() async {
    widget.onLoginSuccess();
  }

  Future<void> _signUp() async {
    await _authenticate(signUp: true);
  }

  Future<void> _authenticate({required bool signUp}) async {
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
    });

    try {
      final response = signUp
          ? await Supabase.instance.client.auth.signUp(
              email: email,
              password: password,
            )
          : await Supabase.instance.client.auth.signInWithPassword(
              email: email,
              password: password,
            );

      final session = response.session;
      if (session != null) {
        widget.onLoginSuccess();
        return;
      }

      if (signUp && response.user != null && response.user!.email != null) {
        setState(() {
          _errorText = '作成しました。ログインしてください。';
        });
      } else {
        setState(() {
          _errorText = signUp
              ? 'アカウント作成に失敗しました。すでに登録済みの可能性があります。'
              : 'ログインに失敗しました。メールアドレスとパスワードを確認してください。';
        });
      }
    } catch (e) {
      setState(() {
        _errorText = signUp
            ? 'アカウント作成でエラーが発生しました。もう一度試してください。'
            : 'ログインでエラーが発生しました。もう一度試してください。';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7EE),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const Text(
                  'ログイン',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'ポジティブメモを保存して、分析とコインを貯めよう。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF6B6B6B),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),
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
                if (_errorText != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorText!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5A79),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'ログイン',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    '新規作成',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
