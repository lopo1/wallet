import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../models/network.dart';
import '../services/address_count_service.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final TextEditingController _searchController = TextEditingController();
  double _dragOffset = 0.0;
  bool _isDragging = false;
  String _searchQuery = '';
  Map<String, int> _addressCounts = {};
  bool _isLoadingAddressCounts = false;
  final Set<String> _expandedTokens = <String>{}; // 跟踪展开的代币

  @override
  void initState() {
    super.initState();
    _loadAddressCounts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 加载地址数量
  Future<void> _loadAddressCounts() async {
    if (_isLoadingAddressCounts) return;

    setState(() {
      _isLoadingAddressCounts = true;
    });

    try {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      final networks = walletProvider.supportedNetworks;
      final Map<String, int> counts = {};

      for (final network in networks) {
        final count = await AddressCountService.getAddressCount(network.id);
        counts[network.id] = count;
      }

      if (mounted) {
        setState(() {
          _addressCounts = counts;
          _isLoadingAddressCounts = false;
        });
      }
    } catch (e) {
      debugPrint('加载地址数量失败: $e');
      if (mounted) {
        setState(() {
          _isLoadingAddressCounts = false;
        });
      }
    }
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragOffset = 0.0;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dy;
      if (_dragOffset < 0) _dragOffset = 0;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });

    if (_dragOffset > 100) {
      Navigator.pop(context);
    } else {
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
          // 背景层
          Container(
            color: const Color(0xFF1A1A1A),
            child: SafeArea(
              child: Column(
                children: [
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
          // 前景层 - 发送页面
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
                  // 拖拽指示条
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
                  // AppBar区域
                  Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back,
                                  color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '选择币种',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        // 网络选择器
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A2E),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.language,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text(
                                '全部网络',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down,
                                  color: Colors.white, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 搜索框
                  Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search,
                            color: Colors.white54, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: '代币名称或者合约地址',
                              hintStyle: TextStyle(
                                  color: Colors.white38, fontSize: 14),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value.toLowerCase();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 主要内容区域 - 代币列表
                  Expanded(
                    child: Consumer<WalletProvider>(
                      builder: (context, walletProvider, child) {
                        final networks = walletProvider.supportedNetworks;
                        final filteredNetworks = _searchQuery.isEmpty
                            ? networks
                            : networks.where((network) {
                                return network.name
                                        .toLowerCase()
                                        .contains(_searchQuery) ||
                                    network.symbol
                                        .toLowerCase()
                                        .contains(_searchQuery);
                              }).toList();

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: filteredNetworks.length,
                          itemBuilder: (context, index) {
                            return _buildTokenCard(
                                filteredNetworks[index], walletProvider);
                          },
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

  Widget _buildTokenCard(Network network, WalletProvider walletProvider) {
    final currentWallet = walletProvider.currentWallet;
    final addresses = currentWallet?.addresses[network.id] ?? [];
    final primaryAddress = addresses.isNotEmpty ? addresses.first : null;
    final hasMultipleAddresses = addresses.length > 1;
    final isExpanded = _expandedTokens.contains(network.id);

    // 判断是否为原生代币（简化判断）
    final isNativeToken = _isNativeToken(network.id);

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                if (hasMultipleAddresses) {
                  // 如果有多个地址，展开/收起地址列表
                  setState(() {
                    if (isExpanded) {
                      _expandedTokens.remove(network.id);
                    } else {
                      _expandedTokens.add(network.id);
                    }
                  });
                } else if (primaryAddress != null) {
                  // 如果只有一个地址，直接进入发送详情页面
                  _navigateToSendDetail(network, primaryAddress);
                }
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // 代币图标 + 链图标
                    Stack(
                      children: [
                        // 主代币图标
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Color(network.color).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Center(
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Color(network.color),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  network.symbol.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // 链图标徽章（右下角）
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: _getChainBadgeColor(network.id),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF1A1A2E),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _getChainIcon(network.id),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),

                    // 代币信息
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 代币符号 + 链标识
                          Row(
                            children: [
                              Text(
                                network.symbol,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              // 链标识徽章
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6C5CE7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _getChainBadgeText(network.id),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // 显示合约地址或链名称
                          Text(
                            isNativeToken
                                ? network.name
                                : (primaryAddress != null
                                    ? '${primaryAddress.substring(0, 8)}...${primaryAddress.substring(primaryAddress.length - 8)}'
                                    : network.name),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 余额信息
                    FutureBuilder<double>(
                      future: walletProvider.getNetworkBalance(network.id),
                      builder: (context, snapshot) {
                        final balance = snapshot.data ?? 0.0;
                        final usdValue = balance * _getTokenPrice(network.id);
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              balance.toStringAsFixed(2),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '≈\$${usdValue.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    // 展开/收起图标（仅在有多个地址时显示）
                    if (hasMultipleAddresses)
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white54,
                          size: 20,
                        ),
                      )
                    else
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white24,
                        size: 14,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // 展开的地址列表
        if (isExpanded && hasMultipleAddresses)
          Container(
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: addresses.asMap().entries.map((entry) {
                final index = entry.key;
                final address = entry.value;

                return Container(
                  margin: EdgeInsets.only(
                      bottom: index < addresses.length - 1 ? 8 : 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: InkWell(
                    onTap: () {
                      // 选择特定地址进行发送，进入发送详情页面
                      _navigateToSendDetail(network, address);
                    },
                    child: Row(
                      children: [
                        // 地址信息
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${network.symbol} Chain${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${address.substring(0, 8)}...${address.substring(address.length - 8)}',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 地址余额
                        FutureBuilder<double>(
                          future: walletProvider.getNetworkBalance(network.id),
                          builder: (context, snapshot) {
                            final addressBalance = snapshot.data ?? 0.0;
                            final addressUsdValue = addressBalance * _getTokenPrice(network.id);
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  addressBalance.toStringAsFixed(2),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '≈\$${addressUsdValue.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  String _getChainBadgeText(String networkId) {
    // 返回链标识文本
    switch (networkId) {
      case 'ethereum':
        return '+1';
      case 'bitcoin':
        return '+2';
      case 'solana':
        return '+1';
      case 'polygon':
        return '+2';
      case 'bsc':
        return '+2';
      case 'avalanche':
        return '+1';
      case 'arbitrum':
        return '+1';
      case 'optimism':
        return '+1';
      case 'base':
        return '+1';
      case 'tron':
        return '+1';
      default:
        return '+1';
    }
  }

  String _getChainIcon(String networkId) {
    // 返回链图标（字符）
    switch (networkId) {
      case 'ethereum':
        return 'E';
      case 'bitcoin':
        return 'B';
      case 'solana':
        return 'S';
      case 'polygon':
        return 'P';
      case 'bsc':
        return 'B';
      case 'avalanche':
        return 'A';
      case 'arbitrum':
        return 'A';
      case 'optimism':
        return 'O';
      case 'base':
        return 'B';
      case 'tron':
        return 'T';
      default:
        return '?';
    }
  }

  Color _getChainBadgeColor(String networkId) {
    // 返回链徽章颜色
    switch (networkId) {
      case 'ethereum':
        return const Color(0xFF627EEA);
      case 'bitcoin':
        return const Color(0xFFF7931A);
      case 'solana':
        return const Color(0xFF14F195);
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
        return const Color(0xFFEB0029);
      default:
        return const Color(0xFF6C5CE7);
    }
  }

  bool _isNativeToken(String networkId) {
    // 判断是否为原生代币
    // 这里简化处理，实际应该根据token的合约地址判断
    // 原生代币通常没有合约地址
    return true; // 暂时都当作原生代币，实际需要根据token类型判断
  }

  double _getTokenPrice(String networkId) {
    // 模拟代币价格数据
    switch (networkId) {
      case 'ethereum':
        return 2000.0;
      case 'bitcoin':
        return 45000.0;
      case 'solana':
        return 100.0;
      case 'polygon':
        return 0.8;
      case 'bsc':
        return 300.0;
      case 'avalanche':
        return 25.0;
      case 'arbitrum':
        return 2000.0;
      case 'optimism':
        return 2000.0;
      case 'base':
        return 2000.0;
      case 'tron':
        return 0.1;
      default:
        return 1.0;
    }
  }

  void _navigateToSendDetail(Network network, String address) {
    Navigator.pushNamed(
      context,
      '/send_detail',
      arguments: {
        'network': network,
        'address': address,
      },
    );
  }
}
