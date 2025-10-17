import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/token_model.dart';

class TokenInputField extends StatefulWidget {
  final Token? token;
  final double amount;
  final double balance;
  final String label;
  final bool isInput;
  final bool showMaxButton;
  final bool showPercentageButtons;
  final ValueChanged<double> onAmountChanged;
  final VoidCallback onTokenTap;
  final VoidCallback? onMaxPressed;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool isLoading;
  final String? errorText;
  final String? hintText;
  final bool readOnly;
  final int decimals;
  
  const TokenInputField({
    Key? key,
    this.token,
    required this.amount,
    required this.balance,
    required this.label,
    this.isInput = true,
    this.showMaxButton = true,
    this.showPercentageButtons = false,
    required this.onAmountChanged,
    required this.onTokenTap,
    this.onMaxPressed,
    this.backgroundColor,
    this.borderColor,
    this.isLoading = false,
    this.errorText,
    this.hintText,
    this.readOnly = false,
    this.decimals = 18,
  }) : super(key: key);

  @override
  State<TokenInputField> createState() => _TokenInputFieldState();
}

class _TokenInputFieldState extends State<TokenInputField> {
  late TextEditingController _controller;
  bool _isEditing = false;
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: _formatAmount(widget.amount)
    );
  }
  
  @override
  void didUpdateWidget(TokenInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 只在用户没有编辑时更新控制器
    if (!_isEditing && _controller.text != _formatAmount(widget.amount)) {
      _controller.text = _formatAmount(widget.amount);
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  String _formatAmount(double amount) {
    if (amount == 0) return '';
    return amount.toStringAsFixed(widget.decimals > 6 ? 6 : widget.decimals);
  }
  
  void _onAmountChanged(String value) {
    _isEditing = true;
    
    if (value.isEmpty) {
      widget.onAmountChanged(0.0);
      return;
    }
    
    try {
      final amount = double.parse(value);
      widget.onAmountChanged(amount);
    } catch (e) {
      // 忽略无效输入
    }
    
    // 延迟重置编辑状态，避免快速输入时的闪烁
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isEditing = false;
        });
      }
    });
  }
  
  void _onMaxPressed() {
    if (widget.onMaxPressed != null) {
      widget.onMaxPressed!();
    } else {
      widget.onAmountChanged(widget.balance);
    }
  }
  
  void _onPercentagePressed(double percentage) {
    final amount = widget.balance * percentage / 100;
    widget.onAmountChanged(amount);
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final backgroundColor = widget.backgroundColor ?? 
      (isDark ? Colors.grey.shade900 : Colors.grey.shade50);
    
    final borderColor = widget.borderColor ?? 
      (widget.errorText != null ? Colors.red : 
       isDark ? Colors.grey.shade800 : Colors.grey.shade300);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标签行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (widget.showMaxButton && widget.balance > 0)
                GestureDetector(
                  onTap: _onMaxPressed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'MAX',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 输入行
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 代币选择按钮
              GestureDetector(
                onTap: widget.onTokenTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.primaryColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.token != null) ...[
                        // 代币图标
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: widget.token!.color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              widget.token!.symbol.substring(0, 1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.token?.symbol ?? '选择代币',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 20,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // 金额输入
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextField(
                      controller: _controller,
                      onChanged: _onAmountChanged,
                      readOnly: widget.readOnly || widget.isLoading,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^[0-9]*\.?[0-9]*$')),
                      ],
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.hintText ?? '0.0',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        errorText: widget.errorText,
                      ),
                    ),
                    if (widget.token != null && widget.amount > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '~\$${(widget.amount * 1.0).toStringAsFixed(2)}', // 这里应该使用实际价格
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          
          // 余额显示
          if (widget.balance > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '余额: ${widget.balance.toStringAsFixed(4)} ${widget.token?.symbol ?? ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                  ),
                ),
                if (widget.showPercentageButtons && widget.isInput)
                  Row(
                    children: [
                      _buildPercentageButton(25),
                      const SizedBox(width: 4),
                      _buildPercentageButton(50),
                      const SizedBox(width: 4),
                      _buildPercentageButton(75),
                    ],
                  ),
              ],
            ),
          ],
          
          // 错误提示
          if (widget.errorText != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 16,
                  color: Colors.red,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.errorText!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildPercentageButton(double percentage) {
    return GestureDetector(
      onTap: () => _onPercentagePressed(percentage),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '${percentage.toInt()}%',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}