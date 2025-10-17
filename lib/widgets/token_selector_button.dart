import 'package:flutter/material.dart';
import '../models/token_model.dart';
import 'universal_token_selector.dart';
import 'overlaid_token_icon.dart';

/// Token选择按钮组件
/// 用于在输入字段中显示当前选中的token并提供选择功能
class TokenSelectorButton extends StatelessWidget {
  /// 当前选中的token
  final Token? selectedToken;
  
  /// token选择回调
  final ValueChanged<Token?> onTokenSelected;
  
  /// 选择器配置
  final TokenSelectorConfig config;
  
  /// 按钮样式配置
  final TokenSelectorButtonStyle style;
  
  /// 是否启用
  final bool enabled;
  
  /// 占位符文本
  final String placeholder;

  const TokenSelectorButton({
    Key? key,
    this.selectedToken,
    required this.onTokenSelected,
    this.config = const TokenSelectorConfig(),
    this.style = const TokenSelectorButtonStyle(),
    this.enabled = true,
    this.placeholder = '选择代币',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? () => _onTap(context) : null,
      child: Container(
        padding: style.padding,
        decoration: BoxDecoration(
          color: _getBackgroundColor(context),
          borderRadius: BorderRadius.circular(style.borderRadius),
          border: Border.all(
            color: _getBorderColor(context),
            width: style.borderWidth,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Token图标
            if (selectedToken != null) ...[
              _buildTokenIcon(),
              SizedBox(width: style.spacing),
            ],
            
            // Token符号或占位符
            Text(
              selectedToken?.symbol ?? placeholder,
              style: _getTextStyle(context),
            ),
            
            SizedBox(width: style.spacing),
            
            // 下拉箭头
            Icon(
              Icons.arrow_drop_down,
              size: style.iconSize,
              color: _getIconColor(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenIcon() {
    if (selectedToken == null) return const SizedBox.shrink();

    // 构建叠加链标记的代币图标
    final asset = {
      'id': selectedToken!.id,
      'symbol': selectedToken!.symbol,
      'logoUrl': selectedToken!.iconUrl,
      'networkId': selectedToken!.networkId,
      'color': selectedToken!.color ?? Colors.blue,
      'icon': selectedToken!.icon ?? Icons.token,
    };

    return TokenWithNetworkIcon(
      asset: asset,
      networkId: selectedToken!.networkId,
      size: style.iconSize,
      chainIconRatio: 0.45,
    );
  }

  Widget _buildFallbackIcon() {
    return Center(
      child: Text(
        selectedToken?.symbol.substring(0, 1) ?? '',
        style: TextStyle(
          color: Colors.white,
          fontSize: style.iconSize * 0.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getBackgroundColor(BuildContext context) {
    if (!enabled) return style.disabledBackgroundColor ?? Colors.grey.shade300;
    return style.backgroundColor ?? 
           Theme.of(context).primaryColor.withOpacity(0.1);
  }

  Color _getBorderColor(BuildContext context) {
    if (!enabled) return style.disabledBorderColor ?? Colors.grey.shade400;
    return style.borderColor ?? 
           Theme.of(context).primaryColor.withOpacity(0.2);
  }

  TextStyle _getTextStyle(BuildContext context) {
    final baseStyle = style.textStyle ?? 
                     Theme.of(context).textTheme.bodyLarge ?? 
                     const TextStyle();
    
    if (!enabled) {
      return baseStyle.copyWith(
        color: style.disabledTextColor ?? Colors.grey.shade600,
      );
    }
    
    return baseStyle.copyWith(
      fontWeight: FontWeight.w600,
    );
  }

  Color _getIconColor(BuildContext context) {
    if (!enabled) return style.disabledIconColor ?? Colors.grey.shade600;
    return style.iconColor ?? 
           Theme.of(context).textTheme.bodyLarge?.color ?? 
           Colors.black;
  }

  void _onTap(BuildContext context) async {
    final result = await UniversalTokenSelector.show(
      context: context,
      config: config.copyWith(
        preselectedToken: selectedToken,
      ),
    );
    
    if (result != null && !result.cancelled) {
      onTokenSelected(result.selectedToken);
    }
  }
}

/// Token选择按钮样式配置
class TokenSelectorButtonStyle {
  /// 内边距
  final EdgeInsets padding;
  
  /// 边框圆角
  final double borderRadius;
  
  /// 边框宽度
  final double borderWidth;
  
  /// 图标大小
  final double iconSize;
  
  /// 元素间距
  final double spacing;
  
  /// 背景颜色
  final Color? backgroundColor;
  
  /// 边框颜色
  final Color? borderColor;
  
  /// 文本样式
  final TextStyle? textStyle;
  
  /// 图标颜色
  final Color? iconColor;
  
  /// 禁用状态背景颜色
  final Color? disabledBackgroundColor;
  
  /// 禁用状态边框颜色
  final Color? disabledBorderColor;
  
  /// 禁用状态文本颜色
  final Color? disabledTextColor;
  
  /// 禁用状态图标颜色
  final Color? disabledIconColor;

  const TokenSelectorButtonStyle({
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.borderRadius = 12,
    this.borderWidth = 1,
    this.iconSize = 24,
    this.spacing = 8,
    this.backgroundColor,
    this.borderColor,
    this.textStyle,
    this.iconColor,
    this.disabledBackgroundColor,
    this.disabledBorderColor,
    this.disabledTextColor,
    this.disabledIconColor,
  });

  TokenSelectorButtonStyle copyWith({
    EdgeInsets? padding,
    double? borderRadius,
    double? borderWidth,
    double? iconSize,
    double? spacing,
    Color? backgroundColor,
    Color? borderColor,
    TextStyle? textStyle,
    Color? iconColor,
    Color? disabledBackgroundColor,
    Color? disabledBorderColor,
    Color? disabledTextColor,
    Color? disabledIconColor,
  }) {
    return TokenSelectorButtonStyle(
      padding: padding ?? this.padding,
      borderRadius: borderRadius ?? this.borderRadius,
      borderWidth: borderWidth ?? this.borderWidth,
      iconSize: iconSize ?? this.iconSize,
      spacing: spacing ?? this.spacing,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      textStyle: textStyle ?? this.textStyle,
      iconColor: iconColor ?? this.iconColor,
      disabledBackgroundColor: disabledBackgroundColor ?? this.disabledBackgroundColor,
      disabledBorderColor: disabledBorderColor ?? this.disabledBorderColor,
      disabledTextColor: disabledTextColor ?? this.disabledTextColor,
      disabledIconColor: disabledIconColor ?? this.disabledIconColor,
    );
  }
}

/// TokenSelectorConfig扩展方法
extension TokenSelectorConfigExtension on TokenSelectorConfig {
  TokenSelectorConfig copyWith({
    TokenSelectorMode? mode,
    String? title,
    bool? showSearch,
    bool? showNetworkFilter,
    bool? showBalance,
    bool? showUsdValue,
    bool? onlyShowWithBalance,
    Token? preselectedToken,
    List<String>? excludeTokens,
    List<Token>? customTokens,
    bool? multiSelect,
    int? maxSelection,
  }) {
    return TokenSelectorConfig(
      mode: mode ?? this.mode,
      title: title ?? this.title,
      showSearch: showSearch ?? this.showSearch,
      showNetworkFilter: showNetworkFilter ?? this.showNetworkFilter,
      showBalance: showBalance ?? this.showBalance,
      showUsdValue: showUsdValue ?? this.showUsdValue,
      onlyShowWithBalance: onlyShowWithBalance ?? this.onlyShowWithBalance,
      preselectedToken: preselectedToken ?? this.preselectedToken,
      excludeTokens: excludeTokens ?? this.excludeTokens,
      customTokens: customTokens ?? this.customTokens,
      multiSelect: multiSelect ?? this.multiSelect,
      maxSelection: maxSelection ?? this.maxSelection,
    );
  }
}