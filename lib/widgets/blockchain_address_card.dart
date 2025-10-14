import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/blockchain_address.dart';
import '../providers/wallet_provider.dart';
import '../screens/account_detail_screen.dart';

class BlockchainAddressCard extends StatefulWidget {
  final BlockchainAddress blockchainAddress;
  final VoidCallback? onExpandToggle;

  const BlockchainAddressCard({
    super.key,
    required this.blockchainAddress,
    this.onExpandToggle,
  });

  @override
  State<BlockchainAddressCard> createState() => _BlockchainAddressCardState();
}

class _BlockchainAddressCardState extends State<BlockchainAddressCard> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.blockchainAddress.isExpanded;
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      widget.blockchainAddress.isExpanded = _isExpanded;
    });
    
    if (widget.onExpandToggle != null) {
      widget.onExpandToggle!();
    }
  }

  Future<void> _copyAddress(String address) async {
    try {
      await Clipboard.setData(ClipboardData(text: address));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('地址已复制: ${widget.blockchainAddress.formattedPrimaryAddress}'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('复制失败: $e'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade300;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 主卡片内容
          InkWell(
            onTap: () => _copyAddress(widget.blockchainAddress.primaryAddress),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // 链图标
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getChainColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        widget.blockchainAddress.chainSymbol.substring(0, 1),
                        style: TextStyle(
                          color: _getChainColor(),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // 链信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.blockchainAddress.chainName,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // 地址文本（移除左侧复制图标）
                        Text(
                          widget.blockchainAddress.formattedPrimaryAddress,
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 14,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 右侧操作区：二维码、复制、展开
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.qr_code_2, color: secondaryTextColor),
                        tooltip: '地址详情',
                        onPressed: () {
                          final walletProvider = Provider.of<WalletProvider>(context, listen: false);
                          walletProvider.setSelectedAddress(widget.blockchainAddress.primaryAddress);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AccountDetailScreen(),
                            ),
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(Icons.content_copy, color: secondaryTextColor),
                        tooltip: '复制地址',
                        onPressed: () => _copyAddress(widget.blockchainAddress.primaryAddress),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      if (widget.blockchainAddress.hasMultipleAddresses)
                        IconButton(
                          icon: Icon(
                            _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: secondaryTextColor,
                            size: 24,
                          ),
                          onPressed: _toggleExpand,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // 展开的地址列表（黑色小框容器）
          if (_isExpanded && widget.blockchainAddress.hasMultipleAddresses)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    ...widget.blockchainAddress.addresses.asMap().entries.map((entry) {
                      final index = entry.key;
                      final address = entry.value;
                      final isLast = index == widget.blockchainAddress.addresses.length - 1;
                      
                      return InkWell(
                        onTap: () => _copyAddress(address),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.radio_button_unchecked,
                                size: 12,
                                color: secondaryTextColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.blockchainAddress.formattedAddresses[index],
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 13,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.content_copy,
                                size: 14,
                                color: secondaryTextColor.withOpacity(0.8),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getChainColor() {
    // 根据链类型返回不同的颜色
    switch (widget.blockchainAddress.chainSymbol.toUpperCase()) {
      case 'ETH':
      case 'ETHEREUM':
        return const Color(0xFF627EEA);
      case 'BTC':
      case 'BITCOIN':
        return const Color(0xFFF7931A);
      case 'SOL':
      case 'SOLANA':
        return const Color(0xFF9945FF);
      case 'BNB':
      case 'BINANCE':
        return const Color(0xFFF3BA2F);
      case 'MATIC':
      case 'POLYGON':
        return const Color(0xFF8247E5);
      case 'ARB':
      case 'ARBITRUM':
        return const Color(0xFF28A0F0);
      case 'OP':
      case 'OPTIMISM':
        return const Color(0xFFFF0420);
      default:
        return Colors.blue;
    }
  }
}