import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../models/network.dart';
import '../services/private_key_service.dart';
import '../constants/password_constants.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        title: const Text(
          '修改钱包名称',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // 检查是否可以返回，如果不能则导航到首页
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          },
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
        color: const Color(0xFF1A1B23),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_circle, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                '修改钱包名称',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(_isEditingName ? Icons.check : Icons.edit, color: Colors.white),
                onPressed: () => _toggleNameEditing(walletProvider),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _isEditingName
              ? TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF6366F1)),
                    ),
                    hintText: '输入钱包名称',
                    hintStyle: TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: (_) => _toggleNameEditing(walletProvider),
                )
              : Text(
                  currentWallet.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
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
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1B23),
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Network>(
              value: walletProvider.currentNetwork ?? walletProvider.supportedNetworks.first,
              isExpanded: true,
              dropdownColor: const Color(0xFF1A1B23),
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
                      Text(
                        network.name,
                        style: const TextStyle(color: Colors.white),
                      ),
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
        final currentWallet = walletProvider.currentWallet;
        final currentNetwork = walletProvider.currentNetwork;
        
        if (currentWallet == null || currentNetwork == null) {
          return const SizedBox.shrink();
        }

        final addressList = currentWallet.addresses[currentNetwork.id] ?? [];
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${currentNetwork.name} 地址列表',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    onPressed: () => _generateNewAddress(walletProvider),
                    icon: const Icon(Icons.add, color: Colors.white, size: 20),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1B23),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: addressList.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 48,
                            color: Colors.white70,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '暂无地址',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '点击右上角加号生成新地址',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(12),
                      itemCount: addressList.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final address = addressList[index];
                        final addressName = currentWallet.addressNames[address] ?? 
                            '${currentWallet.name} #${index + 1}';
                        
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1117),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      addressName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _copyAddress(address),
                                    icon: const Icon(Icons.copy, color: Colors.white70, size: 16),
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              SelectableText(
                                address,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            if (addressList.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.blue.shade300,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '点击复制按钮可将地址复制到剪贴板，所有地址均由同一助记词安全生成',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
        final currentAddress = walletProvider.getCurrentNetworkAddress();
        final wallet = walletProvider.currentWallet;
        return Column(
          children: [
            // 已将复制功能移至地址后方的图标按钮，不再显示文字按钮
            if (wallet?.importType == 'mnemonic')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _exportMnemonic(),
                  icon: const Icon(Icons.lock_open, color: Colors.orange),
                  label: const Text(
                    '导出助记词',
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
              )
            else
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
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmDeleteWallet(),
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: const Text(
                  '删除钱包',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Colors.red),
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
      // 保存钱包名称
      final newName = _nameController.text.trim();
      final wallet = walletProvider.currentWallet;
      if (wallet != null) {
        try {
          await walletProvider.updateWalletName(wallet.id, newName);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('钱包名称更新成功'),
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
      // 进入编辑模式，设置当前钱包名称
      final wallet = walletProvider.currentWallet;
      if (wallet != null) {
        _nameController.text = wallet.name;
      }
    }
    setState(() {
      _isEditingName = !_isEditingName;
    });
  }

  void _generateNewAddress(WalletProvider walletProvider) async {
    final currentWallet = walletProvider.currentWallet;
    final currentNetwork = walletProvider.currentNetwork;
    
    if (currentWallet == null || currentNetwork == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('无法获取当前钱包或网络信息'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 检查钱包是否是通过助记词导入的
    if (currentWallet.importType != 'mnemonic') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('只有通过助记词导入的钱包才能生成新地址'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // 显示加载状态
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            backgroundColor: Color(0xFF1A1B23),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF6366F1)),
                SizedBox(height: 16),
                Text(
                  '正在生成新地址...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        },
      );

      // 获取当前网络的地址列表
      final addressList = currentWallet.addresses[currentNetwork.id] ?? [];
      final nextIndex = addressList.length;

      // 新增：派生前进行密码校验并解密助记词
      final TextEditingController passwordController = TextEditingController();
      String? decryptedMnemonic;

      // 密码输入对话框
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext ctx) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1B23),
            title: const Text('输入钱包密码', style: TextStyle(color: Colors.white)),
            content: TextField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(PasswordConstants.passwordLength),
              ],
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
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('取消', style: TextStyle(color: Colors.white70)),
              ),
              TextButton(
                onPressed: () async {
                  final password = passwordController.text.trim();
                  final error = PasswordConstants.validatePassword(password);
                  if (error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  final ok = await walletProvider.verifyPasswordForWallet(currentWallet.id, password);
                  if (!ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('密码错误'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  decryptedMnemonic = await walletProvider.getWalletMnemonic(currentWallet.id, password);
                  if (decryptedMnemonic == null || decryptedMnemonic!.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('助记词解密失败'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  Navigator.of(ctx).pop();
                },
                child: const Text('确认', style: TextStyle(color: Colors.orange)),
              ),
            ],
          );
        },
      );

      if (decryptedMnemonic == null || decryptedMnemonic!.isEmpty) {
        throw Exception('未获取到助记词，无法派生新地址');
      }

      // 使用解密后的助记词派生新地址
      final newAddress = await walletProvider.generateAddressForNetworkWithIndex(
        decryptedMnemonic!,
        currentNetwork.id,
        nextIndex,
      );

      // 添加新地址到钱包
      if (currentWallet.addresses[currentNetwork.id] == null) {
        currentWallet.addresses[currentNetwork.id] = [];
      }
      currentWallet.addresses[currentNetwork.id]!.add(newAddress);

      // 更新地址索引
      currentWallet.addressIndexes[currentNetwork.id] = nextIndex + 1;

      // 设置默认地址名称
      final defaultName = '${currentWallet.name} #${nextIndex + 1}';
      currentWallet.addressNames[newAddress] = defaultName;

      // 保存到存储
      await walletProvider.updateWalletAddressesAndIndexes(
        currentWallet.id,
        currentWallet.addresses,
        currentWallet.addressIndexes,
        currentWallet.addressNames,
      );

      // 关闭加载对话框
      if (mounted) {
        Navigator.pop(context);
        
        // 显示成功消息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('新地址生成成功: $defaultName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // 关闭加载对话框
      if (mounted) {
        Navigator.pop(context);
        
        // 显示错误消息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('生成新地址失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(PasswordConstants.passwordLength),
                ],
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
                final error = PasswordConstants.validatePassword(password);
                if (error == null) {
                  Navigator.of(context).pop();
                  await _performPrivateKeyExport(password);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error), backgroundColor: Colors.red),
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
      
      String? privateKey;
      if (currentWallet.importType == 'private_key') {
        // 直接读取加密存储的私钥
        privateKey = await walletProvider.getWalletPrivateKey(currentWallet.id, password);
        if (privateKey == null || privateKey.isEmpty) {
          throw Exception('密码错误或私钥获取失败');
        }
      } else {
        // 助记词导入的钱包，根据助记词生成私钥
        final mnemonic = await walletProvider.getWalletMnemonic(
          currentWallet.id,
          password,
        );
        if (mnemonic == null || mnemonic.isEmpty) {
          throw Exception('密码错误或助记词获取失败');
        }
        privateKey = await _generatePrivateKey(mnemonic, walletProvider.currentNetwork!.id);
      }
      
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

  void _exportMnemonic() {
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
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(PasswordConstants.passwordLength),
                ],
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
                '导出助记词存在高安全风险，请在安全环境中操作',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () async {
                final password = passwordController.text.trim();
                final error = PasswordConstants.validatePassword(password);
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error), backgroundColor: Colors.red),
                  );
                  return;
                }
                final walletProvider = Provider.of<WalletProvider>(context, listen: false);
                final wallet = walletProvider.currentWallet;
                if (wallet == null) return;
                final ok = await walletProvider.verifyPasswordForWallet(wallet.id, password);
                if (!ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('密码错误'), backgroundColor: Colors.red),
                  );
                  return;
                }
                Navigator.pop(context);
                await _performMnemonicExport(password);
              },
              child: const Text('确认导出', style: TextStyle(color: Colors.orange)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performMnemonicExport(String password) async {
    try {
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      final wallet = walletProvider.currentWallet;
      if (wallet == null) throw Exception('没有可用的钱包');

      final mnemonic = await walletProvider.getWalletMnemonic(wallet.id, password);
      if (mnemonic == null || mnemonic.isEmpty) {
        throw Exception('密码错误或助记词获取失败');
      }
      _showMnemonicDialog(mnemonic);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showMnemonicDialog(String mnemonic) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1B23),
          title: const Text('助记词', style: TextStyle(color: Colors.white)),
          content: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: SelectableText(
              mnemonic,
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 14,
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: mnemonic));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('助记词已复制'), backgroundColor: Colors.orange),
                );
              },
              child: const Text('复制助记词', style: TextStyle(color: Colors.orange)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭', style: TextStyle(color: Colors.white70)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteWallet() {
    final TextEditingController passwordController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1B23),
          title: const Text('确认删除钱包', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('删除后将无法恢复，请输入密码确认', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(PasswordConstants.passwordLength),
                ],
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () async {
                final password = passwordController.text.trim();
                final error = PasswordConstants.validatePassword(password);
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error), backgroundColor: Colors.red),
                  );
                  return;
                }
                final walletProvider = Provider.of<WalletProvider>(context, listen: false);
                final wallet = walletProvider.currentWallet;
                if (wallet == null) return;
                final ok = await walletProvider.verifyPasswordForWallet(wallet.id, password);
                if (!ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('密码错误'), backgroundColor: Colors.red),
                  );
                  return;
                }
                await walletProvider.deleteWallet(wallet.id);
                if (mounted) {
                  Navigator.pop(context); // 关闭对话框
                  Navigator.pop(this.context); // 退出管理页
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('钱包已删除'), backgroundColor: Colors.green),
                  );
                }
              },
              child: const Text('确认删除', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
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