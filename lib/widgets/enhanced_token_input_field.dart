import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/token_model.dart';
import 'token_selector_button.dart';
import 'universal_token_selector.dart';
import '../providers/wallet_provider.dart';
import '../utils/amount_utils.dart';

/// 增强版Token输入字段组件
/// 整合了token选择和金额输入功能，提供完整的交易输入体验
class EnhancedTokenInputField extends StatefulWidget {
  /// 当前选中的token
  final Token? selectedToken;
  
  /// 输入的金额
  final String? amount;
  
  /// token选择回调
  final ValueChanged<Token?> onTokenChanged;
  
  /// 金额变化回调
  final ValueChanged<String> onAmountChanged;
  
  /// 最大按钮点击回调
  final VoidCallback? onMaxPressed;
  
  /// 字段标签
  final String? label;
  
  /// 金额输入提示文本
  final String amountHint;
  
  /// token选择提示文本
  final String tokenHint;
  
  /// 是否显示余额
  final bool showBalance;
  
  /// 是否显示USD价值
  final bool showUsdValue;
  
  /// 是否显示最大按钮
  final bool showMaxButton;
  
  /// 是否启用
  final bool enabled;

  /// 金额输入是否只读（用于接收框禁止手动输入但允许选择代币）
  final bool amountReadOnly;
  
  /// 输入字段样式
  final TokenInputFieldStyle style;
  
  /// token选择器配置
  final TokenSelectorConfig selectorConfig;
  
  /// 金额输入控制器
  final TextEditingController? amountController;

  const EnhancedTokenInputField({
    Key? key,
    this.selectedToken,
    this.amount,
    required this.onTokenChanged,
    required this.onAmountChanged,
    this.onMaxPressed,
    this.label,
    this.amountHint = '0.0',
    this.tokenHint = '选择代币',
    this.showBalance = true,
    this.showUsdValue = true,
    this.showMaxButton = true,
    this.enabled = true,
    this.amountReadOnly = false,
    this.style = const TokenInputFieldStyle(),
    this.selectorConfig = const TokenSelectorConfig(),
    this.amountController,
  }) : super(key: key);

  @override
  State<EnhancedTokenInputField> createState() => _EnhancedTokenInputFieldState();
}

class _EnhancedTokenInputFieldState extends State<EnhancedTokenInputField> {
  late TextEditingController _amountController;
  bool _isAmountFocused = false;

  @override
  void initState() {
    super.initState();
    _amountController = widget.amountController ?? TextEditingController();
    if (widget.amount != null) {
      _amountController.text = widget.amount!;
    }
  }

