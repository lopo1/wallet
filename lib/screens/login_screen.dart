import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../widgets/pin_code_input.dart';
import '../constants/password_constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      final success =
          await walletProvider.loginWithPassword(_passwordController.text);

      if (success) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('密码错误，请重试'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('登录失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B23),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  48,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 1),
                  // Logo or App Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Welcome Back Title
                  const Text(
                    '欢迎回来',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Subtitle
                  const Text(
                    '请输入密码以解锁您的钱包',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Login Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Password Field - 8位密码输入
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '请输入您的8位钱包密码',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            PinCodeInput(
                              controller: _passwordController,
                              length: 8,
                              obscureText: !_isPasswordVisible,
                              onChanged: (value) {
                                // 实时验证
                                setState(() {});
                              },
                              onCompleted: (value) {
                                // 密码输入完成后自动登录
                                _login();
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return PasswordConstants.passwordEmptyError;
                                }
                                if (value.length !=
                                    PasswordConstants.pinCodeLength) {
                                  return PasswordConstants.pinCodeLengthError;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // 显示/隐藏密码切换按钮
                            Center(
                              child: TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                                label: Text(
                                  _isPasswordVisible ? '隐藏密码' : '显示密码',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              disabledBackgroundColor:
                                  const Color(0xFF6366F1).withOpacity(0.5),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text(
                                    '解锁钱包',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Forgot Password / Reset Wallet
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF2A2D3A),
                          title: const Text(
                            '重置钱包',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: const Text(
                            '如果您忘记了密码，需要删除当前钱包并重新创建或导入。\n\n警告：这将删除所有本地数据，请确保您有助记词备份。',
                            style: TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text(
                                '取消',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                final walletProvider =
                                    Provider.of<WalletProvider>(context,
                                        listen: false);
                                await walletProvider.resetWallet();
                                if (mounted) {
                                  Navigator.of(context)
                                      .pushReplacementNamed('/welcome');
                                }
                              },
                              child: const Text(
                                '重置',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text(
                      '忘记密码？重置钱包',
                      style: TextStyle(
                        color: Color(0xFF6366F1),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}