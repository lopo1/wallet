import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/wallet_provider.dart';
import '../models/network.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  Network? _selectedNetwork;
  String? _currentAddress;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      setState(() {
        _selectedNetwork = walletProvider.currentNetwork ?? walletProvider.supportedNetworks.first;
      });
      _loadAddress();
    });
  }

  Future<void> _loadAddress() async {
    if (_selectedNetwork == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      final currentWallet = walletProvider.currentWallet;
      if (currentWallet != null) {
        // 使用选中的地址或默认地址
        String? address = walletProvider.getCurrentNetworkAddress();
        
        // 如果地址不存在，重新生成
        if (address == null || address.isEmpty) {
          // 需要用户输入密码获取助记词来生成地址
          final password = await _showPasswordDialog();
          if (password == null) {
            throw Exception('需要密码来生成地址');
          }
          
          final retrievedMnemonic = await walletProvider.getWalletMnemonic(
            currentWallet.id, 
            password
          );
          
          if (retrievedMnemonic == null || retrievedMnemonic.isEmpty) {
            throw Exception('密码错误或助记词获取失败');
          }
          
          address = await walletProvider.generateAddressForNetwork(
            retrievedMnemonic, 
            _selectedNetwork!.id
          );
          
          // 更新钱包中的地址并保存到存储
          currentWallet.addresses[_selectedNetwork!.id] = [address];
          await walletProvider.updateWalletAddresses(
            currentWallet.id, 
            currentWallet.addresses
          );
        }
        
        setState(() {
          _currentAddress = address;
        });
      } else {
        throw Exception('没有可用的钱包');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('获取地址失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<String?> _showPasswordDialog() async {
    final TextEditingController passwordController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('输入钱包密码'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '密码',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final password = passwordController.text.trim();
                if (password.isNotEmpty) {
                  Navigator.of(context).pop(password);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('请输入密码'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('接收'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer<WalletProvider>(
            builder: (context, walletProvider, child) {
              final currentAddress = walletProvider.getCurrentNetworkAddress();
              return IconButton(
                icon: const Icon(Icons.share),
                onPressed: currentAddress != null ? () { _shareAddress(currentAddress); } : null,
              );
            },
          ),
        ],
      ),
      body: Consumer<WalletProvider>(
        builder: (context, walletProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Network Selection
                _buildNetworkSelector(walletProvider),
                const SizedBox(height: 32),
                
                // QR Code
                _buildQRCode(),
                const SizedBox(height: 32),
                
                // Address Display
                _buildAddressDisplay(),
                const SizedBox(height: 32),
                
                // Action Buttons
                _buildActionButtons(),
                const SizedBox(height: 24),
                
                // Instructions
                _buildInstructions(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNetworkSelector(WalletProvider walletProvider) {
    return Column(
      children: [
        const Text(
          '选择网络',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Network>(
              value: _selectedNetwork,
              hint: const Text('选择网络'),
              isExpanded: true,
              items: walletProvider.supportedNetworks.map((network) {
                return DropdownMenuItem<Network>(
                  value: network,
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Color(network.color),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(network.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (Network? network) {
                setState(() {
                  _selectedNetwork = network;
                  _currentAddress = null;
                });
                _loadAddress();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQRCode() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Consumer<WalletProvider>(
        builder: (context, walletProvider, child) {
          final currentAddress = walletProvider.getCurrentNetworkAddress();
          return _isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : currentAddress != null
                  ? _buildQRCodeContent(currentAddress)
                  : const Center(
                      child: Icon(
                        Icons.qr_code,
                        size: 80,
                        color: Colors.grey,
                      ),
                    );
        },
      ),
    );
  }

  Widget _buildQRCodeContent(String address) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: QrImageView(
        data: address,
        version: QrVersions.auto,
        size: 160.0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      ),
    );
  }

  Widget _buildAddressDisplay() {
    if (_currentAddress == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            '请选择网络',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '我的地址',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (_selectedNetwork != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(_selectedNetwork!.color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _selectedNetwork!.name,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(_selectedNetwork!.color),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Consumer<WalletProvider>(
            builder: (context, walletProvider, child) {
              final currentAddress = walletProvider.getCurrentNetworkAddress();
              return SelectableText(
                currentAddress ?? '暂无地址',
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
        final currentAddress = walletProvider.getCurrentNetworkAddress();
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: currentAddress != null ? () { _copyAddress(currentAddress); } : null,
                    icon: const Icon(Icons.copy),
                    label: const Text('复制地址'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: currentAddress != null ? () { _shareAddress(currentAddress); } : null,
                    icon: const Icon(Icons.share),
                    label: const Text('分享'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '接收说明',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• 只能接收 ${_selectedNetwork?.name ?? ''} 网络上的 ${_selectedNetwork?.symbol ?? ''} 代币\n'
            '• 发送其他网络的代币到此地址将导致资产丢失\n'
            '• 请确认发送方使用正确的网络和地址',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _copyAddress(String address) {
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('地址已复制到剪贴板'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareAddress(String address) {
    // In a real app, you would use the share package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('分享功能待实现')),
    );
  }
}