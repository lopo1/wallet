import 'package:flutter/material.dart';
import '../models/swap_model.dart';

class TransactionDetailsPanel extends StatelessWidget {
  final SwapQuote? quote;
  final bool isLoading;
  final double slippageTolerance;
  final VoidCallback? onSettingsTap;
  
  const TransactionDetailsPanel({
    Key? key,
    this.quote,
    this.isLoading = false,
    this.slippageTolerance = 1.0,
    this.onSettingsTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '交易详情',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              if (onSettingsTap != null)
                GestureDetector(
                  onTap: onSettingsTap,
                  child: Icon(
                    Icons.settings,
                    size: 20,
                    color: theme.primaryColor,
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 详情内容
          if (isLoading) ...[
            _buildLoadingRow(),
            const SizedBox(height: 12),
            _buildLoadingRow(),
            const SizedBox(height: 12),
            _buildLoadingRow(),
          ] else if (quote != null) ...[
            // 预期接收
            _buildDetailRow(
              '预期接收',
              '${quote!.toAmount.toStringAsFixed(6)} ${quote!.toToken}',
              valueColor: Colors.green.shade700,
              isImportant: true,
            ),
            
            const SizedBox(height: 12),
            
            // 最小接收
            _buildDetailRow(
              '最小接收',
              '${quote!.minimumToAmount.toStringAsFixed(6)} ${quote!.toToken}',
              valueColor: Colors.orange.shade700,
              hasTooltip: true,
              tooltipText: '考虑滑点后的最小接收数量',
            ),
            
            const SizedBox(height: 12),
            
            // 价格影响
            _buildDetailRow(
              '价格影响',
              '${quote!.priceImpact.toStringAsFixed(2)}%',
              valueColor: getPriceImpactColor(getPriceImpactLevel(quote!.priceImpact)),
              hasTooltip: true,
              tooltipText: '您的交易对市场价格的影响程度',
            ),
            
            const SizedBox(height: 12),
            
            // 网络费用
            _buildDetailRow(
              '网络费用 (预估)',
              '${quote!.estimatedGas.toStringAsFixed(6)} ETH',
              hasTooltip: true,
              tooltipText: '执行此交易所需的网络费用',
            ),
            
            const SizedBox(height: 12),
            
            // 滑点设置
            _buildDetailRow(
              '滑点容忍度',
              '${quote!.slippage.toStringAsFixed(2)}%',
              valueColor: quote!.slippage <= 1.0 ? Colors.green : Colors.orange,
              hasTooltip: true,
              tooltipText: '价格变化的最大容忍度',
            ),
            
            const SizedBox(height: 12),
            
            // 路由信息
            _buildDetailRow(
              '路由',
              quote!.route,
              hasTooltip: true,
              tooltipText: '交易将通过此路由执行',
            ),
            
            const SizedBox(height: 12),
            
            // 到期时间
            _buildDetailRow(
              '报价有效期',
              _formatExpiryTime(quote!.expiry),
              valueColor: quote!.isExpired ? Colors.red : Colors.grey.shade700,
              hasTooltip: true,
              tooltipText: '此报价的有效时间',
            ),
          ] else ...[
            // 空状态
            Center(
              child: Text(
                '输入兑换金额查看详情',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    bool isImportant = false,
    bool hasTooltip = false,
    String? tooltipText,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontWeight: isImportant ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            if (hasTooltip && tooltipText != null) ...[
              const SizedBox(width: 4),
              Tooltip(
                message: tooltipText,
                child: Icon(
                  Icons.info_outline,
                  size: 14,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isImportant ? FontWeight.w600 : FontWeight.w500,
            color: valueColor ?? (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ],
    );
  }
  
  Widget _buildLoadingRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 120,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        Container(
          width: 80,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }
  
  String _formatExpiryTime(DateTime expiry) {
    final now = DateTime.now();
    final difference = expiry.difference(now);
    
    if (difference.isNegative) {
      return '已过期';
    }
    
    if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟后';
    } else {
      return '${difference.inSeconds}秒后';
    }
  }
}