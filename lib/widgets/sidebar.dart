import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../models/wallet.dart';
import '../models/network.dart';

class Sidebar extends StatefulWidget {
  final Function(bool)? onCollapseChanged;

  const Sidebar({super.key, this.onCollapseChanged});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  String? _expandedNetworkId;
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _isCollapsed ? 80 : 300,
      color: const Color(0xFF2A2D3A),
      child: Column(
        children: [
          // Header with wallet selector and collapse button
          Container(
            padding: EdgeInsets.all(_isCollapsed ? 12 : 24),
            child: Row(
              mainAxisAlignment: _isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.spaceBetween,
              children: [
                if (!_isCollapsed)
                  Expanded(
                    child: _buildWalletSelector(),
                  ),
                if (!_isCollapsed)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isCollapsed = !_isCollapsed;
                      });
                      widget.onCollapseChanged?.call(_isCollapsed);
                    },
                    child: const Icon(
                      Icons.chevron_left,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                if (_isCollapsed)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isCollapsed = !_isCollapsed;
                      });
                      widget.onCollapseChanged?.call(_isCollapsed);
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFF627EEA),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Portfolio section
          if (!_isCollapsed)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Portfolio',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Total Retolls',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
          // Network list
          Expanded(
            child: Consumer<WalletProvider>(
              builder: (context, walletProvider, child) {
                final networks = walletProvider.supportedNetworks;
                final currentNetwork = walletProvider.currentNetwork;

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: networks.map((network) {
                    final isSelected = currentNetwork?.id == network.id;
                    final isExpanded = _expandedNetworkId == network.id;
                    final currentWallet = walletProvider.currentWallet;
                    final addressList = currentWallet?.addresses[network.id];
                    final networkAddress = addressList?.isNotEmpty == true
                        ? addressList!.first
                        : null;

                    return Column(
                      children: [
                        _buildNetworkItem(
                          icon: _getNetworkIcon(network.id),
                          name: network.name,
                          color: Color(network.color),
                          isSelected: isSelected,
                          hasDropdown: networkAddress != null && !_isCollapsed,
                          isExpanded: isExpanded,
                          isCollapsed: _isCollapsed,
                          onTap: () {
                            walletProvider.setCurrentNetwork(network);
                          },
                          onDropdownTap: networkAddress != null && !_isCollapsed
                              ? () {
                                  setState(() {
                                    _expandedNetworkId =
                                        isExpanded ? null : network.id;
                                  });
                                }
                              : null,
                        ),
                        if (isExpanded &&
                            addressList != null &&
                            addressList.isNotEmpty &&
                            !_isCollapsed)
                          ...addressList.map((address) =>
                              _buildAddressDropdown(address, network)),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ),
          // Bottom section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildBottomItem(
                  icon: Icons.build,
                  name: 'Toolbox',
                  isCollapsed: _isCollapsed,
                ),
                const SizedBox(height: 8),
                _buildBottomItem(
                  icon: Icons.calculate,
                  name: 'Solana 费用估算',
                  isCollapsed: _isCollapsed,
                  onTap: () {
                    Navigator.pushNamed(context, '/solana-fee-estimator');
                  },
                ),
                const SizedBox(height: 8),
                _buildBottomItem(
                  icon: Icons.link,
                  name: 'WalletConnect',
                  isCollapsed: _isCollapsed,
                  onTap: () {
                    Navigator.pushNamed(context, '/walletconnect-sessions');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkItem({
    required IconData icon,
    required String name,
    required Color color,
    bool isSelected = false,
    bool hasDropdown = false,
    bool isExpanded = false,
    bool isCollapsed = false,
    VoidCallback? onTap,
    VoidCallback? onDropdownTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3A3D4A) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: const Color(0xFF6366F1), width: 2)
              : null,
        ),
        child: isCollapsed
            ? Center(
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              )
            : Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (hasDropdown)
                    GestureDetector(
                      onTap: onDropdownTap,
                      child: Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildBottomItem({
    required IconData icon,
    required String name,
    bool isSelected = false,
    bool isCollapsed = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3A3D4A) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: isCollapsed
            ? Center(
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.white70,
                  size: 20,
                ),
              )
            : Row(
                children: [
                  Icon(
                    icon,
                    color: isSelected ? Colors.white : Colors.white70,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAddressDropdown(String address, Network network) {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
        final currentWallet = walletProvider.currentWallet;
        final addressName = currentWallet?.addressNames[address];
        final displayName =
            addressName ?? _getDefaultAddressName(walletProvider, address);
        final isSelected = walletProvider.selectedAddress == address;

        return GestureDetector(
          onTap: () {
            // 直接使用传入的网络上下文，避免EVM网络地址相同的问题
            walletProvider.setCurrentNetwork(network);
            walletProvider.setSelectedAddress(address);
          },
          child: Container(
            margin: const EdgeInsets.only(left: 36, right: 12, bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF2A2D3A)
                  : const Color(0xFF1A1B23),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? const Color(0xFF4A90E2) : Colors.white10,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _getShortAddress(address),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/account_detail');
                          },
                          child: const Icon(
                            Icons.settings,
                            color: Colors.white70,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            _copyAddress(context, address);
                          },
                          child: const Icon(
                            Icons.copy,
                            color: Colors.white70,
                            size: 14,
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
      },
    );
  }

  String _getDefaultAddressName(WalletProvider walletProvider, String address) {
    final currentWallet = walletProvider.currentWallet;
    final currentNetwork = walletProvider.currentNetwork;
    if (currentWallet != null && currentNetwork != null) {
      final addressList = currentWallet.addresses[currentNetwork.id];
      if (addressList != null) {
        final index = addressList.indexOf(address);
        if (index >= 0) {
          return '${currentWallet.name} #${index + 1}';
        }
      }
    }
    return '地址';
  }

  String _getShortAddress(String address) {
    if (address.length > 10) {
      return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
    }
    return address;
  }

  IconData _getNetworkIcon(String networkId) {
    switch (networkId) {
      case 'ethereum':
        return Icons.currency_bitcoin;
      case 'polygon':
        return Icons.hexagon;
      case 'bsc':
        return Icons.account_balance;
      case 'bitcoin':
        return Icons.currency_bitcoin;
      case 'solana':
        return Icons.wb_sunny;
      default:
        return Icons.network_check;
    }
  }

  Widget _buildWalletSelector() {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
        final wallets = walletProvider.wallets;
        final currentWallet = walletProvider.currentWallet;

        if (wallets.isEmpty || currentWallet == null) {
          return Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF627EEA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.currency_bitcoin,
              color: Colors.white,
              size: 20,
            ),
          );
        }

        return GestureDetector(
          onTap: () => _showWalletDropdown(context, walletProvider),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFF627EEA),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          currentWallet.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 3),
                      CustomPaint(
                        size: const Size(8, 5),
                        painter: TrianglePainter(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWalletDropdown(
      BuildContext context, WalletProvider walletProvider) {
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
            color: Color(0xFF2A2D3A),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
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
              // Wallet list
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: walletProvider.wallets.length,
                  itemBuilder: (context, index) {
                    final wallet = walletProvider.wallets[index];
                    final isSelected =
                        walletProvider.currentWallet?.id == wallet.id;

                    return _buildWalletItem(
                      wallet: wallet,
                      isSelected: isSelected,
                      onTap: () {
                        walletProvider.setCurrentWallet(wallet);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              // Add wallet button
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showAddWalletOptions(context);
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('添加钱包'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWalletItem({
    required Wallet wallet,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3A3D4A) : const Color(0xFF1A1B23),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF627EEA).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: Color(0xFF627EEA),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wallet.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '创建于 ${_formatDate(wallet.createdAt)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF6366F1),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _showAddWalletOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF2A2D3A),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const Text(
                '添加钱包',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.add_circle, color: Colors.white70),
                title:
                    const Text('创建新钱包', style: TextStyle(color: Colors.white)),
                subtitle: const Text('生成新的助记词',
                    style: TextStyle(color: Colors.white70)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/create_wallet');
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_download, color: Colors.white70),
                title:
                    const Text('导入钱包', style: TextStyle(color: Colors.white)),
                subtitle: const Text('使用助记词导入',
                    style: TextStyle(color: Colors.white70)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/import_wallet');
                },
              ),
              ListTile(
                leading: const Icon(Icons.vpn_key, color: Colors.white70),
                title:
                    const Text('导入私钥', style: TextStyle(color: Colors.white)),
                subtitle: const Text('使用私钥导入',
                    style: TextStyle(color: Colors.white70)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/import_private_key');
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  void _copyAddress(BuildContext context, String address) {
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('地址已复制到剪贴板'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// 自定义三角形绘制器
class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    // 绘制向下的三角形
    path.moveTo(0, 0); // 左上角
    path.lineTo(size.width, 0); // 右上角
    path.lineTo(size.width / 2, size.height); // 底部中心点
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
