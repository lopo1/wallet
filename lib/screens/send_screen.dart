import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/wallet_provider.dart';
import '../models/network.dart';
import '../constants/network_constants.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();
  
  Network? _selectedNetwork;
  String? _selectedRpcUrl;
  bool _isLoading = false;
  double _estimatedFee = 0.001; // 动态预估费用
  double _priorityFeeMultiplier = 1.0; // 优先费倍数，默认1倍
  
  // 添加定时器相关变量
  Timer? _refreshTimer;
  Timer? _countdownTimer;
  int _countdown = 5; // 倒计时秒数
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  // 费用状态管理
  ValueNotifier<double>? _feeNotifier;
  ValueNotifier<int>? _countdownNotifier;

  @override
  void initState() {
    super.initState();
    
    // 初始化费用通知器和倒计时通知器
    _feeNotifier = ValueNotifier<double>(_estimatedFee);
    _countdownNotifier = ValueNotifier<int>(5);
    
    // 初始化动画控制器
    _animationController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      setState(() {
        _selectedNetwork = walletProvider.currentNetwork ?? walletProvider.supportedNetworks.first;
        _selectedRpcUrl = _selectedNetwork?.rpcUrl;
      });
      
      // 启动定时器，每5秒刷新一次
      _startRefreshTimer();
    });
  }

  @override
  void dispose() {
    // 清理定时器和动画控制器
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    _animationController.dispose();
    _feeNotifier?.dispose();
    _countdownNotifier?.dispose();
    _addressController.dispose();
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  // 启动刷新定时器
  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    
    // 重置倒计时
    _countdown = 5;
    _countdownNotifier?.value = 5;
    _animationController.reset();
    _animationController.forward();
    
    // 启动倒计时定时器
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _countdown--;
        _countdownNotifier?.value = _countdown;
        
        if (_countdown <= 0) {
          // 倒计时结束，执行刷新
          _performRefresh();
          // 重新开始倒计时
          _countdown = 5;
          _countdownNotifier?.value = 5;
          _animationController.reset();
          _animationController.forward();
        }
      }
    });
  }

  // 执行刷新操作 - 只刷新费用
  void _performRefresh() {
    _updateEstimatedFee();
    print('自动刷新费用');
  }

  // 手动刷新 - 刷新余额和费用
  void _manualRefresh() {
    // 手动刷新时触发余额重新获取
    setState(() {
      // 触发整个页面重新构建以刷新余额
    });
    _updateEstimatedFee();
    // 重新启动定时器
    _startRefreshTimer();
    print('手动刷新余额和费用');
  }

  // 更新预估费用 - 使用真实的RPC调用获取动态费用
  void _updateEstimatedFee() async {
    if (_selectedNetwork != null) {
      try {
        final walletProvider = Provider.of<WalletProvider>(context, listen: false);
        
        // 获取转账金额（如果有输入）
        final amount = double.tryParse(_amountController.text);
        
        // 调用WalletProvider的实时费用估算方法
        final newFee = await walletProvider.getNetworkFeeEstimate(
          _selectedNetwork!.id,
          rpcUrl: _selectedRpcUrl,
          amount: amount,
        );
        
        debugPrint('获取到实时费用: $newFee ${_selectedNetwork!.symbol}');
        
        // 只有费用发生变化时才更新UI，但不触发整个页面重构
        if ((newFee - _estimatedFee).abs() > NetworkConstants.feeUpdateThreshold) { // 使用网络常量阈值避免微小变化
          _estimatedFee = newFee;
          // 只通知费用相关的组件更新，不调用setState避免余额重新加载
          if (mounted) {
            // 使用局部更新而不是全局setState
            _notifyFeeUpdate();
          }
        }
      } catch (e) {
        debugPrint('获取实时费用失败，使用默认值: $e');
        // 如果RPC调用失败，使用默认费用
        double defaultFee;
        switch (_selectedNetwork!.id) {
          case NetworkConstants.ethereumNetworkId:
          case NetworkConstants.bscNetworkId:
          case NetworkConstants.polygonNetworkId:
            defaultFee = NetworkConstants.ethereumBaseFee;
            break;
          case NetworkConstants.solanaNetworkId:
            defaultFee = NetworkConstants.solanaBaseFee;
            break;
          case NetworkConstants.bitcoinNetworkId:
            defaultFee = NetworkConstants.bitcoinBaseFee;
            break;
          default:
            defaultFee = NetworkConstants.ethereumBaseFee;
        }
        
        if ((defaultFee - _estimatedFee).abs() > NetworkConstants.feeUpdateThreshold) {
          _estimatedFee = defaultFee;
          if (mounted) {
            _notifyFeeUpdate();
          }
        }
      }
    }
  }
  
  // 通知费用更新的方法
  void _notifyFeeUpdate() {
    // 创建一个ValueNotifier来管理费用状态，避免全局setState
    if (_feeNotifier != null) {
      _feeNotifier!.value = _estimatedFee;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('发送'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<WalletProvider>(
        builder: (context, walletProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Network Selection
                  _buildNetworkSelector(walletProvider),
                  const SizedBox(height: 16),
                  
                  // RPC Node Selection
                  _buildRpcSelector(walletProvider),
                  const SizedBox(height: 16),
                  
                  // Balance Display
                  _buildBalanceDisplay(walletProvider),
                  const SizedBox(height: 24),
                  
                  // Recipient Address
                  _buildAddressInput(),
                  const SizedBox(height: 24),
                  
                  // Amount Input
                  _buildAmountInput(),
                  const SizedBox(height: 24),
                  
                  // Memo (Optional)
                  _buildMemoInput(),
                  const SizedBox(height: 24),
                  
                  // Priority Fee Selector (Solana only)
                  if (_selectedNetwork?.id == 'solana') ...[
                    _buildPriorityFeeSelector(),
                    const SizedBox(height: 24),
                  ],
                  
                  // Transaction Summary
                  _buildTransactionSummary(),
                  const SizedBox(height: 32),
                  
                  // Send Button
                  _buildSendButton(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNetworkSelector(WalletProvider walletProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '选择网络',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Network>(
              value: _selectedNetwork,
              hint: const Text('选择网络'),
              isExpanded: true,
              items: walletProvider.supportedNetworks.map((network) {
                return DropdownMenuItem<Network>(
                  value: network,
                  child: Row(
                    children: [
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
                      const SizedBox(width: 12),
                      Text(network.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (Network? network) {
                setState(() {
                  _selectedNetwork = network;
                  _selectedRpcUrl = network?.rpcUrl;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceDisplay(WalletProvider walletProvider) {
    if (_selectedNetwork == null) return const SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet,
            color: Colors.blue.shade600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '可用余额',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                FutureBuilder<double>(
                  future: walletProvider.getNetworkBalance(_selectedNetwork!.id, rpcUrl: _selectedRpcUrl),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Row(
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.blue.shade600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '加载中...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      );
                    } else if (snapshot.hasError) {
                      return Text(
                        '获取失败',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red.shade600,
                        ),
                      );
                    } else {
                      final balance = snapshot.data ?? 0.0;
                      return Text(
                        '${balance.toStringAsFixed(6)} ${_selectedNetwork!.symbol}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _manualRefresh, // 使用新的手动刷新方法
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.refresh,
                  size: 16,
                  color: Colors.blue.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  '刷新',
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 倒计时圆形进度条组件
  Widget _buildCountdownIndicator() {
    return ValueListenableBuilder<int>(
      valueListenable: _countdownNotifier!,
      builder: (context, countdown, child) {
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    value: _animation.value,
                    strokeWidth: 3,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      countdown <= 1 ? Colors.orange : Colors.blue.shade600,
                    ),
                  ),
                ),
                Text(
                  '$countdown',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: countdown <= 1 ? Colors.orange : Colors.blue.shade600,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAddressInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '收款地址',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _pasteFromClipboard,
              icon: const Icon(Icons.paste, size: 16),
              label: const Text('粘贴'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _addressController,
          decoration: InputDecoration(
            hintText: '输入或粘贴收款地址',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: _scanQRCode,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '请输入收款地址';
            }
            if (_selectedNetwork != null) {
              // Add address validation logic here
              if (!_isValidAddress(value, _selectedNetwork!)) {
                return '无效的地址格式';
              }
            }
            return null;
          },
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '金额',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: _setMaxAmount,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: const Text('最大'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _amountController,
          decoration: InputDecoration(
            hintText: '0.00',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixText: _selectedNetwork?.symbol ?? '',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '请输入金额';
            }
            final amount = double.tryParse(value);
            if (amount == null || amount <= 0) {
              return '请输入有效金额';
            }
            
            // 余额检查将在发送交易时进行
            
            return null;
          },
          onChanged: (value) {
            setState(() {
              // Update estimated fee based on amount
            });
          },
        ),
      ],
    );
  }

  Widget _buildMemoInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '备注 (可选)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _memoController,
          decoration: InputDecoration(
            hintText: '添加备注信息',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          maxLines: 2,
          maxLength: 100,
        ),
      ],
    );
  }

  Widget _buildPriorityFeeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '优先费',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildPriorityFeeOption('标准', 1.0, '推荐'),
              _buildPriorityFeeOption('快速', 2.0, '2倍费用'),
              _buildPriorityFeeOption('极速', 4.0, '4倍费用'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityFeeOption(String label, double multiplier, String description) {
    final isSelected = _priorityFeeMultiplier == multiplier;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _priorityFeeMultiplier = multiplier;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1).withOpacity(0.1) : Colors.transparent,
            border: Border(
              right: multiplier != 4.0 ? BorderSide(color: Colors.grey.shade300) : BorderSide.none,
            ),
            borderRadius: BorderRadius.horizontal(
              left: multiplier == 1.0 ? const Radius.circular(12) : Radius.zero,
              right: multiplier == 4.0 ? const Radius.circular(12) : Radius.zero,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? const Color(0xFF6366F1) : Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionSummary() {
    if (_selectedNetwork == null) return const SizedBox.shrink();
    
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ValueListenableBuilder<double>(
        valueListenable: _feeNotifier!,
        builder: (context, currentFee, child) {
          final actualFee = _selectedNetwork!.id == 'solana' 
              ? currentFee * _priorityFeeMultiplier 
              : currentFee;
          final total = amount + actualFee;
          
          return Column(
            children: [
              _buildSummaryRow('网络', _selectedNetwork!.name),
              const SizedBox(height: 8),
              _buildSummaryRow('金额', '${amount.toStringAsFixed(6)} ${_selectedNetwork!.symbol}'),
              const SizedBox(height: 8),
              // 预估费用行，带更新指示器和平滑动画
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        _selectedNetwork!.id == 'solana' ? '手续费 (${_priorityFeeMultiplier}x)' : '预估手续费',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 倒计时圆形进度条
                      _buildCountdownIndicator(),
                    ],
                  ),
                  // 使用AnimatedSwitcher实现费用数字的平滑切换
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    child: Text(
                      '${actualFee.toStringAsFixed(6)} ${_selectedNetwork!.symbol}',
                      key: ValueKey(actualFee.toStringAsFixed(6)),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              // 总计行，使用平滑动画
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '总计',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    child: Text(
                      '${total.toStringAsFixed(6)} ${_selectedNetwork!.symbol}',
                      key: ValueKey(total.toStringAsFixed(6)),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 添加费用更新说明
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '费用每5秒自动更新，圆形进度条显示刷新倒计时',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            color: isTotal ? null : Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading || _selectedNetwork == null ? null : _sendTransaction,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                '发送',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null) {
      _addressController.text = clipboardData!.text!;
    }
  }

  void _scanQRCode() {
    // Implement QR code scanning
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR码扫描功能待实现')),
    );
  }

  Future<void> _setMaxAmount() async {
    if (_selectedNetwork == null) return;
    
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final balance = await walletProvider.getNetworkBalance(_selectedNetwork!.id, rpcUrl: _selectedRpcUrl);
    
    // 计算实际手续费，使用ValueNotifier中的当前费用值
    final currentFee = _feeNotifier?.value ?? _estimatedFee;
    final actualFee = _selectedNetwork!.id == 'solana' 
        ? currentFee * _priorityFeeMultiplier 
        : currentFee;
    
    // 减去实际手续费，确保有足够的余额支付手续费
    final maxAmount = balance - actualFee;
    if (maxAmount > 0) {
      _amountController.text = maxAmount.toStringAsFixed(6);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('余额不足以支付手续费'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isValidAddress(String address, Network network) {
    // Implement address validation logic
    switch (network.id) {
      case 'ethereum':
      case 'bsc':
      case 'polygon':
        return RegExp(r'^0x[a-fA-F0-9]{40}$').hasMatch(address);
      case 'bitcoin':
        return RegExp(r'^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$').hasMatch(address);
      case 'solana':
        return RegExp(r'^[1-9A-HJ-NP-Za-km-z]{32,44}$').hasMatch(address);
      default:
        return true;
    }
  }

  Future<String?> _getPasswordFromUser() async {
    final TextEditingController passwordController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('输入钱包密码'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: '请输入钱包密码',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final password = passwordController.text;
                if (password.isNotEmpty) {
                  Navigator.of(context).pop(password);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('密码不能为空'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Show confirmation dialog
      final confirmed = await _showConfirmationDialog();
      if (!confirmed) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      
      // 获取密码
      final password = await _getPasswordFromUser();
      if (password == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // 发送交易
      final txHash = await walletProvider.sendTransaction(
        toAddress: _addressController.text,
        amount: amount,
        networkId: _selectedNetwork!.id,
        memo: _memoController.text.isNotEmpty ? _memoController.text : null,
        rpcUrl: _selectedRpcUrl,
        password: password,
        priorityFeeMultiplier: _selectedNetwork!.id == 'solana' ? _priorityFeeMultiplier : null,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('交易已提交\n交易哈希: ${txHash.substring(0, 10)}...'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('发送失败: $e'),
            backgroundColor: Colors.red,
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

  Future<bool> _showConfirmationDialog() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    // 使用ValueNotifier中的当前费用值
    final currentFee = _feeNotifier?.value ?? _estimatedFee;
    final actualFee = _selectedNetwork!.id == 'solana' 
        ? currentFee * _priorityFeeMultiplier 
        : currentFee;
    final total = amount + actualFee;
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认交易'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('收款地址: ${_addressController.text}'),
            const SizedBox(height: 8),
            Text('金额: ${amount.toStringAsFixed(6)} ${_selectedNetwork!.symbol}'),
            const SizedBox(height: 8),
            Text(
              _selectedNetwork!.id == 'solana' 
                  ? '手续费 (${_priorityFeeMultiplier}x): ${actualFee.toStringAsFixed(6)} ${_selectedNetwork!.symbol}'
                  : '手续费: ${actualFee.toStringAsFixed(6)} ${_selectedNetwork!.symbol}'
            ),
            const SizedBox(height: 8),
            Text(
              '总计: ${total.toStringAsFixed(6)} ${_selectedNetwork!.symbol}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认'),
          ),
        ],
      ),
    ) ?? false;
  }

  Widget _buildRpcSelector(WalletProvider walletProvider) {
    if (_selectedNetwork == null || _selectedNetwork!.rpcUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RPC节点',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedNetwork!.rpcUrls.contains(_selectedRpcUrl) ? _selectedRpcUrl : _selectedNetwork!.rpcUrl,
              hint: const Text('选择RPC节点'),
              isExpanded: true,
              items: _selectedNetwork!.rpcUrls.map((rpcUrl) {
                return DropdownMenuItem<String>(
                  value: rpcUrl,
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud,
                        color: rpcUrl == _selectedNetwork!.rpcUrl 
                            ? Colors.green 
                            : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          rpcUrl,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (rpcUrl == _selectedNetwork!.rpcUrl)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16,
                        ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? rpcUrl) {
                setState(() {
                  _selectedRpcUrl = rpcUrl;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}