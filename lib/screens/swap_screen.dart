import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../providers/wallet_provider.dart';
import '../models/network.dart';

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
  String _fromToken = 'ETH';
  String _toToken = 'USDC';
  double _exchangeRate = 2500.0; // Mock exchange rate
  bool _isSwapping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      if (walletProvider.supportedNetworks.isNotEmpty) {
        setState(() {
          _fromNetwork = walletProvider.supportedNetworks.first;
          _toNetwork = walletProvider.supportedNetworks.first;
        });
      }
    });
    
    _fromAmountController.addListener(_onFromAmountChanged);
  }

  @override
  void dispose() {
    _fromAmountController.dispose();
    _toAmountController.dispose();
    super.dispose();
  }

  void _onFromAmountChanged() {
    final fromAmount = double.tryParse(_fromAmountController.text) ?? 0.0;
    final toAmount = fromAmount * _exchangeRate;
    _toAmountController.text = toAmount.toStringAsFixed(6);
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
      
      // Swap amounts
      final tempAmount = _fromAmountController.text;
      _fromAmountController.text = _toAmountController.text;
      _toAmountController.text = tempAmount;
      
      // Update exchange rate (inverse)
      _exchangeRate = 1 / _exchangeRate;
    });
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
      appBar: AppBar(
        title: const Text('交换'),
        backgroundColor: Colors.transparent,
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
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // From Token Section
                _buildTokenSection(
                  title: '从',
                  network: _fromNetwork,
                  token: _fromToken,
                  controller: _fromAmountController,
                  isFrom: true,
                  walletProvider: walletProvider,
                ),
                const SizedBox(height: 16),
                
                // Swap Button
                _buildSwapButton(),
                const SizedBox(height: 16),
                
                // To Token Section
                _buildTokenSection(
                  title: '到',
                  network: _toNetwork,
                  token: _toToken,
                  controller: _toAmountController,
                  isFrom: false,
                  walletProvider: walletProvider,
                ),
                const SizedBox(height: 32),
                
                // Exchange Rate
                _buildExchangeRate(),
                const SizedBox(height: 24),
                
                // Transaction Details
                _buildTransactionDetails(),
                const SizedBox(height: 32),
                
                // Execute Swap Button
                _buildExecuteButton(),
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
    required String token,
    required TextEditingController controller,
    required bool isFrom,
    required WalletProvider walletProvider,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (isFrom)
                Text(
                  '余额: 1.2345 $token',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Token Selection
              GestureDetector(
                onTap: () => _showTokenSelector(isFrom),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (network != null)
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Color(network.color),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        token,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Amount Input
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.right,
                  enabled: isFrom,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.0',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (isFrom) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    controller.text = '0.5';
                    _onFromAmountChanged();
                  },
                  child: const Text('50%'),
                ),
                TextButton(
                  onPressed: () {
                    controller.text = '1.0';
                    _onFromAmountChanged();
                  },
                  child: const Text('最大'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSwapButton() {
    return Center(
      child: GestureDetector(
        onTap: _swapTokens,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.3),
                blurRadius: 8,
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

  Widget _buildExchangeRate() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.trending_up,
            color: Colors.blue.shade700,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '汇率',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
          const Spacer(),
          Text(
            '1 $_fromToken = ${_exchangeRate.toStringAsFixed(2)} $_toToken',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '交易详情',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('滑点容忍度', '0.5%'),
          _buildDetailRow('最小接收', '${(double.tryParse(_toAmountController.text) ?? 0) * 0.995} $_toToken'),
          _buildDetailRow('网络费用', '~0.003 ETH'),
          _buildDetailRow('路由', 'Uniswap V3'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
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
        onPressed: hasAmount && !_isSwapping ? _executeSwap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
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
                hasAmount ? '交换' : '输入数量',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  void _showTokenSelector(bool isFrom) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final tokens = ['ETH', 'USDC', 'USDT', 'DAI', 'WBTC'];
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '选择代币',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ...tokens.map((token) => ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF6366F1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(token),
                subtitle: Text('$token Token'),
                onTap: () {
                  setState(() {
                    if (isFrom) {
                      _fromToken = token;
                    } else {
                      _toToken = token;
                    }
                  });
                  Navigator.pop(context);
                },
              )),
            ],
          ),
        );
      },
    );
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
}