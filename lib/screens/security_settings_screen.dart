import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/screen_lock_service.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  int _lockScreenTimeout = -1; // 默认永不锁屏
  final StorageService _storageService = StorageService();
  final ScreenLockService _screenLockService = ScreenLockService();

  @override
  void initState() {
    super.initState();
    _loadLockScreenTimeout();
  }

  /// 加载锁屏时间设置
  Future<void> _loadLockScreenTimeout() async {
    try {
      final timeout = await _storageService.getLockScreenTimeout();
      if (mounted) {
        setState(() {
          _lockScreenTimeout = timeout;
        });
      }
    } catch (e) {
      debugPrint('加载锁屏时间设置失败: $e');
    }
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

              // 内容区域
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // 安全设置列表
                      _buildSecurityOptions(),

                      const SizedBox(height: 100), // 底部留白
                    ],
                  ),
                ),
              ),
            ],
          ),
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
          // 返回按钮
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),

          // 标题
          const Expanded(
            child: Text(
              '安全性与隐私',
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

  /// 构建安全设置选项列表
  Widget _buildSecurityOptions() {
    return Column(
      children: [
        // 锁屏时间设置
        _buildSecurityItem(
          icon: Icons.timer,
          iconColor: const Color(0xFF10B981),
          title: '锁屏时间',
          subtitle: '设置自动锁屏时间',
          trailing: _getLockScreenTimeoutText(),
          onTap: () => _navigateToLockScreenSettings(),
        ),

        const SizedBox(height: 12),

        // 生物识别设置（预留）
        _buildSecurityItem(
          icon: Icons.fingerprint,
          iconColor: const Color(0xFF6366F1),
          title: '生物识别',
          subtitle: '指纹或面部识别',
          trailing: '未启用',
          onTap: () => _showComingSoon('生物识别'),
        ),

        const SizedBox(height: 12),

        // 密码设置（预留）
        _buildSecurityItem(
          icon: Icons.lock,
          iconColor: const Color(0xFFF59E0B),
          title: '密码设置',
          subtitle: '修改钱包密码',
          onTap: () => _showComingSoon('密码设置'),
        ),

        const SizedBox(height: 12),

        // 助记词备份（预留）
        _buildSecurityItem(
          icon: Icons.backup,
          iconColor: const Color(0xFF8B5CF6),
          title: '助记词备份',
          subtitle: '备份钱包助记词',
          onTap: () => _showComingSoon('助记词备份'),
        ),

        const SizedBox(height: 12),

        // 隐私设置（预留）
        _buildSecurityItem(
          icon: Icons.visibility_off,
          iconColor: const Color(0xFF6B7280),
          title: '隐私设置',
          subtitle: '控制数据隐私',
          onTap: () => _showComingSoon('隐私设置'),
        ),
      ],
    );
  }

  /// 构建安全设置项
  Widget _buildSecurityItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? trailing,
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),

            const SizedBox(width: 12),

            // 标题和副标题
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // 尾部内容
            if (trailing != null) ...[
              Text(
                trailing,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
            ],

            // 箭头
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

  /// 获取锁屏时间显示文本
  String _getLockScreenTimeoutText() {
    if (_lockScreenTimeout == -1) {
      return '永不';
    } else if (_lockScreenTimeout < 60) {
      return '$_lockScreenTimeout秒后';
    } else if (_lockScreenTimeout == 300) {
      return '5分钟后';
    } else if (_lockScreenTimeout == 600) {
      return '10分钟后';
    } else {
      return '$_lockScreenTimeout秒后';
    }
  }

  /// 导航到锁屏时间设置页面
  void _navigateToLockScreenSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LockScreenTimeoutScreen(
          currentTimeout: _lockScreenTimeout,
          onTimeoutChanged: (newTimeout) {
            setState(() {
              _lockScreenTimeout = newTimeout;
            });
          },
        ),
      ),
    );
  }

  /// 显示功能开发中提示
  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature功能开发中...'),
        backgroundColor: const Color(0xFF6366F1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// 锁屏时间设置页面
class LockScreenTimeoutScreen extends StatefulWidget {
  final int currentTimeout;
  final Function(int) onTimeoutChanged;

  const LockScreenTimeoutScreen({
    super.key,
    required this.currentTimeout,
    required this.onTimeoutChanged,
  });

  @override
  State<LockScreenTimeoutScreen> createState() =>
      _LockScreenTimeoutScreenState();
}

class _LockScreenTimeoutScreenState extends State<LockScreenTimeoutScreen> {
  late int _selectedTimeout;
  final StorageService _storageService = StorageService();
  final ScreenLockService _screenLockService = ScreenLockService();

  // 锁屏时间选项
  final List<Map<String, dynamic>> _timeoutOptions = [
    {'title': '立即', 'value': 0},
    {'title': '15秒后', 'value': 15},
    {'title': '30秒后', 'value': 30},
    {'title': '1分钟后', 'value': 60},
    {'title': '5分钟后', 'value': 300},
    {'title': '10分钟后', 'value': 600},
    {'title': '永不', 'value': -1},
  ];

  @override
  void initState() {
    super.initState();
    _selectedTimeout = widget.currentTimeout;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 用户交互时重置锁屏计时器
        _screenLockService.resetTimer();
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

              // 内容区域
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // 说明文字
                      Text(
                        '选择自动锁屏时间，超过设定时间未操作将自动锁定钱包',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 时间选项列表
                      _buildTimeoutOptions(),

                      const SizedBox(height: 100), // 底部留白
                    ],
                  ),
                ),
              ),
            ],
          ),
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
          // 返回按钮
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),

          // 标题
          const Expanded(
            child: Text(
              '锁屏时间',
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

  /// 构建时间选项列表
  Widget _buildTimeoutOptions() {
    return Column(
      children: _timeoutOptions.map((option) {
        final isSelected = _selectedTimeout == option['value'];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => _selectTimeout(option['value']),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF6366F1).withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF6366F1)
                      : Colors.white.withValues(alpha: 0.1),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // 选择指示器
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF6366F1)
                            : Colors.white38,
                        width: 2,
                      ),
                      color: isSelected
                          ? const Color(0xFF6366F1)
                          : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 12,
                          )
                        : null,
                  ),

                  const SizedBox(width: 16),

                  // 选项文字
                  Expanded(
                    child: Text(
                      option['title'],
                      style: TextStyle(
                        color:
                            isSelected ? const Color(0xFF6366F1) : Colors.white,
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 选择锁屏时间
  Future<void> _selectTimeout(int timeout) async {
    try {
      await _storageService.saveLockScreenTimeout(timeout);

      if (mounted) {
        setState(() {
          _selectedTimeout = timeout;
        });

        // 通知父页面更新
        widget.onTimeoutChanged(timeout);

        // 显示成功提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('锁屏时间已设置为：${_getTimeoutText(timeout)}'),
            backgroundColor: const Color(0xFF6366F1),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        // 延迟返回，让用户看到选择效果
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('设置失败：$e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  /// 获取时间显示文本
  String _getTimeoutText(int timeout) {
    final option = _timeoutOptions.firstWhere(
      (opt) => opt['value'] == timeout,
      orElse: () => {'title': '未知'},
    );
    return option['title'];
  }
}
