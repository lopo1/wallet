import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../models/network.dart';
import '../services/private_key_service.dart';

class AccountDetailScreen extends StatefulWidget {
  const AccountDetailScreen({super.key});

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    // 初始化时不需要设置名称控制器，因为我们现在显示地址名称
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _getCurrentAddressDisplayName(dynamic currentWallet, WalletProvider walletProvider) {
    final currentAddress = walletProvider.getCurrentNetworkAddress();
    if (currentAddress == null) {
      return '未知地址';
    }
    
    // 检查是否有自定义名称
    final customName = currentWallet.addressNames[currentAddress];
    if (customName != null && customName.isNotEmpty) {
      return customName;
    }
    
    // 如果没有自定义名称，显示默认格式：钱包名称 + 地址索引
    final networkAddresses = currentWallet.addresses[walletProvider.currentNetwork?.id] ?? [];
    final addressIndex = networkAddresses.indexOf(currentAddress);
    if (addressIndex >= 0) {
      return '${currentWallet.name} #${addressIndex + 1}';
    }
    
    return currentWallet.name;
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('账户详情'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<WalletProvider>(
        builder: (context, walletProvider, child) {
          final currentWallet = walletProvider.currentWallet;
          if (currentWallet == null) {
            return const Center(
              child: Text('没有可用的钱包'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 账户名称编辑
                _buildAccountNameSection(currentWallet, walletProvider),
                const SizedBox(height: 32),
                
                // 网络选择
                _buildNetworkSelector(walletProvider),
                const SizedBox(height: 24),
                
                // 地址信息
                _buildAddressSection(),
                const SizedBox(height: 32),
                
                // 操作按钮
                _buildActionButtons(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAccountNameSection(dynamic currentWallet, WalletProvider walletProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_circle, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                '账户名称',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(_isEditingName ? Icons.check : Icons.edit),
                onPressed: () => _toggleNameEditing(walletProvider),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _isEditingName
              ? TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '输入地址名称',
                  ),
                  onSubmitted: (_) => _toggleNameEditing(walletProvider),
                )
              : Text(
                  _getCurrentAddressDisplayName(currentWallet, walletProvider),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildNetworkSelector(WalletProvider walletProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '选择网络',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Network>(
              value: walletProvider.currentNetwork ?? walletProvider.supportedNetworks.first,
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
                      ),
                      const SizedBox(width: 12),
                      Text(network.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (Network? newNetwork) {
                if (newNetwork != null) {
                  walletProvider.setCurrentNetwork(newNetwork);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
        final currentAddress = walletProvider.getCurrentNetworkAddress();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '当前地址',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${walletProvider.currentNetwork?.name ?? ''} 地址',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    currentAddress ?? '暂无地址',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
        final currentAddress = walletProvider.getCurrentNetworkAddress();
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: currentAddress != null ? () => _copyAddress(currentAddress) : null,
                icon: const Icon(Icons.copy),
                label: const Text('复制地址'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: currentAddress != null ? () => _exportPrivateKey(currentAddress) : null,
                icon: const Icon(Icons.key, color: Colors.orange),
                label: const Text(
                  '导出私钥',
                  style: TextStyle(color: Colors.orange),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Colors.orange),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _toggleNameEditing(WalletProvider walletProvider) async {
    if (_isEditingName) {
      // 保存地址名称
      final newName = _nameController.text.trim();
      final currentAddress = walletProvider.getCurrentNetworkAddress();
      if (currentAddress != null) {
        try {
          await walletProvider.updateAddressName(currentAddress, newName);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('地址名称更新成功'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('更新失败: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } else {
      // 进入编辑模式，设置当前地址名称
      final currentAddress = walletProvider.getCurrentNetworkAddress();
      if (currentAddress != null) {
        final customName = walletProvider.currentWallet?.addressNames[currentAddress];
        _nameController.text = customName ?? '';
      }
    }
    setState(() {
      _isEditingName = !_isEditingName;
    });
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

  void _exportPrivateKey(String address) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1B23),
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                '安全警告',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '导出私钥存在极高安全风险：',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '• 任何人获得您的私钥都可以完全控制对应地址的资产\n'
                '• 私钥一旦泄露，资产将面临被盗风险\n'
                '• 请确保在完全安全的环境中操作\n'
                '• 不要在任何网络平台分享或存储私钥\n'
                '• 建议使用硬件钱包等更安全的方式管理私钥',
                style: TextStyle(
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                '取消',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _proceedWithPrivateKeyExport();
              },
              child: const Text(
                '我了解风险，继续',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        );
      },
    );
  }

  void _proceedWithPrivateKeyExport() {
    final TextEditingController passwordController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1B23),
          title: const Text(
            '输入钱包密码',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: '密码',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '将导出当前网络的私钥',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '取消',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () async {
                final password = passwordController.text.trim();
                if (password.isNotEmpty) {
                  Navigator.of(context).pop();
                  await _performPrivateKeyExport(password);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('请输入密码'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text(
                '确认',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performPrivateKeyExport(String password) async {
    try {
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      final currentWallet = walletProvider.currentWallet;
      
      if (currentWallet == null || walletProvider.currentNetwork == null) {
        throw Exception('没有可用的钱包或网络');
      }
      
      // Get mnemonic first
      final mnemonic = await walletProvider.getWalletMnemonic(
        currentWallet.id,
        password,
      );
      
      if (mnemonic == null || mnemonic.isEmpty) {
        throw Exception('密码错误或助记词获取失败');
      }
      
      // Generate private key for the selected network
      final privateKey = await _generatePrivateKey(mnemonic, walletProvider.currentNetwork!.id);
      
      _showPrivateKeyDialog(privateKey);
    } catch (e) {
      String errorMessage = '导出失败';
      if (e.toString().contains('Invalid password')) {
        errorMessage = '密码错误，请重新输入';
      } else if (e.toString().contains('密码错误')) {
        errorMessage = '密码错误，请重新输入';
      } else {
        errorMessage = '导出失败: $e';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String> _generatePrivateKey(String mnemonic, String networkId) async {
    try {
      // Use the proper private key service to generate real private keys
      final privateKey = await PrivateKeyService.generatePrivateKey(
        mnemonic: mnemonic,
        network: networkId,
        index: 0, // Using index 0 for the first address
      );
      
      return privateKey;
    } catch (e) {
      throw Exception('Failed to generate private key: $e');
    }
  }

  void _showPrivateKeyDialog(String privateKey) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1B23),
          title: Row(
            children: [
              const Icon(Icons.key, color: Colors.orange),
              const SizedBox(width: 8),
              Consumer<WalletProvider>(
                builder: (context, walletProvider, child) {
                  return Text(
                    '${walletProvider.currentNetwork?.name ?? ''} 私钥',
                    style: const TextStyle(color: Colors.white),
                  );
                },
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '地址:',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Consumer<WalletProvider>(
                    builder: (context, walletProvider, child) {
                      return SelectableText(
                        walletProvider.getCurrentNetworkAddress() ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '私钥:',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: SelectableText(
                    privateKey,
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 14,
                      fontFamily: 'monospace',
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '请立即安全保存此私钥，关闭后将无法再次查看',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: privateKey));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('私钥已复制到剪贴板'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              child: const Text(
                '复制私钥',
                style: TextStyle(color: Colors.orange),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                '关闭',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        );
      },
    );
  }
}