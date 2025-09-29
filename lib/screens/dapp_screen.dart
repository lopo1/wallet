import 'package:flutter/material.dart';
import '../utils/url_utils.dart';

/// DApp组件 - 可嵌入的Widget
class DAppScreen extends StatefulWidget {
  const DAppScreen({super.key});

  @override
  State<DAppScreen> createState() => _DAppScreenState();
}

class _DAppScreenState extends State<DAppScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategoryIndex = 0; // 默认选中推荐

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 搜索框
          _buildSearchBox(),
          const SizedBox(height: 16),
          // 分类标签
          _buildCategoryTabs(),
          const SizedBox(height: 16),
          // Features标题
          const Text(
            'Features',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // DApp网格
          Expanded(
            child: SingleChildScrollView(
              child: _buildDAppGrid(),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建搜索框
  Widget _buildSearchBox() {
    final hasText = _searchController.text.isNotEmpty;
    final isUrl = hasText && UrlUtils.isValidUrl(_searchController.text);
    
    return Container(
      height: 48, // 固定高度防止变形
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 左侧图标 - 固定宽度
          SizedBox(
            width: 32,
            child: Icon(
              isUrl ? Icons.link : Icons.search,
              color: isUrl ? const Color(0xFF6366F1) : Colors.white70,
              size: 20,
            ),
          ),
          // 输入框
          Expanded(
            child: TextField(
              controller: _searchController,
              onSubmitted: _handleSearchSubmit,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: '搜索 DApps 或输入网址',
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                setState(() {}); // 更新 UI 以显示/隐藏图标和按钮
              },
            ),
          ),
          // 右侧按钮区域 - 固定宽度
          SizedBox(
            width: 72,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 清除按钮
                if (hasText)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                // 搜索/跳转按钮
                if (hasText)
                  GestureDetector(
                    onTap: () => _handleSearchSubmit(_searchController.text),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isUrl ? const Color(0xFF6366F1) : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isUrl ? Icons.arrow_forward : Icons.search,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建分类标签
  Widget _buildCategoryTabs() {
    final categories = ['推荐', 'DeFi', 'NFT', '游戏', '旗', '工具', '牧文'];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value;
          final isSelected = _selectedCategoryIndex == index;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategoryIndex = index;
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: index < categories.length - 1 ? 16 : 0),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? const Color(0xFF6366F1) : Colors.white30,
                  width: 1.5,
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 构建DApp网格
  Widget _buildDAppGrid() {
    final dapps = _getFilteredDApps();
    
    return GridView.builder(
      shrinkWrap: true, // 让 GridView 适应内容高度
      physics: const NeverScrollableScrollPhysics(), // 禁用 GridView 自身滚动
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: dapps.length,
      itemBuilder: (context, index) {
        final dapp = dapps[index];
        return _buildDAppCard(dapp);
      },
    );
  }

  /// 处理搜索提交
  void _handleSearchSubmit(String query) async {
    if (query.trim().isEmpty) return;
    
    print('搜索提交: $query'); // 调试信息
    
    // 检查是否为 URL 或域名
    final isValidUrl = UrlUtils.isValidUrl(query);
    print('是否为有效URL: $isValidUrl'); // 调试信息
    
    if (isValidUrl) {
      final formattedUrl = UrlUtils.formatUrl(query);
      print('格式化后的URL: $formattedUrl'); // 调试信息
      
      try {
        // 在应用内打开 URL
        print('尝试打开WebView...'); // 调试信息
        final success = await UrlUtils.openUrlInApp(context, query);
        print('WebView打开结果: $success'); // 调试信息
        
        if (success) {
          // 清空搜索框
          _searchController.clear();
          setState(() {});
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('无法打开该网址'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        print('打开WebView时发生错误: $e'); // 调试信息
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('打开网址时发生错误: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } else {
      // 执行 DApp 搜索
      _performDAppSearch(query);
    }
  }
  
  /// 执行 DApp 搜索
  void _performDAppSearch(String query) {
    // 这里可以实现 DApp 搜索逻辑
    // 目前显示搜索结果提示
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('搜索 DApp: "$query"'),
          backgroundColor: const Color(0xFF6366F1),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  /// 获取过滤后的DApp列表
  List<Map<String, dynamic>> _getFilteredDApps() {
    final allDapps = [
      {
        'name': 'Uniswap',
        'description': 'Decentralized exchange',
        'category': 'DeFi',
        'icon': Icons.swap_horiz,
        'color': const Color(0xFFFF007A),
        'isPopular': true,
        'url': 'https://app.uniswap.org/',
      },
      {
        'name': 'OpenSea',
        'description': 'NFT Marketplace',
        'category': 'NFT',
        'icon': Icons.store,
        'color': const Color(0xFF2081E2),
        'isPopular': true,
        'url': 'https://opensea.io/',
      },
      {
        'name': 'Axie Infinity',
        'description': 'Play-to-earn game',
        'category': '游戏',
        'icon': Icons.pets,
        'color': const Color(0xFF4A90E2),
        'isPopular': true,
        'url': 'https://axieinfinity.com/',
      },
      {
        'name': 'Compound',
        'description': 'Lending protocol',
        'category': 'DeFi',
        'icon': Icons.account_balance,
        'color': const Color(0xFF00D395),
        'isPopular': false,
        'url': 'https://compound.finance/',
      },
      {
        'name': 'Aave',
        'description': 'Liquidity protocol',
        'category': 'DeFi',
        'icon': Icons.waves,
        'color': const Color(0xFFB6509E),
        'isPopular': false,
        'url': 'https://aave.com/',
      },
      {
        'name': 'CryptoKitties',
        'description': 'Collectible game',
        'category': 'NFT',
        'icon': Icons.pets,
        'color': const Color(0xFFFF6B6B),
        'isPopular': false,
        'url': 'https://www.cryptokitties.co/',
      },
      {
        'name': 'Decentraland',
        'description': 'Virtual world',
        'category': '游戏',
        'icon': Icons.public,
        'color': const Color(0xFF42A5F5),
        'isPopular': false,
        'url': 'https://decentraland.org/',
      },
      {
        'name': 'MetaMask',
        'description': 'Wallet extension',
        'category': '工具',
        'icon': Icons.account_balance_wallet,
        'color': const Color(0xFFF6851B),
        'isPopular': true,
        'url': 'https://metamask.io/',
      },
      {
        'name': '牧文工具',
        'description': '专业DeFi工具',
        'category': '牧文',
        'icon': Icons.build,
        'color': const Color(0xFF8B5CF6),
        'isPopular': false,
        'url': 'https://example.com/muwen-tools',
      },
    ];

    final categories = ['推荐', 'DeFi', 'NFT', '游戏', '旗', '工具', '牧文'];
    final selectedCategory = categories[_selectedCategoryIndex];
    
    if (selectedCategory == '推荐') {
      return allDapps.where((dapp) => dapp['isPopular'] == true).toList();
    } else {
      return allDapps.where((dapp) => dapp['category'] == selectedCategory).toList();
    }
  }

  /// 构建单个DApp卡片
  Widget _buildDAppCard(Map<String, dynamic> dapp) {
    return GestureDetector(
      onTap: () async {
        final url = dapp['url'] as String?;
        if (url != null && url.isNotEmpty) {
          try {
            // 使用UrlUtils在应用内打开URL
            final success = await UrlUtils.openUrlInApp(context, url);
            if (!success) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('无法打开 ${dapp['name']}'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('打开 ${dapp['name']} 时发生错误: $e'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        } else {
          // 如果没有URL，显示提示
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${dapp['name']} 暂未配置访问地址'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        height: 95,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: dapp['color'] as Color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                dapp['icon'] as IconData,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              dapp['name'] as String,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              dapp['description'] as String,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}