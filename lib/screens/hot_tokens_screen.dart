import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HotTokensScreen extends StatefulWidget {
  const HotTokensScreen({super.key});

  @override
  State<HotTokensScreen> createState() => _HotTokensScreenState();
}

class _HotTokensScreenState extends State<HotTokensScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _selectedNetwork = '全部网络';
  
  // 网络选项列表
  final List<String> _networks = [
    '全部网络',
    '以太坊',
    'BSC',
    'Polygon',
    'Arbitrum',
    'Optimism',
    'Solana',
  ];
  
  // 模拟热门代币数据
  final List<TokenData> _hotTokens = [
    TokenData(
      symbol: 'USDT',
      name: 'Tether',
      price: '\$1',
      change: '+0.01638%',
      isPositive: true,
      marketCap: '\$179.95B',
      volume: '\$152.39B',
      icon: 'T',
      iconColor: const Color(0xFF26A17B),
      network: 'Ethereum',
      contractAddress: '0xdAC17F958D2ee523a2206206994597C13D831ec7',
      isNativeToken: false,
      chainIcon: 'Ξ',
    ),
    TokenData(
      symbol: 'BTC',
      name: 'Bitcoin',
      price: '\$111,871',
      change: '-3.12944%',
      isPositive: false,
      marketCap: '\$2.23T',
      volume: '\$73.6B',
      icon: '₿',
      iconColor: const Color(0xFFF7931A),
      network: 'Ethereum',
      contractAddress: '0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599', // WBTC
      isNativeToken: false,
      chainIcon: 'Ξ',
    ),
    TokenData(
      symbol: 'ETH',
      name: 'Ethereum',
      price: '\$3,995.76',
      change: '-4.7648%',
      isPositive: false,
      marketCap: '\$482.28B',
      volume: '\$46.35B',
      icon: 'Ξ',
      iconColor: const Color(0xFF627EEA),
      network: 'Ethereum',
      isNativeToken: true,
      chainIcon: 'Ξ',
    ),
    TokenData(
      symbol: 'SOL',
      name: 'Solana',
      price: '\$195.83',
      change: '-1.46447%',
      isPositive: false,
      marketCap: '\$107.06B',
      volume: '\$12.86B',
      icon: 'S',
      iconColor: const Color(0xFF9945FF),
      network: 'Solana',
      isNativeToken: true,
      chainIcon: 'S',
    ),
    // 添加更多不同网络的代币
    TokenData(
      symbol: 'BNB',
      name: 'BNB',
      price: '\$712.45',
      change: '+2.34%',
      isPositive: true,
      marketCap: '\$102.8B',
      volume: '\$2.1B',
      icon: 'B',
      iconColor: const Color(0xFFF3BA2F),
      network: 'BSC',
      isNativeToken: true,
      chainIcon: 'B',
    ),
    TokenData(
      symbol: 'MATIC',
      name: 'Polygon',
      price: '\$0.4521',
      change: '-1.23%',
      isPositive: false,
      marketCap: '\$4.2B',
      volume: '\$890M',
      icon: 'M',
      iconColor: const Color(0xFF8247E5),
      network: 'Polygon',
      isNativeToken: true,
      chainIcon: 'M',
    ),
    TokenData(
      symbol: 'ARB',
      name: 'Arbitrum',
      price: '\$0.8934',
      change: '+5.67%',
      isPositive: true,
      marketCap: '\$3.1B',
      volume: '\$456M',
      icon: 'A',
      iconColor: const Color(0xFF28A0F0),
      network: 'Arbitrum',
      isNativeToken: true,
      chainIcon: 'A',
    ),
    TokenData(
      symbol: 'OP',
      name: 'Optimism',
      price: '\$2.1456',
      change: '-0.89%',
      isPositive: false,
      marketCap: '\$2.8B',
      volume: '\$234M',
      icon: 'O',
      iconColor: const Color(0xFFFF0420),
      network: 'Optimism',
      isNativeToken: true,
      chainIcon: 'O',
    ),
  ];

  List<TokenData> _filteredTokens = [];

  @override
  void initState() {
    super.initState();
    _filteredTokens = _getFilteredTokensByNetwork();
  }

  void _filterTokens(String query) {
    setState(() {
      List<TokenData> tokensToFilter = _getFilteredTokensByNetwork();
      
      if (query.isEmpty) {
        _filteredTokens = tokensToFilter;
      } else {
        _filteredTokens = tokensToFilter
            .where((token) =>
                token.symbol.toLowerCase().contains(query.toLowerCase()) ||
                token.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  List<TokenData> _getFilteredTokensByNetwork() {
    if (_selectedNetwork == '全部网络') {
      return _hotTokens;
    } else {
      return _hotTokens.where((token) => token.network == _selectedNetwork).toList();
    }
  }

  void _onNetworkChanged(String network) {
    setState(() {
      _selectedNetwork = network;
      // 重新应用搜索筛选，但基于新的网络筛选结果
      _filterTokens(_searchController.text);
    });
  }

  void _showNetworkSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2D3A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '选择网络',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
               ..._networks.map((network) => ListTile(
                title: Text(
                  network,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                trailing: _selectedNetwork == network
                    ? const Icon(
                        Icons.check,
                        color: Color(0xFF6366F1),
                      )
                    : null,
                onTap: () {
                  _onNetworkChanged(network);
                  Navigator.pop(context);
                },
              )).toList(),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B23),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: _buildTokensList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            '热门代币',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _showNetworkSelector,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2D3A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.language,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _selectedNetwork,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white.withOpacity(0.7),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D3A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterTokens,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: '代币名称或者合约地址',
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.white.withOpacity(0.5),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTokensList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredTokens.length,
      itemBuilder: (context, index) {
        final token = _filteredTokens[index];
        return _buildTokenItem(token);
      },
    );
  }

  Widget _buildTokenItem(TokenData token) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D3A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 代币图标 + 链图标
            Stack(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: token.iconColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      token.icon,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // 链图标在右下角
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1D29),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF2A2D3A),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        token.chainIcon,
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
            const SizedBox(width: 10),
            // 代币信息
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          token.symbol,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    token.name,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  // 显示合约地址（仅非原生代币）
                  if (!token.isNativeToken && token.contractAddress != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${token.contractAddress!.substring(0, 6)}...${token.contractAddress!.substring(token.contractAddress!.length - 4)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 9,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  // 流动性和成交量放在同一行
                  Text(
                    '流动性 ${token.marketCap} • 24H成交额 ${token.volume}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 9,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // 价格和涨跌幅
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    token.price,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    token.change,
                    style: TextStyle(
                      color: token.isPositive ? Colors.green : Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            // 开关按钮
            SizedBox(
              width: 40,
              child: Transform.scale(
                scale: 0.7,
                child: Switch(
                  value: true,
                  onChanged: (value) {
                    // TODO: 实现代币开关逻辑
                  },
                  activeColor: const Color(0xFF6366F1),
                  inactiveThumbColor: Colors.white.withOpacity(0.5),
                  inactiveTrackColor: Colors.white.withOpacity(0.2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TokenData {
  final String symbol;
  final String name;
  final String price;
  final String change;
  final bool isPositive;
  final String marketCap;
  final String volume;
  final String icon;
  final Color iconColor;
  final String network; // 网络属性
  final String? contractAddress; // 合约地址（可选）
  final bool isNativeToken; // 是否为原生代币
  final String chainIcon; // 链图标

  TokenData({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.isPositive,
    required this.marketCap,
    required this.volume,
    required this.icon,
    required this.iconColor,
    required this.network,
    this.contractAddress, // 可选参数
    required this.isNativeToken,
    required this.chainIcon,
  });
}