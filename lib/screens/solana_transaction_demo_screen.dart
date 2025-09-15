import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../models/solana_transaction.dart';
import 'dart:async';

class SolanaTransactionDemoScreen extends StatefulWidget {
  const SolanaTransactionDemoScreen({super.key});

  @override
  State<SolanaTransactionDemoScreen> createState() =>
      _SolanaTransactionDemoScreenState();
}

class _SolanaTransactionDemoScreenState
    extends State<SolanaTransactionDemoScreen> {
  final _toAddressController = TextEditingController();
  final _amountController = TextEditingController();

  SolanaTransactionPriority _selectedPriority =
      SolanaTransactionPriority.medium;
  bool _isLoading = false;
  StreamSubscription<SolanaTransaction>? _transactionSubscription;
  SolanaTransaction? _currentTransaction;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 设置默认值用于测试
    _toAddressController.text = '11111111111111111111111111111112';
    _amountController.text = '0.001';
  }

  Future<void> _sendTransaction() async {
    if (_toAddressController.text.isEmpty || _amountController.text.isEmpty) {
      setState(() {
        _errorMessage = '请填写接收地址和转账金额';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentTransaction = null;
    });

    try {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      final amount = double.parse(_amountController.text);

      // 发送交易并开始监控
      final transactionStream =
          await walletProvider.sendSolanaTransactionWithMonitoring(
        toAddress: _toAddressController.text,
        amount: amount,
        priority: _selectedPriority,
        memo: '测试交易 - 优先级: ${_getPriorityName(_selectedPriority)}',
      );

      // 监听交易状态更新
      _transactionSubscription?.cancel();
      _transactionSubscription = transactionStream.listen(
        (transaction) {
          setState(() {
            _currentTransaction = transaction;
            _isLoading = false;
          });
        },
        onError: (error) {
          setState(() {
            _errorMessage = '交易监控失败: $error';
            _isLoading = false;
          });
        },
        onDone: () {
          setState(() {
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = '发送交易失败: $e';
        _isLoading = false;
      });
    }
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

  Color _getStatusColor(SolanaTransactionStatus status) {
    switch (status) {
      case SolanaTransactionStatus.pending:
        return Colors.grey;
      case SolanaTransactionStatus.processing:
        return Colors.blue;
      case SolanaTransactionStatus.confirmed:
        return Colors.green;
      case SolanaTransactionStatus.finalized:
        return Colors.green.shade700;
      case SolanaTransactionStatus.failed:
        return Colors.red;
      case SolanaTransactionStatus.timeout:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solana交易费用演示'),
        backgroundColor: const Color(0xFF9945FF),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 交易表单
            _buildTransactionForm(),
            const SizedBox(height: 16),

            // 发送按钮
            _buildSendButton(),
            const SizedBox(height: 16),

            // 错误信息
            if (_errorMessage != null) _buildErrorCard(),

            // 交易状态
            if (_currentTransaction != null) _buildTransactionStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '发送交易',
              style: Theme.of(context).textTheme.titleLarge,
            ),
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

            // 优先级选择
            Text(
              '优先级选择',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            ...SolanaTransactionPriority.values.map((priority) {
              return RadioListTile<SolanaTransactionPriority>(
                title: Text(_getPriorityName(priority)),
                subtitle: Text(_getPriorityDescription(priority)),
                value: priority,
                groupValue: _selectedPriority,
                onChanged: _isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _selectedPriority = value!;
                        });
                      },
                activeColor: _getPriorityColor(priority),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _getPriorityDescription(SolanaTransactionPriority priority) {
    switch (priority) {
      case SolanaTransactionPriority.low:
        return '费用最低，确认时间较长';
      case SolanaTransactionPriority.medium:
        return '平衡费用和速度';
      case SolanaTransactionPriority.high:
        return '费用较高，快速确认';
      case SolanaTransactionPriority.veryHigh:
        return '费用最高，最快确认';
    }
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _sendTransaction,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.send),
        label: Text(_isLoading ? '发送中...' : '发送交易'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9945FF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionStatus() {
    final transaction = _currentTransaction!;
    final statusColor = _getStatusColor(transaction.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  '交易状态',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    transaction.statusDescription,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 交易基本信息
            _buildInfoRow('交易签名', transaction.signature ?? '生成中...'),
            _buildInfoRow('发送地址', transaction.fromAddress),
            _buildInfoRow('接收地址', transaction.toAddress ?? ''),
            _buildInfoRow(
                '转账金额', '${(transaction.amount ?? 0) / 1000000000} SOL'),

            const Divider(),

            // 费用信息
            Text(
              '费用信息',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            _buildInfoRow('总费用', '${transaction.fee.totalFee} lamports'),
            _buildInfoRow('基础费用', '${transaction.fee.baseFee} lamports'),
            _buildInfoRow('优先费', '${transaction.fee.priorityFee} lamports'),
            _buildInfoRow('计算单元', '${transaction.fee.computeUnits}'),
            _buildInfoRow(
                '单元价格', '${transaction.fee.computeUnitPrice} 微lamports'),
            _buildInfoRow('优先级倍数',
                '${transaction.fee.priorityMultiplier.toStringAsFixed(1)}x'),

            // 以SOL为单位显示费用
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '总费用 (SOL)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${(transaction.fee.totalFee / 1000000000).toStringAsFixed(9)} SOL',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // 确认信息
            if (transaction.confirmation != null) ...[
              const Divider(),
              Text(
                '确认信息',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _buildInfoRow('区块槽位', '${transaction.confirmation!.slot}'),
              _buildInfoRow(
                  '确认数', '${transaction.confirmation!.confirmations}'),
              if (transaction.confirmation!.blockTime != null)
                _buildInfoRow(
                    '区块时间', transaction.confirmation!.blockTime!.toString()),
            ],

            // 时间信息
            const Divider(),
            _buildInfoRow('创建时间', transaction.createdAt.toString()),
            if (transaction.sentAt != null)
              _buildInfoRow('发送时间', transaction.sentAt!.toString()),
            if (transaction.confirmedAt != null)
              _buildInfoRow('确认时间', transaction.confirmedAt!.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _toAddressController.dispose();
    _amountController.dispose();
    _transactionSubscription?.cancel();
    super.dispose();
  }
}
