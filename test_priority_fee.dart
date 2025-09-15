import 'package:flutter/material.dart';
import 'package:flutter_wallet/services/solana_wallet_service.dart';
import 'package:flutter_wallet/models/solana_transaction.dart';

void main() {
  runApp(const PriorityFeeTestApp());
}

class PriorityFeeTestApp extends StatelessWidget {
  const PriorityFeeTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solana优先费测试',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        useMaterial3: true,
      ),
      home: const PriorityFeeTestScreen(),
    );
  }
}

class PriorityFeeTestScreen extends StatefulWidget {
  const PriorityFeeTestScreen({super.key});

  @override
  State<PriorityFeeTestScreen> createState() => _PriorityFeeTestScreenState();
}

class _PriorityFeeTestScreenState extends State<PriorityFeeTestScreen> {
  String _status = '准备测试Solana优先费功能...';
  bool _isLoading = false;
  final List<String> _testResults = [];
  Map<SolanaTransactionPriority, SolanaTransactionFee>? _feeEstimates;

  Future<void> _runPriorityFeeTest() async {
    setState(() {
      _isLoading = true;
      _testResults.clear();
      _feeEstimates = null;
      _status = '开始测试优先费功能...';
    });

    try {
      _addResult('🚀 开始Solana优先费测试');

      // 创建服务
      _addResult('📡 创建SolanaWalletService');
      final service = SolanaWalletService('https://api.devnet.solana.com');

      // 测试参数
      const testMnemonic =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      const testAddress = '11111111111111111111111111111112';
      const testAmount = 0.001;

      _addResult('💰 测试参数:');
      _addResult('  转账金额: $testAmount SOL');
      _addResult('  接收地址: $testAddress');

      // 测试所有优先级的费用估算
      _addResult('🔍 测试所有优先级费用估算...');
      final allFees = await service.getAllPriorityFees(
        mnemonic: testMnemonic,
        toAddress: testAddress,
        amount: testAmount,
      );

      setState(() {
        _feeEstimates = allFees;
      });

      _addResult('✅ 费用估算完成，结果:');
      for (final entry in allFees.entries) {
        final priority = entry.key;
        final fee = entry.value;
        final priorityName = _getPriorityName(priority);

        _addResult('  $priorityName:');
        _addResult('    总费用: ${fee.totalFee} lamports');
        _addResult('    基础费用: ${fee.baseFee} lamports');
        _addResult('    优先费: ${fee.priorityFee} lamports');
        _addResult('    计算单元: ${fee.computeUnits}');
        _addResult('    单元价格: ${fee.computeUnitPrice} 微lamports');
        _addResult('    优先级倍数: ${fee.priorityMultiplier}x');
        _addResult(
            '    SOL费用: ${(fee.totalFee / 1000000000).toStringAsFixed(9)} SOL');
        _addResult('');
      }

      // 测试网络状态
      _addResult('🌐 获取网络状态...');
      final networkStatus = await service.getNetworkStatus();
      final congestionLevel = networkStatus['congestionLevel'] ?? 'unknown';
      final recommendedPriority = networkStatus['recommendedPriority'];

      _addResult('  网络拥堵级别: $congestionLevel');
      if (recommendedPriority != null) {
        _addResult('  推荐优先级: ${_getPriorityName(recommendedPriority)}');
      }

      // 测试费用优化
      _addResult('⚡ 测试费用优化 (最大费用: 0.001 SOL)...');
      final optimizedFee = await service.optimizeTransactionFee(
        mnemonic: testMnemonic,
        toAddress: testAddress,
        amount: testAmount,
        maxFeeInSol: 0.001,
      );

      _addResult('  优化后费用: ${optimizedFee.totalFee} lamports');
      _addResult(
          '  优化后SOL费用: ${(optimizedFee.totalFee / 1000000000).toStringAsFixed(9)} SOL');

      // 测试确认时间预测
      _addResult('⏱️ 测试确认时间预测...');
      final confirmationTimes = await service.predictConfirmationTimes();
      for (final entry in confirmationTimes.entries) {
        final priority = entry.key;
        final time = entry.value;
        final priorityName = _getPriorityName(priority);
        final timeStr = _formatDuration(time);
        _addResult('  $priorityName: ~$timeStr');
      }

      _addResult('');
      _addResult('🎉 所有测试完成！优先费功能正常工作');

      setState(() {
        _status = '测试完成 - 优先费功能验证成功！';
      });
    } catch (e) {
      _addResult('❌ 测试失败: $e');
      setState(() {
        _status = '测试失败，请检查网络连接';
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

  Color _getPriorityColor(SolanaTransactionPriority priority) {
    switch (priority) {
      case SolanaTransactionPriority.low:
        return Colors.green;
      case SolanaTransactionPriority.medium:
        return Colors.orange;
      case SolanaTransactionPriority.high:
        return Colors.red;
      case SolanaTransactionPriority.veryHigh:
        return Colors.purple;
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
        title: const Text('Solana优先费测试'),
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
                onPressed: _isLoading ? null : _runPriorityFeeTest,
                icon: const Icon(Icons.play_arrow),
                label: Text(_isLoading ? '测试中...' : '开始优先费测试'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9945FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 费用对比表格
            if (_feeEstimates != null) ...[
              Text(
                '费用对比',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // 表头
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          children: [
                            Expanded(
                                flex: 2,
                                child: Text('优先级',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            Expanded(
                                flex: 2,
                                child: Text('总费用',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            Expanded(
                                flex: 2,
                                child: Text('优先费',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            Expanded(
                                flex: 2,
                                child: Text('SOL费用',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 数据行
                      ...SolanaTransactionPriority.values.map((priority) {
                        final fee = _feeEstimates![priority]!;
                        final priorityColor = _getPriorityColor(priority);
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: priorityColor.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: priorityColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _getPriorityName(priority),
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ),
                              Expanded(flex: 2, child: Text('${fee.totalFee}')),
                              Expanded(
                                  flex: 2, child: Text('${fee.priorityFee}')),
                              Expanded(
                                  flex: 2,
                                  child: Text(
                                      '${(fee.totalFee / 1000000000).toStringAsFixed(9)}')),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

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
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Text(
                            _testResults[index],
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
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
