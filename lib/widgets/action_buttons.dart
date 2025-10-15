import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/send_screen.dart';
import '../screens/receive_screen.dart';
import '../screens/address_selection_screen.dart';
import '../providers/wallet_provider.dart';

class ActionButtons extends StatelessWidget {
  const ActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            title: 'Send',
            icon: Icons.arrow_upward,
            color: const Color(0xFF6366F1),
            onTap: () => _handleSendButtonTap(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            title: 'Receive',
            icon: Icons.arrow_downward,
            color: const Color(0xFF3B82F6),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ReceiveScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            title: 'Swap',
            icon: Icons.swap_horiz,
            color: Colors.white,
            textColor: Colors.black,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('兑换功能开发中...')),
              );
            },
          ),
        ),
      ],
    );
  }

  // 处理发送按钮点击事件
  void _handleSendButtonTap(BuildContext context) async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    
    // 检查当前钱包和网络
    if (walletProvider.currentWallet == null || walletProvider.currentNetwork == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择钱包和网络')),
      );
      return;
    }

    final currentWallet = walletProvider.currentWallet!;
    final currentNetwork = walletProvider.currentNetwork!;
    
    // 获取当前网络的地址列表
    final addressList = currentWallet.addresses[currentNetwork.id] ?? [];
    
    if (addressList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前网络没有可用地址')),
      );
      return;
    }
    
    // 根据地址数量决定跳转逻辑
    if (addressList.length == 1) {
      // 只有一个地址，直接跳转到发送页面
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SendScreen(),
        ),
      );
    } else {
      // 多个地址，先跳转到地址选择页面
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddressSelectionScreen(
           network: currentNetwork,
         ),
        ),
      );
    }
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
    Color textColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: textColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}