  @override
  void didUpdateWidget(EnhancedTokenInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.amount != oldWidget.amount && widget.amount != null) {
      _amountController.text = widget.amount!;
    }
  }

  @override
  void dispose() {
    if (widget.amountController == null) {
      _amountController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标签
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: widget.style.labelStyle ?? 
                   Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: widget.style.labelSpacing),
        ],
        
        // 主输入区域
        Container(
          padding: widget.style.containerPadding,
          decoration: BoxDecoration(
            color: _getBackgroundColor(context),
            borderRadius: BorderRadius.circular(widget.style.borderRadius),
            border: Border.all(
              color: _getBorderColor(context),
              width: widget.style.borderWidth,
            ),
          ),
          child: Column(
            children: [
              // 金额输入和token选择行
              Row(
                children: [
                  // 金额输入
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _amountController,
                          enabled: widget.enabled,
                          readOnly: widget.amountReadOnly,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                          ],
                          style: widget.style.amountTextStyle ?? 
                                 const TextStyle(
                                   color: Colors.white,
                                   fontSize: 20,
                                   fontWeight: FontWeight.w500,
                                 ),
                          decoration: InputDecoration(
                            hintText: widget.amountHint,
                            hintStyle: widget.style.hintTextStyle,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: widget.onAmountChanged,
                          onTapOutside: (event) {
                            FocusScope.of(context).unfocus();
                          },
                        ),
                        // USD价值显示在输入框下面
                        if (widget.showUsdValue && widget.selectedToken != null && _amountController.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: _buildUsdValue(),
                          ),
                      ],
                    ),
                  ),
                  
                  // 减少间距，让币种选择按钮更贴近右边
                  const SizedBox(width: 8),
                  
                  // Token选择按钮
                  TokenSelectorButton(
                    selectedToken: widget.selectedToken,
                    onTokenSelected: widget.onTokenChanged,
                    config: widget.selectorConfig,
                    enabled: widget.enabled,
                    placeholder: widget.tokenHint,
                    style: TokenSelectorButtonStyle(
                      // 减少内边距，让按钮更紧凑
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      // 启用状态：与主题主色弱化一致
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderColor: Theme.of(context).primaryColor.withOpacity(0.2),
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      iconColor: Colors.white70,
                      // 禁用状态：统一深色外观，避免白色背景
                      disabledBackgroundColor: const Color(0xFF1A1A2E),
                      disabledBorderColor: Colors.white12,
                      disabledTextColor: Colors.white,
                      disabledIconColor: Colors.white70,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: widget.style.elementSpacing),
              
              // 余额和MAX行（避免溢出：余额使用Expanded，右侧MAX固定宽度）
              Row(
                children: [
                  if (widget.showBalance && widget.selectedToken != null)
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _buildBalanceInfo(),
                      ),
                    ),
                  if (widget.showMaxButton && widget.onMaxPressed != null)
                    _buildMaxButton(),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceInfo() {
    if (widget.selectedToken == null) return const SizedBox.shrink();

    // 使用WalletProvider获取原生代币余额；合约代币后续接入TokenService
    return _BalanceFutureView(
      token: widget.selectedToken!,
      textStyle: widget.style.balanceTextStyle ??
          Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
    );
  }

  Widget _buildMaxButton() {
    return GestureDetector(
      onTap: widget.enabled ? widget.onMaxPressed : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: widget.enabled 
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.enabled 
                ? Theme.of(context).primaryColor.withOpacity(0.3)
                : Colors.grey.shade400,
          ),
        ),
        child: Text(
          'MAX',
          style: TextStyle(
            color: widget.enabled 
                ? Theme.of(context).primaryColor
                : Colors.grey.shade600,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildUsdValue() {
    if (widget.selectedToken == null || _amountController.text.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final price = widget.selectedToken!.priceUsd ?? 0.0;
    final usdValue = amount * price;
    
    return Text(
      '\$${usdValue.toStringAsFixed(2)}',
      style: widget.style.usdValueTextStyle ?? 
             Theme.of(context).textTheme.bodySmall?.copyWith(
               color: Colors.grey.shade600,
             ),
    );
  }

  Color _getBackgroundColor(BuildContext context) {
    if (!widget.enabled) {
      return widget.style.disabledBackgroundColor ?? Colors.grey.shade100;
    }
    if (_isAmountFocused) {
      return widget.style.focusedBackgroundColor ?? 
             Theme.of(context).primaryColor.withOpacity(0.05);
    }
    return widget.style.backgroundColor ?? Colors.white;
  }

  Color _getBorderColor(BuildContext context) {
    if (!widget.enabled) {
      return widget.style.disabledBorderColor ?? Colors.grey.shade300;
    }
    if (_isAmountFocused) {
      return widget.style.focusedBorderColor ?? 
             Theme.of(context).primaryColor;
    }
    return widget.style.borderColor ?? Colors.grey.shade300;
  }

}

/// 单独的余额Future渲染组件，避免在主组件中持有异步状态
class _BalanceFutureView extends StatelessWidget {
  final Token token;
  final TextStyle? textStyle;

  const _BalanceFutureView({
    Key? key,
    required this.token,
    this.textStyle,
  }) : super(key: key);

  Future<double> _fetchBalance(BuildContext context) async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    try {
      if (token.isNative) {
        return await walletProvider.getNetworkBalance(token.networkId);
      } else {
        // 非原生代币余额暂未接入，后续通过TokenService查询
        return 0.0;
      }
    } catch (_) {
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: _fetchBalance(context),
      builder: (context, snapshot) {
        final balance = snapshot.data ?? 0.0;
        final balanceText = AmountUtils.formatTruncated(balance, decimals: 6);
        return Text(
          '余额: $balanceText ${token.symbol}',
          style: textStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        );
      },
    );
  }
}

/// Token输入字段样式配置
class TokenInputFieldStyle {
  /// 容器内边距
  final EdgeInsets containerPadding;
  
  /// 边框圆角
  final double borderRadius;
  
  /// 边框宽度
  final double borderWidth;
  
  /// 元素间距
  final double elementSpacing;
  
  /// 标签间距
  final double labelSpacing;
  
  /// 背景颜色
  final Color? backgroundColor;
  
  /// 聚焦时背景颜色
  final Color? focusedBackgroundColor;
  
  /// 禁用时背景颜色
  final Color? disabledBackgroundColor;
  
  /// 边框颜色
  final Color? borderColor;
  
  /// 聚焦时边框颜色
  final Color? focusedBorderColor;
  
  /// 禁用时边框颜色
  final Color? disabledBorderColor;
  
  /// 标签文本样式
  final TextStyle? labelStyle;
  
  /// 金额文本样式
  final TextStyle? amountTextStyle;
  
  /// 提示文本样式
  final TextStyle? hintTextStyle;
  
  /// 余额文本样式
  final TextStyle? balanceTextStyle;
  
  /// USD价值文本样式
  final TextStyle? usdValueTextStyle;

  const TokenInputFieldStyle({
    this.containerPadding = const EdgeInsets.all(16),
    this.borderRadius = 16,
    this.borderWidth = 1,
    this.elementSpacing = 12,
    this.labelSpacing = 8,
    this.backgroundColor,
    this.focusedBackgroundColor,
    this.disabledBackgroundColor,
    this.borderColor,
    this.focusedBorderColor,
    this.disabledBorderColor,
    this.labelStyle,
    this.amountTextStyle,
    this.hintTextStyle,
    this.balanceTextStyle,
    this.usdValueTextStyle,
  });
}