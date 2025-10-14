import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../models/network.dart';

class BuyCryptoScreen extends StatefulWidget {
  const BuyCryptoScreen({super.key});

  @override
  State<BuyCryptoScreen> createState() => _BuyCryptoScreenState();
}

class _BuyCryptoScreenState extends State<BuyCryptoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _payAmountController = TextEditingController();
  final _receiveAmountController = TextEditingController();
  
  String _selectedPayCurrency = 'USD';
  String _selectedReceiveCurrency = 'ETH';
  String _selectedPaymentMethod = 'card';
  Network? _selectedNetwork;
  bool _isLoading = false;
  double _exchangeRate = 2500.0; // Mock exchange rate
  double _fee = 2.5; // Mock fee
  
  // 现代色彩方案
  static const Color primaryBackground = Color(0xFF0A0B0D);
  static const Color cardBackground = Color(0xFF1A1D29);
  static const Color accentColor = Color(0xFF6366F1);
  static const Color successColor = Color(0xFF10B981);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color borderColor = Color(0xFF374151);

  // 支持的法币
  final List<Map<String, dynamic>> _fiatCurrencies = [
    {'code': 'USD', 'name': '美元', 'symbol': '\$', 'flag': '🇺🇸'},
    {'code': 'EUR', 'name': '欧元', 'symbol': '€', 'flag': '🇪🇺'},
    {'code': 'CNY', 'name': '人民币', 'symbol': '¥', 'flag': '🇨🇳'},
    {'code': 'JPY', 'name': '日元', 'symbol': '¥', 'flag': '🇯🇵'},
  ];

  // 支持的加密货币
  final List<Map<String, dynamic>> _cryptoCurrencies = [
    {'code': 'ETH', 'name': 'Ethereum', 'icon': '⟠', 'color': Color(0xFF627EEA)},
    {'code': 'BTC', 'name': 'Bitcoin', 'icon': '₿', 'color': Color(0xFFF7931A)},
    {'code': 'USDC', 'name': 'USD Coin', 'icon': '💵', 'color': Color(0xFF2775CA)},
    {'code': 'SOL', 'name': 'Solana', 'icon': '◎', 'color': Color(0xFF9945FF)},
  ];

  // 支付方式
  final List<Map<String, dynamic>> _paymentMethods = [
    {'id': 'card', 'name': '银行卡', 'icon': Icons.credit_card, 'fee': '2.5%'},
    {'id': 'bank', 'name': '银行转账', 'icon': Icons.account_balance, 'fee': '1.0%'},
    {'id': 'apple_pay', 'name': 'Apple Pay', 'icon': Icons.phone_iphone, 'fee': '2.0%'},
    {'id': 'google_pay', 'name': 'Google Pay', 'icon': Icons.payment, 'fee': '2.0%'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      setState(() {
        _selectedNetwork = walletProvider.currentNetwork ?? walletProvider.supportedNetworks.first;
      });
    });
    
    _payAmountController.addListener(_onPayAmountChanged);
  }

  @override
  void dispose() {
    _payAmountController.dispose();
    _receiveAmountController.dispose();
    super.dispose();
  }

  void _onPayAmountChanged() {
    final payAmount = double.tryParse(_payAmountController.text) ?? 0.0;
    final receiveAmount = payAmount / _exchangeRate;
    _receiveAmountController.text = receiveAmount.toStringAsFixed(6);
  }

  void _swapCurrencies() {
    // 这里可以实现货币交换逻辑
    HapticFeedback.lightImpact();
  }

  Future<void> _processPurchase() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // 模拟购买处理
      await Future.delayed(const Duration(seconds: 3));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('购买请求已提交，请等待处理'),
            backgroundColor: successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('购买失败: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBackground,
      appBar: AppBar(
        backgroundColor: primaryBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _BuyCryptoScreenState.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '购买加密货币',
          style: TextStyle(
            color: _BuyCryptoScreenState.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 支付金额部分
              _buildPaymentSection(),
              
              const SizedBox(height: 20),
              
              // 交换按钮
              _buildSwapButton(),
              
              const SizedBox(height: 20),
              
              // 接收金额部分
              _buildReceiveSection(),
              
              const SizedBox(height: 30),
              
              // 支付方式选择
              _buildPaymentMethodSection(),
              
              const SizedBox(height: 30),
              
              // 交易详情
              _buildTransactionDetails(),
              
              const SizedBox(height: 40),
              
              // 购买按钮
              _buildPurchaseButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '我要支付',
            style: TextStyle(
              color: textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _payAmountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    color: textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(color: _BuyCryptoScreenState.textSecondary),
                    border: InputBorder.none,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入支付金额';
                    }
                    if (double.tryParse(value) == null || double.parse(value) <= 0) {
                      return '请输入有效金额';
                    }
                    return null;
                  },
                ),
              ),
              GestureDetector(
                onTap: () => _showCurrencySelector(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _fiatCurrencies.firstWhere((c) => c['code'] == _selectedPayCurrency)['flag'],
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _selectedPayCurrency,
                        style: const TextStyle(
                          color: accentColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, color: accentColor, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwapButton() {
    return Center(
      child: GestureDetector(
        onTap: _swapCurrencies,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.swap_vert,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildReceiveSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '我将得到',
            style: TextStyle(
              color: textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _receiveAmountController,
                  readOnly: true,
                  style: const TextStyle(
                    color: textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(color: _BuyCryptoScreenState.textSecondary),
                    border: InputBorder.none,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _showCurrencySelector(false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getCryptoColor(_selectedReceiveCurrency).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getCryptoColor(_selectedReceiveCurrency).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getCryptoIcon(_selectedReceiveCurrency),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _selectedReceiveCurrency,
                        style: TextStyle(
                          color: _getCryptoColor(_selectedReceiveCurrency),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down, color: _getCryptoColor(_selectedReceiveCurrency), size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '支付方式',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...(_paymentMethods.map((method) => _buildPaymentMethodItem(method)).toList()),
      ],
    );
  }

  Widget _buildPaymentMethodItem(Map<String, dynamic> method) {
    final isSelected = _selectedPaymentMethod == method['id'];
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method['id'];
        });
        HapticFeedback.selectionClick();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.1) : cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              method['icon'],
              color: isSelected ? accentColor : textSecondary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method['name'],
                    style: TextStyle(
                      color: isSelected ? accentColor : textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '手续费: ${method['fee']}',
                    style: const TextStyle(
                      color: textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: accentColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionDetails() {
    final payAmount = double.tryParse(_payAmountController.text) ?? 0.0;
    final feeAmount = payAmount * _fee / 100;
    final totalAmount = payAmount + feeAmount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '交易详情',
            style: TextStyle(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('汇率', '1 $_selectedReceiveCurrency = \$${_exchangeRate.toStringAsFixed(2)}'),
          _buildDetailRow('手续费', '\$${feeAmount.toStringAsFixed(2)}'),
          const Divider(color: borderColor, height: 24),
          _buildDetailRow('总计', '\$${totalAmount.toStringAsFixed(2)}', isTotal: true),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? textPrimary : textSecondary,
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isTotal ? textPrimary : textSecondary,
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _processPurchase,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          disabledBackgroundColor: accentColor.withOpacity(0.5),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                '确认购买',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  void _showCurrencySelector(bool isPayCurrency) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final currencies = isPayCurrency ? _fiatCurrencies : _cryptoCurrencies;
        
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isPayCurrency ? '选择支付货币' : '选择接收货币',
                style: const TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ...currencies.map((currency) => ListTile(
                leading: Text(
                  isPayCurrency ? currency['flag'] : currency['icon'],
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(
                  currency['name'],
                  style: const TextStyle(color: _BuyCryptoScreenState.textPrimary),
                ),
                subtitle: Text(
                  currency['code'],
                  style: const TextStyle(color: _BuyCryptoScreenState.textSecondary),
                ),
                onTap: () {
                  setState(() {
                    if (isPayCurrency) {
                      _selectedPayCurrency = currency['code'];
                    } else {
                      _selectedReceiveCurrency = currency['code'];
                    }
                  });
                  Navigator.pop(context);
                },
              )).toList(),
            ],
          ),
        );
      },
    );
  }

  Color _getCryptoColor(String code) {
    final crypto = _cryptoCurrencies.firstWhere(
      (c) => c['code'] == code,
      orElse: () => {'color': accentColor},
    );
    return crypto['color'];
  }

  String _getCryptoIcon(String code) {
    final crypto = _cryptoCurrencies.firstWhere(
      (c) => c['code'] == code,
      orElse: () => {'icon': '💰'},
    );
    return crypto['icon'];
  }
}