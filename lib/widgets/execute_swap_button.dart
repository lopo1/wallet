import 'package:flutter/material.dart';
import '../models/swap_model.dart';

class ExecuteSwapButton extends StatelessWidget {
  final bool canExecute;
  final TransactionStatus status;
  final bool isLoading;
  final String? errorText;
  final VoidCallback onPressed;
  final double fromAmount;
  final double toAmount;
  final String? fromToken;
  final String? toToken;
  
  const ExecuteSwapButton({
    Key? key,
    required this.canExecute,
    required this.status,
    this.isLoading = false,
    this.errorText,
    required this.onPressed,
    this.fromAmount = 0.0,
    this.toAmount = 0.0,
    this.fromToken,
    this.toToken,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      children: [
        // 状态指示器
        if (status != TransactionStatus.idle) ...[
          _buildStatusIndicator(context),
          const SizedBox(height: 16),
        ],
        
        // 错误提示
        if (errorText != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200, width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorText!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // 执行按钮
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canExecute && !isLoading ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _getButtonColor(theme),
              foregroundColor: _getButtonTextColor(theme),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: _getElevation(),
              disabledBackgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
              disabledForegroundColor: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
            ),
            child: _buildButtonContent(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatusIndicator(BuildContext context) {
    final theme = Theme.of(context);
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (status) {
      case TransactionStatus.loading:
        statusColor = Colors.blue;
        statusIcon = Icons.sync;
        statusText = '正在准备交易...';
        break;
      case TransactionStatus.submitted:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = '交易已提交，等待确认...';
        break;
      case TransactionStatus.confirmed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = '交易已成功确认！';
        break;
      case TransactionStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error_outline;
        statusText = '交易失败，请重试';
        break;
      case TransactionStatus.cancelled:
        statusColor = Colors.grey;
        statusIcon = Icons.cancel;
        statusText = '交易已取消';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info_outline;
        statusText = '';
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (status == TransactionStatus.loading) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildButtonContent() {
    if (isLoading) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          SizedBox(width: 12),
          Text(
            '处理中...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }
    
    if (status == TransactionStatus.confirmed) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 20),
          SizedBox(width: 8),
          Text(
            '交易成功',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }
    
    if (!canExecute) {
      return Text(
        _getDisabledButtonText(),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    
    return Column(
      children: [
        Text(
          '兑换',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (fromAmount > 0 && toAmount > 0 && fromToken != null && toToken != null) ...[
          const SizedBox(height: 4),
          Text(
            '$fromAmount $fromToken → $toAmount $toToken',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
  
  Color _getButtonColor(ThemeData theme) {
    switch (status) {
      case TransactionStatus.failed:
      case TransactionStatus.cancelled:
        return Colors.red;
      case TransactionStatus.confirmed:
        return Colors.green;
      default:
        return theme.primaryColor;
    }
  }
  
  Color _getButtonTextColor(ThemeData theme) {
    switch (status) {
      case TransactionStatus.failed:
      case TransactionStatus.cancelled:
      case TransactionStatus.confirmed:
        return Colors.white;
      default:
        return theme.primaryColorBrightness == Brightness.dark 
            ? Colors.white 
            : Colors.white;
    }
  }
  
  double _getElevation() {
    return canExecute && !isLoading ? 2 : 0;
  }
  
  String _getDisabledButtonText() {
    if (fromAmount <= 0) {
      return '输入兑换数量';
    }
    if (fromToken == null || toToken == null) {
      return '选择代币';
    }
    if (fromToken == toToken) {
      return '选择不同代币';
    }
    if (fromAmount > 0 && fromAmount > (double.tryParse('1000000') ?? double.infinity)) {
      return '余额不足';
    }
    return '准备兑换';
  }
}