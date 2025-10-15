import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../models/network.dart';
import 'qr_display_screen.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  final Set<String> _expandedNetworks = <String>{};
  final Map<String, bool> _copiedAddresses = <String, bool>{};
  double _dragOffset = 0.0;
  bool _isDragging = false;

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragOffset = 0.0;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dy;
      // 限制拖拽范围，只允许向下拖拽
      if (_dragOffset < 0) _dragOffset = 0;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });

    // 如果拖拽距离超过阈值，则关闭页面
    if (_dragOffset > 100) {
      Navigator.pop(context);
    } else {
      // 否则回弹到原位置
      setState(() {
        _dragOffset = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 背景层 - 显示之前页面的内容（模拟效果）
          Container(
            color: const Color(0xFF1A1A1A), // 稍微不同的背景色来模拟之前的页面
            child: SafeArea(
              child: Column(
                children: [
                  // 模拟之前页面的内容
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet,
                            color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        const Text(
                          '钱包',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.settings, color: Colors.white),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  // 模拟资产列表
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          '资产列表',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          // 前景层 - 当前接收页面
          Transform.translate(
            offset: Offset(0, _dragOffset),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: _dragOffset > 0
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      )
                    : null,
                boxShadow: _dragOffset > 0
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  // 状态栏占位
                  Container(
                    height: MediaQuery.of(context).padding.top,
                    color: Colors.black,
                  ),
                  // 拖拽指示条 - 现在在最顶部（状态栏下方）
                  GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: Container(
                      width: double.infinity,
                      color: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: _isDragging
                                ? Colors.white.withValues(alpha: 0.8)
                                : Colors.white.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // AppBar区域 - 现在在拖拽指示条下方
                  Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '接收',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            // 检查是否可以返回，如果不能则导航到首页
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            } else {
                              Navigator.of(context).pushReplacementNamed('/home');
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  // 主要内容区域
                  Expanded(
                    child: Consumer<WalletProvider>(
                      builder: (context, walletProvider, child) {
                        return Container(
                          color: Colors.transparent,
                          child: DraggableScrollableSheet(
                            initialChildSize: 1.0,
                            minChildSize: 0.0,
                            maxChildSize: 1.0,
                            builder: (context, scrollController) {
                              return Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  ),
                                ),
                                child: SingleChildScrollView(
                                  controller: scrollController,
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      // 显示所有支持的网络和地址
                                      ...walletProvider.supportedNetworks
                                          .map((network) {
                                        return _buildNetworkCard(
                                            network, walletProvider);
                                      }),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkCard(Network network, WalletProvider walletProvider) {
    final currentWallet = walletProvider.currentWallet;
    final addresses = currentWallet?.addresses[network.id] ?? [];
    final primaryAddress = addresses.isNotEmpty ? addresses.first : null;
    final isExpanded = _expandedNetworks.contains(network.id);
    final hasMultipleAddresses = addresses.length > 1;

    // 为主地址创建唯一标识符
    final primaryAddressKey =
        primaryAddress != null ? '${network.id}_primary_$primaryAddress' : null;
    final isCopied = primaryAddressKey != null &&
        (_copiedAddresses[primaryAddressKey] ?? false);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded ? const Color(0xFF6C5CE7) : Colors.white12,
          width: isExpanded ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // 主要地址卡片
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 网络图标
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(network.color),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      network.symbol.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 网络名称和地址
                Expanded(
                  child: GestureDetector(
                    onTap: primaryAddress != null
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QRDisplayScreen(
                                  address: primaryAddress,
                                  networkName: network.name,
                                  networkSymbol: network.symbol,
                                ),
                              ),
                            );
                          }
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          network.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: isCopied
                              ? Text(
                                  '已复制',
                                  key: ValueKey('copied_$primaryAddressKey'),
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              : Text(
                                  primaryAddress != null
                                      ? '${primaryAddress.substring(0, 6)}...${primaryAddress.substring(primaryAddress.length - 4)}'
                                      : '暂无地址',
                                  key: ValueKey('address_$primaryAddressKey'),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 右侧操作按钮
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // QR码按钮
                    GestureDetector(
                      onTap: primaryAddress != null
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => QRDisplayScreen(
                                    address: primaryAddress,
                                    networkName: network.name,
                                    networkSymbol: network.symbol,
                                  ),
                                ),
                              );
                            }
                          : null,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.qr_code,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 复制按钮
                    GestureDetector(
                      onTap: primaryAddress != null && primaryAddressKey != null
                          ? () {
                              _copyAddress(primaryAddress, primaryAddressKey);
                            }
                          : null,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          isCopied ? Icons.check : Icons.copy,
                          color: isCopied ? Colors.green : Colors.white,
                          size: 20,
                        ),
                      ),
                    ),

                    // 展开按钮（仅在有多个地址时显示）
                    if (hasMultipleAddresses) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedNetworks.remove(network.id);
                            } else {
                              _expandedNetworks.add(network.id);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // 展开的地址列表
          if (isExpanded && hasMultipleAddresses)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children:
                    addresses.skip(1).toList().asMap().entries.map((entry) {
                  final index =
                      entry.key + 1; // +1 because we skipped the first address
                  final address = entry.value;

                  // 为每个地址创建唯一标识符
                  final addressKey = '${network.id}_${index}_$address';
                  final isAddressCopied = _copiedAddresses[addressKey] ?? false;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D0D1A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        // 小圆点
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white70,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // 地址
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => QRDisplayScreen(
                                    address: address,
                                    networkName: network.name,
                                    networkSymbol: network.symbol,
                                  ),
                                ),
                              );
                            },
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: isAddressCopied
                                  ? Text(
                                      '已复制',
                                      key: ValueKey('copied_$addressKey'),
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    )
                                  : Text(
                                      '${address.substring(0, 6)}...${address.substring(address.length - 4)}',
                                      key: ValueKey('address_$addressKey'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        // QR码按钮
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QRDisplayScreen(
                                  address: address,
                                  networkName: network.name,
                                  networkSymbol: network.symbol,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.qr_code,
                              color: Colors.white70,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // 复制按钮
                        GestureDetector(
                          onTap: () => _copyAddress(address, addressKey),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              isAddressCopied ? Icons.check : Icons.copy,
                              color: isAddressCopied
                                  ? Colors.green
                                  : Colors.white70,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  void _copyAddress(String address, String addressKey) {
    Clipboard.setData(ClipboardData(text: address));

    setState(() {
      _copiedAddresses[addressKey] = true;
    });

    // 2秒后恢复显示地址
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copiedAddresses[addressKey] = false;
        });
      }
    });
  }
}
