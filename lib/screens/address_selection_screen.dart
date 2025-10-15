import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../models/network.dart';

class AddressSelectionScreen extends StatefulWidget {
  final Network network;
  final Map<String, dynamic>? preselectedToken;

  const AddressSelectionScreen({
    super.key,
    required this.network,
    this.preselectedToken,
  });

  @override
  State<AddressSelectionScreen> createState() => _AddressSelectionScreenState();
}

class _AddressSelectionScreenState extends State<AddressSelectionScreen> {
  String? _selectedAddress;

  // 获取特定地址的余额
  Future<double> _getAddressBalance(WalletProvider walletProvider, String address) async {
    try {
      // 暂时选择该地址以获取余额
      final originalAddress = walletProvider.selectedAddress;
      walletProvider.setSelectedAddress(address);
      
      // 获取余额
      final balance = await walletProvider.getNetworkBalance(widget.network.id);
      
      // 恢复原来的选中地址
      if (originalAddress != null) {
        walletProvider.setSelectedAddress(originalAddress);
      }
      
      return balance;
    } catch (e) {
      debugPrint('获取地址余额失败: $e');
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              '选择发送地址',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _getNetworkColor(widget.network.id),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      widget.network.symbol.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.network.name,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Consumer<WalletProvider>(
        builder: (context, walletProvider, child) {
          final currentWallet = walletProvider.currentWallet;
          if (currentWallet == null) {
            return const Center(
              child: Text(
                '未找到钱包',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final addresses = currentWallet.addresses[widget.network.id] ?? [];
          
          if (addresses.isEmpty) {
            return const Center(
              child: Text(
                '该网络暂无地址',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return Column(
            children: [
              // 提示信息
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.withValues(alpha: 0.8),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '请选择用于发送交易的地址',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // 地址列表 - 全部展示
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: addresses.length, // 显示所有地址
                  itemBuilder: (context, index) {
                    final address = addresses[index];
                    final isSelected = _selectedAddress == address;
                    final addressName = currentWallet.addressNames[address] ?? '地址 ${index + 1}';
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isSelected 
                          ? const Color(0xFF6C5CE7).withOpacity(0.1)
                          : const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected 
                            ? const Color(0xFF6C5CE7) 
                            : Colors.white.withOpacity(0.1),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedAddress = address;
                          });
                          // 直接跳转到发送详情页面
                          Navigator.pushNamed(
                            context,
                            '/send_detail',
                            arguments: {
                              'network': widget.network,
                              'address': address,
                              if (widget.preselectedToken != null) 'preselectedToken': widget.preselectedToken,
                            },
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // 选择指示器
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected 
                                      ? const Color(0xFF6C5CE7) 
                                      : Colors.white30,
                                    width: 2,
                                  ),
                                  color: isSelected 
                                    ? const Color(0xFF6C5CE7) 
                                    : Colors.transparent,
                                ),
                                child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 14,
                                    )
                                  : null,
                              ),
                              const SizedBox(width: 16),
                              
                              // 地址信息
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      addressName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${address.substring(0, 8)}...${address.substring(address.length - 8)}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // 余额显示
                                    FutureBuilder<double>(
                                      future: _getAddressBalance(walletProvider, address),
                                      builder: (context, snapshot) {
                                        final balance = snapshot.data ?? 0.0;
                                        return Text(
                                          '$balance ${widget.network.symbol}',
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              
                              // 复制按钮
                              IconButton(
                                icon: const Icon(
                                  Icons.copy,
                                  color: Colors.white54,
                                  size: 20,
                                ),
                                onPressed: () => _copyAddress(address),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 复制地址到剪贴板
  void _copyAddress(String address) {
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('地址已复制到剪贴板'),
        backgroundColor: const Color(0xFF6C5CE7),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // 确认选择
  void _confirmSelection() {
    if (_selectedAddress != null) {
      Navigator.pushNamed(
        context,
        '/send_detail',
        arguments: {
          'network': widget.network,
          'address': _selectedAddress!,
          if (widget.preselectedToken != null) 'preselectedToken': widget.preselectedToken,
        },
      );
    }
  }

  // 获取网络颜色
  Color _getNetworkColor(String networkId) {
    switch (networkId) {
      case 'ethereum':
        return const Color(0xFF627EEA);
      case 'bitcoin':
        return const Color(0xFFF7931A);
      case 'solana':
        return const Color(0xFF9945FF);
      case 'polygon':
        return const Color(0xFF8247E5);
      case 'bsc':
        return const Color(0xFFF3BA2F);
      case 'avalanche':
        return const Color(0xFFE84142);
      case 'arbitrum':
        return const Color(0xFF28A0F0);
      case 'optimism':
        return const Color(0xFFFF0420);
      case 'base':
        return const Color(0xFF0052FF);
      case 'tron':
        return const Color(0xFFFF060A);
      default:
        return const Color(0xFF26D0CE);
    }
  }

  // 显示所有地址的对话框
  void _showAllAddressesDialog(List<String> addresses, dynamic currentWallet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '选择地址',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final address = addresses[index];
              final addressName = currentWallet.addressNames[address] ?? '地址 ${index + 1}';
              
              return ListTile(
                title: Text(
                  addressName,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${address.substring(0, 8)}...${address.substring(address.length - 8)}',
                  style: const TextStyle(color: Colors.white70),
                ),
                onTap: () {
                  Navigator.pop(context); // 关闭对话框
                  Navigator.pushNamed(
                    context,
                    '/send_detail',
                    arguments: {
                      'network': widget.network,
                      'address': address,
                      if (widget.preselectedToken != null) 'preselectedToken': widget.preselectedToken,
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '取消',
              style: TextStyle(color: Color(0xFF6C5CE7)),
            ),
          ),
        ],
      ),
    );
  }
}