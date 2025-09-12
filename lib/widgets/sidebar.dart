import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';

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
          // Header with Ethereum logo and collapse button
          Container(
            padding: EdgeInsets.all(_isCollapsed ? 12 : 24),
            child: Row(
              mainAxisAlignment: _isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
              children: [
                if (!_isCollapsed)
                  Container(
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
                    child: const Icon(
                      Icons.chevron_right,
                      color: Colors.white70,
                      size: 20,
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
                    final networkAddress = addressList?.isNotEmpty == true ? addressList!.first : null;
                    
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
                          onDropdownTap: networkAddress != null && !_isCollapsed ? () {
                            setState(() {
                              _expandedNetworkId = isExpanded ? null : network.id;
                            });
                          } : null,
                        ),
                        if (isExpanded && addressList != null && addressList.isNotEmpty && !_isCollapsed)
                          ...addressList.map((address) => _buildAddressDropdown(address)),
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
                  icon: Icons.apps,
                  name: 'DApps',
                  isSelected: true,
                  isCollapsed: _isCollapsed,
                ),
                const SizedBox(height: 8),
                _buildBottomItem(
                  icon: Icons.build,
                  name: 'Toolbox',
                  isCollapsed: _isCollapsed,
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
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (hasDropdown)
                    GestureDetector(
                      onTap: onDropdownTap,
                      child: Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
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
  }) {
    return Container(
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
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAddressDropdown(String address) {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
        final currentWallet = walletProvider.currentWallet;
        final addressName = currentWallet?.addressNames[address];
        final displayName = addressName ?? _getDefaultAddressName(walletProvider, address);
        final isSelected = walletProvider.selectedAddress == address;
        
        return GestureDetector(
          onTap: () {
            walletProvider.setSelectedAddress(address);
          },
          child: Container(
            margin: const EdgeInsets.only(left: 36, right: 12, bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF2A2D3A) : const Color(0xFF1A1B23),
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