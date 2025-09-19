import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'lib/providers/wallet_provider.dart';

void main() {
  runApp(const MnemonicDuplicationTestApp());
}

class MnemonicDuplicationTestApp extends StatelessWidget {
  const MnemonicDuplicationTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => WalletProvider(),
      child: MaterialApp(
        title: '助记词重复检查测试',
        theme: ThemeData.dark(),
        home: const MnemonicDuplicationTestScreen(),
      ),
    );
  }
}

class MnemonicDuplicationTestScreen extends StatefulWidget {
  const MnemonicDuplicationTestScreen({super.key});

  @override
  State<MnemonicDuplicationTestScreen> createState() =>
      _MnemonicDuplicationTestScreenState();
}

class _MnemonicDuplicationTestScreenState
    extends State<MnemonicDuplicationTestScreen> {
  final _mnemonicController = TextEditingController();
  bool _isChecking = false;
  String? _checkResult;

  Future<void> _checkMnemonic() async {
    final mnemonic = _mnemonicController.text.trim();
    if (mnemonic.isEmpty) {
      setState(() {
        _checkResult = '请输入助记词';
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _checkResult = null;
    });

    try {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      final isAlreadyImported =
          await walletProvider.isMnemonicAlreadyImported(mnemonic);

      if (isAlreadyImported) {
        final existingWalletName =
            await walletProvider.getWalletNameByMnemonic(mnemonic);
        setState(() {
          _checkResult = '❌ 此助记词已经导入过了\n钱包名称：$existingWalletName';
        });
      } else {
        setState(() {
          _checkResult = '✅ 此助记词可以导入';
        });
      }
    } catch (e) {
      setState(() {
        _checkResult = '❌ 检查失败: $e';
      });
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  Future<void> _createTestWallet() async {
    try {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      await walletProvider.createWallet(
        name: '测试钱包 ${DateTime.now().millisecondsSinceEpoch}',
        password: '12345678',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('测试钱包创建成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2D3A),
        title: const Text('助记词重复检查测试', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '测试助记词重复检查功能',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '先创建一个测试钱包，然后尝试用相同的助记词再次导入',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),

            // 创建测试钱包按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _createTestWallet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '创建测试钱包',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 当前钱包信息
            Consumer<WalletProvider>(
              builder: (context, walletProvider, child) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2D3A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '当前钱包信息：',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '钱包总数: ${walletProvider.wallets.length}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      if (walletProvider.currentWallet != null) ...[
                        Text(
                          '当前钱包: ${walletProvider.currentWallet!.name}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '助记词（用于测试）:',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1B23),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(
                            walletProvider.currentWallet!.mnemonic,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // 助记词输入框
            const Text(
              '输入助记词进行检查：',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _mnemonicController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '输入助记词，用空格分隔',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF2A2D3A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 检查按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isChecking ? null : _checkMnemonic,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isChecking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        '检查助记词',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // 检查结果
            if (_checkResult != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _checkResult!.startsWith('✅')
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _checkResult!.startsWith('✅')
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                child: Text(
                  _checkResult!,
                  style: TextStyle(
                    color: _checkResult!.startsWith('✅')
                        ? Colors.green
                        : Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mnemonicController.dispose();
    super.dispose();
  }
}
