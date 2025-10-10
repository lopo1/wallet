import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../widgets/sidebar.dart';
import '../models/token.dart';
import '../services/storage_service.dart';
import 'transaction_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _isSidebarCollapsed = false;
  bool _isLoadingBalances = false;
  Map<String, double> _realBalances = {};
  double _totalPortfolioValue = 0.0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedTabIndex = 0; // 0: 资产, 1: 收藏品
  List<Token> _customTokens = [];
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRealBalances();
    _loadCustomTokens();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 当应用重新获得焦点时，刷新代币列表
      _loadCustomTokens();
    }
  }

  /// 加载真实余额数据
  Future<void> _loadRealBalances() async {
    setState(() {
      _isLoadingBalances = true;
    });

    try {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      final networks = ['ethereum', 'polygon', 'bsc', 'bitcoin', 'solana'];
      final prices = {
        'ethereum': 2000.0,
        'polygon': 0.8,
        'bsc': 300.0,
        'bitcoin': 45000.0,
        'solana': 100.0,
      };

      double totalValue = 0.0;
      Map<String, double> balances = {};

      for (String networkId in networks) {
        try {
          final balance = await walletProvider.getNetworkBalance(networkId);
          balances[networkId] = balance;
          totalValue += balance * (prices[networkId] ?? 0.0);
        } catch (e) {
          debugPrint('获取 $networkId 余额失败: $e');
          balances[networkId] = 0.0;
        }
      }

      setState(() {
        _realBalances = balances;
        _totalPortfolioValue = totalValue;
        _isLoadingBalances = false;
      });
    } catch (e) {
      debugPrint('加载余额失败: $e');
      setState(() {
        _isLoadingBalances = false;
      });
    }
  }

  /// 刷新余额
  Future<void> _refreshBalances() async {
    await _loadRealBalances();
    await _loadCustomTokens();
  }

  /// 加载自定义代币
  Future<void> _loadCustomTokens() async {
    try {
      final tokensData = await _storageService.getCustomTokens();
      debugPrint('加载自定义代币: 找到 ${tokensData.length} 个代币');
      setState(() {
        _customTokens = tokensData.map((data) => Token.fromJson(data)).toList();
      });
      debugPrint('自定义代币列表已更新: ${_customTokens.length} 个代币');
    } catch (e) {
      debugPrint('加载自定义代币失败: $e');
    }
  }

  /// 获取所有资产（原生代币 + 自定义代币）
  List<Map<String, dynamic>> _getAllAssets() {
    // 原生代币
    final nativeAssets = [
      {
        'id': 'ethereum',
        'name': 'Ethereum',
        'symbol': 'ETH',
        'icon': Icons.currency_bitcoin,
        'color': const Color(0xFF627EEA),
        'price': 2000.0,
        'isNative': true,
      },
      {
        'id': 'polygon',
        'name': 'Polygon',
        'symbol': 'MATIC',
        'icon': Icons.hexagon,
        'color': const Color(0xFF8247E5),
        'price': 0.8,
        'isNative': true,
      },
      {
        'id': 'bsc',
        'name': 'BNB',
        'symbol': 'BNB',
        'icon': Icons.currency_exchange,
        'color': const Color(0xFFF3BA2F),
        'price': 300.0,
        'isNative': true,
      },
      {
        'id': 'bitcoin',
        'name': 'Bitcoin',
        'symbol': 'BTC',
        'icon': Icons.currency_bitcoin,
        'color': const Color(0xFFF7931A),
        'price': 45000.0,
        'isNative': true,
      },
      {
        'id': 'solana',
        'name': 'Solana',
        'symbol': 'SOL',
        'icon': Icons.wb_sunny,
        'color': const Color(0xFF9945FF),
        'price': 100.0,
        'isNative': true,
      },
    ];

    // 自定义代币
    final customAssets = _customTokens
        .map((token) => {
              'id': token.address,
              'name': token.name,
              'symbol': token.symbol,
              'icon': Icons.token,
              'color': const Color(0xFF6366F1),
              'price': token.price ?? 0.0,
              'isNative': false,
              'networkId': token.networkId,
              'decimals': token.decimals,
              'logoUrl': token.logoUrl,
              'token': token,
            })
        .toList();

    final allAssets = [...nativeAssets, ...customAssets];
    debugPrint(
        '总资产数量: ${allAssets.length} (原生: ${nativeAssets.length}, 自定义: ${customAssets.length})');

    return allAssets;
  }

  /// 格式化价值显示
  String _formatValue(double value) {
    if (value.isNaN || value.isInfinite) {
      return '\$0.00';
    }
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(2)}K';
    } else if (value >= 1) {
      return "\$${value.toStringAsFixed(2)}";
    } else {
      return "\$${value.toStringAsFixed(4)}";
    }
  }

  /// 格式化余额显示
  String _formatBalance(double balance) {
    if (balance.isNaN || balance.isInfinite) {
      return '0.0000';
    }
    if (balance >= 1000000) {
      return '${(balance / 1000000).toStringAsFixed(2)}M';
    } else if (balance >= 1000) {
      return '${(balance / 1000).toStringAsFixed(2)}K';
    } else if (balance >= 1) {
      return balance.toStringAsFixed(4);
    } else {
      return balance.toStringAsFixed(6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF1A1B23),
      drawer: isMobile
          ? Drawer(
              backgroundColor: const Color(0xFF1A1B23),
              child: SafeArea(
                child: Sidebar(
                  onCollapseChanged: (isCollapsed) {
                    setState(() {
                      _isSidebarCollapsed = isCollapsed;
                    });
                    Navigator.of(context).pop(); // 关闭抽屉
                  },
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: isMobile
            ? _buildMobileLayout()
            : Row(
                children: [
                  // Desktop Sidebar
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
                    child: _buildMainContent(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(
          child: _buildMainContent(),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    final isMobile = MediaQuery.of(context).size.width < 768;

    // 显示默认的主屏幕内容
    return Column(
      children: [
        // 可滚动的主内容
        Expanded(
          child: Container(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 24, // left
              isMobile ? 8 : 24, // top - 减少顶部间距
              isMobile ? 16 : 24, // right
              0, // bottom - 移除底部padding，因为有固定按钮
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  if (isMobile) _buildMobileHeader() else _buildDesktopHeader(),
                  SizedBox(height: isMobile ? 16 : 24), // 减少间距
                  // Portfolio content
                  _buildPortfolioContent(),
                  // 添加底部间距，避免内容被固定按钮遮挡
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
        // 固定在底部的功能按钮
        _buildFixedActionButtons(),
      ],
    );
  }

  Widget _buildMobileHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8), // 添加底部间距
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: () {
                try {
                  _scaffoldKey.currentState?.openDrawer();
                } catch (e) {
                  debugPrint('打开抽屉失败: $e');
                }
              },
              icon: const Icon(
                Icons.menu,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
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
          const Spacer(),
          GestureDetector(
            onTap: _showWalletMenu,
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.red,
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader() {
    return Row(
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
    );
  }

  Widget _buildPortfolioContent() {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Portfolio title and total value
        const Text(
          'Swal Portfolio',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _isLoadingBalances
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : GestureDetector(
                onTap: _refreshBalances,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        _formatValue(_totalPortfolioValue),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.refresh,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ],
                ),
              ),
        const SizedBox(height: 4),
        const Text(
          'Assets Chain',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        // Selected Balance section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected Balance:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Consumer<WalletProvider>(
                      builder: (context, walletProvider, child) {
                        final currentNetwork = walletProvider.currentNetwork;
                        final currentAddress =
                            walletProvider.getCurrentNetworkAddress();

                        if (currentAddress == null || currentNetwork == null) {
                          return const Text(
                            '\$0.00',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }

                        final balance = _realBalances[currentNetwork.id] ?? 0.0;
                        final prices = {
                          'ethereum': 2000.0,
                          'polygon': 0.8,
                          'bsc': 300.0,
                          'bitcoin': 45000.0,
                          'solana': 100.0,
                        };
                        final price = prices[currentNetwork.id] ?? 0.0;
                        final value = balance * price;

                        return Text(
                          _formatValue(value),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Consumer<WalletProvider>(
                builder: (context, walletProvider, child) {
                  final currentNetwork = walletProvider.currentNetwork;
                  return Text(
                    currentNetwork?.name ?? '未选择',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Network cards - responsive layout
        if (isMobile)
          _buildMobileNetworkCards()
        else
          _buildDesktopNetworkCards(),
        const SizedBox(height: 24),
        // Assets section with tabs and more menu
        _buildAssetsHeader(),
        const SizedBox(height: 16),
        _selectedTabIndex == 0 ? _buildAssetsList() : _buildCollectiblesList(),
      ],
    );
  }

  Widget _buildMobileNetworkCards() {
    return Column(
      children: [
        _buildNetworkCard(
          title: 'Available Balance:',
          color: const Color(0xFF6366F1),
          icon: 'P',
          getValue: () {
            final walletProvider =
                Provider.of<WalletProvider>(context, listen: false);
            final currentNetwork = walletProvider.currentNetwork;
            if (currentNetwork == null) {
              return _formatValue(_totalPortfolioValue);
            }

            final balance = _realBalances[currentNetwork.id] ?? 0.0;
            final prices = {
              'ethereum': 2000.0,
              'polygon': 0.8,
              'bsc': 300.0,
              'bitcoin': 45000.0,
              'solana': 100.0,
            };
            final price = prices[currentNetwork.id] ?? 0.0;
            final networkValue = balance * price;
            return _formatValue(networkValue);
          },
        ),
        const SizedBox(height: 12),
        _buildNetworkCard(
          title: 'Polygon',
          color: const Color(0xFF8B5CF6),
          icon: 'P',
          getValue: () {
            final polygonBalance = _realBalances['polygon'] ?? 0.0;
            const polygonPrice = 0.8;
            final polygonValue = polygonBalance * polygonPrice;
            return _formatValue(polygonValue);
          },
        ),
      ],
    );
  }

  Widget _buildDesktopNetworkCards() {
    return Row(
      children: [
        Expanded(
          child: _buildNetworkCard(
            title: 'Available Balance:',
            color: const Color(0xFF6366F1),
            icon: 'P',
            getValue: () {
              final walletProvider =
                  Provider.of<WalletProvider>(context, listen: false);
              final currentNetwork = walletProvider.currentNetwork;
              if (currentNetwork == null) {
                return _formatValue(_totalPortfolioValue);
              }

              final balance = _realBalances[currentNetwork.id] ?? 0.0;
              final prices = {
                'ethereum': 2000.0,
                'polygon': 0.8,
                'bsc': 300.0,
                'bitcoin': 45000.0,
                'solana': 100.0,
              };
              final price = prices[currentNetwork.id] ?? 0.0;
              final networkValue = balance * price;
              return _formatValue(networkValue);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildNetworkCard(
            title: 'Polygon',
            color: const Color(0xFF8B5CF6),
            icon: 'P',
            getValue: () {
              final polygonBalance = _realBalances['polygon'] ?? 0.0;
              const polygonPrice = 0.8;
              final polygonValue = polygonBalance * polygonPrice;
              return _formatValue(polygonValue);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkCard({
    required String title,
    required Color color,
    required String icon,
    required String Function() getValue,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
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
                child: Center(
                  child: Text(
                    icon,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _refreshBalances,
                child: const Icon(
                  Icons.refresh,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            getValue(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetsHeader() {
    return Row(
      children: [
        // 标签页切换
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTabButton('Assets', 0),
              _buildTabButton('收藏品', 1),
            ],
          ),
        ),
        const Spacer(),
        // 更多选项菜单
        PopupMenuButton<String>(
          icon: const Icon(
            Icons.more_horiz,
            color: Colors.white70,
            size: 24,
          ),
          color: const Color(0xFF2A2D3A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (String value) {
            _handleMoreMenuAction(value);
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'manage_tokens',
              child: Row(
                children: [
                  Icon(Icons.token, color: Colors.white70, size: 20),
                  SizedBox(width: 12),
                  Text('管理代币', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'show_balance',
              child: Row(
                children: [
                  Icon(Icons.visibility, color: Colors.white70, size: 20),
                  SizedBox(width: 12),
                  Text('显示余额', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'wallet_settings',
              child: Row(
                children: [
                  Icon(Icons.settings, color: Colors.white70, size: 20),
                  SizedBox(width: 12),
                  Text('钱包设置', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh, color: Colors.white70, size: 20),
                  SizedBox(width: 12),
                  Text('刷新', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'add_token',
              child: Row(
                children: [
                  Icon(Icons.add_circle, color: Colors.white70, size: 20),
                  SizedBox(width: 12),
                  Text('添加Token', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  void _handleMoreMenuAction(String action) {
    switch (action) {
      case 'manage_tokens':
        _showManageTokensDialog();
        break;
      case 'show_balance':
        _toggleBalanceVisibility();
        break;
      case 'wallet_settings':
        Navigator.pushNamed(context, '/settings');
        break;
      case 'refresh':
        _refreshBalances();
        break;
      case 'add_token':
        _showAddTokenDialog();
        break;
    }
  }

  void _showManageTokensDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2D3A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '管理代币',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            '这里可以管理您的代币列表，添加或移除代币。',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  void _toggleBalanceVisibility() {
    // 切换余额显示/隐藏
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('余额显示状态已切换'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAddTokenDialog() async {
    final result = await Navigator.pushNamed(context, '/add_token');
    if (result != null) {
      // 代币添加成功，立即刷新自定义代币列表
      await _loadCustomTokens();
      // 显示成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('代币列表已更新'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showRemoveTokenDialog(Token token) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2D3A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '移除代币',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '确定要移除 ${token.symbol} (${token.name}) 吗？',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_outlined,
                      color: Colors.orange,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '移除后，您可以随时重新添加此代币',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
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
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _removeCustomToken(token);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('移除'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeCustomToken(Token token) async {
    try {
      // 从存储中移除代币
      final existingTokensData = await _storageService.getCustomTokens();
      final existingTokens =
          existingTokensData.map((data) => Token.fromJson(data)).toList();

      existingTokens.removeWhere((t) =>
          t.address.toLowerCase() == token.address.toLowerCase() &&
          t.networkId == token.networkId);

      // 保存更新后的代币列表
      final tokensData = existingTokens.map((t) => t.toJson()).toList();
      await _storageService.saveCustomTokens(tokensData);

      // 刷新本地代币列表
      await _loadCustomTokens();

      // 显示成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${token.symbol} 代币已移除'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('移除代币失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('移除代币失败: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildCollectiblesList() {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 200,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: _buildNFTGrid(),
    );
  }

  Widget _buildNFTGrid() {
    // 模拟NFT数据
    final nfts = [
      {
        'id': '1',
        'name': 'Bored Ape #1234',
        'collection': 'Bored Ape Yacht Club',
        'image': 'https://via.placeholder.com/150',
        'price': '2.5 ETH',
      },
      {
        'id': '2',
        'name': 'CryptoPunk #5678',
        'collection': 'CryptoPunks',
        'image': 'https://via.placeholder.com/150',
        'price': '15.0 ETH',
      },
      {
        'id': '3',
        'name': 'Azuki #9012',
        'collection': 'Azuki',
        'image': 'https://via.placeholder.com/150',
        'price': '1.2 ETH',
      },
    ];

    if (nfts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.collections,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                '暂无收藏品',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '您的NFT收藏品将在这里显示',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: nfts.length,
      itemBuilder: (context, index) {
        final nft = nfts[index];
        return _buildNFTCard(nft);
      },
    );
  }

  Widget _buildNFTCard(Map<String, String> nft) {
    return GestureDetector(
      onTap: () {
        _showNFTDetails(nft);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // NFT图片
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: const Icon(
                  Icons.image,
                  size: 48,
                  color: Colors.grey,
                ),
              ),
            ),
            // NFT信息
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nft['name']!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nft['collection']!,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      nft['price']!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNFTDetails(Map<String, String> nft) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2D3A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            nft['name']!,
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.image,
                  size: 64,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '系列: ${nft['collection']}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                '价格: ${nft['price']}',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAssetsList() {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 200,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Consumer<WalletProvider>(
        builder: (context, walletProvider, child) {
          final allAssets = _getAllAssets();

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: allAssets.length,
            itemBuilder: (context, index) {
              final asset = allAssets[index];
              final balance = _realBalances[asset['id']] ?? 0.0;
              final price = asset['price'] as double;
              final value = balance * price;
              final isCustomToken = asset['isNative'] == false;
              final token = asset['token'] as Token?;
              final networkId = asset['networkId'] as String?;

              return _buildAssetItem(
                icon: asset['icon'] as IconData,
                name: asset['name'] as String,
                symbol: asset['symbol'] as String,
                balance: balance,
                value: value,
                color: asset['color'] as Color,
                assetId: asset['id'] as String,
                isCustomToken: isCustomToken,
                token: token,
                networkId: networkId,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAssetItem({
    required IconData icon,
    required String name,
    required String symbol,
    required double balance,
    required double value,
    required Color color,
    required String assetId,
    bool isCustomToken = false,
    Token? token,
    String? networkId,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionHistoryScreen(
              assetId: assetId,
              assetName: name,
              assetSymbol: symbol,
              assetColor: color,
              assetIcon: icon,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: Stack(
                children: [
                  // 主图标（代币图标）
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: isCustomToken
                        ? Center(
                            child: Text(
                              symbol.isNotEmpty ? symbol[0].toUpperCase() : '?',
                              style: TextStyle(
                                color: color,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : Icon(
                            icon,
                            color: color,
                            size: 20,
                          ),
                  ),
                  // 链图标（右下角小图标）
                  if (isCustomToken && networkId != null)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Color(_getNetworkColor(networkId)),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF1A1B23),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          _getNetworkIcon(networkId),
                          color: Colors.white,
                          size: 8,
                        ),
                      ),
                    ),
                ],
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    symbol,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatBalance(balance),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatValue(value),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            if (isCustomToken && token != null)
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  size: 16,
                  color: Colors.grey,
                ),
                color: const Color(0xFF2A2D3A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                onSelected: (String value) {
                  if (value == 'remove') {
                    _showRemoveTokenDialog(token);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text('移除代币', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              )
            else
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedActionButtons() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1A1B23).withValues(alpha: 0.0),
            const Color(0xFF1A1B23).withValues(alpha: 0.8),
            const Color(0xFF1A1B23),
          ],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2D3A).withValues(alpha: 0.95),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: Icons.qr_code,
                label: '收款',
                gradientColors: [
                  const Color(0xFF10B981),
                  const Color(0xFF059669)
                ],
                onTap: () {
                  Navigator.pushNamed(context, '/receive');
                },
              ),
              _buildActionButton(
                icon: Icons.send,
                label: '发送',
                gradientColors: [
                  const Color(0xFF6366F1),
                  const Color(0xFF4F46E5)
                ],
                onTap: () {
                  Navigator.pushNamed(context, '/send');
                },
              ),
              _buildActionButton(
                icon: Icons.swap_horiz,
                label: '兑换',
                gradientColors: [
                  const Color(0xFFF59E0B),
                  const Color(0xFFD97706)
                ],
                onTap: () {
                  Navigator.pushNamed(context, '/swap');
                },
              ),
              _buildActionButton(
                icon: Icons.web,
                label: 'DApp',
                gradientColors: [
                  const Color(0xFF8B5CF6),
                  const Color(0xFF7C3AED)
                ],
                onTap: () {
                  Navigator.pushNamed(context, '/dapp-browser');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 获取网络图标
  IconData _getNetworkIcon(String networkId) {
    switch (networkId) {
      case 'ethereum':
        return Icons.currency_bitcoin;
      case 'polygon':
        return Icons.hexagon;
      case 'bsc':
        return Icons.currency_exchange;
      case 'bitcoin':
        return Icons.currency_bitcoin;
      case 'solana':
        return Icons.wb_sunny;
      default:
        return Icons.network_check;
    }
  }

  /// 获取网络颜色
  int _getNetworkColor(String networkId) {
    switch (networkId) {
      case 'ethereum':
        return 0xFF627EEA;
      case 'polygon':
        return 0xFF8247E5;
      case 'bsc':
        return 0xFFF3BA2F;
      case 'bitcoin':
        return 0xFFF7931A;
      case 'solana':
        return 0xFF9945FF;
      default:
        return 0xFF6366F1;
    }
  }

  void _showWalletMenu() {
    // 钱包菜单实现
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
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                '钱包菜单',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.white70),
                title: const Text('设置', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/settings');
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
