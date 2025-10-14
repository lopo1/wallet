import 'package:flutter/material.dart';
import '../models/blockchain_address.dart';
import 'blockchain_address_card.dart';

class BlockchainAddressList extends StatefulWidget {
  final List<BlockchainAddress> blockchainAddresses;
  final Function(BlockchainAddress)? onAddressSelected;
  final bool isLoading;

  const BlockchainAddressList({
    super.key,
    required this.blockchainAddresses,
    this.onAddressSelected,
    this.isLoading = false,
  });

  @override
  State<BlockchainAddressList> createState() => _BlockchainAddressListState();
}

class _BlockchainAddressListState extends State<BlockchainAddressList> {
  
  void _handleAddressSelected(BlockchainAddress address) {
    // 处理地址选择
    if (widget.onAddressSelected != null) {
      widget.onAddressSelected!(address);
    }
  }

  void _handleExpandToggle(BlockchainAddress address) {
    setState(() {
      address.isExpanded = !address.isExpanded;
    });
  }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;

    if (widget.isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
        ),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              '加载地址中...',
              style: TextStyle(color: secondaryTextColor),
            ),
          ],
        ),
      );
    }

    if (widget.blockchainAddresses.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(
              Icons.wallet_outlined,
              size: 48,
              color: secondaryTextColor,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无地址数据',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '请添加钱包或导入地址',
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '区块链地址',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: _showAddressManagement,
                child: Text(
                  '管理',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 地址列表（黑色背景容器）
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
            ),
            padding: const EdgeInsets.all(12),
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: widget.blockchainAddresses.length,
              itemBuilder: (context, index) {
                final blockchainAddress = widget.blockchainAddresses[index];
                return BlockchainAddressCard(
                  blockchainAddress: blockchainAddress,
                  onExpandToggle: () => _handleExpandToggle(blockchainAddress),
                );
              },
            ),
          ),
          
          // 底部提示
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.blue.withOpacity(0.1) 
                  : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark 
                    ? Colors.blue.withOpacity(0.3) 
                    : Colors.blue.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: isDark ? Colors.blue.shade300 : Colors.blue.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '点击地址可复制到剪贴板，点击箭头可展开查看所有地址',
                    style: TextStyle(
                      color: isDark ? Colors.blue.shade300 : Colors.blue.shade600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddressManagement() {
    // 显示地址管理对话框或跳转到地址管理页面
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('地址管理功能开发中...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}