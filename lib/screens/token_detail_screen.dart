import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../models/token.dart';
import '../utils/amount_utils.dart';
import 'receive_screen.dart';
import 'swap_screen.dart';
import 'address_selection_screen.dart';

class TokenDetailScreen extends StatefulWidget {
  final Map<String, dynamic> asset;
  final double balance;
  final double usdValue;

  const TokenDetailScreen({
    super.key,
    required this.asset,
    required this.balance,
    required this.usdValue,
  });

  @override
  State<TokenDetailScreen> createState() => _TokenDetailScreenState();
}

class _TokenDetailScreenState extends State<TokenDetailScreen> {
  // 现代色彩方案
  static const Color primaryBackground = Color(0xFF0A0B0D);
  static const Color cardBackground = Color(0xFF1A1D29);
  static const Color accentColor = Color(0xFF6366F1);
  static const Color successColor = Color(0xFF10B981);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);

  // 模拟交易记录
  final List<Map<String, dynamic>> _transactions = [
    {
      'type': 'receive',
      'amount': 4.01,
      'from': 'TNB7bbN9..MHybNjgA',
      'date': '2025/10/14',
      'time': '14:19',
      'status': 'success',
      'hash': '0x1234567890abcdef...',
    },
    {
      'type': 'send',
      'amount': -2.50,
      'to': 'TB6LhBWh..ZiruMzr7',
      'date': '2025/10/13',
      'time': '09:30',
      'status': 'success',
      'hash': '0xabcdef1234567890...',
    },
    {
      'type': 'receive',
      'amount': 1.75,
      'from': 'TC9MnXvK..PqwRst8',
      'date': '2025/10/12',
      'time': '16:45',
      'status': 'success',
      'hash': '0x567890abcdef1234...',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildBalanceSection(),
                    _buildAccountSection(),
                    _buildTransactionSection(),
                    const SizedBox(height: 100), // Space for bottom buttons
                  ],
                ),
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: textPrimary,
                size: 18,
              ),
            ),
          ),
          const Spacer(),
          // Token info
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Token icon
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: (widget.asset['color'] as Color).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: widget.asset['logoUrl'] != null
                          ? ClipOval(
                              child: Image.network(
                                widget.asset['logoUrl']!,
                                width: 16,
                                height: 16,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    widget.asset['icon'] as IconData,
                                    color: widget.asset['color'] as Color,
                                    size: 12,
                                  );
                                },
                              ),
                            )
                          : Icon(
                              widget.asset['icon'] as IconData,
                              color: widget.asset['color'] as Color,
                              size: 12,
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.asset['symbol'] as String,
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _formatAddress(widget.asset['id'] as String),
                style: const TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          // More options
          GestureDetector(
            onTap: _showMoreOptions,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.more_horiz,
                color: textPrimary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSection() {
    final change24h = (widget.asset['change24h'] as num?)?.toDouble() ?? 0.0155;
    final isPositive = change24h >= 0;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Main balance
          Text(
            AmountUtils.format(widget.balance),
            style: const TextStyle(
              color: textPrimary,
              fontSize: 48,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          // USD value and change
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '≈\$${AmountUtils.format(widget.usdValue)}',
                style: const TextStyle(
                  color: textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive 
                      ? successColor.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${isPositive ? '+' : ''}${(change24h * 100).toStringAsFixed(4)}%',
                  style: TextStyle(
                    color: isPositive ? successColor : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '我的账户',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _addAccount,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: textPrimary,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAccountItem(),
        ],
      ),
    );
  }

  Widget _buildAccountItem() {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
        final currentWallet = walletProvider.currentWallet;
        if (currentWallet == null) return const SizedBox.shrink();

        // 获取当前网络的地址列表
        final networkId = widget.asset['id'] as String;
        final addressList = currentWallet.addresses[networkId] ?? [];
        
        if (addressList.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 32,
                  color: textSecondary,
                ),
                const SizedBox(height: 8),
                const Text(
                  '暂无地址',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '点击右上角加号生成新地址',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }

        // 支持区域内滚动显示所有地址
        return Container(
          constraints: const BoxConstraints(maxHeight: 300),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: addressList.length,
            itemBuilder: (context, index) {
              final address = addressList[index];
              final addressName = currentWallet.addressNames[address] ?? '${currentWallet.name} #${index + 1}';
              
              return Container(
                margin: EdgeInsets.only(bottom: index < addressList.length - 1 ? 8 : 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: InkWell(
                  onTap: () => _navigateToSendWithAddress(address),
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              addressName,
                              style: const TextStyle(
                                color: textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${address.substring(0, 6)}...${address.substring(address.length - 4)}',
                              style: const TextStyle(
                                color: textSecondary,
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
                            AmountUtils.format(widget.balance / addressList.length), // 平均分配余额显示
                            style: const TextStyle(
                              color: textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '≈\$${AmountUtils.format(widget.usdValue / addressList.length)}',
                            style: const TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                         onTap: () => _copyAddressWithParam(address),
                         child: Container(
                           padding: const EdgeInsets.all(6),
                           decoration: BoxDecoration(
                             color: Colors.white.withOpacity(0.1),
                             borderRadius: BorderRadius.circular(6),
                           ),
                           child: const Icon(
                             Icons.copy,
                             color: textSecondary,
                             size: 16,
                           ),
                         ),
                       ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _copyAddressWithParam(String address) {
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('地址已复制到剪贴板'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildTransactionSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '交易记录',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _showAllTransactions,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.calendar_today,
                    color: textSecondary,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Date header
          Text(
            '2025/10/14',
            style: const TextStyle(
              color: textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          // Transaction item
          _buildTransactionItem(_transactions[0]),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final isReceive = transaction['type'] == 'receive';
    final amount = transaction['amount'] as double;
    final isPositive = amount > 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Transaction icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isPositive 
                  ? successColor.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isReceive ? Icons.arrow_downward : Icons.arrow_upward,
              color: isPositive ? successColor : Colors.red,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          // Transaction info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isReceive ? '接收' : '发送',
                  style: const TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'From ${_formatAddress(transaction['from'] ?? transaction['to'] ?? '')}',
                  style: const TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Amount and status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPositive ? '+' : ''}${AmountUtils.format(amount.abs())} ${widget.asset['symbol']}',
                style: TextStyle(
                  color: isPositive ? successColor : Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '接收成功',
                    style: const TextStyle(
                      color: textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    transaction['time'] as String,
                    style: const TextStyle(
                      color: textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryBackground,
        border: Border(
          top: BorderSide(
            color: textSecondary.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              '接收',
              Icons.arrow_downward,
              accentColor,
              () => _navigateToReceive(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              '发送',
              Icons.arrow_upward,
              accentColor,
              () => _navigateToSend(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              '兑换',
              Icons.swap_horiz,
              accentColor,
              () => _navigateToSwap(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: textPrimary,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAddress(String address) {
    if (address.length <= 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOptionItem(Icons.copy, '复制地址', () {
              Navigator.pop(context);
              _copyAddress();
            }),
            _buildOptionItem(Icons.share, '分享', () {
              Navigator.pop(context);
              _shareToken();
            }),
            _buildOptionItem(Icons.info_outline, '代币信息', () {
              Navigator.pop(context);
              _showTokenInfo();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: textPrimary),
      title: Text(
        title,
        style: const TextStyle(color: textPrimary),
      ),
      onTap: onTap,
    );
  }

  void _addAccount() async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final currentWallet = walletProvider.currentWallet;
    
    if (currentWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可用的钱包')),
      );
      return;
    }

    // 检查钱包类型，只有助记词钱包才能生成新地址
    if (currentWallet.importType != 'mnemonic') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('只有助记词钱包才能生成新地址'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // 显示加载对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            backgroundColor: Color(0xFF1A1B23),
            content: Row(
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(width: 16),
                Text(
                  '正在生成新地址...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        },
      );

      final networkId = widget.asset['id'] as String;
      
      // 获取当前网络的地址列表
      final addressList = currentWallet.addresses[networkId] ?? [];
      final nextIndex = addressList.length;

      // 使用AddressService生成新地址
      final newAddress = await walletProvider.generateAddressForNetworkWithIndex(
        currentWallet.mnemonic,
        networkId,
        nextIndex,
      );

      // 添加新地址到钱包
      if (currentWallet.addresses[networkId] == null) {
        currentWallet.addresses[networkId] = [];
      }
      currentWallet.addresses[networkId]!.add(newAddress);

      // 更新地址索引
      currentWallet.addressIndexes[networkId] = nextIndex + 1;

      // 设置默认地址名称
      final defaultName = '${currentWallet.name} #${nextIndex + 1}';
      currentWallet.addressNames[newAddress] = defaultName;

      // 保存到存储
      await walletProvider.updateWalletAddressesAndIndexes(
        currentWallet.id,
        currentWallet.addresses,
        currentWallet.addressIndexes,
        currentWallet.addressNames,
      );

      // 关闭加载对话框
      if (mounted) {
        Navigator.pop(context);
        
        // 显示成功消息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('新地址生成成功: $defaultName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // 关闭加载对话框
      if (mounted) {
        Navigator.pop(context);
        
        // 显示错误消息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('生成新地址失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showAllTransactions() {
    Navigator.pushNamed(context, '/transaction_history');
  }

  void _navigateToReceive() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReceiveScreen(),
      ),
    );
  }

  void _navigateToSend() {
    // 使用 addPostFrameCallback 来避免在 build 过程中调用 setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      final currentWallet = walletProvider.currentWallet;
      
      if (currentWallet != null) {
        // 获取对应的网络信息
        final network = walletProvider.supportedNetworks.firstWhere(
          (net) => net.id == widget.asset['id'],
          orElse: () => walletProvider.supportedNetworks.first,
        );
        
        // 获取当前网络的地址列表
        final addressList = currentWallet.addresses[widget.asset['id'] as String] ?? [];
        
        if (addressList.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('当前网络没有可用地址')),
          );
          return;
        }
        
        // 根据地址数量决定跳转逻辑
        if (addressList.length == 1) {
          // 只有一个地址，直接跳转到发送详情页面
          Navigator.pushNamed(
            context,
            '/send_detail',
            arguments: {
              'network': network,
              'address': addressList.first,
              'preselectedToken': widget.asset, // 传递预选的token信息
            },
          );
        } else {
          // 多个地址，先跳转到地址选择页面
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddressSelectionScreen(
                network: network,
                preselectedToken: widget.asset, // 传递预选的token信息
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先创建或导入钱包')),
        );
      }
    });
  }

  // 直接跳转到发送页面，传递指定地址
  void _navigateToSendWithAddress(String address) {
    // 使用 addPostFrameCallback 来避免在 build 过程中调用 setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      final currentWallet = walletProvider.currentWallet;
      
      if (currentWallet != null) {
        // 获取对应的网络信息
        final network = walletProvider.supportedNetworks.firstWhere(
          (net) => net.id == widget.asset['id'],
          orElse: () => walletProvider.supportedNetworks.first,
        );
        
        Navigator.pushNamed(
          context,
          '/send_detail',
          arguments: {
            'network': network,
            'address': address,
            'preselectedToken': widget.asset, // 传递预选的token信息
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先创建或导入钱包')),
        );
      }
    });
  }

  
  void _navigateToSwap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SwapScreen(),
      ),
    );
  }

  void _copyAddress() {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final currentWallet = walletProvider.currentWallet;
    if (currentWallet != null) {
      final address = walletProvider.getAddressForNetwork(
        currentWallet.id,
        widget.asset['id'] as String,
      );
      if (address != null) {
        Clipboard.setData(ClipboardData(text: address));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('地址已复制到剪贴板')),
        );
      }
    }
  }

  void _shareToken() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('分享功能开发中')),
    );
  }

  void _showTokenInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          '代币信息',
          style: const TextStyle(color: textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('名称', widget.asset['name'] as String),
            _buildInfoRow('符号', widget.asset['symbol'] as String),
            _buildInfoRow('网络', widget.asset['id'] as String),
            if (widget.asset['token'] != null)
              _buildInfoRow('合约地址', (widget.asset['token'] as Token).address),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭', style: TextStyle(color: accentColor)),
          ),
        ],
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
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: textSecondary, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: textPrimary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}