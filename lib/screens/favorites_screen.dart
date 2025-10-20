import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dapp_info.dart';
import '../services/dapp_connection_service.dart';
import 'dapp_browser_screen.dart';

/// 收藏页面
/// 显示用户收藏的 DApp 列表
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  int _selectedTabIndex = 0; // 0: 收藏, 1: 最近浏览

  // 预定义的 DApp 信息（用于匹配收藏的 URL）
  final Map<String, DAppInfo> _knownDApps = {
    'https://app.uniswap.org': const DAppInfo(
      id: 'uniswap',
      name: 'Uniswap',
      description: '最大的链上市场,MMA交易开创者!',
      url: 'https://app.uniswap.org',
      iconUrl: 'https://app.uniswap.org/favicon.ico',
      category: DAppCategory.defi,
      supportedNetworks: ['ethereum', 'polygon', 'arbitrum'],
      rating: 4.8,
      isVerified: true,
    ),
    'https://pancakeswap.finance': const DAppInfo(
      id: 'pancakeswap',
      name: 'Pancakeswap',
      description: '用户最喜欢的DEX，支持9条公链!',
      url: 'https://pancakeswap.finance',
      iconUrl: 'https://pancakeswap.finance/favicon.ico',
      category: DAppCategory.defi,
      supportedNetworks: ['bsc'],
      rating: 4.4,
      isVerified: true,
    ),
    'https://gdao.org': const DAppInfo(
      id: 'gdao',
      name: 'G-DAO',
      description: '去中心化自治组织',
      url: 'https://gdao.org',
      iconUrl: 'https://gdao.org/favicon.ico',
      category: DAppCategory.defi,
      supportedNetworks: ['ethereum'],
      rating: 4.2,
      isVerified: true,
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '收藏',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 标签栏
          _buildTabBar(),

          // 内容区域
          Expanded(
            child: _selectedTabIndex == 0
                ? _buildFavoritesList()
                : _buildRecentList(),
          ),
        ],
      ),
    );
  }

  /// 构建标签栏
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildTabItem('收藏', 0),
          const SizedBox(width: 24),
          _buildTabItem('最近浏览', 1),
        ],
      ),
    );
  }

  /// 构建标签项
  Widget _buildTabItem(String title, int index) {
    final isSelected = _selectedTabIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white54,
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 2,
            width: 40,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF8B5CF6) : Colors.transparent,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建收藏列表
  Widget _buildFavoritesList() {
    return Consumer<DAppConnectionService>(
      builder: (context, connectionService, child) {
        final favoriteUrls = connectionService.favoriteDApps.toList();

        // 如果没有收藏，显示一些示例数据
        List<String> displayUrls = favoriteUrls;
        if (favoriteUrls.isEmpty) {
          // 添加一些示例收藏数据
          displayUrls = [
            'https://app.uniswap.org',
            'https://pancakeswap.finance',
            'https://gdao.org',
          ];
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: displayUrls.length,
          itemBuilder: (context, index) {
            final url = displayUrls[index];
            final dappInfo = _knownDApps[url];

            if (dappInfo == null) {
              return _buildUnknownDAppItem(url, connectionService);
            }

            return _buildDAppItem(dappInfo, connectionService);
          },
        );
      },
    );
  }

  /// 构建最近浏览列表
  Widget _buildRecentList() {
    return Consumer<DAppConnectionService>(
      builder: (context, connectionService, child) {
        final recentUrls = connectionService.dappHistory.toList();

        // 如果没有浏览记录，显示一些示例数据
        List<String> displayUrls = recentUrls;
        if (recentUrls.isEmpty) {
          // 添加一些示例浏览记录
          displayUrls = [
            'https://app.uniswap.org',
            'https://pancakeswap.finance',
          ];
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: displayUrls.length,
          itemBuilder: (context, index) {
            final url = displayUrls[index];
            final dappInfo = _knownDApps[url];

            if (dappInfo == null) {
              return _buildUnknownDAppItem(url, connectionService);
            }

            return _buildDAppItem(dappInfo, connectionService);
          },
        );
      },
    );
  }

  /// 构建 DApp 项目
  Widget _buildDAppItem(
      DAppInfo dappInfo, DAppConnectionService connectionService) {
    final isFavorite = connectionService.isFavorite(dappInfo.url);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openDApp(dappInfo),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // DApp 图标
                _buildDAppIcon(dappInfo),

                const SizedBox(width: 16),

                // DApp 信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dappInfo.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dappInfo.description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // 删除按钮（仅在收藏页面显示）
                if (_selectedTabIndex == 0)
                  IconButton(
                    onPressed: () async {
                      await connectionService.removeFromFavorites(dappInfo.url);
                      setState(() {});
                    },
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.white54,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建未知 DApp 项目
  Widget _buildUnknownDAppItem(
      String url, DAppConnectionService connectionService) {
    // 从 URL 提取域名作为名称
    final uri = Uri.tryParse(url);
    final name = uri?.host ?? url;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openCustomUrl(url, name),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // 默认图标
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.language,
                    color: Color(0xFF6C5CE7),
                    size: 24,
                  ),
                ),

                const SizedBox(width: 16),

                // DApp 信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        url,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // 删除按钮（仅在收藏页面显示）
                if (_selectedTabIndex == 0)
                  IconButton(
                    onPressed: () async {
                      await connectionService.removeFromFavorites(url);
                      setState(() {});
                    },
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.white54,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建 DApp 图标
  Widget _buildDAppIcon(DAppInfo dappInfo) {
    Color iconColor;
    IconData iconData;

    switch (dappInfo.id) {
      case 'uniswap':
        iconColor = const Color(0xFFFF007A);
        iconData = Icons.swap_horiz;
        break;
      case 'pancakeswap':
        iconColor = const Color(0xFF1FC7D4);
        iconData = Icons.cake;
        break;
      case 'gdao':
        iconColor = const Color(0xFF4285F4);
        iconData = Icons.handshake;
        break;
      default:
        iconColor = const Color(0xFF6C5CE7);
        iconData = Icons.language;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// 打开 DApp
  void _openDApp(DAppInfo dapp) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DAppBrowserScreen(
          initialUrl: dapp.url,
          title: dapp.name,
          dappInfo: dapp.toJson(),
        ),
      ),
    );
  }

  /// 打开自定义 URL
  void _openCustomUrl(String url, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DAppBrowserScreen(
          initialUrl: url,
          title: title,
        ),
      ),
    );
  }
}
