import 'package:flutter/material.dart';
import 'package:flutter_wallet/services/solana_wallet_service.dart';
import 'package:flutter_wallet/models/solana_transaction.dart';

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solana Gas费测试',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        useMaterial3: true,
      ),
      home: const TestScreen(),
    );
  }
}

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  String _status = '准备测试Solana Gas费功能...';
  bool _isLoading = false;
  final List<String> _testResults = [];

  Future<void> _runTests() async {
    setState(() {
      _isLoading = true;
      _testResults.clear();
      _status = '开始测试...';
    });

    try {
      // 测试1: 创建服务
      _addResult('✅ 测试1: 创建SolanaWalletService');
      final service = SolanaWalletService('https://api.devnet.solana.com');
      _addResult('   服务创建成功');

      // 测试2: 获取网络状态
      _addResult('🔄 测试2: 获取网络状态');
      final networkStatus = await service.getNetworkStatus();
      final congestionLevel = networkStatus['congestionLevel'] ?? 'unknown';
      _addResult('   网络拥堵级别: $congestionLevel');

      // 测试3: 费用估算
      _addResult('🔄 测试3: 费用估算');
      const testMnemonic =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      const testAddress = '11111111111111111111111111111112';

      final feeEstimate = await service.estimateTransactionFee(
        mnemonic: testMnemonic,
        toAddress: testAddress,
        amount: 0.1,
        priority: SolanaTransactionPriority.medium,
      );
      _addResult('   中等优先级费用: ${feeEstimate.totalFee} lamports');
      _addResult('   基础费用: ${feeEstimate.baseFee} lamports');
      _addResult('   优先费: ${feeEstimate.priorityFee} lamports');

      // 测试4: 所有优先级费用
      _addResult('🔄 测试4: 获取所有优先级费用');
      final allFees = await service.getAllPriorityFees(
        mnemonic: testMnemonic,
        toAddress: testAddress,
        amount: 0.1,
      );

      for (final entry in allFees.entries) {
        final priorityName = _getPriorityName(entry.key);
        _addResult('   $priorityName: ${entry.value.totalFee} lamports');
      }

      // 测试5: 确认时间预测
      _addResult('🔄 测试5: 确认时间预测');
      final confirmationTimes = await service.predictConfirmationTimes();
      for (final entry in confirmationTimes.entries) {
        final priorityName = _getPriorityName(entry.key);
        final time = _formatDuration(entry.value);
        _addResult('   $priorityName: ~$time');
      }

      _addResult('✅ 所有测试完成！');
      setState(() {
        _status = '测试完成 - Solana Gas费功能正常工作！';
      });
    } catch (e) {
      _addResult('❌ 测试失败: $e');
      setState(() {
        _status = '测试失败，请检查网络连接和配置';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addResult(String result) {
    setState(() {
      _testResults.add(result);
    });
  }

  String _getPriorityName(SolanaTransactionPriority priority) {
    switch (priority) {
      case SolanaTransactionPriority.low:
        return '低优先级';
      case SolanaTransactionPriority.medium:
        return '中等优先级';
      case SolanaTransactionPriority.high:
        return '高优先级';
      case SolanaTransactionPriority.veryHigh:
        return '极高优先级';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}分钟';
    } else {
      return '${duration.inSeconds}秒';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solana Gas费测试'),
        backgroundColor: const Color(0xFF9945FF),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 状态卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '测试状态',
                      style: Theme.of(context).textTheme.titleLarge,
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

            // 测试按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _runTests,
                icon: const Icon(Icons.play_arrow),
                label: Text(_isLoading ? '测试中...' : '开始测试'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9945FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 测试结果
            if (_testResults.isNotEmpty) ...[
              Text(
                '测试结果',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ListView.builder(
                      itemCount: _testResults.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            _testResults[index],
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
