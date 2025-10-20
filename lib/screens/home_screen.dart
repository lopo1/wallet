import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/wallet_provider.dart';
import '../widgets/sidebar.dart';
import '../models/token.dart';
import '../services/storage_service.dart';
import '../services/address_count_service.dart';
import '../services/screen_lock_service.dart';
import 'transaction_history_screen.dart';
import 'buy_crypto_screen.dart';
import '../utils/amount_utils.dart';
import '../widgets/overlaid_token_icon.dart';

import '../widgets/blockchain_address_list.dart';
import '../models/blockchain_address.dart';
import 'favorites_screen.dart';

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
  double _portfolioChange24h = 2.34; // 模拟24小时变化
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedTabIndex = 0; // 0: 资产, 1: 收藏品
  int _selectedBottomIndex = 0; // 底部导航索引：0 XBIT, 1 兑换, 2 发现, 3 设置
  List<Token> _customTokens = [];
  final StorageService _storageService = StorageService();
  final ScrollController _scrollController = ScrollController();
  final ScreenLockService _screenLockService = ScreenLockService();

  // 现代色彩方案
  static const Color primaryBackground = Color(0xFF0A0B0D);
  static const Color cardBackground = Color(0xFF1A1D29);
  static const Color accentColor = Color(0xFF6366F1);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);

  // 区块链地址数据
  final List<Map<String, dynamic>> _blockchainAddresses = [];

  // 地址数量缓存
  Map<String, int> _addressCounts = {};
  bool _isLoadingAddressCounts = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRealBalances();
    _loadCustomTokens();
    _initializeMockData(); // 初始化模拟数据
    _loadAddressCounts(); // 加载地址数量
  }

  // 加载地址数量
  Future<void> _loadAddressCounts() async {
    if (_isLoadingAddressCounts || !mounted) return;

    setState(() {
      _isLoadingAddressCounts = true;
    });

    try {
      final assets = _getAllAssets();
      final Map<String, int> counts = {};

      for (final asset in assets) {
        final chainId = asset['id'] as String;
        final count = await AddressCountService.getAddressCount(chainId);
        counts[chainId] = count;
      }

      if (mounted) {
        setState(() {
          _addressCounts = counts;
          _isLoadingAddressCounts = false;
        });
      }
    } catch (e) {
      debugPrint('加载地址数量失败: $e');
      if (mounted) {
        setState(() {
          _isLoadingAddressCounts = false;
        });
      }
    }
  }

  // 初始化模拟数据
  void _initializeMockData() {
    // 模拟区块链地址数据
    _blockchainAddresses.addAll([
      {
        'chainId': 'ethereum',
        'chainName': 'Ethereum',
        'chainSymbol': 'ETH',
        'chainIcon': '🔷',
        'primaryAddress': '0x742d35Cc6634C0532925a3b8D4e6D3b6e8d3e8A9',
        'addresses': [
          '0x742d35Cc6634C0532925a3b8D4e6D3b6e8d3e8A9',
          '0x1234567890123456789012345678901234567890',
        ],
      },
      {
        'chainId': 'bitcoin',
        'chainName': 'Bitcoin',
        'chainSymbol': 'BTC',
        'chainIcon': '₿',
        'primaryAddress': 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh',
        'addresses': [
          'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh',
        ],
      },
      {
        'chainId': 'solana',
        'chainName': 'Solana',
        'chainSymbol': 'SOL',
        'chainIcon': '◎',
        'primaryAddress': '7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJos8AsU',
        'addresses': [
          '7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJos8AsU',
          '5oNDL3swdJJF1g9DzJiZ4ynHXgszjFpDticvJ3wv3r1A',
          '9v5gci7mC8Kj6p3gZ9XyQ2n8HsK4mN7vB8xC9j0wQ1r2',
        ],
      },
      {
        'chainId': 'polygon',
        'chainName': 'Polygon',
        'chainSymbol': 'MATIC',
        'chainIcon': '⬡',
        'primaryAddress': '0x742d35Cc6634C0532925a3b8D4e6D3b6e8d3e8A9',
        'addresses': [
          '0x742d35Cc6634C0532925a3b8D4e6D3b6e8d3e8A9',
        ],
      },
    ]);
  }

  void _toggleBalanceVisibility() {
    Provider.of<WalletProvider>(context, listen: false)
        .toggleBalanceVisibility();
  }

  void _showRemoveTokenDialog(Token token) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Remove Token',
            style: TextStyle(color: _HomeScreenState.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to remove ${token.symbol} (${token.name})?',
                style: TextStyle(color: _HomeScreenState.textSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: warningColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This will only remove the token from your wallet display. Your actual token balance will not be affected.',
                        style: TextStyle(
                          color: warningColor,
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
              child: Text(
                'Cancel',
                style: TextStyle(color: _HomeScreenState.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _removeCustomToken(token);
              },
              child: Text(
                'Remove',
                style: TextStyle(color: warningColor),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showNFTDetails(Map<String, String> nft) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            nft['name']!,
            style: TextStyle(color: _HomeScreenState.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: _HomeScreenState.textSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.image,
                  size: 64,
                  color: _HomeScreenState.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Collection: ${nft['collection']}',
                style: TextStyle(color: _HomeScreenState.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                'Price: ${nft['price']}',
                style: TextStyle(color: _HomeScreenState.textPrimary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: TextStyle(color: _HomeScreenState.accentColor),
              ),
            ),
          ],
        );
      },
    );
  }

  void _removeCustomToken(Token token) async {
    try {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      final success = await walletProvider.removeCustomToken(token);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${token.symbol} removed successfully'),
            duration: const Duration(seconds: 2),
            backgroundColor: successColor,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove ${token.symbol}'),
            duration: const Duration(seconds: 3),
            backgroundColor: warningColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove token: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: warningColor,
          ),
        );
      }
    }
  }

  // 显示接收页面
  void _showReceiveUploadDialog() {
    Navigator.pushNamed(context, '/receive');
  }

  void _handleMoreMenuAction(String value) {
    switch (value) {
      case 'manage_tokens':
        Navigator.pushNamed(context, '/manage_tokens');
        break;
      case 'toggle_balance':
        _toggleBalanceVisibility();
        break;
      case 'wallet_settings':
        Navigator.pushNamed(context, '/wallet_settings');
        break;
      case 'refresh':
        _refreshBalances();
        break;
      case 'favorites':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FavoritesScreen(),
          ),
        );
        break;
      case 'add_token':
        Navigator.pushNamed(context, '/add_token');
        break;
    }
  }

  Widget _buildModernMobileHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: const BoxDecoration(
        color: primaryBackground,
      ),
      child: Row(
        children: [
          // 左侧头像和用户名
          Consumer<WalletProvider>(
            builder: (context, walletProvider, _) {
              final walletName = walletProvider.currentWallet?.name ?? '未命名';
              return GestureDetector(
                onTap: () => _showWalletSwitcher(context, walletProvider),
                child: Row(
                  children: [
                    // 圆形头像（自动裁剪、不压缩）
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: ClipOval(
                        child: SvgPicture.asset(
                          'assets/images/harbor_logo.svg',
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 用户名称
                    Text(
                      walletName,
                      style: TextStyle(
                        color: _HomeScreenState.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: _HomeScreenState.textSecondary,
                      size: 16,
                    ),
                  ],
                ),
              );
            },
          ),
          const Spacer(),
          // 右侧图标
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: cardBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.fullscreen,
                      color: _HomeScreenState.textSecondary, size: 16),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: cardBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.search,
                      color: _HomeScreenState.textSecondary, size: 16),
                  onPressed: () {
                    Navigator.pushNamed(context, '/hot-tokens');
                  },
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatAddress(String address) {
    if (address.length <= 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  void _showWalletSwitcher(
      BuildContext context, WalletProvider walletProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
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
              // 拖拽指示器
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 标题与管理
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Text(
                      '选择钱包',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/account_detail');
                      },
                      child: const Text(
                        '管理',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 总资产展示
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '钱包总资产',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        FormatUtils.formatValue(_totalPortfolioValue),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // 钱包列表
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: walletProvider.wallets.length,
                  itemBuilder: (context, index) {
                    final wallet = walletProvider.wallets[index];
                    final isSelected =
                        wallet.id == walletProvider.currentWallet?.id;
                    return _buildWalletItem(
                        context, walletProvider, wallet, isSelected);
                  },
                ),
              ),
              const SizedBox(height: 12),
              // 添加钱包按钮
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: GestureDetector(
                  onTap: () {
                    _showAddWalletOptions(context);
                  },
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: const Center(
                      child: Text(
                        '+ 添加钱包',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWalletItem(BuildContext context, WalletProvider walletProvider,
      dynamic wallet, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected
                ? const Color(0xFF6366F1)
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        tileColor: isSelected
            ? const Color(0xFF6366F1).withOpacity(0.1)
            : Colors.white.withOpacity(0.05),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF6366F1).withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.account_balance_wallet,
            color: Color(0xFF6366F1),
            size: 20,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    wallet.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        const Icon(Icons.check, color: Colors.white, size: 14),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '≈${FormatUtils.formatValue(0)}', // 可替换为真实估值
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'EVM: ${_formatAddress(walletProvider.getAddressForNetwork(wallet.id, walletProvider.currentNetwork?.id ?? 'ethereum') ?? '')}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    final addr = walletProvider.getAddressForNetwork(wallet.id,
                        walletProvider.currentNetwork?.id ?? 'ethereum');
                    if (addr != null) {
                      Clipboard.setData(ClipboardData(text: addr));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('地址已复制')),
                      );
                    }
                  },
                  child:
                      const Icon(Icons.copy, color: Colors.white54, size: 16),
                ),
              ],
            ),
          ],
        ),
        trailing: isSelected ? const SizedBox.shrink() : null,
        onTap: () {
          walletProvider.setCurrentWallet(wallet);
          // 切换钱包后刷新首页数据
          _refreshBalances();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showAddWalletOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1B23),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 拖拽指示器
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Column(
                        children: [
                          // 顶部Logo区域
                          Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6B5BFF),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x336B5BFF),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    )
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: SvgPicture.asset(
                                    'assets/images/harbor_logo.svg',
                                    colorFilter: const ColorFilter.mode(
                                        Colors.white, BlendMode.srcIn),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // 标题
                          const Text(
                            '全球领先的',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Web3经济通行证',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '轻松安全管理25000+数字资产\n私钥自持 去中心化钱包',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // 创建钱包按钮
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, '/create_wallet');
                            },
                            child: Container(
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white24),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: const [
                                  Icon(Icons.add_circle_outline,
                                      color: Colors.white, size: 24),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text('创建钱包',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600)),
                                        SizedBox(height: 4),
                                        Text('创建新的助记词钱包',
                                            style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right,
                                      color: Colors.white54),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // 导入钱包按钮
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, '/import_wallet');
                            },
                            child: Container(
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white24),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: const [
                                  Icon(Icons.download_outlined,
                                      color: Colors.white, size: 24),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text('导入钱包',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600)),
                                        SizedBox(height: 4),
                                        Text('使用助记词/私钥导入',
                                            style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right,
                                      color: Colors.white54),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // 右上角关闭
              Positioned(
                right: 12,
                top: 12,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
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
    if (!mounted) return;

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

      if (mounted) {
        setState(() {
          _realBalances = balances;
          _totalPortfolioValue = totalValue;
          _isLoadingBalances = false;
        });
      }
    } catch (e) {
      debugPrint('加载余额失败: $e');
      if (mounted) {
        setState(() {
          _isLoadingBalances = false;
        });
      }
    }
  }

  /// 刷新余额
  Future<void> _refreshBalances() async {
    await _loadRealBalances();
    await _loadCustomTokens();
  }

  /// 加载自定义代币
  Future<void> _loadCustomTokens() async {
    if (!mounted) return;

    try {
      final tokensData = await _storageService.getCustomTokens();
      debugPrint('加载自定义代币: 找到 ${tokensData.length} 个代币');
      if (mounted) {
        setState(() {
          _customTokens =
              tokensData.map((data) => Token.fromJson(data)).toList();
        });
      }
      debugPrint('自定义代币列表已更新: ${_customTokens.length} 个代币');
    } catch (e) {
      debugPrint('加载自定义代币失败: $e');
    }
  }

  /// 获取所有资产（原生代币 + 自定义代币）
  List<Map<String, dynamic>> _getAllAssets() {
    // 原生代币
    const nativeAssets = [
      {
        'id': 'ethereum',
        'name': 'Ethereum',
        'symbol': 'ETH',
        'icon': Icons.currency_bitcoin,
        'color': const Color(0xFF627EEA),
        'price': 2000.0,
        'change24h': 2.34,
        'isNative': true,
      },
      {
        'id': 'polygon',
        'name': 'Polygon',
        'symbol': 'MATIC',
        'icon': Icons.hexagon,
        'color': const Color(0xFF8247E5),
        'price': 0.8,
        'change24h': -1.23,
        'isNative': true,
      },
      {
        'id': 'bsc',
        'name': 'BNB',
        'symbol': 'BNB',
        'icon': Icons.currency_exchange,
        'color': const Color(0xFFF3BA2F),
        'price': 300.0,
        'change24h': 5.67,
        'isNative': true,
      },
      {
        'id': 'bitcoin',
        'name': 'Bitcoin',
        'symbol': 'BTC',
        'icon': Icons.currency_bitcoin,
        'color': const Color(0xFFF7931A),
        'price': 45000.0,
        'change24h': 3.45,
        'isNative': true,
      },
      {
        'id': 'solana',
        'name': 'Solana',
        'symbol': 'SOL',
        'icon': Icons.wb_sunny,
        'color': const Color(0xFF9945FF),
        'price': 100.0,
        'change24h': -2.18,
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
              'change24h': 1.45, // 模拟变化
            })
        .toList();

    final allAssets = [...nativeAssets, ...customAssets];
    debugPrint(
        '总资产数量: ${allAssets.length} (原生: ${nativeAssets.length}, 自定义: ${customAssets.length})');

    return allAssets;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

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
        key: _scaffoldKey,
        backgroundColor: primaryBackground,
        drawer: isMobile
            ? Drawer(
                backgroundColor: primaryBackground,
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
        floatingActionButton: null,
        floatingActionButtonLocation: null,
        bottomNavigationBar: isMobile ? _buildBottomNavBar() : null,
      ),
    );
  }

  Widget _buildMainContent() {
    return RefreshIndicator(
      color: _HomeScreenState.accentColor,
      backgroundColor: cardBackground,
      onRefresh: _refreshBalances,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            _buildModernPortfolioContent(),
            const SizedBox(height: 2),
            _buildFixedActionButtons(),
            const SizedBox(height: 24),
            // 资产列表部分保持左对齐
            SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildModernAssetsHeader(),
                  const SizedBox(height: 16),
                  _selectedTabIndex == 0
                      ? _buildModernAssetsList()
                      : _buildModernCollectiblesList(),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    // 返回内容布局，避免嵌套多个 Scaffold 导致树不一致
    return Column(
      children: [
        _buildModernMobileHeader(),
        Expanded(child: _buildMainContent()),
      ],
    );
  }

  Widget _buildModernPortfolioContent() {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 主要余额显示
          Consumer<WalletProvider>(
            builder: (context, walletProvider, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      FormatUtils.formatValue(_totalPortfolioValue),
                      style: TextStyle(
                        color: _HomeScreenState.textPrimary,
                        fontSize: isMobile ? 48 : 56,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '+${FormatUtils.formatValue(_portfolioChange24h)}',
                          style: TextStyle(
                            color: successColor,
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '+100%',
                          style: TextStyle(
                            color: successColor,
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// 构建底部导航栏，选中项向上半圆突出
  Widget _buildBottomNavBar() {
    return BottomNavBar(
      selectedIndex: _selectedBottomIndex,
      onItemSelected: (index) {
        setState(() {
          _selectedBottomIndex = index;
        });
        switch (index) {
          case 0:
            // 保持在首页
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/swap');
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/dapp-discovery');
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/settings');
            break;
        }
      },
    );
  }

  Widget _buildFixedActionButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.qr_code_2,
              label: '接收',
              color: const Color(0xFF8B5CF6),
              onPressed: () {
                _showReceiveUploadDialog();
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.near_me,
              label: '发送',
              color: const Color(0xFF8B5CF6),
              onPressed: () {
                Navigator.pushNamed(context, '/send');
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.shopping_bag_outlined,
              label: '购买',
              color: const Color(0xFF8B5CF6),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BuyCryptoScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.apps,
              label: '更多',
              color: const Color(0xFF8B5CF6),
              onPressed: () {
                // 更多功能
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: _HomeScreenState.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAssetsHeader() {
    return Row(
      children: [
        _buildModernTabButton('Assets', 0),
        const SizedBox(width: 16),
        _buildModernTabButton('Collectibles', 1),
        const Spacer(),
        _buildModernMoreMenu(),
      ],
    );
  }

  Widget _buildModernTabButton(String text, int index) {
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
          color: isSelected ? _HomeScreenState.accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : _HomeScreenState.accentColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected
                ? _HomeScreenState.textPrimary
                : _HomeScreenState.textSecondary,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildModernMoreMenu() {
    return PopupMenuButton<String>(
      onSelected: _handleMoreMenuAction,
      color: cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _HomeScreenState.accentColor.withOpacity(0.2)),
      ),
      constraints: const BoxConstraints(
        minWidth: 200,
        maxWidth: 250,
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _HomeScreenState.accentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.more_horiz,
          color: _HomeScreenState.textSecondary,
          size: 20,
        ),
      ),
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'manage_tokens',
          child: SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Icon(Icons.token,
                    color: _HomeScreenState.accentColor, size: 18),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Manage Tokens',
                    style: TextStyle(
                        color: _HomeScreenState.textPrimary, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: 'toggle_balance',
          child: SizedBox(
            width: double.infinity,
            child: Consumer<WalletProvider>(
              builder: (context, walletProvider, child) {
                return Row(
                  children: [
                    Icon(
                      walletProvider.isBalanceHidden
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: _HomeScreenState.textSecondary,
                      size: 18,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        walletProvider.isBalanceHidden
                            ? 'Show Balance'
                            : 'Hide Balance',
                        style: TextStyle(
                            color: _HomeScreenState.textPrimary, fontSize: 14),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: 'wallet_settings',
          child: SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Icon(Icons.settings,
                    color: _HomeScreenState.textSecondary, size: 18),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Wallet Settings',
                    style: TextStyle(
                        color: _HomeScreenState.textPrimary, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: 'refresh',
          child: SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Icon(Icons.refresh,
                    color: _HomeScreenState.textSecondary, size: 18),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Refresh',
                    style: TextStyle(
                        color: _HomeScreenState.textPrimary, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: 'add_token',
          child: SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Icon(Icons.add_circle_outline, color: successColor, size: 18),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Add Token',
                    style: TextStyle(
                        color: _HomeScreenState.textPrimary, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernAssetsList() {
    final assets = _getAllAssets();

    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: assets.length,
          itemBuilder: (context, index) {
            final asset = assets[index];
            return _buildModernAssetItem(asset, walletProvider);
          },
        );
      },
    );
  }

  Widget _buildModernAssetItem(
      Map<String, dynamic> asset, WalletProvider walletProvider) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final isBalanceHidden = walletProvider.isBalanceHidden;
    final balance = _realBalances[asset['id']] ?? 0.0;
    final value = balance * (asset['price'] ?? 0.0);
    final change24h = (asset['change24h'] as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _HomeScreenState.accentColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/token_detail',
              arguments: {
                'asset': asset,
                'balance': balance,
                'usdValue': value,
                'change24h': change24h,
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 资产图标
                  TokenWithNetworkIcon(
                    asset: asset,
                    size: 48,
                  ),
                  const SizedBox(width: 12),

                  // 资产信息
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 第一行：币种symbol和标签
                        Row(
                          children: [
                            Flexible(
                              flex: 3,
                              child: Text(
                                asset['symbol'] as String,
                                style: const TextStyle(
                                  color: _HomeScreenState.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (asset['isNative'] == false) ...[
                              const SizedBox(width: 4),
                              Flexible(
                                flex: 1,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _HomeScreenState.accentColor
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Custom',
                                    style: TextStyle(
                                      color: _HomeScreenState.accentColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        // 第二行：币价和涨跌
                        Row(
                          children: [
                            // 显示币价
                            Expanded(
                              child: Text(
                                FormatUtils.formatPrice(
                                    asset['price'] as double),
                                style: TextStyle(
                                  color: _HomeScreenState.textSecondary
                                      .withOpacity(0.8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            // 显示涨跌
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: change24h >= 0
                                    ? successColor.withOpacity(0.2)
                                    : Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    change24h >= 0
                                        ? Icons.trending_up
                                        : Icons.trending_down,
                                    color: change24h >= 0
                                        ? successColor
                                        : Colors.red,
                                    size: 10,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    FormatUtils.formatChange(change24h),
                                    style: TextStyle(
                                      color: change24h >= 0
                                          ? successColor
                                          : Colors.red,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 余额和价值
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 120),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              isBalanceHidden
                                  ? '****'
                                  : FormatUtils.formatBalance(balance),
                              style: const TextStyle(
                                color: _HomeScreenState.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 120),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              isBalanceHidden
                                  ? '****'
                                  : FormatUtils.formatValue(value),
                              style: TextStyle(
                                color: _HomeScreenState.textSecondary
                                    .withOpacity(0.7),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 自定义代币的移除按钮
                  if (asset['isNative'] == false) ...[
                    const SizedBox(width: 8),
                    Align(
                      alignment: Alignment.center,
                      child: PopupMenuButton<String>(
                        color: cardBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                              color: _HomeScreenState.accentColor
                                  .withOpacity(0.2)),
                        ),
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem<String>(
                            value: 'remove',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  color: Colors.red.withOpacity(0.8),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Remove',
                                  style: TextStyle(
                                    color: Colors.red.withOpacity(0.8),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (String value) {
                          if (value == 'remove' && asset['token'] != null) {
                            _showRemoveTokenDialog(asset['token'] as Token);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.more_vert,
                            color:
                                _HomeScreenState.textSecondary.withOpacity(0.7),
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernCollectiblesList() {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 200,
      ),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: _HomeScreenState.accentColor.withOpacity(0.1)),
      ),
      child: _buildModernNFTGrid(),
    );
  }

  Widget _buildModernNFTGrid() {
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.collections,
                size: 64,
                color: _HomeScreenState.textSecondary,
              ),
              const SizedBox(height: 16),
              const Text(
                'No Collectibles',
                style: TextStyle(
                  fontSize: 16,
                  color: _HomeScreenState.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your NFT collections will appear here',
                style: TextStyle(
                  fontSize: 14,
                  color: _HomeScreenState.textSecondary.withOpacity(0.7),
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
        childAspectRatio: 0.75, // 稍微调高一点，给信息部分更多空间
      ),
      itemCount: nfts.length,
      itemBuilder: (context, index) {
        final nft = nfts[index];
        return _buildModernNFTCard(nft);
      },
    );
  }

  Widget _buildModernNFTCard(Map<String, String> nft) {
    return GestureDetector(
      onTap: () {
        _showNFTDetails(nft);
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: _HomeScreenState.accentColor.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: _HomeScreenState.accentColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
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
                  color: _HomeScreenState.textSecondary.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Icon(
                  Icons.image,
                  size: 48,
                  color: _HomeScreenState.textSecondary,
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        nft['name']!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _HomeScreenState.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Flexible(
                      child: Text(
                        nft['collection']!,
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              _HomeScreenState.textSecondary.withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _HomeScreenState.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        nft['price']!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _HomeScreenState.accentColor,
                        ),
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
}
