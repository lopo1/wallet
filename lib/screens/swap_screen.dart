import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../providers/wallet_provider.dart';
import '../models/network.dart';
import '../models/token_model.dart';
import '../widgets/overlaid_token_icon.dart';
import '../widgets/enhanced_token_input_field.dart';
import '../widgets/universal_token_selector.dart';
import '../utils/amount_utils.dart';
import '../services/storage_service.dart';

class SwapScreen extends StatefulWidget {
  const SwapScreen({super.key});

  @override
  State<SwapScreen> createState() => _SwapScreenState();
}

class _SwapScreenState extends State<SwapScreen> {
  final TextEditingController _fromAmountController = TextEditingController();
  final TextEditingController _toAmountController = TextEditingController();

  Network? _fromNetwork;
  Network? _toNetwork;
  Token? _fromToken;
  Token? _toToken;
  double _exchangeRate = 0.98949999; // Mock exchange rate
  double _availableBalance = 4.02; // Mock balance
  bool _isSwapping = false;
  double _slippage = 0.5; // 滑点百分比，默认0.5%
  String? _recipientAddress; // 接收地址

  // 持久化最近选择
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      if (walletProvider.supportedNetworks.isNotEmpty) {
        setState(() {
          _fromNetwork = walletProvider.supportedNetworks.first;
          _toNetwork = walletProvider.supportedNetworks.first;
          // 初始化接收地址为当前钱包地址
          _recipientAddress = walletProvider.getCurrentNetworkAddress();
        });
        _initializeDefaultSelection(walletProvider);
      }
    });

    _fromAmountController.addListener(_onFromAmountChanged);
  }

  @override
  void dispose() {
    _fromAmountController.removeListener(_onFromAmountChanged);
    _fromAmountController.dispose();
    _toAmountController.dispose();
    super.dispose();
  }

  void _onFromAmountChanged() {
    final fromAmount = double.tryParse(_fromAmountController.text) ?? 0.0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final newText =
          fromAmount > 0 ? (fromAmount * _exchangeRate).toStringAsFixed(3) : '';
      if (_toAmountController.text == newText) return;
      setState(() {
        _toAmountController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
      });
    });
  }

  bool get _hasInsufficientBalance {
    final amount = double.tryParse(_fromAmountController.text) ?? 0.0;
    return amount > _availableBalance;
  }

  bool get _hasValidAmount {
    final amount = double.tryParse(_fromAmountController.text) ?? 0.0;
    return amount > 0 && !_hasInsufficientBalance;
  }

  void _swapTokens() {
    setState(() {
      // Swap networks
      final tempNetwork = _fromNetwork;
      _fromNetwork = _toNetwork;
      _toNetwork = tempNetwork;

      // Swap tokens
      final tempToken = _fromToken;
      _fromToken = _toToken;
      _toToken = tempToken;

      // Clear amounts when swapping
      _fromAmountController.clear();
      _toAmountController.clear();

      // Update exchange rate (inverse)
      _exchangeRate = 1 / _exchangeRate;
    });
    _saveLastSelection();
  }

  Future<void> _executeSwap() async {
    if (_fromAmountController.text.isEmpty ||
        double.tryParse(_fromAmountController.text) == null ||
        double.parse(_fromAmountController.text) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入有效的交换数量'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSwapping = true;
    });

    try {
      // Simulate swap transaction
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('交换成功！'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _fromAmountController.clear();
        _toAmountController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('交换失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSwapping = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('交换'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // 检查是否可以返回，如果不能则导航到首页
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: Consumer<WalletProvider>(
        builder: (context, walletProvider, child) {
          // 同步接收地址：如果当前选中的地址属于接收代币的网络，则使用该地址
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_toToken != null &&
                walletProvider.selectedAddress != null &&
                walletProvider.currentNetwork?.id == _toToken!.networkId &&
                _recipientAddress != walletProvider.selectedAddress) {
              setState(() {
                _recipientAddress = walletProvider.selectedAddress;
              });
            }
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // From Token Section
                // 使用 Stack 实现交换图标跨越两输入框边界，并在两卡片之间加入2像素间隙
                Column(
                  children: [
                    // From Token Section
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12, width: 1),
                      ),
                      child: _buildTokenSection(
                        title: '发送',
                        network: _fromNetwork,
                        token: _fromToken,
                        controller: _fromAmountController,
                        isFrom: true,
                        walletProvider: walletProvider,
                      ),
                    ),

                    // Swap Button with spacing
                    Container(
                      height: 52,
                      alignment: Alignment.center,
                      child: _buildSwapButton(),
                    ),

                    // To Token Section
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12, width: 1),
                      ),
                      child: _buildTokenSection(
                        title: '接收',
                        network: _toNetwork,
                        token: _toToken,
                        controller: _toAmountController,
                        isFrom: false,
                        walletProvider: walletProvider,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Execute Swap Button
                _buildExecuteButton(),
                const SizedBox(height: 12),

                // Exchange Rate - show when tokens selected
                if (_fromToken != null && _toToken != null) ...[
                  _buildExchangeRate(),
                  const SizedBox(height: 16),
                ],

                // Transaction Details - only show when amount is entered
                if (_fromAmountController.text.isNotEmpty &&
                    double.tryParse(_fromAmountController.text) != null &&
                    double.parse(_fromAmountController.text) > 0)
                  _buildTransactionDetails(),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 1,
        onItemSelected: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              // current page
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/dapp-browser');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/settings');
              break;
          }
        },
      ),
    );
  }

  Widget _buildTokenSection({
    required String title,
    required Network? network,
    required Token? token,
    required TextEditingController controller,
    required bool isFrom,
    required WalletProvider walletProvider,
  }) {
    // 使用卡片容器包裹，并将“发送/接收”标签置于卡片内部顶部，与输入对齐
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部行：左侧为"发送/接收"标题，右侧为余额和MAX按钮
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (token != null)
                FutureBuilder<double>(
                  future: token!.isNative
                      ? walletProvider.getNetworkBalance(token!.networkId)
                      : Future.value(0.0),
                  builder: (context, snapshot) {
                    final balance = snapshot.data ?? 0.0;
                    final balanceText =
                        AmountUtils.formatTruncated(balance, decimals: 6);
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '余额: $balanceText ${token!.symbol}',
                          style: const TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                        // 只在发送框显示MAX按钮
                        if (isFrom) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () async {
                              // 使用真实余额（原生代币）；合约代币后续接入TokenService
                              final selected = token;
                              double balance = 0.0;
                              if (selected != null) {
                                try {
                                  if (selected.isNative) {
                                    balance = await walletProvider
                                        .getNetworkBalance(selected.networkId);
                                  }
                                } catch (_) {
                                  balance = 0.0;
                                }
                              }
                              controller.text = AmountUtils.formatTruncated(
                                  balance,
                                  decimals: 6);
                              _onFromAmountChanged();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                'MAX',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          EnhancedTokenInputField(
            label: null,
            selectedToken: token,
            amount: controller.text,
            amountController: controller,
            tokenHint: '选择币种',
            onTokenChanged: (selectedToken) {
              setState(() {
                if (isFrom) {
                  _fromToken = selectedToken;
                } else {
                  _toToken = selectedToken;
                  // 当选择接收代币时，更新接收地址为对应网络的地址
                  if (selectedToken != null &&
                      walletProvider.currentWallet != null) {
                    // 如果选择的代币网络与当前网络相同，使用当前选中的地址
                    if (selectedToken.networkId ==
                            walletProvider.currentNetwork?.id &&
                        walletProvider.selectedAddress != null) {
                      _recipientAddress = walletProvider.selectedAddress;
                    } else {
                      // 否则使用该网络的第一个地址
                      _recipientAddress = walletProvider.getAddressForNetwork(
                          walletProvider.currentWallet!.id,
                          selectedToken.networkId);
                    }
                  }
                }
              });
              _saveLastSelection();
            },
            onAmountChanged: (amount) {
              controller.text = amount;
              if (isFrom) {
                _onFromAmountChanged();
              } else {
                final toValue = double.tryParse(amount) ?? 0.0;
                final fromValue =
                    _exchangeRate == 0 ? 0.0 : toValue / _exchangeRate;
                _fromAmountController.text =
                    AmountUtils.formatTruncated(fromValue, decimals: 6);
                setState(() {});
              }
            },
            onMaxPressed: isFrom
                ? () async {
                    // 使用真实余额（原生代币）；合约代币后续接入TokenService
                    final selected = token;
                    double balance = 0.0;
                    if (selected != null) {
                      try {
                        if (selected.isNative) {
                          balance = await walletProvider
                              .getNetworkBalance(selected.networkId);
                        }
                      } catch (_) {
                        balance = 0.0;
                      }
                    }
                    controller.text =
                        AmountUtils.formatTruncated(balance, decimals: 6);
                    _onFromAmountChanged();
                  }
                : null,
            // 允许两侧的代币选择按钮可点击；接收侧金额只读
            enabled: true,
            amountReadOnly: false,
            // 余额已移到顶部行右侧，这里不再重复显示
            showBalance: false,
            showUsdValue: true,
            showMaxButton: false, // MAX按钮已移到顶部行，这里关闭
            style: const TokenInputFieldStyle(
              // 明确的深色输入框与边框，让输入更明显
              backgroundColor: Color(0xFF22223A),
              focusedBackgroundColor: Color(0xFF24243A),
              disabledBackgroundColor: Color(0xFF1A1A2E),
              borderColor: Colors.white12,
              focusedBorderColor: Colors.white30,
              disabledBorderColor: Colors.white10,
              borderRadius: 12,
              borderWidth: 1,
              // 减少容器内边距，让输入框内容更贴近边缘
              containerPadding:
                  EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              amountTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              hintTextStyle: TextStyle(
                color: Colors.white54,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              balanceTextStyle: TextStyle(
                color: Color(0xFF999999),
                fontSize: 13,
              ),
              usdValueTextStyle: TextStyle(
                color: Color(0xFF999999),
                fontSize: 12,
              ),
            ),
            selectorConfig: TokenSelectorConfig(
              title: '选择币种',
              showSearch: true,
              showNetworkFilter: true,
              showBalance: true,
              showUsdValue: true,
              mode: TokenSelectorMode.fullscreen,
              onlyShowWithBalance: false,
              preselectedToken: token,
              excludeTokens: isFrom
                  ? (_toToken != null ? [_toToken!.id] : [])
                  : (_fromToken != null ? [_fromToken!.id] : []),
              customTokens: walletProvider
                  .getAllAssets()
                  .map((asset) => Token(
                        id: asset['id'] as String? ?? asset['symbol'] as String,
                        symbol: asset['symbol'] as String,
                        name: asset['name'] as String,
                        contractAddress:
                            (asset['contractAddress'] as String?) ??
                                (asset['address'] as String?) ??
                                '',
                        decimals: asset['decimals'] as int? ?? 18,
                        networkId: (asset['networkId'] as String?) ??
                            (asset['id'] as String?) ??
                            'ethereum',
                        priceUsd: asset['price'] as double? ?? 0.0,
                        iconUrl: asset['logoUrl'] as String?,
                        isNative: asset['isNative'] as bool? ?? false,
                      ))
                  .toList(),
            ),
          ),
          // 接收地址显示（仅在接收框显示）
          if (!isFrom && _recipientAddress != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '接收地址',
                          style: TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _recipientAddress!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showAddressSelector(walletProvider),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Icon(
                        Icons.contacts,
                        color: Theme.of(context).primaryColor,
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

  Widget _buildSwapButton() {
    return Center(
      child: GestureDetector(
        onTap: _swapTokens,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF7C4DFF),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF1A1A1A),
              width: 3,
            ),
          ),
          child: const Icon(
            Icons.swap_vert,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildRecipientAddress(WalletProvider walletProvider) {
    final address = walletProvider.getCurrentNetworkAddress() ??
        '0x85C88B77318D7F7F11115641d4faBe0C0B0D8';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              address,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF999999),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: address));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('地址已复制'),
                  duration: Duration(seconds: 1),
                  backgroundColor: Color(0xFF4CAF50),
                ),
              );
            },
            child: const Icon(
              Icons.copy,
              size: 16,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '* ',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFFFF9800),
            ),
          ),
          Expanded(
            child: Text(
              '该地址为您钱包的目标地址，请仔细核认以免造成资金损失！',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF999999),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeRate() {
    final fromSymbol = _fromToken?.symbol?.toUpperCase() ?? '';
    final toSymbol = _toToken?.symbol?.toUpperCase() ?? '';
    final rateText = _exchangeRate.toStringAsFixed(6);
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Color(0xFF26A69A),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.sync_alt,
            color: Colors.white,
            size: 12,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '1 $fromSymbol = $rateText $toSymbol',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF999999),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.refresh,
          size: 16,
          color: Color(0xFF999999),
        ),
      ],
    );
  }

  Widget _buildTransactionDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D29),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '交易详情',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('滑点容忍度', '${_slippage}%'),
          _buildDetailRow(
            '最小接收',
            '${AmountUtils.formatTruncated(((double.tryParse(_toAmountController.text) ?? 0.0) * (1 - (_slippage / 100))), decimals: 6)} ${_toToken?.symbol?.toUpperCase() ?? ''}',
          ),
          _buildDetailRow('网络费用', '0.3%'),
          _buildDetailRow('路由', 'Uniswap V3'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecuteButton() {
    final hasAmount = _fromAmountController.text.isNotEmpty &&
        double.tryParse(_fromAmountController.text) != null &&
        double.parse(_fromAmountController.text) > 0;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: !_isSwapping && hasAmount ? _executeSwap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: hasAmount
              ? const Color(0xFF6366F1)
              : const Color.fromARGB(255, 52, 51, 51),
          foregroundColor: hasAmount ? Colors.white : const Color(0xFF666666),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: hasAmount
                ? BorderSide.none
                : const BorderSide(color: Color(0xFF3A3A3A), width: 1),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ).copyWith(
          overlayColor: MaterialStateProperty.all(Colors.transparent),
        ),
        child: _isSwapping
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                hasAmount ? '兑换' : '请输入兑换数量',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: hasAmount ? Colors.white : const Color(0xFF666666),
                ),
              ),
      ),
    );
  }

  void _showTokenSelector(bool isFrom) async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);

    // 配置Token选择器
    final config = TokenSelectorConfig(
      mode: TokenSelectorMode.fullscreen,
      title: '选择币种',
      showSearch: true,
      showNetworkFilter: true,
      showBalance: true,
      showUsdValue: true,
      onlyShowWithBalance: false,
      preselectedToken: isFrom ? _fromToken : _toToken,
      excludeTokens: isFrom
          ? (_toToken != null ? [_toToken!.id] : [])
          : (_fromToken != null ? [_fromToken!.id] : []),
      customTokens: walletProvider
          .getAllAssets()
          .map((asset) => Token(
                id: asset['id'] as String? ?? asset['symbol'] as String,
                symbol: asset['symbol'] as String,
                name: asset['name'] as String,
                contractAddress: (asset['contractAddress'] as String?) ??
                    (asset['address'] as String?) ??
                    '',
                decimals: asset['decimals'] as int? ?? 18,
                networkId: (asset['networkId'] as String?) ??
                    (asset['id'] as String?) ??
                    'ethereum',
                priceUsd: asset['price'] as double? ?? 0.0,
                iconUrl: asset['logoUrl'] as String?,
                isNative: asset['isNative'] as bool? ?? false,
              ))
          .toList(),
    );

    final result = await UniversalTokenSelector.show(
      context: context,
      config: config,
    );

    if (result != null && result.selectedToken != null) {
      final selectedToken = result.selectedToken!;
      setState(() {
        if (isFrom) {
          _fromToken = selectedToken;
          // 如果网络不同，更新网络
          if (_fromNetwork?.id != selectedToken.networkId) {
            _fromNetwork = walletProvider.supportedNetworks.firstWhere(
                (n) => n.id == selectedToken.networkId,
                orElse: () => _fromNetwork!);
          }
        } else {
          _toToken = selectedToken;
          // 如果网络不同，更新网络
          if (_toNetwork?.id != selectedToken.networkId) {
            _toNetwork = walletProvider.supportedNetworks.firstWhere(
                (n) => n.id == selectedToken.networkId,
                orElse: () => _toNetwork!);
          }
        }
      });
    }
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '交换设置',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.speed),
                title: const Text('滑点容忍度'),
                subtitle: const Text('0.5%'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('交易截止时间'),
                subtitle: const Text('20分钟'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _initializeDefaultSelection(
      WalletProvider walletProvider) async {
    try {
      final data = await _storageService.getData('swap_last_selection');
      if (data is Map && data['from'] != null && data['to'] != null) {
        final fromJson = Map<String, dynamic>.from(data['from'] as Map);
        final toJson = Map<String, dynamic>.from(data['to'] as Map);
        final fromToken = Token.fromJson(fromJson);
        final toToken = Token.fromJson(toJson);
        setState(() {
          _fromToken = fromToken;
          _toToken = toToken;
          try {
            _fromNetwork = walletProvider.supportedNetworks.firstWhere(
              (n) => n.id == fromToken.networkId,
              orElse: () => walletProvider.supportedNetworks.first,
            );
            _toNetwork = walletProvider.supportedNetworks.firstWhere(
              (n) => n.id == toToken.networkId,
              orElse: () => walletProvider.supportedNetworks.first,
            );
            // 更新接收地址为接收代币对应的网络地址
            if (walletProvider.currentWallet != null) {
              // 如果接收代币网络与当前网络相同，使用当前选中的地址
              if (toToken.networkId == walletProvider.currentNetwork?.id &&
                  walletProvider.selectedAddress != null) {
                _recipientAddress = walletProvider.selectedAddress;
              } else {
                // 否则使用该网络的第一个地址
                _recipientAddress = walletProvider.getAddressForNetwork(
                    walletProvider.currentWallet!.id, toToken.networkId);
              }
            }
          } catch (_) {}
        });
      } else {
        // 默认：SOL 兑换 Solana USDT
        setState(() {
          _fromToken = TokenPresets.sol;
          _toToken = TokenPresets.usdtSol;
          try {
            _fromNetwork = walletProvider.supportedNetworks.firstWhere(
              (n) => n.id == 'solana',
              orElse: () => walletProvider.supportedNetworks.first,
            );
            _toNetwork = walletProvider.supportedNetworks.firstWhere(
              (n) => n.id == 'solana',
              orElse: () => walletProvider.supportedNetworks.first,
            );
            // 更新接收地址为默认接收代币对应的网络地址
            if (walletProvider.currentWallet != null) {
              // 如果默认接收代币网络与当前网络相同，使用当前选中的地址
              if ('solana' == walletProvider.currentNetwork?.id &&
                  walletProvider.selectedAddress != null) {
                _recipientAddress = walletProvider.selectedAddress;
              } else {
                // 否则使用该网络的第一个地址
                _recipientAddress = walletProvider.getAddressForNetwork(
                    walletProvider.currentWallet!.id, 'solana');
              }
            }
          } catch (_) {}
        });
      }
    } catch (e) {
      // Fallback到默认
      setState(() {
        _fromToken = TokenPresets.sol;
        _toToken = TokenPresets.usdtSol;
        // 更新接收地址为默认接收代币对应的网络地址
        if (walletProvider.currentWallet != null) {
          // 如果默认接收代币网络与当前网络相同，使用当前选中的地址
          if ('solana' == walletProvider.currentNetwork?.id &&
              walletProvider.selectedAddress != null) {
            _recipientAddress = walletProvider.selectedAddress;
          } else {
            // 否则使用该网络的第一个地址
            _recipientAddress = walletProvider.getAddressForNetwork(
                walletProvider.currentWallet!.id, 'solana');
          }
        }
      });
    }
  }

  Future<void> _saveLastSelection() async {
    try {
      if (_fromToken != null && _toToken != null) {
        await _storageService.saveData('swap_last_selection', {
          'from': _fromToken!.toJson(),
          'to': _toToken!.toJson(),
        });
      }
    } catch (_) {}
  }

  // 显示地址选择器
  void _showAddressSelector(WalletProvider walletProvider) {
    final currentWallet = walletProvider.currentWallet;

    if (currentWallet == null || _toToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择钱包和接收代币')),
      );
      return;
    }

    // 使用接收代币的网络ID来获取地址列表
    final targetNetworkId = _toToken!.networkId;
    final addresses = currentWallet.addresses[targetNetworkId] ?? [];

    if (addresses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_toToken!.networkId}网络没有可用地址')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '选择接收地址',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...addresses.asMap().entries.map((entry) {
                final index = entry.key;
                final address = entry.value;
                final addressName = currentWallet.addressNames[address] ??
                    '${currentWallet.name} #${index + 1}';
                final isSelected = address == _recipientAddress;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSelected
                          ? Theme.of(context).primaryColor
                          : const Color(0xFF22223A),
                      child: Icon(
                        Icons.account_balance_wallet,
                        color:
                            isSelected ? Colors.white : const Color(0xFF999999),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      addressName,
                      style: TextStyle(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.white,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      '${address.substring(0, 6)}...${address.substring(address.length - 4)}',
                      style: const TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 12,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(context).primaryColor,
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _recipientAddress = address;
                      });
                      Navigator.pop(context);
                    },
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
