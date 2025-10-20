import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../providers/wallet_provider.dart';
import '../services/dapp_connection_service.dart';
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
  int _selectedFavoritesTabIndex = 0; // 0: 收藏, 1: 最近浏览
  int _selectedDAppSubCategoryIndex = 0; // DApp子分类索引
  String _selectedNetwork = 'All Networks'; // 选中的网络
  late DAppConnectionService _connectionService;
  
  @override
  void initState() {
    super.initState();
    _connectionService = Provider.of<DAppConnectionService>(context, listen: false);
  }
  
  // 支持的网络列表
  final List<Map<String, dynamic>> _supportedNetworks = [
    {'name': 'All Networks', 'displayName': '所有网络', 'icon': '🌐'},
    {'name': 'Ethereum', 'displayName': 'Ethereum', 'icon': '⟠'},
    {'name': 'BSC', 'displayName': 'BSC', 'icon': '🟡'},
    {'name': 'Polygon', 'displayName': 'Polygon', 'icon': '🟣'},
    {'name': 'Arbitrum', 'displayName': 'Arbitrum', 'icon': '🔵'},
    {'name': 'Solana', 'displayName': 'Solana', 'icon': '🟢'},
    {'name': 'Avalanche', 'displayName': 'Avalanche', 'icon': '🔴'},
  ];

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

  // DeFi DApp列表
  final List<Map<String, dynamic>> _defiDApps = [
    {
      'name': 'Aave',
      'description': '去中心化借贷协议，支持多种资产',
      'icon': '👻',
      'tag': 'DeFi',
      'category': 'Defi',
      'url': 'https://app.aave.com',
    },
    {
      'name': 'Compound',
      'description': '算法货币市场协议',
      'icon': '🏛️',
      'tag': 'DeFi',
      'category': 'Defi',
      'url': 'https://app.compound.finance',
    },
    {
      'name': 'MakerDAO',
      'description': 'DAI稳定币发行平台',
      'icon': '🏗️',
      'tag': 'DeFi',
      'category': 'Defi',
      'url': 'https://makerdao.com',
    },
    {
      'name': 'Yearn Finance',
      'description': '收益聚合器，自动化DeFi策略',
      'icon': '🌾',
      'tag': 'DeFi',
      'category': 'Defi',
      'url': 'https://yearn.finance',
    },
  ];

  // DEX DApp列表
  final List<Map<String, dynamic>> _dexDApps = [
    {
      'name': 'Uniswap',
      'description': '以太坊上最大的去中心化交易所',
      'icon': '🦄',
      'tag': 'DEX',
      'category': 'DEX',
      'url': 'https://app.uniswap.org',
    },
    {
      'name': 'SushiSwap',
      'description': '社区驱动的DEX平台',
      'icon': '🍣',
      'tag': 'DEX',
      'category': 'DEX',
      'url': 'https://app.sushi.com',
    },
    {
      'name': 'Pancakeswap',
      'description': 'BSC上最受欢迎的DEX',
      'icon': '🥞',
      'tag': 'DEX',
      'category': 'DEX',
      'url': 'https://pancakeswap.finance',
    },
    {
      'name': '1inch',
      'description': 'DEX聚合器，最优价格交易',
      'icon': '1️⃣',
      'tag': 'DEX',
      'category': 'DEX',
      'url': 'https://app.1inch.io',
    },
  ];

  // 社交媒体DApp列表
  final List<Map<String, dynamic>> _socialDApps = [
    {
      'name': 'Lens Protocol',
      'description': '去中心化社交图谱协议',
      'icon': '🌿',
      'tag': 'Social',
      'category': '社交媒体',
      'url': 'https://www.lens.xyz',
    },
    {
      'name': 'Mirror',
      'description': '去中心化发布平台',
      'icon': '🪞',
      'tag': 'Social',
      'category': '社交媒体',
      'url': 'https://mirror.xyz',
    },
    {
      'name': 'Farcaster',
      'description': '去中心化社交网络',
      'icon': '📡',
      'tag': 'Social',
      'category': '社交媒体',
      'url': 'https://www.farcaster.xyz',
    },
    {
      'name': 'Friend.tech',
      'description': '社交代币化平台',
      'icon': '👥',
      'tag': 'Social',
      'category': '社交媒体',
      'url': 'https://www.friend.tech',
    },
  ];

  // 综合DApp列表（包含所有分类）
  final List<Map<String, dynamic>> _allDApps = [
    // 热门DApp
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
      'name': 'Aave',
      'description': '去中心化借贷协议，支持多种资产',
      'icon': '👻',
      'tag': 'DeFi',
      'category': 'Defi',
      'url': 'https://app.aave.com',
    },
    {
      'name': 'Lens Protocol',
      'description': '去中心化社交图谱协议',
      'icon': '🌿',
      'tag': 'Social',
      'category': '社交媒体',
      'url': 'https://www.lens.xyz',
    },
    {
      'name': 'OpenSea',
      'description': '最大的NFT交易市场',
      'icon': '🌊',
      'tag': 'NFT',
      'category': 'DApp',
      'url': 'https://opensea.io',
    },
    {
      'name': 'Raydium',
      'description': 'Solana生态系统的AMM和流动性提供者',
      'icon': '⚡',
      'tag': 'DEX',
      'category': 'DEX',
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
              child: _selectedCategoryIndex == 0 
                ? _buildFavoritesContent() // 收藏页面内容
                : _buildCategoryContent(), // 根据选中的分类显示内容
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

  /// 根据选中的分类构建内容
  Widget _buildCategoryContent() {
    // 根据选中的分类索引显示对应内容
    switch (_selectedCategoryIndex) {
      case 1: // DApp
        return _buildDAppContent();
      case 2: // Defi
        return _buildDefiContent();
      case 3: // DEX
        return _buildDexContent();
      case 4: // 社交媒体
        return _buildSocialContent();
      default:
        return _buildDAppContent(); // 默认显示DApp内容
    }
  }

  /// 构建DApp分类内容
  Widget _buildDAppContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          // Meme币专区
          _buildMemeSection(),
          const SizedBox(height: 32),
          
          // 热门应用分类
          _buildCategorySection(
            title: '热门应用',
            apps: _allDApps.where((dapp) => dapp['tag'] == 'Hot').toList(),
          ),
          const SizedBox(height: 32),
          
          // 推荐应用分类
          _buildCategorySection(
            title: '推荐应用',
            apps: _allDApps.where((dapp) => 
              dapp['category'] == 'DApp' || dapp['tag'] == 'DeFi'
            ).toList(),
          ),
          const SizedBox(height: 32),
          
          // NFT市场分类
          _buildCategorySection(
            title: 'NFT市场',
            apps: [
              {
                'name': 'OpenSea',
                'description': '最大的NFT交易市场',
                'icon': '🌊',
                'tag': 'NFT',
                'category': 'NFT',
                'url': 'https://opensea.io',
              },
              {
                'name': 'Blur',
                'description': '专业NFT交易平台',
                'icon': '💨',
                'tag': 'NFT',
                'category': 'NFT',
                'url': 'https://blur.io',
              },
              {
                'name': 'Magic Eden',
                'description': 'Solana生态NFT市场',
                'icon': '🪄',
                'tag': 'NFT',
                'category': 'NFT',
                'url': 'https://magiceden.io',
              },
            ],
          ),
          const SizedBox(height: 32),
          
          // 游戏娱乐分类
          _buildCategorySection(
            title: '游戏娱乐',
            apps: [
              {
                'name': 'Axie Infinity',
                'description': '经典区块链游戏',
                'icon': '🎮',
                'tag': 'Game',
                'category': 'Game',
                'url': 'https://axieinfinity.com',
              },
              {
                'name': 'The Sandbox',
                'description': '虚拟世界游戏平台',
                'icon': '🏖️',
                'tag': 'Game',
                'category': 'Game',
                'url': 'https://www.sandbox.game',
              },
              {
                'name': 'Decentraland',
                'description': '去中心化虚拟世界',
                'icon': '🏙️',
                'tag': 'Game',
                'category': 'Game',
                'url': 'https://decentraland.org',
              },
            ],
          ),
          
          const SizedBox(height: 100), // 底部导航栏预留空间
        ],
      ),
    );
  }

  /// 构建DeFi分类内容
  Widget _buildDefiContent() {
    // 根据选中的网络筛选DeFi应用
    final filteredDefiApps = _getFilteredDAppsByNetwork(_defiDApps);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          // 网络选择和标题行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DeFi协议',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _buildNetworkSelector(),
            ],
          ),
          const SizedBox(height: 16),
          
          // DeFi列表
          ...filteredDefiApps.map((dapp) => _buildSimpleDAppItem(dapp)).toList(),
          
          const SizedBox(height: 100), // 底部导航栏预留空间
        ],
      ),
    );
  }

  /// 构建DEX分类内容
  Widget _buildDexContent() {
    // 根据选中的网络筛选DEX应用
    final filteredDexApps = _getFilteredDAppsByNetwork(_dexDApps);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          // 网络选择和标题行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DEX交易所',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _buildNetworkSelector(),
            ],
          ),
          const SizedBox(height: 16),
          
          // DEX列表
          ...filteredDexApps.map((dapp) => _buildSimpleDAppItem(dapp)).toList(),
          
          const SizedBox(height: 100), // 底部导航栏预留空间
        ],
      ),
    );
  }

  /// 构建社交媒体分类内容
  Widget _buildSocialContent() {
    // 根据选中的网络筛选社交媒体应用
    final filteredSocialApps = _getFilteredDAppsByNetwork(_socialDApps);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          // 网络选择和标题行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '社交媒体',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _buildNetworkSelector(),
            ],
          ),
          const SizedBox(height: 16),
          
          // 社交媒体列表
          ...filteredSocialApps.map((dapp) => _buildSimpleDAppItem(dapp)).toList(),
          
          const SizedBox(height: 100), // 底部导航栏预留空间
        ],
      ),
    );
  }

  /// 构建网络选择下拉菜单
  Widget _buildNetworkSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3A3D4A), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedNetwork,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 14),
          dropdownColor: const Color(0xFF2A2D3A),
          style: const TextStyle(color: Colors.white, fontSize: 11),
          items: _supportedNetworks.map((network) {
            return DropdownMenuItem<String>(
              value: network['name'],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(network['icon'], style: const TextStyle(fontSize: 11)),
                  const SizedBox(width: 4),
                  Text(
                    network['displayName'],
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedNetwork = newValue;
              });
            }
          },
        ),
      ),
    );
  }

  /// 根据选中的网络筛选DApp列表
  List<Map<String, dynamic>> _getFilteredDAppsByNetwork(List<Map<String, dynamic>> dapps) {
    if (_selectedNetwork == 'All Networks') {
      return dapps;
    }
    
    // 为每个DApp添加支持的网络信息（模拟数据）
    return dapps.where((dapp) {
      // 根据DApp名称判断支持的网络
      final supportedNetworks = _getDAppSupportedNetworks(dapp['name']);
      return supportedNetworks.contains(_selectedNetwork);
    }).toList();
  }

  /// 获取DApp支持的网络列表（模拟数据）
  List<String> _getDAppSupportedNetworks(String dappName) {
    switch (dappName.toLowerCase()) {
      case 'aave':
        return ['Ethereum', 'Polygon', 'Avalanche'];
      case 'compound':
        return ['Ethereum'];
      case 'makerdao':
        return ['Ethereum'];
      case 'yearn finance':
        return ['Ethereum'];
      case 'uniswap':
        return ['Ethereum', 'Polygon', 'Arbitrum'];
      case 'sushiswap':
        return ['Ethereum', 'Polygon', 'Arbitrum'];
      case 'pancakeswap':
        return ['BSC'];
      case '1inch':
        return ['Ethereum', 'BSC', 'Polygon'];
      case 'lens protocol':
        return ['Polygon'];
      case 'mirror':
        return ['Ethereum'];
      case 'farcaster':
        return ['Ethereum'];
      case 'friend.tech':
        return ['Ethereum'];
      default:
        return ['Ethereum']; // 默认支持以太坊
    }
  }



  /// 构建简化的DApp条目（无框架包装）
  Widget _buildSimpleDAppItem(Map<String, dynamic> dapp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openDApp(dapp['url'], dapp['name']),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // DApp图标
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2D3A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    dapp['icon'],
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
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
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 热门标签
                        if (dapp['tag'] == 'Hot') ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B35).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.local_fire_department,
                                  color: Color(0xFFFF6B35),
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                const Text(
                                  'Hot',
                                  style: TextStyle(
                                    color: Color(0xFFFF6B35),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        // 分类标签
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(dapp['category']).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            dapp['category'],
                            style: TextStyle(
                              color: _getCategoryColor(dapp['category']),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dapp['description'],
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // 收藏按钮
              IconButton(
                onPressed: () {
                  // 收藏功能
                },
                icon: const Icon(
                  Icons.star_border,
                  color: Colors.white54,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建分类区域
  Widget _buildCategorySection({
    required String title,
    required List<Map<String, dynamic>> apps,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        // 应用列表
        ...apps.map((app) => _buildSimpleDAppItem(app)).toList(),
      ],
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
    return GestureDetector(
      onTap: () => _openDApp(dapp['url'], dapp['name']),
      child: Container(
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
               onTap: () async {
                 await _connectionService.toggleFavorite(dapp['url']);
                 setState(() {}); // 刷新UI
               },
               child: Icon(
                 _connectionService.isFavorite(dapp['url']) 
                   ? Icons.star 
                   : Icons.star_border,
                 color: _connectionService.isFavorite(dapp['url']) 
                   ? Colors.orange 
                   : Colors.white54,
                 size: 24,
               ),
             ),
          ],
        ),
      ),
    );
  }

  /// 构建收藏页面内容 - 使用与首页收藏功能相同的UI设计
  Widget _buildFavoritesContent() {
    return Column(
      children: [
        // 标签栏
        _buildFavoritesTabBar(),

        // 内容区域
        Expanded(
          child: _selectedFavoritesTabIndex == 0
              ? _buildFavoritesList()
              : _buildHistoryList(),
        ),
      ],
    );
  }

  /// 构建收藏页面的标签栏
  Widget _buildFavoritesTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          _buildFavoritesTabButton('收藏', 0),
          const SizedBox(width: 16),
          _buildFavoritesTabButton('浏览记录', 1),
        ],
      ),
    );
  }

  /// 构建收藏页面的标签按钮
  Widget _buildFavoritesTabButton(String text, int index) {
    final isSelected = _selectedFavoritesTabIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFavoritesTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : const Color(0xFF6366F1).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// 构建收藏列表
  Widget _buildFavoritesList() {
    final favorites = _connectionService.favoriteDApps.toList();
    
    if (favorites.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_border,
              size: 64,
              color: Colors.white24,
            ),
            SizedBox(height: 16),
            Text(
              '暂无收藏的DApp',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '点击DApp右侧的星标来收藏',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final url = favorites[index];
        return Dismissible(
          key: ValueKey(url),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.white70),
          ),
          onDismissed: (_) async {
            await _connectionService.removeFromFavorites(url);
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('已移除收藏'),
                backgroundColor: Color(0xFF6366F1),
                duration: Duration(seconds: 1),
              ),
            );
          },
          child: _buildFavoriteItem(url),
        );
      },
    );
  }

  /// 构建浏览记录列表（监听服务变化自动刷新）
  Widget _buildHistoryList() {
    return Consumer<DAppConnectionService>(
      builder: (context, service, child) {
        final history = service.dappHistory;

        if (history.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Colors.white24,
                ),
                SizedBox(height: 16),
                Text(
                  '暂无浏览记录',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '访问DApp后会显示在这里',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final url = history[index];
            return _buildHistoryItem(url);
          },
        );
      },
    );
  }

  /// 构建收藏项目（优化UI与交互）
  Widget _buildFavoriteItem(String url) {
    final host = Uri.parse(url).host;
    final accentPalette = const [
      Color(0xFF6366F1),
      Color(0xFF8B5CF6),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFF3B82F6),
    ];
    final accent = accentPalette[host.hashCode.abs() % accentPalette.length];
    final faviconUrl = '${Uri.parse(url).origin}/favicon.ico';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openDApp(url, host),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2D3A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              // 网站图标（带主题色背景）
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    faviconUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.language, color: Colors.white54, size: 24),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // 网站信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      host,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      url,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // 操作按钮（圆形背景+涟漪）
              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _openDApp(url, host),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1B23),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.open_in_new,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () async {
                      await _connectionService.removeFromFavorites(url);
                      setState(() {});
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建浏览记录项目（优化UI与交互）
  Widget _buildHistoryItem(String url) {
    final uri = Uri.tryParse(url);
    final host = (uri?.host?.isNotEmpty == true) ? uri!.host : url;
    final accentPalette = const [
      Color(0xFF6366F1),
      Color(0xFF8B5CF6),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFF3B82F6),
    ];
    final accent = accentPalette[host.hashCode.abs() % accentPalette.length];

    // 仅在 http/https 时才使用 origin，否则合理降级，避免抛异常
    String? originForFavicon;
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      originForFavicon = uri.origin;
    } else if (host.contains('.')) {
      originForFavicon = 'https://$host';
    }

    final String? faviconUrl =
        originForFavicon != null ? '$originForFavicon/favicon.ico' : null;
    final isFav = _connectionService.isFavorite(url);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openDApp(url, host),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2D3A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              // 网站图标（带主题色背景）
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: faviconUrl != null
                      ? Image.network(
                          faviconUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.history, color: Colors.white54, size: 24),
                        )
                      : const Icon(Icons.history, color: Colors.white54, size: 24),
                ),
              ),

              const SizedBox(width: 12),

              // 网站信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      host,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      url,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // 操作按钮（圆形背景+涟漪，带收藏切换动画）
              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _openDApp(url, host),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1B23),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.open_in_new,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: InkWell(
                      key: ValueKey(isFav),
                      borderRadius: BorderRadius.circular(18),
                      onTap: () async {
                        await _connectionService.toggleFavorite(url);
                        setState(() {});
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: (isFav ? Colors.orange : Colors.white54)
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          isFav ? Icons.star : Icons.star_border,
                          color: isFav ? Colors.orange : Colors.white70,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () async {
                      await _connectionService.removeFromHistory(url);
                      setState(() {});
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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


  /// 获取分类颜色
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'DApp':
        return const Color(0xFF2196F3);
      case 'Defi':
        return const Color(0xFF4CAF50);
      case 'DEX':
        return const Color(0xFFFF9800);
      case 'Dex':
        return const Color(0xFFFF9800);
      case 'Meme':
        return const Color(0xFFE91E63);
      case 'Social Media':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF9C27B0);
    }
  }