import 'package:flutter/material.dart';

class SecurityTipsWidget extends StatelessWidget {
  final bool showAddressWarning;
  final bool showSlippageWarning;
  final bool showPriceImpactWarning;
  final double priceImpact;
  final double slippage;
  
  const SecurityTipsWidget({
    Key? key,
    this.showAddressWarning = true,
    this.showSlippageWarning = true,
    this.showPriceImpactWarning = true,
    this.priceImpact = 0.0,
    this.slippage = 1.0,
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
          // 标题
          Row(
            children: [
              Icon(
                Icons.security,
                size: 20,
                color: Colors.blue.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                '安全提示',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 安全提示列表
          if (showAddressWarning) ...[
            _buildTipItem(
              icon: Icons.warning_amber,
              title: '地址验证',
              content: '请仔细核对收款地址，确保地址正确无误。错误的地址将导致资金永久丢失。',
              color: Colors.orange,
            ),
            const SizedBox(height: 8),
          ],
          
          if (showSlippageWarning && slippage > 2.0) ...[
            _buildTipItem(
              icon: Icons.trending_up,
              title: '滑点设置',
              content: '当前滑点设置为 $slippage%，较高的滑点可能导致较大的价格差异。',
              color: Colors.orange,
            ),
            const SizedBox(height: 8),
          ],
          
          if (showPriceImpactWarning && priceImpact > 1.0) ...[
            _buildTipItem(
              icon: Icons.price_change,
              title: '价格影响',
              content: '当前价格影响为 ${priceImpact.toStringAsFixed(2)}%，较大的交易可能导致不利的价格变动。',
              color: priceImpact > 3.0 ? Colors.red : Colors.orange,
            ),
            const SizedBox(height: 8),
          ],
          
          _buildTipItem(
            icon: Icons.info_outline,
            title: '交易确认',
            content: '请在钱包中仔细确认交易详情，包括接收数量和手续费。',
            color: Colors.blue,
          ),
          
          const SizedBox(height: 8),
          
          _buildTipItem(
            icon: Icons.timer,
            title: '交易时间',
            content: '区块链交易可能需要几分钟时间确认，请耐心等待。',
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
  
  Widget _buildTipItem({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AddressInputWidget extends StatefulWidget {
  final String? initialAddress;
  final ValueChanged<String> onAddressChanged;
  final bool showValidation;
  
  const AddressInputWidget({
    Key? key,
    this.initialAddress,
    required this.onAddressChanged,
    this.showValidation = true,
  }) : super(key: key);

  @override
  State<AddressInputWidget> createState() => _AddressInputWidgetState();
}

class _AddressInputWidgetState extends State<AddressInputWidget> {
  late TextEditingController _controller;
  bool _isValid = false;
  bool _isValidating = false;
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialAddress ?? '');
    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      _validateAddress(widget.initialAddress!);
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _onAddressChanged(String address) {
    widget.onAddressChanged(address);
    if (widget.showValidation && address.isNotEmpty) {
      _validateAddress(address);
    } else {
      setState(() {
        _isValid = false;
        _isValidating = false;
      });
    }
  }
  
  Future<void> _validateAddress(String address) async {
    setState(() {
      _isValidating = true;
    });
    
    // 模拟地址验证
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 简化的地址验证逻辑
    final isValid = address.length > 20 && address.startsWith('0x');
    
    if (mounted) {
      setState(() {
        _isValid = isValid;
        _isValidating = false;
      });
    }
  }
  
  void _pasteAddress() async {
    // 模拟粘贴功能
    const mockAddress = '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb3';
    _controller.text = mockAddress;
    _onAddressChanged(mockAddress);
  }
  
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
          color: _isValid 
              ? Colors.green.shade300 
              : (_controller.text.isNotEmpty && widget.showValidation
                  ? Colors.red.shade300
                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade300)),
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
                '接收地址 (可选)',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_controller.text.isEmpty)
                GestureDetector(
                  onTap: _pasteAddress,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '粘贴',
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
          
          // 地址输入框
          TextField(
            controller: _controller,
            onChanged: _onAddressChanged,
            decoration: InputDecoration(
              hintText: '输入接收地址 (默认使用当前地址)',
              hintStyle: TextStyle(
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
              suffixIcon: _isValidating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : (_controller.text.isNotEmpty && widget.showValidation
                      ? Icon(
                          _isValid ? Icons.check_circle : Icons.error_outline,
                          color: _isValid ? Colors.green : Colors.red,
                          size: 20,
                        )
                      : null),
            ),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
          ),
          
          // 验证状态提示
          if (_controller.text.isNotEmpty && widget.showValidation) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _isValid ? Icons.check_circle : Icons.error_outline,
                  size: 14,
                  color: _isValid ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  _isValid ? '地址格式正确' : '地址格式无效',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isValid ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}