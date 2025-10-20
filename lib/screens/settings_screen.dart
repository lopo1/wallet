import 'package:flutter/material.dart';
import '../services/screen_lock_service.dart';
import '../widgets/bottom_nav_bar.dart';
import 'security_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ScreenLockService _screenLockService = ScreenLockService();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 用户交互时重置锁屏计时器
        _screenLockService.resetTimer();
        // 隐藏键盘
        FocusScope.of(context).unfocus();
      },
      onPanDown: (_) {
        // 用户滑动时重置锁屏计时器
        _screenLockService.resetTimer();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1B23),
        body: SafeArea(
          child: Column(
            children: [
              // 顶部标题栏
              _buildHeader(),

              // 搜索框
              _buildSearchBar(),

              // 内容区域
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // 用户信息卡片
                      _buildUserCard(),

                      const SizedBox(height: 24),

                      // 设置选项列表
                      _buildSettingsOptions(),

                      const SizedBox(height: 100), // 底部留白
                    ],
                  ),
                ),
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
              Navigator.pushReplacementNamed(context, '/dapp-discovery');
              break;
              case 3:
                // current page
                break;
            }
          },
        ),
      ),
    );
  }

  /// 构建顶部标题栏
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // 关闭按钮
          GestureDetector(
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacementNamed('/home');
              }
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),

          // 标题
          const Expanded(
            child: Text(
              '设置',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // 占位，保持标题居中
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  /// 构建搜索框
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: Colors.white.withValues(alpha: 0.6),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: '搜索...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 16,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建用户信息卡片
  Widget _buildUserCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 用户头像
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B6B), Color(0xFF4ECDC4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Text(
                '🐰',
                style: TextStyle(fontSize: 24),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 用户名
          const Expanded(
            child: Text(
              '@SpryBunny634',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // 箭头
          Icon(
            Icons.chevron_right,
            color: Colors.white.withValues(alpha: 0.4),
            size: 20,
          ),
        ],
      ),
    );
  }

  /// 构建设置选项列表
  Widget _buildSettingsOptions() {
    return Column(
      children: [
        _buildSettingItem(
          icon: Icons.account_balance_wallet,
          iconColor: const Color(0xFF6366F1),
          title: '管理账户',
          trailing: '1',
          onTap: () => _showAccountManagement(),
        ),
        const SizedBox(height: 12),
        _buildSettingItem(
          icon: Icons.tune,
          iconColor: const Color(0xFF8B5CF6),
          title: '偏好设置',
          onTap: () => _showPreferences(),
        ),
        const SizedBox(height: 12),
        _buildSettingItem(
          icon: Icons.security,
          iconColor: const Color(0xFF10B981),
          title: '安全性与隐私',
          onTap: () => _showSecuritySettings(),
        ),
        const SizedBox(height: 12),
        _buildSettingItem(
          icon: Icons.language,
          iconColor: const Color(0xFF3B82F6),
          title: '有效网络',
          trailing: '6',
          onTap: () => _showNetworkSettings(),
        ),
        const SizedBox(height: 12),
        _buildSettingItem(
          icon: Icons.location_on,
          iconColor: const Color(0xFFF59E0B),
          title: '地址簿',
          onTap: () => _showAddressBook(),
        ),
        const SizedBox(height: 12),
        _buildSettingItem(
          icon: Icons.apps,
          iconColor: const Color(0xFF8B5CF6),
          title: '关联的应用',
          onTap: () => _showConnectedApps(),
        ),
        const SizedBox(height: 24),
        _buildSettingItem(
          icon: Icons.developer_mode,
          iconColor: const Color(0xFF6B7280),
          title: '开发者设置',
          onTap: () => _showDeveloperSettings(),
        ),
        const SizedBox(height: 24),
        _buildSettingItem(
          icon: Icons.help_outline,
          iconColor: const Color(0xFF6B7280),
          title: '帮助与支持',
          showExternalIcon: true,
          onTap: () => _showHelpAndSupport(),
        ),
        const SizedBox(height: 12),
        _buildSettingItem(
          icon: Icons.person_add_outlined,
          iconColor: const Color(0xFF6B7280),
          title: '邀请好友',
          showShareIcon: true,
          onTap: () => _showInviteFriends(),
        ),
      ],
    );
  }

  /// 构建设置项
  Widget _buildSettingItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? trailing,
    bool showExternalIcon = false,
    bool showShareIcon = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // 图标
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 18,
              ),
            ),

            const SizedBox(width: 12),

            // 标题
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // 尾部内容
            if (trailing != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  trailing,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],

            // 图标
            if (showExternalIcon)
              Icon(
                Icons.open_in_new,
                color: Colors.white.withValues(alpha: 0.4),
                size: 16,
              )
            else if (showShareIcon)
              Icon(
                Icons.share,
                color: Colors.white.withValues(alpha: 0.4),
                size: 16,
              )
            else
              Icon(
                Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.4),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  // 各种设置页面的处理方法
  void _showAccountManagement() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('账户管理功能开发中...'),
        backgroundColor: Color(0xFF6366F1),
      ),
    );
  }

  void _showPreferences() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('偏好设置功能开发中...'),
        backgroundColor: Color(0xFF6366F1),
      ),
    );
  }

  void _showSecuritySettings() {
    // 导航到安全设置页面
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SecuritySettingsScreen(),
      ),
    );
  }

  void _showNetworkSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('网络设置功能开发中...'),
        backgroundColor: Color(0xFF6366F1),
      ),
    );
  }

  void _showAddressBook() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('地址簿功能开发中...'),
        backgroundColor: Color(0xFF6366F1),
      ),
    );
  }

  void _showConnectedApps() {
    Navigator.pushNamed(context, '/walletconnect-sessions');
  }

  void _showDeveloperSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('开发者设置功能开发中...'),
        backgroundColor: Color(0xFF6366F1),
      ),
    );
  }

  void _showHelpAndSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('帮助与支持功能开发中...'),
        backgroundColor: Color(0xFF6366F1),
      ),
    );
  }

  void _showInviteFriends() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('邀请好友功能开发中...'),
        backgroundColor: Color(0xFF6366F1),
      ),
    );
  }
}
