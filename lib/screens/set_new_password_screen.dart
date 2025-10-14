import 'package:flutter/material.dart';

class SetNewPasswordScreen extends StatefulWidget {
  const SetNewPasswordScreen({super.key});

  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _onDigitPress(String digit) {
    if (_passwordController.text.length >= 6) return;
    _passwordController.text += digit;
    setState(() {});
    if (_passwordController.text.length == 6) {
      _proceedToConfirmPassword();
    }
  }

  void _onDelete() {
    if (_passwordController.text.isEmpty) return;
    _passwordController.text = _passwordController.text.substring(0, _passwordController.text.length - 1);
    setState(() {});
  }

  void _proceedToConfirmPassword() {
    Navigator.of(context).pushNamed('/confirm-password', arguments: _passwordController.text);
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
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text(
                '设置新密码',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '请设置新的6位数字密码',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 40),
              
              // 密码输入框
              AbsorbPointer(
                absorbing: true,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    autofocus: false,
                    enabled: false,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white, 
                      fontSize: 18, 
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                    decoration: const InputDecoration(
                      hintText: '输入新密码',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                      fillColor: Colors.black,
                      filled: true,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // 数字键盘
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
                          const Expanded(child: SizedBox.shrink()),
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
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final Path path = PentagonClipper().getClip(size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}