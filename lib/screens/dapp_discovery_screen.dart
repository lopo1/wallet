import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../providers/wallet_provider.dart';
import 'dapp_browser_screen.dart';

/// DApp发现页面
/// 
/// 提供DApp发现功能，包括：
/// - Meme币专区
/// - 热门DApp推荐
/// - 分类浏览
/// - 搜索功能
class DAppDiscoveryScreen extends StatefulWidget {
  const DAppDiscoveryScreen({super.key});

  @override
  State<DAppDiscoveryScreen> createState() => _DAppDiscoveryScreenState();
}

class _DAppDiscoveryScreenState extends State<DAppDiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategoryIndex = 1; // 默认选中"DApp"
  
  // 分类列表
  final List<String> _categories = [
    '收藏',
    'DApp',
    'Defi',
    'DEX',
    '社交媒体',
  ];
  
  // Meme币专区的DApp列表
  final List<Map<String, dynamic>> _memeDApps = [
    {
      'name': 'PumpFun',
      'icon': '🐰',
      'color': const Color(0xFFFF6B35),
    },
    {
      'name': 'Uniswap',
      'icon': '🦄',
      'color': const Color(0xFFFF007A),
    },
    {
      'name': 'Slerfswap',
      'icon': '🌿',
      'color': const Color(0xFF00D4AA),
    },
    {
      'name': 'Capsule',
      'icon': '💊',
      'color': const Color(0xFF8B5CF6),
    },
    {
      'name': 'Raydium',
      'icon': '⚡',
      'color': const Color(0xFF6366F1),
    },
  ];

  // 热门DApp列表
  final List<Map<String, dynamic>> _hotDApps = [
    {
      'name': 'Pancakeswap',
      'description': '用户最喜欢的DEX，支持9条公链！',
      'icon': '🥞',
      'tag': 'Hot',
      'category': 'DEX',
      'url': 'https://pancakeswap.finance',
    },
    {
      'name': 'Uniswap',
      'description': '最大的链上市场,MMA交易开创者!',
      'icon': '🦄',
      'tag': 'Hot',
      'category': 'DEX',
      'url': 'https://app.uniswap.org',
    },
    {
      'name': 'Raydium',
      'description': 'Raydium 是一个基于 Solana 区块链的自动...',
      'icon': '⚡',
      'tag': 'Hot',
      'category': 'Dex',
      'url': 'https://raydium.io',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 打开DApp
  void _openDApp(String url, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DAppBrowserScreen(
          initialUrl: url,
          title: name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B23),
      body: SafeArea(
        child: Column(
          children: [
            // 分类导航栏
            _buildCategoryBar(),
            
            // 顶部搜索栏
            _buildSearchBar(),
            
            // 主要内容区域
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Meme币专区
                    _buildMemeSection(),
                    
                    const SizedBox(height: 32),
                    
                    // 热门DApp
                    _buildHotSection(),
                    
                    const SizedBox(height: 100), // 底部导航栏预留空间
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 2, // 发现页面对应索引2
        onItemSelected: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/swap');
              break;
            case 2:
              // 当前页面，不需要跳转
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/settings');
              break;
          }
        },
      ),
    );
  }

  /// 构建搜索栏
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D3A),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search,
            color: Colors.white54,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'DApp名称或网址',
                hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              onTap: () {
                // 点击输入框跳转到DApp浏览器界面
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DAppBrowserScreen(),
                  ),
                );
              },
            ),
          ),
          IconButton(
            onPressed: () {
              // 扫码功能
              Navigator.pushNamed(context, '/qr-scanner');
            },
            icon: const Icon(
              Icons.crop_free,
              color: Colors.white54,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建Meme币专区
  Widget _buildMemeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8B5CF6),
            Color(0xFF6366F1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '从入门到精通',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '🔥',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Meme币专区',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Meme工具集，冲刺百倍币的提醒！',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          
          // Meme DApp图标列表
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _memeDApps.map((dapp) => _buildMemeAppIcon(dapp)).toList(),
          ),
        ],
      ),
    );
  }

  /// 构建Meme应用图标
  Widget _buildMemeAppIcon(Map<String, dynamic> dapp) {
    return GestureDetector(
      onTap: () {
        // 这里可以添加具体的跳转逻辑
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('即将打开 ${dapp['name']}'),
            backgroundColor: dapp['color'],
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                dapp['icon'],
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dapp['name'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建热门区域
  Widget _buildHotSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '热门',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        // 热门DApp列表
        ..._hotDApps.map((dapp) => _buildHotDAppItem(dapp)).toList(),
      ],
    );
  }

  /// 构建热门DApp项目
  Widget _buildHotDAppItem(Map<String, dynamic> dapp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D3A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // DApp图标
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1B23),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                dapp['icon'],
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // DApp信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      dapp['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4444),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        dapp['tag'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1B23),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        dapp['category'],
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  dapp['description'],
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 收藏按钮
          GestureDetector(
            onTap: () => _openDApp(dapp['url'], dapp['name']),
            child: const Icon(
              Icons.star_border,
              color: Colors.white54,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建分类导航栏
  Widget _buildCategoryBar() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedCategoryIndex;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategoryIndex = index;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _categories[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white54,
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 2,
                    width: 20,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF6C5CE7) : Colors.transparent,
                      borderRadius: BorderRadius.circular(1),
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
}