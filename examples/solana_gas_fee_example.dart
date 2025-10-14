import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:harbor/providers/wallet_provider.dart';
import 'package:harbor/models/solana_transaction.dart';

/// Solana Gas费功能使用示例
class SolanaGasFeeExample extends StatefulWidget {
  const SolanaGasFeeExample({super.key});

  @override
  State<SolanaGasFeeExample> createState() => _SolanaGasFeeExampleState();
}

class _SolanaGasFeeExampleState extends State<SolanaGasFeeExample> {
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();

  Map<SolanaTransactionPriority, SolanaTransactionFee>? _feeEstimates;
  Map<String, dynamic>? _networkStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNetworkStatus();
  }

  /// 加载网络状态
  Future<void> _loadNetworkStatus() async {
    setState(() => _isLoading = true);

    try {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      final status = await walletProvider.getSolanaNetworkStatus();

      setState(() {
        _networkStatus = status;
      });
    } catch (e) {
      _showError('加载网络状态失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 估算交易费用
  Future<void> _estimateFees() async {
    if (_recipientController.text.isEmpty || _amountController.text.isEmpty) {
      _showError('请填写接收地址和转账金额');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      final amount = double.parse(_amountController.text);

      final estimates = await walletProvider.getSolanaFeeEstimates(
        toAddress: _recipientController.text,
        amount: amount,
      );

      setState(() {
        _feeEstimates = estimates;
      });

      _showSuccess('费用估算完成');
    } catch (e) {
      _showError('费用估算失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 发送交易（使用推荐优先级）
  Future<void> _sendTransactionWithRecommendedPriority() async {
    if (_recipientController.text.isEmpty || _amountController.text.isEmpty) {
      _showError('请填写接收地址和转账金额');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      final amount = double.parse(_amountController.text);

      // 获取推荐的优先级
      final networkStatus = await walletProvider.getSolanaNetworkStatus();
      final recommendedPriority = _getRecommendedPriority(networkStatus);

      // 发送交易
      final transaction = await walletProvider.sendSolanaTransaction(
        toAddress: _recipientController.text,
        amount: amount,
        priority: recommendedPriority,
        memo: '示例转账',
      );

      _showSuccess('交易已发送，签名: ${transaction.signature}');
    } catch (e) {
      _showError('发送交易失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 优化费用并发送
  Future<void> _sendTransactionWithOptimizedFee() async {
    if (_recipientController.text.isEmpty || _amountController.text.isEmpty) {
      _showError('请填写接收地址和转账金额');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      final amount = double.parse(_amountController.text);

      // 优化费用（最大费用设为0.001 SOL）
      final optimizedFee = await walletProvider.optimizeSolanaFee(
        toAddress: _recipientController.text,
        amount: amount,
        maxFeeInSol: 0.001,
      );

      // 根据优化结果确定优先级
      final priority =
          _getPriorityFromMultiplier(optimizedFee.priorityMultiplier);

      // 发送交易
      final transaction = await walletProvider.sendSolanaTransaction(
        toAddress: _recipientController.text,
        amount: amount,
        priority: priority,
        memo: '优化费用转账',
        customComputeUnits: optimizedFee.computeUnits,
        customComputeUnitPrice: optimizedFee.computeUnitPrice,
      );

      _showSuccess('优化费用交易已发送，签名: ${transaction.signature}');
    } catch (e) {
      _showError('优化费用发送失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 根据网络状态获取推荐优先级
  SolanaTransactionPriority _getRecommendedPriority(
      Map<String, dynamic> networkStatus) {
    final congestionLevel =
        networkStatus['congestionLevel'] as String? ?? 'unknown';

    switch (congestionLevel) {
      case 'high':
        return SolanaTransactionPriority.veryHigh;
      case 'medium':
        return SolanaTransactionPriority.high;
      case 'low':
        return SolanaTransactionPriority.medium;
      default:
        return SolanaTransactionPriority.low;
    }
  }

  /// 根据优先费倍数获取优先级
  SolanaTransactionPriority _getPriorityFromMultiplier(double multiplier) {
    if (multiplier >= 4.0) return SolanaTransactionPriority.veryHigh;
    if (multiplier >= 2.5) return SolanaTransactionPriority.high;
    if (multiplier >= 1.5) return SolanaTransactionPriority.medium;
    return SolanaTransactionPriority.low;
  }

  /// 显示成功消息
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 显示错误消息
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solana Gas费示例'),
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
            if (_feeEstimates != null) _buildFeeEstimatesCard(),
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
            const Text(
              '网络状态',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_networkStatus != null) ...[
              _buildStatusRow('拥堵级别',
                  _getCongestionText(_networkStatus!['congestionLevel'])),
              if (_networkStatus!['recommendedPriority'] != null)
                _buildStatusRow('推荐优先级',
                    _getPriorityText(_networkStatus!['recommendedPriority'])),
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
            const Text(
              '转账信息',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _recipientController,
              decoration: const InputDecoration(
                labelText: '接收地址',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: '转账金额 (SOL)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _estimateFees,
                child: const Text('估算费用'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _loadNetworkStatus,
                child: const Text('刷新状态'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed:
                    _isLoading ? null : _sendTransactionWithRecommendedPriority,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('推荐优先级发送'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendTransactionWithOptimizedFee,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('优化费用发送'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeeEstimatesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '费用估算结果',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...SolanaTransactionPriority.values.map((priority) {
              final fee = _feeEstimates![priority]!;
              return _buildFeeRow(priority, fee);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeRow(
      SolanaTransactionPriority priority, SolanaTransactionFee fee) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getPriorityColor(priority),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _getPriorityText(priority),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('总费用: ${fee.totalFee} lamports'),
                Text('基础: ${fee.baseFee}, 优先: ${fee.priorityFee}'),
                Text('计算单元: ${fee.computeUnits} × ${fee.computeUnitPrice}'),
              ],
            ),
          ),
        ],
      ),
    );
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

  String _getCongestionText(String? level) {
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

  String _getPriorityText(dynamic priority) {
    if (priority is SolanaTransactionPriority) {
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
    return priority.toString();
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

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
