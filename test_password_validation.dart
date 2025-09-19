import 'package:flutter/material.dart';
import 'lib/constants/password_constants.dart';

void main() {
  runApp(const PasswordValidationTestApp());
}

class PasswordValidationTestApp extends StatelessWidget {
  const PasswordValidationTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '密码验证测试',
      theme: ThemeData.dark(),
      home: const PasswordValidationTestScreen(),
    );
  }
}

class PasswordValidationTestScreen extends StatefulWidget {
  const PasswordValidationTestScreen({super.key});

  @override
  State<PasswordValidationTestScreen> createState() =>
      _PasswordValidationTestScreenState();
}

class _PasswordValidationTestScreenState
    extends State<PasswordValidationTestScreen> {
  final _passwordController = TextEditingController();
  String? _validationResult;

  void _validatePassword() {
    final password = _passwordController.text;
    String result;

    if (password.isEmpty) {
      result = PasswordConstants.passwordEmptyError;
    } else if (password.length != PasswordConstants.passwordLength) {
      result = PasswordConstants.passwordLengthError;
    } else {
      result = '✅ 密码验证通过！';
    }

    setState(() {
      _validationResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2D3A),
        title: const Text('密码验证测试', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '测试8位密码验证',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '要求：密码必须恰好是${PasswordConstants.passwordLength}位',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),

            // 密码输入框
            const Text(
              '输入密码：',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '输入密码进行测试',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF2A2D3A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixText: '${_passwordController.text.length}/8',
                suffixStyle: TextStyle(
                  color: _passwordController.text.length == 8
                      ? Colors.green
                      : Colors.orange,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _validationResult = null;
                });
              },
            ),
            const SizedBox(height: 24),

            // 验证按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _validatePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '验证密码',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 验证结果
            if (_validationResult != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _validationResult!.startsWith('✅')
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _validationResult!.startsWith('✅')
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                child: Text(
                  _validationResult!,
                  style: TextStyle(
                    color: _validationResult!.startsWith('✅')
                        ? Colors.green
                        : Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // 测试用例
            const Text(
              '测试用例：',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            ..._buildTestCases(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTestCases() {
    final testCases = [
      {'input': '', 'expected': '请输入密码'},
      {'input': '123', 'expected': '密码必须是8位'},
      {'input': '1234567', 'expected': '密码必须是8位'},
      {'input': '12345678', 'expected': '✅ 密码验证通过！'},
      {'input': '123456789', 'expected': '密码必须是8位'},
      {'input': 'abcd1234', 'expected': '✅ 密码验证通过！'},
      {'input': 'password123', 'expected': '密码必须是8位'},
    ];

    return testCases.map((testCase) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2D3A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                '输入: "${testCase['input']}"',
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Text(
                '期望: ${testCase['expected']}',
                style: TextStyle(
                  color: testCase['expected']!.startsWith('✅')
                      ? Colors.green
                      : Colors.orange,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}
