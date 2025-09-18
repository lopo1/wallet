import 'package:flutter/material.dart';
import 'lib/services/solana_wallet_service.dart';
import 'lib/models/solana_transaction.dart';

/// 简单的测试文件来验证Solana gas费功能
void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Solana Gas费测试',
      home: TestScreen(),
    );
  }
}

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  late SolanaWalletService _solanaService;
  String _status = '初始化中...';

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  void _initializeService() {
    try {
      _solanaService = SolanaWalletService('https://api.devnet.solana.com');
      setState(() {
        _status = '服务初始化成功';
      });
    } catch (e) {
      setState(() {
        _status = '初始化失败: $e';
      });
    }
  }

  Future<void> _testNetworkStatus() async {
    setState(() {
      _status = '获取网络状态中...';
    });

    try {
      final networkStatus = await _solanaService.getNetworkStatus();
      setState(() {
        _status = '网络状态: ${networkStatus['congestionLevel']}';
      });
    } catch (e) {
      setState(() {
        _status = '获取网络状态失败: $e';
      });
    }
  }

  Future<void> _testFeeEstimation() async {
    setState(() {
      _status = '估算费用中...';
    });

    try {
      // 使用测试助记词和地址
      const testMnemonic =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      const testToAddress = '11111111111111111111111111111112';
      const testAmount = 0.1;

      final feeEstimate = await _solanaService.estimateTransactionFee(
        mnemonic: testMnemonic,
        toAddress: testToAddress,
        amount: testAmount,
        priority: SolanaTransactionPriority.medium,
      );

      setState(() {
        _status = '费用估算成功: ${feeEstimate.totalFee} lamports';
      });
    } catch (e) {
      setState(() {
        _status = '费用估算失败: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solana Gas费测试'),
        backgroundColor: const Color(0xFF9945FF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '测试状态',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testNetworkStatus,
              child: const Text('测试网络状态'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _testFeeEstimation,
              child: const Text('测试费用估算'),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '功能说明',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('• 智能费用估算'),
                    Text('• 网络拥堵检测'),
                    Text('• 多优先级支持'),
                    Text('• 费用优化'),
                    Text('• 确认时间预测'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
