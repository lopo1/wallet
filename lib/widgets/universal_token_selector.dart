import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/token_model.dart';
import '../models/network.dart';
import '../providers/wallet_provider.dart';
import '../utils/amount_utils.dart';

/// Token选择器配置类
class TokenSelectorConfig {
  /// 显示模式：modal（底部弹窗）、fullscreen（全屏页面）
  final TokenSelectorMode mode;
  
  /// 标题文本
  final String title;
  
  /// 是否显示搜索框
  final bool showSearch;
  
  /// 是否显示网络过滤器
  final bool showNetworkFilter;
  
  /// 是否显示余额信息
  final bool showBalance;
  
  /// 是否显示USD价值
  final bool showUsdValue;
  
  /// 是否只显示有余额的token
  final bool onlyShowWithBalance;
  
  /// 预选的token
  final Token? preselectedToken;
  
  /// 排除的token列表（用于兑换场景，避免选择相同token）
  final List<String>? excludeTokens;
  
  /// 自定义token列表（如果为null则使用默认列表）
  final List<Token>? customTokens;
  
  /// 是否启用多选模式
  final bool multiSelect;
  
  /// 最大选择数量（仅在多选模式下有效）
  final int maxSelection;

  const TokenSelectorConfig({
    this.mode = TokenSelectorMode.modal,
    this.title = '选择代币',
    this.showSearch = true,
    this.showNetworkFilter = true,
    this.showBalance = true,
    this.showUsdValue = true,
    this.onlyShowWithBalance = false,
    this.preselectedToken,
    this.excludeTokens,
    this.customTokens,
    this.multiSelect = false,
    this.maxSelection = 1,
  });
}

/// Token选择器显示模式
enum TokenSelectorMode {
  modal,      // 底部弹窗模式
  fullscreen, // 全屏页面模式
}

/// Token选择结果
class TokenSelectionResult {
  final Token? selectedToken;
  final List<Token>? selectedTokens;
  final bool cancelled;

  const TokenSelectionResult({
    this.selectedToken,
    this.selectedTokens,
    this.cancelled = false,
  });

  factory TokenSelectionResult.single(Token token) {
    return TokenSelectionResult(selectedToken: token);
  }

  factory TokenSelectionResult.multiple(List<Token> tokens) {
    return TokenSelectionResult(selectedTokens: tokens);
  }

  factory TokenSelectionResult.cancelled() {
    return const TokenSelectionResult(cancelled: true);
  }
}

/// 通用Token选择器组件
class UniversalTokenSelector {
  /// 显示Token选择器
  static Future<TokenSelectionResult?> show({
    required BuildContext context,
    TokenSelectorConfig config = const TokenSelectorConfig(),
  }) async {
    if (config.mode == TokenSelectorMode.modal) {
      return await _showModal(context, config);
    } else {
      return await _showFullscreen(context, config);
    }
  }

  /// 显示底部弹窗模式
  static Future<TokenSelectionResult?> _showModal(
    BuildContext context,
    TokenSelectorConfig config,
  ) async {
    return await showModalBottomSheet<TokenSelectionResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: _TokenSelectorContent(config: config),
      ),
    );
  }

  /// 显示全屏页面模式
  static Future<TokenSelectionResult?> _showFullscreen(
    BuildContext context,
    TokenSelectorConfig config,
  ) async {
    return await Navigator.push<TokenSelectionResult>(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: const Color(0xFF000000),
          appBar: AppBar(
            title: Text(config.title),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: _TokenSelectorContent(config: config),
        ),
      ),
    );
  }
}

/// Token选择器内容组件
class _TokenSelectorContent extends StatefulWidget {
  final TokenSelectorConfig config;

  const _TokenSelectorContent({
    required this.config,
  });

  @override
  State<_TokenSelectorContent> createState() => _TokenSelectorContentState();
}

