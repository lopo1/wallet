import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/swap_provider.dart';
import '../models/token_model.dart';
import '../widgets/token_input_field.dart';
import '../widgets/exchange_rate_display.dart';
import '../widgets/transaction_details_panel.dart';
import '../widgets/execute_swap_button.dart';
import '../widgets/security_tips_widget.dart';
import '../widgets/bottom_nav_bar.dart';

class OptimizedSwapScreen extends StatefulWidget {
  const OptimizedSwapScreen({Key? key}) : super(key: key);

  @override
  State<OptimizedSwapScreen> createState() => _OptimizedSwapScreenState();
}

class _OptimizedSwapScreenState extends State<OptimizedSwapScreen> {
  late SwapProvider _swapProvider;
  
  @override
  void initState() {
    super.initState();
    _swapProvider = SwapProvider();
    // 初始化默认代币
    _swapProvider.setFromToken(TokenPresets.ethereum);
    _swapProvider.setToToken(TokenPresets.usdt);
  }
  
  @override
  void dispose() {
    _swapProvider.dispose();
    super.dispose();
  }
  
  void _showTokenSelector(bool isFromToken) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // 标题栏
            Container(
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
                    '选择代币',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // 代币列表
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: TokenPresets.commonTokens.length,
                itemBuilder: (context, index) {
                  final token = TokenPresets.commonTokens[index];
                  return _buildTokenItem(token, isFromToken);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTokenItem(Token token, bool isFromToken) {
    final isSelected = isFromToken 
        ? _swapProvider.fromToken?.id == token.id
        : _swapProvider.toToken?.id == token.id;
    
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: token.color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            token.symbol.substring(0, 1),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      title: Text(
        token.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(token.symbol),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).primaryColor,
            )
          : null,
      onTap: () {
        Navigator.pop(context);
        if (isFromToken) {
          _swapProvider.setFromToken(token);
        } else {
          _swapProvider.setToToken(token);
        }
      },
    );
  }
  
  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSettingsPanel(),
    );
  }
  
  Widget _buildSettingsPanel() {
    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '交易设置',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // 滑点设置
              Text(
                '滑点容忍度',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                '价格变化的最大容忍度',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [0.1, 0.5, 1.0, 2.0, 3.0].map((slippage) {
                  final isSelected = (_swapProvider.slippageTolerance - slippage).abs() < 0.01;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${(slippage * 100).toStringAsFixed(1)}%'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _swapProvider.setSlippageTolerance(slippage);
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 24),
              
              // 交易期限
              Text(
                '交易期限',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                '交易的最大执行时间',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [10, 20, 30, 60].map((minutes) {
                  final isSelected = _swapProvider.transactionDeadline == minutes;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('$minutes 分钟'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _swapProvider.setTransactionDeadline(minutes);
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _swapProvider,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('兑换'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        ),
        body: Consumer<SwapProvider>(
          builder: (context, swapProvider, child) {
            return SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // 响应式布局
                  final isTablet = constraints.maxWidth > 600;
                  final horizontalPadding = isTablet ? 32.0 : 16.0;
                  final maxWidth = isTablet ? 600.0 : double.infinity;
                  
                  return Center(
                    child: Container(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Column(
                        children: [
                          // 主内容区域
                          Expanded(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SizedBox(height: 16),
                                  
                                  // From Token 输入区域
                                  TokenInputField(
                                    token: swapProvider.fromToken,
                                    amount: swapProvider.fromAmount,
                                    balance: swapProvider.fromTokenBalance,
                                    label: '从',
                                    isInput: true,
                                    showMaxButton: true,
                                    showPercentageButtons: true,
                                    onAmountChanged: swapProvider.setFromAmount,
                                    onTokenTap: () => _showTokenSelector(true),
                                    onMaxPressed: swapProvider.setMaxAmount,
                                    isLoading: swapProvider.isLoading,
                                    errorText: _getInputErrorText(swapProvider),
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // 交换按钮
                                  Center(
                                    child: GestureDetector(
                                      onTap: swapProvider.swapTokens,
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Theme.of(context).primaryColor.withOpacity(0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.swap_vert,
                                          size: 24,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // To Token 输入区域
                                  TokenInputField(
                                    token: swapProvider.toToken,
                                    amount: swapProvider.toAmount,
                                    balance: swapProvider.toTokenBalance,
                                    label: '到',
                                    isInput: false,
                                    showMaxButton: false,
                                    onAmountChanged: swapProvider.setToAmount,
                                    onTokenTap: () => _showTokenSelector(false),
                                    readOnly: true, // 只读，由报价计算得出
                                    isLoading: swapProvider.isLoading,
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // 汇率显示
                                  ExchangeRateDisplay(
                                    quote: swapProvider.currentQuote,
                                    isLoading: swapProvider.isLoading,
                                    priceImpact: swapProvider.priceImpact,
                                    lastUpdateTime: swapProvider.lastQuoteTime,
                                    onRefresh: swapProvider.refreshQuote,
                                    showPriceImpact: swapProvider.showPriceImpact,
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // 接收地址输入
                                  AddressInputWidget(
                                    onAddressChanged: swapProvider.setRecipientAddress,
                                    showValidation: true,
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // 交易详情面板
                                  TransactionDetailsPanel(
                                    quote: swapProvider.currentQuote,
                                    isLoading: swapProvider.isLoading,
                                    slippageTolerance: swapProvider.slippageTolerance,
                                    onSettingsTap: _showSettings,
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // 安全提示
                                  SecurityTipsWidget(
                                    showAddressWarning: swapProvider.recipientAddress != null && 
                                                       swapProvider.recipientAddress!.isNotEmpty,
                                    showSlippageWarning: swapProvider.slippageTolerance > 2.0,
                                    showPriceImpactWarning: swapProvider.showPriceImpact,
                                    priceImpact: swapProvider.priceImpact,
                                    slippage: swapProvider.slippageTolerance,
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // 执行按钮
                                  ExecuteSwapButton(
                                    canExecute: swapProvider.canExecuteSwap,
                                    status: swapProvider.transactionStatus,
                                    isLoading: swapProvider.isLoading,
                                    errorText: swapProvider.error,
                                    onPressed: swapProvider.executeSwap,
                                    fromAmount: swapProvider.fromAmount,
                                    toAmount: swapProvider.toAmount,
                                    fromToken: swapProvider.fromToken?.symbol,
                                    toToken: swapProvider.toToken?.symbol,
                                  ),
                                  
                                  const SizedBox(height: 32),
                                ],
                              ),
                            ),
                          ),
                          
                          // 底部导航栏
                          const BottomNavBar(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
  
  String? _getInputErrorText(SwapProvider provider) {
    if (provider.fromAmount > 0 && provider.fromAmount > provider.fromTokenBalance) {
      return '余额不足';
    }
    if (provider.fromToken != null && 
        provider.toToken != null && 
        provider.fromToken!.id == provider.toToken!.id) {
      return '不能兑换相同的代币';
    }
    return null;
  }
}