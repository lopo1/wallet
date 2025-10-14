import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../providers/wallet_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1B23),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // 检查是否可以返回，如果不能则导航到首页
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          },
        ),
        title: const Text(
          '设置',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('钱包管理'),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    children: [
                      _buildSettingItem(
                        icon: Icons.download,
                        title: '导入钱包',
                        subtitle: '通过助记词导入现有钱包',
                        onTap: () => _showImportWalletDialog(),
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      _buildSettingItem(
                        icon: Icons.upload,
                        title: '导出助记词',
                        subtitle: '备份当前钱包的助记词',
                        onTap: () => _showExportMnemonicDialog(),
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      _buildSettingItem(
                        icon: Icons.sync_alt,
                        title: '重置助记词',
                        subtitle: '删除当前助记词并重新导入',
                        onTap: () => _showResetMnemonicDialog(),
                        isDestructive: true,
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      _buildSettingItem(
                        icon: Icons.refresh,
                        title: '清除钱包重新导入',
                        subtitle: '清除所有钱包数据并重新开始',
                        onTap: () => _showResetWalletDialog(),
                        isDestructive: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('网络设置'),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    children: [
                      _buildSettingItem(
                        icon: Icons.network_check,
                        title: 'RPC 配置',
                        subtitle: '管理网络 RPC 端点',
                        onTap: () => _showRpcConfigDialog(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('安全设置'),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    children: [
                      _buildSettingItem(
                        icon: Icons.lock,
                        title: '修改密码',
                        subtitle: '更改钱包解锁密码',
                        onTap: () => _showChangePasswordDialog(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('关于'),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    children: [
                      _buildSettingItem(
                        icon: Icons.info,
                        title: '版本信息',
                        subtitle: 'v1.0.0',
                        onTap: () => _showAboutDialog(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 3,
        onItemSelected: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/swap');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/dapp-browser');
              break;
            case 3:
              // current page
              break;
          }
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSettingCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withOpacity(0.2)
              : const Color(0xFF6366F1).withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : const Color(0xFF6366F1),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDestructive ? Colors.red.withOpacity(0.7) : Colors.white70,
          fontSize: 14,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDestructive ? Colors.red.withOpacity(0.7) : Colors.white38,
      ),
      onTap: onTap,
    );
  }

  void _showResetMnemonicDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1B23),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.warning,
                color: Colors.orange,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                '重置助记词',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '此操作将删除当前钱包的助记词，并引导您重新导入或创建新钱包。',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Text(
                  '⚠️ 请确保您已备份助记词！\n此操作无法撤销，继续操作将使您丢失当前钱包的访问权限，除非您已备份。',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 14,
                  ),
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
            ElevatedButton(
              onPressed: () => _confirmResetMnemonic(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('确认重置'),
            ),
          ],
        );
      },
    );
  }

  void _confirmResetMnemonic() {
    Navigator.of(context).pop(); // 关闭确认对话框
    _executeResetWallet(); // 复用现有的重置钱包逻辑
  }

  void _showResetWalletDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1B23),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.warning,
                color: Colors.red,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                '清除钱包',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '此操作将会：',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              _buildWarningItem('• 删除所有钱包数据'),
              _buildWarningItem('• 清除所有地址和私钥'),
              _buildWarningItem('• 重置所有设置'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Text(
                  '⚠️ 请确保您已备份助记词！\n此操作无法撤销，如果没有备份助记词，您将永久失去对钱包的访问权限。',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
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
            ElevatedButton(
              onPressed: () => _confirmResetWallet(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('确认清除'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
    );
  }

  void _confirmResetWallet() {
    Navigator.of(context).pop(); // 关闭确认对话框

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1B23),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '最后确认',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text(
            '您确定要清除所有钱包数据吗？\n\n请输入 "RESET" 来确认此操作：',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
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
            ElevatedButton(
              onPressed: () => _showResetConfirmationInput(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('继续'),
            ),
          ],
        );
      },
    );
  }

  void _showResetConfirmationInput() {
    Navigator.of(context).pop(); // 关闭上一个对话框

    final TextEditingController confirmController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1B23),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                '输入确认码',
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
                    '请输入 "RESET" 来确认清除操作：',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '输入 RESET',
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
                    onChanged: (value) => setState(() {}),
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
                ElevatedButton(
                  onPressed:
                      confirmController.text.trim().toUpperCase() == 'RESET'
                          ? () => _executeResetWallet()
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        confirmController.text.trim().toUpperCase() == 'RESET'
                            ? Colors.red
                            : Colors.grey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('清除钱包'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _executeResetWallet() async {
    Navigator.of(context).pop(); // 关闭输入对话框

    setState(() {
      _isLoading = true;
    });

    try {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      await walletProvider.resetWallet();

      if (mounted) {
        // 显示成功消息
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('钱包已成功清除'),
            backgroundColor: Colors.green,
          ),
        );

        // 导航到欢迎页面
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/welcome',
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('清除钱包失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImportWalletDialog() {
    Navigator.pushNamed(context, '/create-wallet',
        arguments: {'mode': 'import'});
  }

  void _showExportMnemonicDialog() {
    // TODO: 实现导出助记词功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('导出助记词功能开发中...'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showRpcConfigDialog() {
    // TODO: 实现RPC配置功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('RPC配置功能开发中...'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showChangePasswordDialog() {
    // TODO: 实现修改密码功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('修改密码功能开发中...'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1B23),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '关于',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Harbor',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '版本: v1.0.0',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 16),
              Text(
                '一个支持多链的加密货币钱包应用，支持以太坊、Solana、比特币等主流区块链网络。',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
}