class _TokenSelectorContentState extends State<_TokenSelectorContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedNetworkFilter = 'all';
  final Set<String> _selectedTokenIds = <String>{};
  bool _showNetworkDropdown = false;
  final Set<String> _expandedTokenIds = <String>{};

  @override
  void initState() {
    super.initState();
    // 初始化预选token
    if (widget.config.preselectedToken != null) {
      _selectedTokenIds.add(widget.config.preselectedToken!.id);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFullscreen = widget.config.mode == TokenSelectorMode.fullscreen;

    return Column(
      children: [
        // 标题栏
        if (!isFullscreen && widget.config.mode == TokenSelectorMode.modal)
          _buildHeader(),
        if (isFullscreen)
          _buildFullscreenHeader(),

        // 搜索框
        if (widget.config.showSearch)
          _buildSearchBar(),

        // 网络过滤器（仅在modal模式显示原有的Chip样式；全屏采用右上角下拉菜单）
        if (!isFullscreen && widget.config.showNetworkFilter)
          _buildNetworkFilter(),

        // Token列表 + 网络下拉（全屏）
        Expanded(
          child: Stack(
            children: [
              _buildTokenList(),
              if (isFullscreen && _showNetworkDropdown)
                Positioned(
                  top: 0,
                  right: 16,
                  child: _buildNetworkDropdown(),
                ),
            ],
          ),
        ),

        // 多选模式下的确认按钮
        if (widget.config.multiSelect)
          _buildConfirmButton(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.config.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context, TokenSelectionResult.cancelled()),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final bool isFullscreen = widget.config.mode == TokenSelectorMode.fullscreen;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 48,
      decoration: BoxDecoration(
        // 全屏模式统一使用深色背景，避免受主题亮度影响出现白色背景
        color: isFullscreen
            ? const Color(0xFF1A1A2E)
            : (Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1A1A2E)
                : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.white54, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: '代币名称或者合约地址',
                hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 顶部全屏头部（返回 + 标题 + 全部网络下拉）
  Widget _buildFullscreenHeader() {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context, TokenSelectionResult.cancelled()),
              ),
              const SizedBox(width: 8),
              Text(
                widget.config.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          // 网络选择器按钮（右上角）
          GestureDetector(
            onTap: () {
              setState(() {
                _showNetworkDropdown = !_showNetworkDropdown;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _getNetworkFilterText(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _showNetworkDropdown ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 全屏下拉网络菜单（右上角）
  Widget _buildNetworkDropdown() {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final networks = walletProvider.supportedNetworks;

    final networkOptions = [
      {'id': 'all', 'name': '全部网络', 'icon': Icons.language},
      ...networks.map((n) => {
        'id': n.id,
        'name': n.name,
        'icon': Icons.currency_bitcoin,
      }),
    ];

    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: networkOptions.map((option) {
          final isSelected = _selectedNetworkFilter == option['id'];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                setState(() {
                  _selectedNetworkFilter = option['id'] as String;
                  _showNetworkDropdown = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      option['icon'] as IconData,
                      color: isSelected ? Colors.blue : Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        option['name'] as String,
                        style: TextStyle(
                          color: isSelected ? Colors.blue : Colors.white,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check, color: Colors.blue, size: 16),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNetworkFilter() {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
        final networks = walletProvider.supportedNetworks;
        
        return Container(
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildNetworkFilterChip('all', '全部'),
              ...networks.map((network) => 
                _buildNetworkFilterChip(network.id, network.name)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNetworkFilterChip(String networkId, String name) {
    final isSelected = _selectedNetworkFilter == networkId;
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(name),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedNetworkFilter = networkId;
          });
        },
        backgroundColor: Colors.transparent,
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
        checkmarkColor: Theme.of(context).primaryColor,
        labelStyle: TextStyle(
          color: isSelected 
              ? Theme.of(context).primaryColor 
              : Colors.white70,
        ),
        side: BorderSide(
          color: isSelected 
              ? Theme.of(context).primaryColor 
              : Colors.white24,
        ),
      ),
    );
  }

  Widget _buildTokenList() {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
        final tokens = _getFilteredTokens(walletProvider);
        
        if (tokens.isEmpty) {
          return const Center(
            child: Text(
              '未找到匹配的代币',
              style: TextStyle(color: Colors.white54),
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: tokens.length,
          itemBuilder: (context, index) {
            return _buildTokenItem(tokens[index], walletProvider);
          },
        );
      },
    );
  }

  Widget _buildTokenItem(Token token, WalletProvider walletProvider) {
    final isSelected = _selectedTokenIds.contains(token.id);
    final isExcluded = widget.config.excludeTokens?.contains(token.id) ?? false;
    final isFullscreen = widget.config.mode == TokenSelectorMode.fullscreen;
    
    if (isExcluded) return const SizedBox.shrink();
    
    // 统一的卡片外观（全屏采用与发送页一致的卡片样式）
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isFullscreen ? const Color(0xFF1A1A2E) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isFullscreen
            ? null
            : Border.all(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.white12,
              ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async => _onTokenTap(token, walletProvider),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                // 图标 + 链徽章
                Stack(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: (token.color ?? Colors.blue).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Center(
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: token.color ?? Colors.blue,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              token.symbol.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: _getChainBadgeColor(token.networkId),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF1A1A2E), width: 2),
                        ),
                        child: Center(
                          child: Text(
                            _getChainIcon(token.networkId),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // 文本信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            token.symbol,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // 地址数量徽章（与发送页一致）
                          FutureBuilder<List<String>>(
                            future: _getAddressesForNetwork(token.networkId, walletProvider),
                            builder: (context, snapshot) {
                              final count = snapshot.data?.length ?? 0;
                              return GestureDetector(
                                onTap: () async {
                                  if (count <= 1) {
                                    final addresses = snapshot.data ?? [];
                                    if (addresses.isNotEmpty) {
                                      _onAddressTap(token, addresses.first, walletProvider);
                                    } else {
                                      _onTokenSelectDirect(token);
                                    }
                                  } else {
                                    setState(() {
                                      if (_expandedTokenIds.contains(token.id)) {
                                        _expandedTokenIds.remove(token.id);
                                      } else {
                                        _expandedTokenIds.add(token.id);
                                      }
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6C5CE7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '+$count',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getNetworkName(token.networkId, walletProvider),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // 余额信息
                if (widget.config.showBalance)
                  _buildBalanceInfo(token, walletProvider),
                const SizedBox(width: 4),
                // 右侧箭头
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white24,
                  size: 14,
                ),
                  ],
                ),

                // 展开地址列表
                if (_expandedTokenIds.contains(token.id)) ...[
                  const SizedBox(height: 12),
                  FutureBuilder<List<String>>(
                    future: _getAddressesForNetwork(token.networkId, walletProvider),
                    builder: (context, snapshot) {
                      final addresses = snapshot.data ?? [];
                      if (addresses.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        children: List.generate(addresses.length, (index) {
                          final address = addresses[index];
                          final addressName = _getAddressName(walletProvider, address, index);
                          return Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF23233A),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => _onAddressTap(token, address, walletProvider),
                              child: Row(
                                children: [
                                  // 左侧标记
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6C5CE7).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.account_balance_wallet, color: Colors.white70, size: 16),
                                  ),
                                  const SizedBox(width: 10),
                                  // 地址信息
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          addressName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${address.substring(0, 8)}...${address.substring(address.length - 8)}',
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // 地址余额
                                  FutureBuilder<double>(
                                    future: _getAddressBalanceForToken(token, address, walletProvider),
                                    builder: (context, snap) {
                                      final addrBalance = snap.data ?? 0.0;
                                      final usdValue = addrBalance * (token.priceUsd ?? 0.0);
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            AmountUtils.formatTruncated(addrBalance, decimals: 6),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (widget.config.showUsdValue)
                                            Text(
                                              '≈\$${usdValue.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 12,
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceInfo(Token token, WalletProvider walletProvider) {
    // 使用全局缓存显示余额，避免重复请求；缓存更新时通过notifyListeners触发重绘
    final double balance = token.isNative
        ? walletProvider.getCachedNetworkBalance(token.networkId)
        : (token.networkId == 'tron' && token.contractAddress.isNotEmpty)
            ? walletProvider.getCachedTrc20Balance(token.contractAddress)
            : 0.0;
    final double usdValue = balance * (token.priceUsd ?? 0.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          AmountUtils.formatTruncated(balance, decimals: 6),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        if (widget.config.showUsdValue)
          Text(
            '≈\$${usdValue.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: _selectedTokenIds.isEmpty ? null : _onConfirm,
          child: Text(
            '确认选择 (${_selectedTokenIds.length})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  List<Token> _getFilteredTokens(WalletProvider walletProvider) {
    List<Token> tokens;
    
    // 使用自定义token列表或默认列表
    if (widget.config.customTokens != null) {
      tokens = widget.config.customTokens!;
    } else {
      tokens = _getDefaultTokens(walletProvider);
    }
    
    // 应用过滤条件
    return tokens.where((token) {
      // 网络过滤
      if (_selectedNetworkFilter != 'all' && token.networkId != _selectedNetworkFilter) {
        return false;
      }
      
      // 搜索过滤
      if (_searchQuery.isNotEmpty) {
        final symbol = token.symbol.toLowerCase();
        final name = token.name.toLowerCase();
        final address = token.contractAddress.toLowerCase();
        return symbol.contains(_searchQuery) || 
               name.contains(_searchQuery) || 
               address.contains(_searchQuery);
      }
      
      // 只显示有余额的token
      if (widget.config.onlyShowWithBalance) {
        // 这里需要异步获取余额，暂时返回true
        return true;
      }
      
      return true;
    }).toList();
  }

  List<Token> _getDefaultTokens(WalletProvider walletProvider) {
    // 从WalletProvider获取所有可用的token
    final allAssets = walletProvider.getAllAssets();
    return allAssets.map((asset) => Token(
      id: asset['id'] as String? ?? asset['symbol'] as String,
      name: asset['name'] as String,
      symbol: asset['symbol'] as String,
      contractAddress: asset['address'] as String? ?? '',
      // 对于原生资产，networkId 可能未显式给出，回退到 id 以确保正确过滤
      networkId: (asset['networkId'] as String?) ?? (asset['id'] as String?) ?? 'ethereum',
      decimals: asset['decimals'] as int? ?? 18,
      color: asset['color'] as Color? ?? Colors.blue,
      priceUsd: asset['price'] as double?,
      iconUrl: asset['logoUrl'] as String?,
      isNative: asset['isNative'] as bool? ?? false,
    )).toList();
  }

  Future<double> _getTokenBalance(Token token, WalletProvider walletProvider) async {
    // 改为使用缓存（组件不主动发起RPC刷新，避免列表重复请求）
    if (token.isNative) {
      return walletProvider.getCachedNetworkBalance(token.networkId);
    } else {
      if (token.networkId == 'tron' && token.contractAddress.isNotEmpty) {
        return walletProvider.getCachedTrc20Balance(token.contractAddress);
      }
      return 0.0;
    }
  }

  // 按地址获取余额（支持原生与合约代币）
  Future<double> _getAddressBalanceForToken(
    Token token,
    String address,
    WalletProvider walletProvider,
  ) async {
    try {
      if (token.isNative) {
        return await walletProvider.getNetworkBalanceForAddress(
          token.networkId,
          address,
        );
      } else {
        // TODO: 非原生代币余额后续接入 token_service
        return 0.0;
      }
    } catch (e) {
      debugPrint('按地址获取余额失败: $e');
      return 0.0;
    }
  }

  // 工具：根据网络ID获取显示名称
  String _getNetworkName(String networkId, WalletProvider walletProvider) {
    try {
      return walletProvider.supportedNetworks.firstWhere((n) => n.id == networkId).name;
    } catch (_) {
      return networkId;
    }
  }

  // 工具：获取网络的地址列表
  Future<List<String>> _getAddressesForNetwork(String networkId, WalletProvider walletProvider) async {
    final currentWallet = walletProvider.currentWallet;
    final addresses = currentWallet?.addresses[networkId] ?? [];
    return addresses;
  }

  String _getAddressName(WalletProvider walletProvider, String address, int index) {
    final currentWallet = walletProvider.currentWallet;
    final name = currentWallet?.addressNames[address];
    if (name != null && name.isNotEmpty) return name;
    final baseName = currentWallet?.name ?? '地址';
    return '$baseName #${index + 1}';
  }

  // 工具：网络筛选文本
  String _getNetworkFilterText() {
    switch (_selectedNetworkFilter) {
      case 'all':
        return '全部网络';
      default:
        return _selectedNetworkFilter; // 简化显示为ID；上方下拉列表展示中文名称
    }
  }

  // 工具：链图标字符
  String _getChainIcon(String networkId) {
    switch (networkId) {
      case 'ethereum':
        return 'E';
      case 'bitcoin':
        return 'B';
      case 'solana':
        return 'S';
      case 'polygon':
        return 'M';
      case 'bsc':
        return 'B';
      case 'avalanche':
        return 'A';
      case 'arbitrum':
        return 'A';
      case 'optimism':
        return 'O';
      case 'base':
        return 'B';
      case 'tron':
        return 'T';
      default:
        return '?';
    }
  }

  // 工具：链徽章颜色
  Color _getChainBadgeColor(String networkId) {
    switch (networkId) {
      case 'ethereum':
        return const Color(0xFF627EEA);
      case 'bitcoin':
        return const Color(0xFFF7931A);
      case 'solana':
        return const Color(0xFF14F195);
      case 'polygon':
        return const Color(0xFF8247E5);
      case 'bsc':
        return const Color(0xFFF3BA2F);
      case 'avalanche':
        return const Color(0xFFE84142);
      case 'arbitrum':
        return const Color(0xFF28A0F0);
      case 'optimism':
        return const Color(0xFFFF0420);
      case 'base':
        return const Color(0xFF0052FF);
      case 'tron':
        return const Color(0xFFEB0029);
      default:
        return const Color(0xFF6C5CE7);
    }
  }

  Future<void> _onTokenTap(Token token, WalletProvider walletProvider) async {
    if (widget.config.multiSelect) {
      setState(() {
        if (_selectedTokenIds.contains(token.id)) {
          _selectedTokenIds.remove(token.id);
        } else if (_selectedTokenIds.length < widget.config.maxSelection) {
          _selectedTokenIds.add(token.id);
        }
      });
      return;
    }

    final addresses = await _getAddressesForNetwork(token.networkId, walletProvider);
    if (addresses.length <= 1) {
      if (addresses.isNotEmpty) {
        _onAddressTap(token, addresses.first, walletProvider);
      } else {
        _onTokenSelectDirect(token);
      }
    } else {
      setState(() {
        if (_expandedTokenIds.contains(token.id)) {
          _expandedTokenIds.remove(token.id);
        } else {
          _expandedTokenIds.add(token.id);
        }
      });
    }
  }

  void _onTokenSelectDirect(Token token) {
    Navigator.pop(context, TokenSelectionResult.single(token));
  }

  void _onAddressTap(Token token, String address, WalletProvider walletProvider) {
    // 选择具体地址即视为选中该token
    walletProvider.setSelectedAddress(address);
    Navigator.pop(context, TokenSelectionResult.single(token));
  }

  void _onConfirm() {
    final selectedTokens = _getFilteredTokens(
      Provider.of<WalletProvider>(context, listen: false)
    ).where((token) => _selectedTokenIds.contains(token.id)).toList();
    
    Navigator.pop(context, TokenSelectionResult.multiple(selectedTokens));
  }
}