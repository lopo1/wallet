import 'package:flutter/material.dart';
import 'lib/services/solana_wallet_service.dart';
import 'lib/models/solana_transaction.dart';

/// 简化的测试应用，验证基本功能
void main() {
  runApp(const SimpleTestApp());
}

class SimpleTestApp extends StatelessWidget {
  const SimpleTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solana Gas费简单测试',
      home: const SimpleTestScreen(),
    );
  }
}

class SimpleTestScreen extends StatefulWidget {
  const SimpleTestScreen({super.key});

  @override
  State<SimpleTestScreen> createState() => _SimpleTestScreenState();
}

class _SimpleTestScreenState extends State<SimpleTestScreen> {
  String _status = '准备测试...';
  bool _isLoading = false;

  Future<void> _testBasicFunctionality() async {
    setState(() {
      _isLoading = true;
      _status = '开始测试...';
    });

    try {
      // 测试1: 创建服务
      setState(() => _status = '1/4 创建Solana服务...');
      final service = SolanaWalletService('https://api.devnet.solana.com');

      // 测试2: 获取网络状态
      setState(() => _status = '2/4 获取网络状态...');
      final networkStatus = await service.getNetworkStatus();
      final congestionLevel = networkStatus['congestionLevel'] ?? 'unknown';

      // 测试3: 测试费用估算
      setState(() => _status = '3/4 测试费用估算...');
      const testMnemonic =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      const testAddress = '11111111111111111111111111111112';

      final feeEstimate = await service.estimateTransactionFee(
        mnemonic: testMnemonic,
        toAddress: testAddress,
        amount: 0.1,
        priority: SolanaTransactionPriority.medium,
      );

      // 测试4: 获取所有优先级费用
      setState(() => _status = '4/4 获取所有优先级费用...');
      final allFees = await service.getAllPriorityFees(
        mnemonic: testMnemonic,
        toAddress: testAddress,
        amount: 0.1,
      );

      setState(() {
        _status = '''测试完成! ✅
网络拥堵: $congestionLevel
中等优先级费用: ${feeEstimate.totalFee} lamports
所有优先级数量: ${allFees.length}''';
      });
    } catch (e) {
      setState(() {
        _status = '测试失败: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solana Gas费简单测试'),
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
                    if (_isLoading) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _testBasicFunctionality,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9945FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
                child: Text(
                  _isLoading ? '测试中...' : '开始测试',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '测试内容',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('1. 创建SolanaWalletService实例'),
                    Text('2. 获取网络拥堵状态'),
                    Text('3. 估算单个优先级费用'),
                    Text('4. 获取所有优先级费用'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '功能特性',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('✅ 智能费用估算'),
                    Text('✅ 网络拥堵检测'),
                    Text('✅ 多优先级支持'),
                    Text('✅ 费用优化算法'),
                    Text('✅ 确认时间预测'),
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
