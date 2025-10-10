import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dapp_info.dart';
import '../services/dapp_connection_service.dart';
import 'dapp_browser_screen.dart';

/// DApp主页屏幕
///
/// 显示推荐DApp、收藏和最近访问的DApp
class DAppHomeScreen extends StatefulWidget {
  const DAppHomeScreen({super.key});

  @override
  State<DAppHomeScreen> createState() => _DAppHomeScreenState();
}

class _DAppHomeScreenState extends State<DAppHomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  int _selectedCategoryIndex = 0;

  // DApp分类
  final List<DAppCategory> _categories = DAppCategory.values;

  // 推荐的DApp列表
  final List<DAppInfo> _recommendedDApps = [
    DAppInfo(
      id: 'uniswap',
      name: 'Uniswap',
      description: '去中心化交易所',
      url: 'https://app.uniswap.org',
      iconUrl: 'https://app.uniswap.org/favicon.ico',
      category: DAppCategory.defi,
      supportedNetworks: ['ethereum', 'polygon', 'arbitrum'],
      rating: 4.8,
      isVerified: true,
    ),
    DAppInfo(
      id: 'opensea',
      name: 'OpenSea',
      description: 'NFT市场',
      url: 'https://opensea.io',
      iconUrl: 'https://opensea.io/favicon.ico',
      category: DAppCategory.nft,
      supportedNetworks: ['ethereum', 'polygon'],
      rating: 4.6,
      isVerified: true,
    ),
    DAppInfo(
      id: 'compound',
      name: 'Compound',
      description: '借贷协议',
      url: 'https://app.compound.finance',
      iconUrl: 'https://app.compound.finance/favicon.ico',
      category: DAppCategory.defi,
      supportedNetworks: ['ethereum'],
      rating: 4.5,
      isVerified: true,
    ),
    DAppInfo(
      id: 'aave',
      name: 'Aave',
      description: '流动性协议',
      url: 'https://app.aave.com',
      iconUrl: 'https://app.aave.com/favicon.ico',
      category: DAppCategory.defi,
      supportedNetworks: ['ethereum', 'polygon', 'avalanche'],
      rating: 4.7,
      isVerified: true,
    ),
    DAppInfo(
      id: 'pancakeswap',
      name: 'PancakeSwap',
      description: 'BSC上的DEX',
      url: 'https://pancakeswap.finance',
      iconUrl: 'https://pancakeswap.finance/favicon.ico',
      category: DAppCategory.defi,
      supportedNetworks: ['bsc'],
      rating: 4.4,
      isVerified: true,
    ),
    DAppInfo(
      id: 'sushiswap',
      name: 'SushiSwap',
      description: '多链DEX协议',
      url: 'https://app.sushi.com',
      iconUrl: 'https://app.sushi.com/favicon.ico',
      category: DAppCategory.defi,
      supportedNetworks: ['ethereum', 'polygon', 'arbitrum'],
      rating: 4.3,
      isVerified: true,
    ),
  ];

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  /// 获取过滤后的DApp列表
  List<DAppInfo> _getFilteredDApps() {
    final selectedCategory = _categories[_selectedCategoryIndex];

    switch (selectedCategory) {
      case DAppCategory.recommended:
        return _recommendedDApps;
      case DAppCategory.defi:
        return _recommendedDApps
            .where((dapp) => dapp.category == DAppCategory.defi)
            .toList();
      case DAppCategory.nft:
        return _recommendedDApps
            .where((dapp) => dapp.category == DAppCategory.nft)
            .toList();
      case DAppCategory.gaming:
        return _recommendedDApps
            .where((dapp) => dapp.category == DAppCategory.gaming)
            .toList();
      case DAppCategory.tools:
        return _recommendedDApps
            .where((dapp) => dapp.category == DAppCategory.tools)
            .toList();
      case DAppCategory.social:
        return _recommendedDApps
            .where((dapp) => dapp.category == DAppCategory.social)
            .toList();
    }
  }

  /// 打开DApp
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

  /// 打开自定义URL
  void _openCustomUrl() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    String finalUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      finalUrl = 'https://$url';
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DAppBrowserScreen(
          initialUrl: finalUrl,
          title: 'Custom DApp',
        ),
      ),
    );

    _urlController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2D3A),
        elevation: 0,
        title: const Text(
          'DApp浏览器',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // 搜索栏
          _buildSearchSection(),

          // 分类标签
          _buildCategoryTabs(),

          // DApp列表
          Expanded(
            child: _buildDAppGrid(),
          ),
        ],
      ),
    );
  }

  /// 构建搜索区域
  Widget _buildSearchSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D3A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search,
            color: Colors.white70,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _urlController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: '搜索DApp或输入网址...',
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (value) => _openCustomUrl(),
            ),
          ),
          IconButton(
            onPressed: _openCustomUrl,
            icon: const Icon(Icons.arrow_forward, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  /// 构建分类标签
  Widget _buildCategoryTabs() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategoryIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategoryIndex = index;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF6366F1)
                    : const Color(0xFF2A2D3A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category.icon,
                    color: isSelected ? Colors.white : Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    category.displayName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建DApp网格
  Widget _buildDAppGrid() {
    final filteredDApps = _getFilteredDApps();

    if (filteredDApps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.apps,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '该分类下暂无DApp',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Consumer<DAppConnectionService>(
      builder: (context, connectionService, child) {
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: filteredDApps.length,
          itemBuilder: (context, index) {
            final dapp = filteredDApps[index];
            return _buildDAppCard(dapp, connectionService);
          },
        );
      },
    );
  }

  /// 构建DApp卡片
  Widget _buildDAppCard(
      DAppInfo dapp, DAppConnectionService connectionService) {
    final isFavorite = connectionService.isFavorite(dapp.url);
    final isConnected = connectionService.isConnected(dapp.url);

    return GestureDetector(
      onTap: () => _openDApp(dapp),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2D3A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isConnected
                ? Colors.green.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部：图标和收藏按钮
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color:
                        _getCategoryColor(dapp.category).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    dapp.category.icon,
                    color: _getCategoryColor(dapp.category),
                    size: 18,
                  ),
                ),
                const Spacer(),
                if (dapp.isVerified)
                  const Icon(
                    Icons.verified,
                    color: Colors.blue,
                    size: 16,
                  ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () async {
                    await connectionService.toggleFavorite(dapp.url);
                    setState(() {}); // 刷新UI
                  },
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.white70,
                    size: 16,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // DApp名称
            Text(
              dapp.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            // DApp描述
            Text(
              dapp.description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const Spacer(),

            // 底部：评分和连接状态
            Row(
              children: [
                if (dapp.rating > 0) ...[
                  Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 12,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    dapp.rating.toStringAsFixed(1),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
                const Spacer(),
                if (isConnected)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '已连接',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 获取分类颜色
  Color _getCategoryColor(DAppCategory category) {
    switch (category) {
      case DAppCategory.recommended:
        return Colors.amber;
      case DAppCategory.defi:
        return Colors.green;
      case DAppCategory.nft:
        return Colors.purple;
      case DAppCategory.gaming:
        return Colors.orange;
      case DAppCategory.tools:
        return Colors.blue;
      case DAppCategory.social:
        return Colors.pink;
    }
  }
}
