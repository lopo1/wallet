import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../models/token_model.dart';
import '../widgets/enhanced_token_input_field.dart';
import '../widgets/universal_token_selector.dart';
import '../utils/amount_utils.dart';

class EnhancedSendScreen extends StatefulWidget {
  const EnhancedSendScreen({super.key});

  @override
  State<EnhancedSendScreen> createState() => _EnhancedSendScreenState();
}

class _EnhancedSendScreenState extends State<EnhancedSendScreen> {
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  
  Token? _selectedToken;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _onTokenChanged(Token? token) {
    setState(() {
      _selectedToken = token;
      _amountController.clear();
      _errorMessage = '';
    });
  }

  void _onAmountChanged(String amount) {
    setState(() {
      _errorMessage = '';
    });
  }

  void _onMaxPressed() {
    if (_selectedToken == null) return;
    
    // TODO: 实现获取最大可发送金额的逻辑
    // 需要考虑gas费用
    final maxAmount = 0.0; // 临时值
    _amountController.text = maxAmount.toString();
  }

  Future<void> _sendTransaction() async {
    if (_selectedToken == null) {
      setState(() {
        _errorMessage = '请选择要发送的代币';
      });
      return;
    }

    final recipient = _recipientController.text.trim();
    if (recipient.isEmpty) {
      setState(() {
        _errorMessage = '请输入收款地址';
      });
      return;
    }

    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      setState(() {
        _errorMessage = '请输入发送数量';
      });
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() {
        _errorMessage = '请输入有效的发送数量';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      
      // TODO: 实现实际的发送交易逻辑
      await Future.delayed(const Duration(seconds: 2)); // 模拟网络请求
      
      if (!mounted) return;

      // 显示成功对话框
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text(
            '交易已提交',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '代币: ${_selectedToken!.symbol}',
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                '数量: $amount ${_selectedToken!.symbol}',
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                '收款地址: ${recipient.substring(0, 8)}...${recipient.substring(recipient.length - 8)}',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // 返回上一页
              },
              child: const Text('确定'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = '发送失败: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _scanQRCode() {
    // TODO: 实现二维码扫描功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('二维码扫描功能待实现')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '发送代币',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 代币选择和数量输入
            const Text(
              '选择代币和数量',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            EnhancedTokenInputField(
              label: '发送',
              selectedToken: _selectedToken,
              amount: _amountController.text,
              onTokenChanged: _onTokenChanged,
              onAmountChanged: _onAmountChanged,
              onMaxPressed: _onMaxPressed,
              selectorConfig: TokenSelectorConfig(
                title: '选择要发送的代币',
                showBalance: true,
                showSearch: true,
                mode: TokenSelectorMode.modal,
              ),
              style: const TokenInputFieldStyle(
                labelStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: Color(0xFF1A1A2E),
                borderColor: Colors.white12,
                amountTextStyle: TextStyle(color: Colors.white),
                hintTextStyle: TextStyle(color: Colors.white54),
              ),
            ),
            const SizedBox(height: 24),

            // 收款地址
            const Text(
              '收款地址',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _recipientController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: '请输入收款地址',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                          onTap: _scanQRCode,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.qr_code_scanner,
                                color: Color(0xFF6C5CE7),
                                size: 20,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '扫码',
                                style: TextStyle(
                                  color: Color(0xFF6C5CE7),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 备注（可选）
            const Text(
              '备注（可选）',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: TextField(
                controller: _memoController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: '输入备注信息（可选）',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 错误信息
            if (_errorMessage.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),

            // 发送按钮
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  disabledBackgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        '发送',
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
      ),
    );
  }
}