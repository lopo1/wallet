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
  bool _isLoadingBalances = false;
  Map<String, double> _realBalances = {};
  double _totalPortfolioValue = 0.0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadRealBalances();
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

    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 24, // left
        isMobile ? 8 : 24, // top - 减少顶部间距
        isMobile ? 16 : 24, // right
        isMobile ? 16 : 24, // bottom
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
          ],
        ),
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8), // 添加底部间距
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
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
            color: Colors.white.withOpacity(0.1),
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
        _buildAssetsList(),
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
            if (currentNetwork == null)
              return _formatValue(_totalPortfolioValue);

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
            final polygonPrice = 0.8;
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
              if (currentNetwork == null)
                return _formatValue(_totalPortfolioValue);

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
              final polygonPrice = 0.8;
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

  Widget _buildAssetsList() {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 200,
        maxHeight: 400,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Consumer<WalletProvider>(
        builder: (context, walletProvider, child) {
          final allAssets = [
            {
              'id': 'ethereum',
              'name': 'Ethereum',
              'symbol': 'ETH',
              'icon': Icons.currency_bitcoin,
              'color': const Color(0xFF627EEA),
              'price': 2000.0,
            },
            {
              'id': 'polygon',
              'name': 'Polygon',
              'symbol': 'MATIC',
              'icon': Icons.hexagon,
              'color': const Color(0xFF8247E5),
              'price': 0.8,
            },
            {
              'id': 'bsc',
              'name': 'BNB',
              'symbol': 'BNB',
              'icon': Icons.currency_exchange,
              'color': const Color(0xFFF3BA2F),
              'price': 300.0,
            },
            {
              'id': 'bitcoin',
              'name': 'Bitcoin',
              'symbol': 'BTC',
              'icon': Icons.currency_bitcoin,
              'color': const Color(0xFFF7931A),
              'price': 45000.0,
            },
            {
              'id': 'solana',
              'name': 'Solana',
              'symbol': 'SOL',
              'icon': Icons.wb_sunny,
              'color': const Color(0xFF9945FF),
              'price': 100.0,
            },
          ];

          return ListView.builder(
            shrinkWrap: true,
            itemCount: allAssets.length,
            itemBuilder: (context, index) {
              final asset = allAssets[index];
              final balance = _realBalances[asset['id']] ?? 0.0;
              final price = asset['price'] as double;
              final value = balance * price;

              return _buildAssetItem(
                icon: asset['icon'] as IconData,
                name: asset['name'] as String,
                symbol: asset['symbol'] as String,
                balance: balance,
                value: value,
                color: asset['color'] as Color,
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
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
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
        ],
      ),
    );
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
