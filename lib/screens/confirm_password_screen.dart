import 'package:flutter/material.dart';

class ConfirmPasswordScreen extends StatefulWidget {
  const ConfirmPasswordScreen({super.key});

  @override
  State<ConfirmPasswordScreen> createState() => _ConfirmPasswordScreenState();
}

class _ConfirmPasswordScreenState extends State<ConfirmPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  String? _originalPassword;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _originalPassword = ModalRoute.of(context)?.settings.arguments as String?;
  }

  void _onDigitPress(String digit) {
    if (_passwordController.text.length < 6) {
      setState(() {
        _passwordController.text += digit;
      });
      
      if (_passwordController.text.length == 6) {
        _verifyPassword();
      }
    }
  }

  void _onDelete() {
    if (_passwordController.text.isNotEmpty) {
      setState(() {
        _passwordController.text = _passwordController.text.substring(0, _passwordController.text.length - 1);
      });
    }
  }

  void _verifyPassword() {
    if (_passwordController.text == _originalPassword) {
      // 密码匹配，跳转到助记词输入页面，并传递密码参数
      Navigator.of(context).pushNamed('/import-mnemonic', arguments: _originalPassword);
    } else {
      // 密码不匹配，显示错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('密码不一致，请重新输入'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _passwordController.clear();
      });
    }
  }

  Widget _buildKey(String label, {VoidCallback? onTap}) {
    final bool isDelete = label.toLowerCase() == 'x';
    if (isDelete) {
      return Center(
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 32,
            height: 22,
            child: Stack(
              children: [
                ClipPath(
                  clipper: PentagonClipper(),
                  child: Container(color: Colors.black),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: PentagonBorderPainter(),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(3, -3),
                  child: const Center(
                    child: Text(
                      'x',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox.expand(
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 顶部 Logo 和名称
              const SizedBox(height: 12),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D3748),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.lock_outline, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 12),
              const Text(
                '确认密码',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),

              // 中间 PIN 输入框（禁用系统键盘）
              const SizedBox(height: 24),
              AbsorbPointer(
                absorbing: true,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    autofocus: false,
                    enabled: false, // 禁用系统键盘
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white, 
                      fontSize: 18, 
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                    decoration: const InputDecoration(
                      hintText: '再次输入密码',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                      fillColor: Colors.black,
                      filled: true,
                    ),
                  ),
                ),
              ),

              // 数字键盘
              const SizedBox(height: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: _buildKey('1', onTap: () => _onDigitPress('1'))),
                          const SizedBox(width: 8),
                          Expanded(child: _buildKey('2', onTap: () => _onDigitPress('2'))),
                          const SizedBox(width: 8),
                          Expanded(child: _buildKey('3', onTap: () => _onDigitPress('3'))),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: _buildKey('4', onTap: () => _onDigitPress('4'))),
                          const SizedBox(width: 8),
                          Expanded(child: _buildKey('5', onTap: () => _onDigitPress('5'))),
                          const SizedBox(width: 8),
                          Expanded(child: _buildKey('6', onTap: () => _onDigitPress('6'))),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: _buildKey('7', onTap: () => _onDigitPress('7'))),
                          const SizedBox(width: 8),
                          Expanded(child: _buildKey('8', onTap: () => _onDigitPress('8'))),
                          const SizedBox(width: 8),
                          Expanded(child: _buildKey('9', onTap: () => _onDigitPress('9'))),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: const SizedBox.shrink()),
                          const SizedBox(width: 8),
                          Expanded(child: _buildKey('0', onTap: () => _onDigitPress('0'))),
                          const SizedBox(width: 8),
                          Expanded(child: _buildKey('x', onTap: _onDelete)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PentagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final double w = size.width;
    final double h = size.height;
    final double inset = w * 0.12;
    final Path p = Path()
      ..moveTo(inset, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h)
      ..lineTo(inset, h)
      ..lineTo(0, h / 2)
      ..close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class PentagonBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final Path path = PentagonClipper().getClip(size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}