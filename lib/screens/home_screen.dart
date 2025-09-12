import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../models/wallet.dart';
import '../models/network.dart';
import '../widgets/sidebar.dart';
import '../services/asset_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSidebarCollapsed = false;
  
  void _showWalletMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1B23),
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
              // Menu items
              Flexible(
                child: SingleChildScrollView(
                  child: Consumer<WalletProvider>(
                    builder: (context, walletProvider, child) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                      // Current wallet info
                      if (walletProvider.currentWallet != null)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.red,
                                child: Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      walletProvider.currentWallet!.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getShortAddress(walletProvider),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      // Menu options
                      _buildMenuOption(
                        icon: Icons.swap_horiz,
                        title: '切换钱包',
                        onTap: () {
                          Navigator.pop(context);
                          _showWalletSwitcher();
                        },
                      ),
                      _buildMenuOption(
                        icon: Icons.download,
                        title: '导入助记词',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/create-wallet', arguments: {'mode': 'import'});
                        },
                      ),
                      _buildMenuOption(
                        icon: Icons.add,
                        title: '创建新钱包',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/create-wallet');
                        },
                      ),
                      _buildMenuOption(
                        icon: Icons.upload,
                        title: '导出助记词',
                        onTap: () {
                          Navigator.pop(context);
                          _showExportMnemonic();
                        },
                        isDestructive: true,
                      ),
                      _buildMenuOption(
                        icon: Icons.settings,
                        title: '设置',
                        onTap: () {
                          Navigator.pop(context);
                          // TODO: Navigate to settings
                        },
                      ),
                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getShortAddress(WalletProvider walletProvider) {
    final address = walletProvider.getCurrentNetworkAddress();
    if (address != null && address.length > 10) {
      return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
    }
    return '未生成地址';
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red : Colors.white70,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.red : Colors.white,
            fontSize: 16,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildAccountOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
          icon,
          color: Colors.white70,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  void _showNetworkRpcConfig() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DefaultTabController(
          length: 2,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Color(0xFF1A1B23),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
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
                const Text(
                  '设置',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                // Tab bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: const [
                      Tab(text: 'RPC 配置'),
                      Tab(text: '账户管理'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Tab content
                Expanded(
                  child: TabBarView(
                    children: [
                      // RPC Configuration Tab
                      _buildRpcConfigTab(),
                      // Account Management Tab
                      _buildAccountManagementTab(),
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

  Widget _buildRpcConfigTab() {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
        final currentNetwork = walletProvider.currentNetwork;
        if (currentNetwork == null) {
          return const Center(
            child: Text(
              '请先选择网络',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }
        
        final rpcUrls = walletProvider.getNetworkRpcUrls(currentNetwork.id);
        
        return Column(
          children: [
            // Current network info
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(currentNetwork.color),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        currentNetwork.symbol.substring(0, 1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentNetwork.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Chain ID: ${currentNetwork.chainId}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // RPC URLs list
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'RPC 地址列表',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: rpcUrls.length,
                      itemBuilder: (context, index) {
                        final rpcUrl = rpcUrls[index];
                        final isCurrentRpc = rpcUrl == currentNetwork.rpcUrl;
                        
                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isCurrentRpc 
                                ? Colors.green.withOpacity(0.2)
                                : Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                            border: isCurrentRpc
                                ? Border.all(color: Colors.green, width: 1)
                                : null,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            title: Text(
                              rpcUrl,
                              style: TextStyle(
                                color: isCurrentRpc ? Colors.green : Colors.white,
                                fontSize: 14,
                                fontFamily: 'monospace',
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isCurrentRpc)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                if (!isCurrentRpc)
                                  IconButton(
                                    onPressed: () {
                                      walletProvider.updateNetworkRpcUrl(
                                        currentNetwork.id,
                                        rpcUrl,
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('已切换到: $rpcUrl'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.radio_button_unchecked,
                                      color: Colors.white70,
                                      size: 20,
                                    ),
                                  ),
                              ],
                            ),
                            onTap: () {
                              if (!isCurrentRpc) {
                                walletProvider.updateNetworkRpcUrl(
                                  currentNetwork.id,
                                  rpcUrl,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('已切换到: $rpcUrl'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  // Add new RPC button
                  Container(
                    margin: const EdgeInsets.all(20),
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showAddRpcDialog(currentNetwork.id);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('添加新 RPC 地址'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
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

  Widget _buildAccountManagementTab() {
    return SingleChildScrollView(
      child: Consumer<WalletProvider>(
        builder: (context, walletProvider, child) {
          return Column(
            children: [
              const SizedBox(height: 10),
              _buildAccountOption(
                 icon: Icons.account_circle,
                 title: '查看当前账户',
                 onTap: () {
                   Navigator.pop(context);
                   _showCurrentAccount();
                 },
               ),
               _buildAccountOption(
                 icon: Icons.add_circle_outline,
                 title: '添加新地址',
                 onTap: () {
                   Navigator.pop(context);
                   _showAddNewAddress();
                 },
               ),
               _buildAccountOption(
                 icon: Icons.key,
                 title: '导入私钥',
                 onTap: () {
                   Navigator.pop(context);
                   _showImportPrivateKey();
                 },
               ),
               _buildAccountOption(
                 icon: Icons.swap_horiz,
                 title: '切换地址',
                 onTap: () {
                   Navigator.pop(context);
                   _showSwitchAddress();
                 },
               ),
               _buildAccountOption(
                 icon: Icons.wallet,
                 title: '钱包管理',
                 onTap: () {
                   Navigator.pop(context);
                   _showWalletSwitcher();
                 },
               ),
               _buildAccountOption(
                 icon: Icons.security,
                 title: '导出助记词',
                 onTap: () {
                   Navigator.pop(context);
                   _showExportMnemonic();
                 },
               ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  void _showAddRpcDialog(String networkId) {
    final TextEditingController rpcController = TextEditingController();
    final TextEditingController nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1B23),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '添加新 RPC 地址',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'RPC URL',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: rpcController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'https://...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '名称 (可选)',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '自定义名称',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                '取消',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final rpcUrl = rpcController.text.trim();
                if (rpcUrl.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('请输入 RPC URL'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // Validate URL format
                 final uri = Uri.tryParse(rpcUrl);
                 if (uri == null || !uri.hasAbsolutePath) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(
                       content: Text('请输入有效的 URL 格式'),
                       backgroundColor: Colors.red,
                     ),
                   );
                   return;
                 }
                
                try {
                  final walletProvider = Provider.of<WalletProvider>(context, listen: false);
                  
                  // Test RPC connection
                  final isValid = await walletProvider.testRpcConnection(rpcUrl);
                  if (!isValid) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('RPC 连接测试失败，请检查 URL 是否正确'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    return;
                  }
                  
                  // Add custom RPC URL
                   walletProvider.addCustomRpcUrl(networkId, rpcUrl);
                  
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('已添加 RPC: $rpcUrl'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('添加失败: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('添加'),
            ),
          ],
        );
      },
    );
  }

  void _showAccountManagement() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1B23),
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
              const Text(
                '账户管理',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              // Account management options
              Flexible(
                child: SingleChildScrollView(
                  child: Consumer<WalletProvider>(
                    builder: (context, walletProvider, child) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildAccountOption(
                            icon: Icons.account_circle,
                            title: '查看当前账户',
                            onTap: () {
                              Navigator.pop(context);
                              _showCurrentAccount();
                            },
                          ),
                          _buildAccountOption(
                            icon: Icons.add_circle_outline,
                            title: '添加新地址',
                            onTap: () {
                              Navigator.pop(context);
                              _showAddNewAddress();
                            },
                          ),
                          _buildAccountOption(
                            icon: Icons.key,
                            title: '导入私钥',
                            onTap: () {
                              Navigator.pop(context);
                              _showImportPrivateKey();
                            },
                          ),
                          _buildAccountOption(
                            icon: Icons.swap_horiz,
                            title: '切换地址',
                            onTap: () {
                              Navigator.pop(context);
                              _showSwitchAddress();
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCurrentAccount() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<WalletProvider>(
          builder: (context, walletProvider, child) {
            final currentWallet = walletProvider.currentWallet;
            final currentNetwork = walletProvider.currentNetwork;
            final address = walletProvider.getCurrentNetworkAddress();
            
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1B23),
              title: const Text(
                '当前账户',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '网络: ${currentNetwork?.name ?? '未选择'}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '钱包: ${currentWallet?.name ?? '未选择'}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '地址:',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      address ?? '未生成地址',
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
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
      },
    );
  }

  void _showAddNewAddress() {
    final TextEditingController passwordController = TextEditingController();
    bool isPasswordVisible = false;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Consumer<WalletProvider>(
              builder: (context, walletProvider, child) {
                final currentWallet = walletProvider.currentWallet;
                final currentNetwork = walletProvider.currentNetwork;
                
                if (currentWallet == null || currentNetwork == null) {
                  return AlertDialog(
                    backgroundColor: const Color(0xFF1A1B23),
                    title: const Text(
                      '错误',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      '请先选择钱包和网络',
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          '确定',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  );
                }
                
                return AlertDialog(
                  backgroundColor: const Color(0xFF1A1B23),
                  title: const Text(
                    '添加新地址',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '将为 ${currentNetwork.name} 网络生成新地址',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '注意：新地址将从当前钱包的助记词派生',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        '请输入钱包密码以验证身份：',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passwordController,
                        obscureText: !isPasswordVisible,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: '输入密码',
                          hintStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: const Color(0xFF2A2D3A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: Colors.white54,
                            ),
                            onPressed: () {
                              setState(() {
                                isPasswordVisible = !isPasswordVisible;
                              });
                            },
                          ),
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
                      onPressed: () async {
                        final password = passwordController.text.trim();
                        if (password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('请输入密码'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        
                        Navigator.pop(context);
                        await _generateNewAddress(password);
                      },
                      child: const Text(
                        '生成',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
  
  Future<void> _generateNewAddress(String password) async {
    try {
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      final currentWallet = walletProvider.currentWallet;
      final currentNetwork = walletProvider.currentNetwork;
      
      if (currentWallet == null || currentNetwork == null) {
        throw Exception('钱包或网络未选择');
      }
      
      // 显示加载提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('正在生成新地址...'),
          backgroundColor: Colors.blue,
        ),
      );
      
      // 获取助记词（使用用户输入的密码验证）
       final mnemonic = await walletProvider.getWalletMnemonic(currentWallet.id, password);
       if (mnemonic == null) {
         throw Exception('密码错误或无法获取助记词');
       }
      
      // 获取当前网络的地址列表和下一个索引
      final currentAddresses = currentWallet.addresses[currentNetwork.id] ?? [];
      final nextIndex = currentWallet.addressIndexes[currentNetwork.id] ?? currentAddresses.length;
      
      // 生成新地址（使用下一个可用的索引）
      final newAddress = await walletProvider.generateAddressForNetworkWithIndex(
        mnemonic,
        currentNetwork.id,
        nextIndex,
      );
      
      // 检查地址是否已存在（避免重复）
      if (currentAddresses.contains(newAddress)) {
        throw Exception('地址已存在，请重试');
      }
      
      // 更新钱包地址映射和索引
      final updatedAddresses = Map<String, List<String>>.from(currentWallet.addresses);
      final updatedIndexes = Map<String, int>.from(currentWallet.addressIndexes);
      
      if (updatedAddresses[currentNetwork.id] == null) {
        updatedAddresses[currentNetwork.id] = [];
      }
      updatedAddresses[currentNetwork.id]!.add(newAddress);
      updatedIndexes[currentNetwork.id] = nextIndex + 1; // 递增索引到下一个可用位置
      
      await walletProvider.updateWalletAddressesAndIndexes(currentWallet.id, updatedAddresses, updatedIndexes);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('新地址已生成: ${newAddress.substring(0, 10)}...'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('生成地址失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImportPrivateKey() {
    final TextEditingController privateKeyController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController walletNameController = TextEditingController();
    bool isPasswordVisible = false;
    bool isPrivateKeyVisible = false;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1B23),
              title: const Text(
                '导入私钥',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '钱包名称:',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: walletNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '输入钱包名称',
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF2A2D3A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '私钥:',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: privateKeyController,
                      obscureText: !isPrivateKeyVisible,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '输入私钥（64位十六进制字符）',
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF2A2D3A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPrivateKeyVisible ? Icons.visibility : Icons.visibility_off,
                            color: Colors.white54,
                          ),
                          onPressed: () {
                            setState(() {
                              isPrivateKeyVisible = !isPrivateKeyVisible;
                            });
                          },
                        ),
                      ),
                      maxLines: isPrivateKeyVisible ? 2 : 1,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '设置钱包密码:',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordController,
                      obscureText: !isPasswordVisible,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '输入密码',
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF2A2D3A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: Colors.white54,
                          ),
                          onPressed: () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '注意：私钥将被安全加密存储，请确保私钥格式正确',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
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
                    final privateKey = privateKeyController.text.trim();
                    final password = passwordController.text.trim();
                    final walletName = walletNameController.text.trim();
                    
                    if (walletName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('请输入钱包名称'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    if (privateKey.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('请输入私钥'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    if (password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('请设置密码'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    Navigator.pop(context);
                    // 使用Future.microtask确保在下一个事件循环中执行，避免context问题
                    Future.microtask(() => _importPrivateKey(privateKey, password, walletName));
                  },
                  child: const Text(
                    '导入',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  Future<void> _importPrivateKey(String privateKey, String password, String walletName) async {
    try {
      // 验证私钥格式
      if (!_isValidPrivateKey(privateKey)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('私钥格式无效，请输入64位十六进制字符'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      
      // 检查是否有当前钱包
      if (walletProvider.currentWallet == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('请先创建或选择一个钱包'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // 显示加载提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('正在导入私钥地址...'),
          backgroundColor: Colors.blue,
        ),
      );
      
      // 将私钥地址添加到当前钱包
      await walletProvider.addPrivateKeyToCurrentWallet(privateKey, walletName);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('私钥地址导入成功！已添加到当前钱包'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('私钥导入失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  bool _isValidPrivateKey(String privateKey) {
    // 移除可能的0x前缀
    final cleanKey = privateKey.toLowerCase().replaceFirst('0x', '');
    
    // 检查长度（64个十六进制字符）
    if (cleanKey.length != 64) {
      return false;
    }
    
    // 检查是否只包含十六进制字符
    final hexRegex = RegExp(r'^[0-9a-f]+$');
    return hexRegex.hasMatch(cleanKey);
  }
  
  String _generateMnemonicFromPrivateKey(String privateKey) {
    // 这是一个简化的实现
    // 实际应用中，私钥导入通常不会生成助记词，而是直接使用私钥
    // 这里为了兼容现有的钱包结构，生成一个有效的助记词
    // 使用一个已知有效的助记词，但在实际应用中应该有更安全的处理方式
    return 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
  }

  void _showSwitchAddress() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<WalletProvider>(
          builder: (context, walletProvider, child) {
            final currentWallet = walletProvider.currentWallet;
            final currentNetwork = walletProvider.currentNetwork;
            
            if (currentWallet == null || currentNetwork == null) {
              return AlertDialog(
                backgroundColor: const Color(0xFF1A1B23),
                title: const Text(
                  '错误',
                  style: TextStyle(color: Colors.white),
                ),
                content: const Text(
                  '请先选择钱包和网络',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      '确定',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              );
            }
            
            // 使用选中的地址或默认地址
            final currentAddress = walletProvider.getCurrentNetworkAddress();
            
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1B23),
              title: const Text(
                '切换地址',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '当前 ${currentNetwork.name} 地址:',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      currentAddress ?? '未生成地址',
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '注意：多地址管理功能正在开发中',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              actions: [
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
      },
    );
  }
 
    void _showWalletSwitcher() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<WalletProvider>(
          builder: (context, walletProvider, child) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1B23),
              title: const Text(
                '切换钱包',
                style: TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: walletProvider.wallets.length,
                  itemBuilder: (context, index) {
                    final wallet = walletProvider.wallets[index];
                    final isSelected = wallet.id == walletProvider.currentWallet?.id;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isSelected ? Colors.red : Colors.grey,
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        wallet.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        _getWalletShortAddress(wallet, walletProvider.currentNetwork),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                      onTap: () {
                        walletProvider.setCurrentWallet(wallet);
                        Navigator.pop(context);
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
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getWalletShortAddress(Wallet wallet, Network? currentNetwork) {
    if (currentNetwork != null) {
      final addressList = wallet.addresses[currentNetwork.id];
      if (addressList != null && addressList.isNotEmpty) {
        final address = addressList.first;
        if (address.length > 10) {
          return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
        }
      }
    }
    return '未生成地址';
  }

  void _showExportMnemonic() {
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
                '导出助记词存在安全风险：',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '• 任何人获得您的助记词都可以完全控制您的钱包\n'
                '• 请确保在安全的环境中操作\n'
                '• 不要在网络上分享或存储助记词\n'
                '• 建议离线保存助记词',
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
                _proceedWithExport();
              },
              child: const Text(
                '我了解风险，继续',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _proceedWithExport() {
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
          content: TextField(
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
                borderSide: BorderSide(color: Colors.red),
              ),
            ),
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
                  await _exportMnemonic(password);
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
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportMnemonic(String password) async {
    try {
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      final currentWallet = walletProvider.currentWallet;
      
      if (currentWallet == null) {
        throw Exception('没有可用的钱包');
      }
      
      final mnemonic = await walletProvider.getWalletMnemonic(
        currentWallet.id,
        password,
      );
      
      if (mnemonic == null || mnemonic.isEmpty) {
        throw Exception('密码错误或助记词获取失败');
      }
      
      _showMnemonicDialog(mnemonic);
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

  void _showMnemonicDialog(String mnemonic) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1B23),
          title: const Text(
            '助记词',
            style: TextStyle(color: Colors.white),
          ),
          content: Container(
            width: double.maxFinite,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              mnemonic,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
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
                  const SnackBar(
                    content: Text('助记词已复制到剪贴板'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text(
                '复制',
                style: TextStyle(color: Colors.white70),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B23),
      body: Row(
        children: [
          // Sidebar
          SizedBox(
            width: _isSidebarCollapsed ? 80 : 280,
            child: Sidebar(
              onCollapseChanged: (isCollapsed) {
                setState(() {
                  _isSidebarCollapsed = isCollapsed;
                });
              },
            ),
          ),
          // Main content
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Dashboard',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: const Text(
                          'Toolbox',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Search and profile icons
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.search,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _showWalletMenu,
                        child: const CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.red,
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Swal Portfolio section
                  const SizedBox(height: 24),
                  // Portfolio Overview
                  Row(
                    children: [
                      // Left side - Portfolio info
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Swal Portfolio',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Consumer<WalletProvider>(
                              builder: (context, walletProvider, child) {
                                final assetService = AssetService();
                                final totalValue = assetService.getTotalPortfolioValue();
                                return Text(
                                  assetService.formatValue(totalValue),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Assets Chain',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Right side - Selected Balance
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Selected Balance:',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Consumer<WalletProvider>(
                              builder: (context, walletProvider, child) {
                                final currentAddress = walletProvider.getCurrentNetworkAddress();
                                return Text(
                                  currentAddress != null 
                                      ? '\$123,456 USD'
                                      : '\$0 USD',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Network section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Network',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Consumer<WalletProvider>(
                            builder: (context, walletProvider, child) {
                              final currentNetwork = walletProvider.currentNetwork;
                              return Text(
                                currentNetwork != null 
                                    ? '当前: ${currentNetwork.name}'
                                    : '未选择网络',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          _showNetworkRpcConfig();
                        },
                        icon: const Icon(
                          Icons.settings,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                   ),
                   const SizedBox(height: 16),
                  // Available Balance Cards
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'P',
                                        style: TextStyle(
                                          color: Color(0xFF6366F1),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Available Balance:',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.refresh,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Consumer<WalletProvider>(
                                builder: (context, walletProvider, child) {
                                  final assetService = AssetService();
                                  final currentNetwork = walletProvider.currentNetwork;
                                  final networkValue = currentNetwork != null 
                                      ? assetService.getNetworkTotalValue(currentNetwork.id)
                                      : assetService.getTotalPortfolioValue();
                                  return Text(
                                    '${assetService.formatValue(networkValue)} USD',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'P',
                                        style: TextStyle(
                                          color: Color(0xFF8B5CF6),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Polygon',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.refresh,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '\$230,000',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Assets section
                  const Text(
                    'Assets',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Assets list
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                      child: Consumer<WalletProvider>(
                        builder: (context, walletProvider, child) {
                          final assetService = AssetService();
                          final currentNetwork = walletProvider.currentNetwork;
                          final assets = currentNetwork != null 
                              ? assetService.getAssetsByNetwork(currentNetwork.id)
                              : assetService.getAllAssets();
                          
                          return ListView(
                            children: assets.map((asset) => _buildAssetItem(
                              icon: asset.icon,
                              name: '${asset.symbol} - ${asset.name}',
                              balance: asset.formattedBalance,
                              value: asset.formattedValue,
                              color: asset.color,
                            )).toList(),
                          );
                        },
                      ),
                  ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Fixed bottom action buttons
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/send');
                          },
                          icon: const Icon(Icons.arrow_upward),
                          label: const Text('发送'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/receive');
                          },
                          icon: const Icon(Icons.arrow_downward),
                          label: const Text('接收'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/swap');
                          },
                          icon: const Icon(Icons.swap_horiz),
                          label: const Text('交换'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetItem({
    required IconData icon,
    required String name,
    required String balance,
    required String value,
    required Color color,
    String? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
         border: Border(
           bottom: BorderSide(color: Colors.grey.shade200),
         ),
       ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (action != null)
                  Text(
                    action,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                balance,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right,
            color: Colors.grey,
            size: 20,
          ),
        ],
      ),
    );
  }
}