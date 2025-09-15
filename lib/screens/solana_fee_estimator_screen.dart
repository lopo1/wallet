import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../models/solana_transaction.dart';

class SolanaFeeEstimatorScreen extends StatefulWidget {
  const SolanaFeeEstimatorScreen({super.key});

  @override
  State<SolanaFeeEstimatorScreen> createState() =>
      _SolanaFeeEstimatorScreenState();
}

class _SolanaFeeEstimatorScreenState extends State<SolanaFeeEstimatorScreen> {
  final _toAddressController = TextEditingController();
  final _amountController = TextEditingController();
  final _maxFeeController = TextEditingController();

  Map<SolanaTransactionPriority, SolanaTransactionFee>? _feeEstimates;
  Map<SolanaTransactionPriority, Duration>? _confirmationTimes;
  Map<String, dynamic>? _networkStatus;
  SolanaTransactionFee? _optimizedFee;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNetworkStatus();
  }

  Future<void> _loadNetworkStatus() async {
    setState(() => _isLoading = true);
    try {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      final status = await walletProvider.getSolanaNetworkStatus();
      final times = await walletProvider.predictSolanaConfirmationTimes();

      if (mounted) {
        setState(() {
          _networkStatus = status;
          _confirmationTimes = times;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载网络状态失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _estimateFees() async {
    if (_toAddressController.text.isEmpty || _amountController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请填写接收地址和转账金额')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      final amount = double.parse(_amountController.text);

      final estimates = await walletProvider.getSolanaFeeEstimates(
        toAddress: _toAddressController.text,
        amount: amount,
      );

      if (mounted) {
        setState(() {
          _feeEstimates = estimates;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('费用估算失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _optimizeFee() async {
    if (_toAddressController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _maxFeeController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请填写所有字段')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      final amount = double.parse(_amountController.text);
      final maxFee = double.parse(_maxFeeController.text);

      final optimized = await walletProvider.optimizeSolanaFee(
        toAddress: _toAddressController.text,
        amount: amount,
        maxFeeInSol: maxFee,
      );

      if (mounted) {
        setState(() {
          _optimizedFee = optimized;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('费用优化失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solana 费用估算器'),
        backgroundColor: const Color(0xFF9945FF),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 网络状态卡片
            _buildNetworkStatusCard(),
            const SizedBox(height: 16),

            // 输入表单
            _buildInputForm(),
            const SizedBox(height: 16),

            // 操作按钮
            _buildActionButtons(),
            const SizedBox(height: 16),

            // 费用估算结果
            if (_feeEstimates != null) _buildFeeEstimates(),
            const SizedBox(height: 16),

            // 优化费用结果
            if (_optimizedFee != null) _buildOptimizedFee(),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.network_check, color: Color(0xFF9945FF)),
                const SizedBox(width: 8),
                const Text('网络状态',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _isLoading ? null : _loadNetworkStatus,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_networkStatus != null) ...[
              _buildStatusRow('拥堵级别',
                  _getCongestionLevelText(_networkStatus!['congestionLevel'])),
              if (_networkStatus!['priorityFeeStats'] != null)
                ..._buildPriorityFeeStats(),
            ] else
              const Text('加载中...'),
          ],
        ),
      ),
    );
  }

  Widget _buildInputForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('交易信息',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _toAddressController,
              decoration: const InputDecoration(
                labelText: '接收地址',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance_wallet),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: '转账金额 (SOL)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monetization_on),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _maxFeeController,
              decoration: const InputDecoration(
                labelText: '最大费用 (SOL) - 用于费用优化',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _estimateFees,
            icon: const Icon(Icons.calculate),
            label: const Text('估算费用'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9945FF),
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _optimizeFee,
            icon: const Icon(Icons.tune),
            label: const Text('优化费用'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeeEstimates() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('费用估算',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...SolanaTransactionPriority.values.map((priority) {
              final fee = _feeEstimates![priority];
              final time = _confirmationTimes?[priority];
              return _buildFeeRow(priority, fee!, time);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizedFee() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('优化费用',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Column(
                children: [
                  _buildFeeDetailRow(
                      '基础费用', '${_optimizedFee!.baseFee} lamports'),
                  _buildFeeDetailRow(
                      '优先费', '${_optimizedFee!.priorityFee} lamports'),
                  _buildFeeDetailRow(
                      '总费用', '${_optimizedFee!.totalFee} lamports'),
                  _buildFeeDetailRow('计算单元', '${_optimizedFee!.computeUnits}'),
                  _buildFeeDetailRow(
                      '单元价格', '${_optimizedFee!.computeUnitPrice} 微lamports'),
                  const Divider(),
                  _buildFeeDetailRow(
                      '总费用 (SOL)',
                      (_optimizedFee!.totalFee / 1000000000)
                          .toStringAsFixed(9)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeRow(SolanaTransactionPriority priority,
      SolanaTransactionFee fee, Duration? time) {
    final priorityText = _getPriorityText(priority);
    final priorityColor = _getPriorityColor(priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: priorityColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
        color: priorityColor.withValues(alpha: 0.05),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: priorityColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              priorityText,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${fee.totalFee} lamports'),
                Text(
                  '${(fee.totalFee / 1000000000).toStringAsFixed(9)} SOL',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (time != null)
            Text(
              '~${_formatDuration(time)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildPriorityFeeStats() {
    final stats = _networkStatus!['priorityFeeStats'] as Map<String, dynamic>;
    return [
      _buildStatusRow('中位数优先费', '${stats['median']} 微lamports'),
      _buildStatusRow('75%分位数', '${stats['percentile75']} 微lamports'),
    ];
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFeeDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _getCongestionLevelText(String level) {
    switch (level) {
      case 'high':
        return '高拥堵 🔴';
      case 'medium':
        return '中等拥堵 🟡';
      case 'low':
        return '轻微拥堵 🟢';
      case 'none':
        return '无拥堵 ✅';
      default:
        return '未知';
    }
  }

  String _getPriorityText(SolanaTransactionPriority priority) {
    switch (priority) {
      case SolanaTransactionPriority.low:
        return '低';
      case SolanaTransactionPriority.medium:
        return '中';
      case SolanaTransactionPriority.high:
        return '高';
      case SolanaTransactionPriority.veryHigh:
        return '极高';
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
  void dispose() {
    _toAddressController.dispose();
    _amountController.dispose();
    _maxFeeController.dispose();
    super.dispose();
  }
}
