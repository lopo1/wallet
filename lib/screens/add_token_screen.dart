import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/token.dart';
import '../services/token_service.dart';
import '../services/storage_service.dart';
import '../providers/wallet_provider.dart';

class AddTokenScreen extends StatefulWidget {
  const AddTokenScreen({super.key});

  @override
  State<AddTokenScreen> createState() => _AddTokenScreenState();
}

class _AddTokenScreenState extends State<AddTokenScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _contractAddressController =
      TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _symbolController = TextEditingController();
  final TextEditingController _decimalsController = TextEditingController();

  bool _isLoading = false;
  Token? _foundToken;
  String? _errorMessage;
  String _selectedNetworkId = 'ethereum';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // 获取当前选中的网络
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    if (walletProvider.currentNetwork != null) {
      _selectedNetworkId = walletProvider.currentNetwork!.id;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _contractAddressController.dispose();
    _nameController.dispose();
    _symbolController.dispose();
    _decimalsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2D3A),
        title: const Text(
          '添加代币',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6366F1),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: '搜索'),
            Tab(text: '自定义'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 网络选择器
          _buildNetworkSelector(),
          // 标签页内容
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSearchTab(),
                _buildCustomTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF2A2D3A),
        border: Border(
          bottom: BorderSide(color: Colors.white10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '选择网络',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Consumer<WalletProvider>(
            builder: (context, walletProvider, child) {
              final networks = walletProvider.supportedNetworks;

              return Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1B23),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white30),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedNetworkId,
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white70,
                    ),
                    dropdownColor: const Color(0xFF2A2D3A),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedNetworkId = newValue;
                          _foundToken = null;
                          _errorMessage = null;
                          _contractAddressController.clear();
                        });
                      }
                    },
                    items: networks.map<DropdownMenuItem<String>>((network) {
                      return DropdownMenuItem<String>(
                        value: network.id,
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Color(network.color),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getNetworkIcon(network.id),
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              network.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 合约地址输入
          _buildContractAddressInput(),
          const SizedBox(height: 24),

          // 搜索结果
          if (_foundToken != null) _buildTokenPreview(),
          if (_errorMessage != null) _buildErrorMessage(),

          const SizedBox(height: 24),

          // 热门代币
          _buildPopularTokens(),
        ],
      ),
    );
  }

  Widget _buildCustomTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '手动输入代币信息',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _contractAddressController,
            label: '合约地址',
            hint: '输入代币合约地址',
            required: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _nameController,
            label: '代币名称',
            hint: '例如: Ethereum',
            required: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _symbolController,
            label: '代币符号',
            hint: '例如: ETH',
            required: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _decimalsController,
            label: '小数位数',
            hint: '例如: 18',
            keyboardType: TextInputType.number,
            required: true,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addCustomToken,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '添加代币',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractAddressInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '合约地址',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _contractAddressController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '输入或粘贴代币合约地址',
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: const Color(0xFF2A2D3A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white30),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white30),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1)),
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.content_paste, color: Colors.white70),
                  onPressed: _pasteFromClipboard,
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                      ),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white70),
                    onPressed: _searchToken,
                  ),
              ],
            ),
          ),
          onChanged: (value) {
            setState(() {
              _foundToken = null;
              _errorMessage = null;
            });
          },
          onSubmitted: (_) => _searchToken(),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: const Color(0xFF2A2D3A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white30),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white30),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF6366F1)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTokenPreview() {
    if (_foundToken == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D3A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6366F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '找到代币',
            style: TextStyle(
              color: Color(0xFF6366F1),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _foundToken!.logoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          _foundToken!.logoUrl!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                _foundToken!.symbol.isNotEmpty
                                    ? _foundToken!.symbol[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Text(
                          _foundToken!.symbol.isNotEmpty
                              ? _foundToken!.symbol[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _foundToken!.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _foundToken!.symbol,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '小数位数: ${_foundToken!.decimals}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _addToken(_foundToken!),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '添加代币',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    if (_errorMessage == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularTokens() {
    final popularTokens = TokenService.getPopularTokens(_selectedNetworkId);

    if (popularTokens.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '热门代币',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...popularTokens.map((token) => _buildPopularTokenItem(token)),
      ],
    );
  }

  Widget _buildPopularTokenItem(Token token) {
    return FutureBuilder<bool>(
      future: _isTokenAdded(token),
      builder: (context, snapshot) {
        final isAdded = snapshot.data ?? false;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: isAdded ? null : () => _addToken(token),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isAdded
                    ? const Color(0xFF2A2D3A).withValues(alpha: 0.5)
                    : const Color(0xFF2A2D3A),
                borderRadius: BorderRadius.circular(12),
                border: isAdded
                    ? Border.all(color: const Color(0xFF6366F1), width: 1)
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: token.logoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              token.logoUrl!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Text(
                                    token.symbol.isNotEmpty
                                        ? token.symbol[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        : Center(
                            child: Text(
                              token.symbol.isNotEmpty
                                  ? token.symbol[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          token.name,
                          style: TextStyle(
                            color: isAdded ? Colors.white70 : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              token.symbol,
                              style: TextStyle(
                                color:
                                    isAdded ? Colors.white54 : Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            if (isAdded) ...[
                              const SizedBox(width: 8),
                              const Text(
                                '已添加',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isAdded ? Icons.check_circle : Icons.add_circle_outline,
                    color: isAdded ? Colors.green : const Color(0xFF6366F1),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null) {
        _contractAddressController.text = clipboardData!.text!;
        _searchToken();
      }
    } catch (e) {
      debugPrint('粘贴失败: $e');
    }
  }

  Future<void> _searchToken() async {
    final address = _contractAddressController.text.trim();

    if (address.isEmpty) {
      setState(() {
        _errorMessage = '请输入合约地址';
      });
      return;
    }

    if (!TokenService.isValidContractAddress(address, _selectedNetworkId)) {
      setState(() {
        _errorMessage = '无效的合约地址格式';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _foundToken = null;
    });

    try {
      final token =
          await TokenService.getTokenInfo(address, _selectedNetworkId);

      setState(() {
        _isLoading = false;
        if (token != null) {
          _foundToken = token;
        } else {
          _errorMessage = '未找到代币信息，请检查合约地址是否正确';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '搜索失败: ${e.toString()}';
      });
    }
  }

  void _addCustomToken() {
    final address = _contractAddressController.text.trim();
    final name = _nameController.text.trim();
    final symbol = _symbolController.text.trim();
    final decimalsText = _decimalsController.text.trim();

    if (address.isEmpty ||
        name.isEmpty ||
        symbol.isEmpty ||
        decimalsText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请填写所有必填字段'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!TokenService.isValidContractAddress(address, _selectedNetworkId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('无效的合约地址格式'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final decimals = int.tryParse(decimalsText);
    if (decimals == null || decimals < 0 || decimals > 18) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('小数位数必须是0-18之间的整数'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final token = Token(
      address: address.toLowerCase(),
      name: name,
      symbol: symbol.toUpperCase(),
      decimals: decimals,
      networkId: _selectedNetworkId,
    );

    _addToken(token);
  }

  /// 检查代币是否已经添加
  Future<bool> _isTokenAdded(Token token) async {
    try {
      final storageService = StorageService();
      final existingTokensData = await storageService.getCustomTokens();
      final existingTokens =
          existingTokensData.map((data) => Token.fromJson(data)).toList();

      return existingTokens.any((t) =>
          t.address.toLowerCase() == token.address.toLowerCase() &&
          t.networkId == token.networkId);
    } catch (e) {
      debugPrint('检查代币状态失败: $e');
      return false;
    }
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

  void _addToken(Token token) async {
    try {
      // 直接使用StorageService保存代币
      final storageService = StorageService();

      // 获取现有代币
      final existingTokensData = await storageService.getCustomTokens();
      final existingTokens =
          existingTokensData.map((data) => Token.fromJson(data)).toList();

      // 检查代币是否已存在
      final exists = existingTokens.any((t) =>
          t.address.toLowerCase() == token.address.toLowerCase() &&
          t.networkId == token.networkId);

      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${token.symbol} 代币已存在'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // 添加新代币
      existingTokens.add(token);

      // 保存到存储
      final tokensData = existingTokens.map((t) => t.toJson()).toList();
      await storageService.saveCustomTokens(tokensData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${token.symbol} 代币添加成功'),
          backgroundColor: Colors.green,
        ),
      );

      // 返回上一页，并传递添加成功的代币
      Navigator.pop(context, token);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('添加代币失败: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
