import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final String assetId;
  final String assetName;
  final String assetSymbol;
  final Color assetColor;
  final IconData assetIcon;

  const TransactionHistoryScreen({
    super.key,
    required this.assetId,
    required this.assetName,
    required this.assetSymbol,
    required this.assetColor,
    required this.assetIcon,
  });

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  bool _isLoading = false;
  List<TransactionRecord> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 模拟加载交易数据
      await Future.delayed(const Duration(seconds: 1));
      
      // 模拟交易记录数据
      final mockTransactions = [
        TransactionRecord(
          id: '1',
          type: TransactionType.receive,
          amount: 0.5,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          status: TransactionStatus.confirmed,
          fromAddress: '0x1234...5678',
          toAddress: '0x9876...4321',
          txHash: '0xabcd...efgh',
        ),
        TransactionRecord(
          id: '2',
          type: TransactionType.send,
          amount: 0.25,
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          status: TransactionStatus.confirmed,
          fromAddress: '0x9876...4321',
          toAddress: '0x1111...2222',
          txHash: '0xijkl...mnop',
        ),
        TransactionRecord(
          id: '3',
          type: TransactionType.send,
          amount: 1.0,
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
          status: TransactionStatus.pending,
          fromAddress: '0x9876...4321',
          toAddress: '0x3333...4444',
          txHash: '0xqrst...uvwx',
        ),
      ];

      setState(() {
        _transactions = mockTransactions;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('加载交易记录失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshTransactions() async {
    await _loadTransactions();
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(2)}K';
    } else if (amount >= 1) {
      return amount.toStringAsFixed(4);
    } else {
      return amount.toStringAsFixed(6);
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}天前';
    } else {
      return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B23),
      body: SafeArea(
        child: Column(
          children: [
            // 自定义钱包管理头部区域
            _buildWalletHeader(context),
            // 交易记录内容区域
            Expanded(
              child: _buildTransactionContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B23),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // 顶部导航栏
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Text(
                  '钱包管理',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 48), // 平衡左侧按钮
            ],
          ),
          const SizedBox(height: 16),
          // 钱包信息和切换区域
          Consumer<WalletProvider>(
            builder: (context, walletProvider, child) {
              final currentWallet = walletProvider.currentWallet;
              if (currentWallet == null) {
                return _buildNoWalletState();
              }
              return _buildWalletSelector(context, walletProvider, currentWallet);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNoWalletState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            color: Colors.white54,
            size: 48,
          ),
          SizedBox(height: 16),
          Text(
            '暂无钱包',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '请先创建或导入钱包',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletSelector(BuildContext context, WalletProvider walletProvider, dynamic currentWallet) {
    return GestureDetector(
      onTap: () => _showWalletSwitcher(context, walletProvider),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // 钱包图标
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: Color(0xFF6366F1),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // 钱包信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          currentWallet.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '助记词',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatAddress(walletProvider.getCurrentNetworkAddress() ?? ''),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${walletProvider.wallets.length} 个钱包',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // 下拉箭头
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white54,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  String _formatAddress(String address) {
    if (address.length <= 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  void _showWalletSwitcher(BuildContext context, WalletProvider walletProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1B23),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 拖拽指示器
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 标题
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      '选择钱包',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 钱包列表
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: walletProvider.wallets.length,
                  itemBuilder: (context, index) {
                    final wallet = walletProvider.wallets[index];
                    final isSelected = wallet.id == walletProvider.currentWallet?.id;
                    return _buildWalletItem(context, walletProvider, wallet, isSelected);
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWalletItem(BuildContext context, WalletProvider walletProvider, dynamic wallet, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? const Color(0xFF6366F1) : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        tileColor: isSelected 
            ? const Color(0xFF6366F1).withOpacity(0.1)
            : Colors.white.withOpacity(0.05),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFF6366F1).withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.account_balance_wallet,
            color: isSelected ? const Color(0xFF6366F1) : Colors.white54,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                wallet.name,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '助记词',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          _formatAddress(walletProvider.getAddressForNetwork(wallet.id, walletProvider.currentNetwork?.id ?? 'ethereum') ?? ''),
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
        trailing: isSelected 
            ? const Icon(
                Icons.check_circle,
                color: Color(0xFF6366F1),
                size: 20,
              )
            : null,
        onTap: () {
          walletProvider.setCurrentWallet(wallet);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildTransactionContent() {
    return RefreshIndicator(
      onRefresh: _refreshTransactions,
      backgroundColor: const Color(0xFF2A2B35),
      color: Colors.white,
      child: Column(
        children: [
          // 资产信息栏
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: widget.assetColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.assetIcon,
                    color: widget.assetColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.assetName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${widget.assetSymbol} 交易记录',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 交易记录列表
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : _transactions.isEmpty
                    ? _buildEmptyState()
                    : _buildTransactionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long,
              color: Colors.white54,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '暂无交易记录',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '当前资产还没有任何交易记录',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        return _buildTransactionItem(transaction);
      },
    );
  }

  Widget _buildTransactionItem(TransactionRecord transaction) {
    final isReceive = transaction.type == TransactionType.receive;
    final statusColor = _getStatusColor(transaction.status);
    final typeIcon = isReceive ? Icons.call_received : Icons.call_made;
    final typeColor = isReceive ? Colors.green : Colors.red;
    final amountPrefix = isReceive ? '+' : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showTransactionDetails(transaction),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    typeIcon,
                    color: typeColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isReceive ? '接收' : '发送',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getStatusText(transaction.status),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(transaction.timestamp),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$amountPrefix${_formatAmount(transaction.amount)} ${widget.assetSymbol}',
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '点击查看详情',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.confirmed:
        return Colors.green;
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.failed:
        return Colors.red;
    }
  }

  String _getStatusText(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.confirmed:
        return '已确认';
      case TransactionStatus.pending:
        return '待确认';
      case TransactionStatus.failed:
        return '失败';
    }
  }

  void _showTransactionDetails(TransactionRecord transaction) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1B23),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '交易详情',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow('交易类型', transaction.type == TransactionType.receive ? '接收' : '发送'),
                    _buildDetailRow('金额', '${_formatAmount(transaction.amount)} ${widget.assetSymbol}'),
                    _buildDetailRow('状态', _getStatusText(transaction.status)),
                    _buildDetailRow('时间', _formatTime(transaction.timestamp)),
                    _buildDetailRow('发送地址', transaction.fromAddress),
                    _buildDetailRow('接收地址', transaction.toAddress),
                    _buildDetailRow('交易哈希', transaction.txHash),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: transaction.txHash));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('交易哈希已复制到剪贴板'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.assetColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '复制交易哈希',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 交易记录数据模型
class TransactionRecord {
  final String id;
  final TransactionType type;
  final double amount;
  final DateTime timestamp;
  final TransactionStatus status;
  final String fromAddress;
  final String toAddress;
  final String txHash;

  TransactionRecord({
    required this.id,
    required this.type,
    required this.amount,
    required this.timestamp,
    required this.status,
    required this.fromAddress,
    required this.toAddress,
    required this.txHash,
  });
}

enum TransactionType {
  send,
  receive,
}

enum TransactionStatus {
  pending,
  confirmed,
  failed,
}