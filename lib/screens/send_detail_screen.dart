import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:decimal/decimal.dart';
import '../models/network.dart';
import '../providers/wallet_provider.dart';
import '../utils/amount_utils.dart';
import 'qr_scanner_screen.dart';

class SendDetailScreen extends StatefulWidget {
  const SendDetailScreen({super.key});

  @override
  State<SendDetailScreen> createState() => _SendDetailScreenState();
}

class _SendDetailScreenState extends State<SendDetailScreen>
    with TickerProviderStateMixin {
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  Timer? _gasRefreshTimer;
  Timer? _countdownTimer;
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;

  Network? network;
  String? address;
  double balance = 2.22;
  double gasFee = 0.00000496;
  String errorMessage = '';
  List<Map<String, String>> contacts = [];
  List<Map<String, String>> filteredContacts = [];
  bool isLoading = false;
  bool _gasFeeLocked = false; // Gas 费用锁定标志

  int _gasRefreshCountdown = 10; // 倒计时秒数

  @override
  void initState() {
    super.initState();

    // 初始化动画控制器
    _progressAnimationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.linear,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          network = args['network'] as Network?;
          address = args['address'] as String?;
        });
        _loadInitialData();
      }
    });
  }

  @override
  void dispose() {
    _gasRefreshTimer?.cancel();
    _countdownTimer?.cancel();
    _progressAnimationController.dispose();
    _recipientController.dispose();
    _amountController.dispose();
    _memoController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (network == null || address == null) return;

    await Future.wait([
      _loadRealBalance(),
      _loadGasFee(),
      _loadContacts(),
    ]);

    // 启动Gas费用自动刷新
    _startGasRefreshTimer();
  }

  Future<void> _loadRealBalance() async {
    if (network == null || address == null) return;

    try {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);

      // 使用统一的网络余额获取方法
      final realBalance = await walletProvider.getNetworkBalance(network!.id);

      debugPrint('=== 加载余额 ===');
      debugPrint('网络: ${network!.id}');
      debugPrint('地址: $address');
      debugPrint('获取到的余额: $realBalance');

      setState(() {
        balance = realBalance;
      });

      debugPrint('设置后的余额: $balance');
    } catch (e) {
      debugPrint('获取余额失败: $e');
      // 保持默认余额值
    }
  }

  Future<void> _loadGasFee() async {
    if (network == null || address == null) return;

    try {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);

      // 获取当前输入的金额
      final amount = _amountController.text.isNotEmpty
          ? double.tryParse(_amountController.text) ?? 0.001
          : 0.001;

      // 使用WalletProvider的费用估算方法
      final feeEstimate = await walletProvider
          .getNetworkFeeEstimate(network!.id, amount: amount);

      setState(() {
        gasFee = feeEstimate;
      });
    } catch (e) {
      debugPrint('获取Gas费用失败: $e');
      setState(() {
        gasFee = 0.000005; // 默认费用
      });
    }
  }

  void _startGasRefreshTimer() {
    _gasRefreshTimer?.cancel();
    _countdownTimer?.cancel();

    // 重置倒计时和动画
    _gasRefreshCountdown = 10;
    _progressAnimationController.reset();
    _progressAnimationController.forward();

    // 启动倒计时定时器，每秒更新一次
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_gasFeeLocked) {
        setState(() {
          _gasRefreshCountdown--;
        });

        if (_gasRefreshCountdown <= 0) {
          // 倒计时结束，刷新Gas费用
          _loadGasFee();
          _gasRefreshCountdown = 10; // 重置倒计时
          _progressAnimationController.reset();
          _progressAnimationController.forward();
        }
      }
    });

    // 主刷新定时器，每10秒执行一次
    _gasRefreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!_gasFeeLocked) {
        _loadGasFee();
        _gasRefreshCountdown = 10; // 重置倒计时
        _progressAnimationController.reset();
        _progressAnimationController.forward();
      }
    });
  }

  Future<void> _loadContacts() async {
    // 模拟联系人数据
    setState(() {
      contacts = [
        {'name': '朋友A', 'address': '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa'},
        {'name': '朋友B', 'address': '3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy'},
        {
          'name': '交易所',
          'address': 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh'
        },
      ];
      filteredContacts = contacts;
    });
  }

  void _filterContacts(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredContacts = contacts;
      } else {
        filteredContacts = contacts.where((contact) {
          return contact['name']!.toLowerCase().contains(query.toLowerCase()) ||
              contact['address']!.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  bool _validateInput() {
    if (_recipientController.text.trim().isEmpty) {
      setState(() {
        errorMessage = '请输入收款地址';
      });
      return false;
    }

    if (_amountController.text.trim().isEmpty) {
      setState(() {
        errorMessage = '请输入发送数量';
      });
      return false;
    }

    // 使用 Decimal 进行精确计算
    final amountDecimal = AmountUtils.fromString(_amountController.text);

    if (AmountUtils.lessThanOrEqual(amountDecimal, Decimal.zero)) {
      setState(() {
        errorMessage = '请输入有效的发送数量';
      });
      return false;
    }

    // 检查余额是否足够（包含手续费）
    // 使用 Decimal 避免浮点数精度问题
    final balanceDecimal = AmountUtils.fromDouble(balance);
    final gasFeeDecimal = AmountUtils.fromDouble(gasFee);
    final totalRequired = AmountUtils.add(amountDecimal, gasFeeDecimal);

    // 调试信息
    debugPrint('=== 余额验证 ===');
    debugPrint('输入金额: ${AmountUtils.format(amountDecimal)}');
    debugPrint('Gas费用: ${AmountUtils.format(gasFeeDecimal)}');
    debugPrint('需要总额: ${AmountUtils.format(totalRequired)}');
    debugPrint('当前余额: ${AmountUtils.format(balanceDecimal)}');
    debugPrint('当前余额: $balance');
    debugPrint(
        '余额充足: ${AmountUtils.lessThanOrEqual(totalRequired, balanceDecimal)}');

    if (AmountUtils.greaterThan(totalRequired, balanceDecimal)) {
      setState(() {
        errorMessage =
            '余额不足（包含手续费）\n需要: ${AmountUtils.format(totalRequired)}\n可用: ${AmountUtils.format(balanceDecimal)}';
      });
      return false;
    }

    setState(() {
      errorMessage = '';
    });
    return true;
  }

  Future<void> _scanQRCode() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const QRScannerScreen(isForAddress: true),
      ),
    );

    if (result != null) {
      setState(() {
        _recipientController.text = result;
      });
    }
  }

  void _selectContact(Map<String, String> contact) {
    setState(() {
      _recipientController.text = contact['address']!;
    });
    Navigator.pop(context);
  }

  void _showContactSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 标题
            const Text(
              '选择联系人',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // 搜索框
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '搜索联系人',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF2A2A3E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _filterContacts,
            ),
            const SizedBox(height: 16),

            // 联系人列表
            Expanded(
              child: ListView.builder(
                itemCount: filteredContacts.length,
                itemBuilder: (context, index) {
                  final contact = filteredContacts[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF6C5CE7),
                      child: Text(
                        contact['name']![0],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      contact['name']!,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      '${contact['address']!.substring(0, 8)}...${contact['address']!.substring(contact['address']!.length - 8)}',
                      style: const TextStyle(color: Colors.white54),
                    ),
                    onTap: () => _selectContact(contact),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendTransaction() async {
    if (!_validateInput()) return;

    // 显示密码确认对话框
    final password = await _showPasswordDialog();
    if (password == null) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      final currentWallet = walletProvider.currentWallet;

      if (currentWallet == null) {
        throw Exception('未找到当前钱包');
      }

      // 验证密码
      final isPasswordValid = await walletProvider.verifyPasswordForWallet(
        currentWallet.id,
        password,
      );

      if (!isPasswordValid) {
        throw Exception('密码错误');
      }

      // 获取金额
      final amount = double.parse(_amountController.text);
      final recipient = _recipientController.text.trim();
      final memo = _memoController.text.trim();

      // 调用钱包提供者的发送交易方法
      final txHash = await walletProvider.sendTransaction(
        networkId: network!.id,
        toAddress: recipient,
        amount: amount,
        password: password,
        memo: memo.isNotEmpty ? memo : null,
      );

      if (!mounted) return;

      Navigator.pop(context, true);

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
              const Text(
                '交易哈希:',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              SelectableText(
                txHash,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '金额: $amount ${network!.symbol}',
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
                // 可以在这里添加查看区块浏览器的功能
              },
              child: const Text('查看详情'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        errorMessage = '发送失败: $e';
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('发送失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<String?> _showPasswordDialog() async {
    final passwordController = TextEditingController();
    bool obscureText = true;
    String? errorText;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text(
            '确认交易',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '请输入钱包密码以确认交易',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: obscureText,
                style: const TextStyle(color: Colors.white),
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '输入密码（至少6位）',
                  hintStyle: const TextStyle(color: Colors.white54),
                  errorText: errorText,
                  errorStyle: const TextStyle(color: Colors.red),
                  filled: true,
                  fillColor: const Color(0xFF2A2A3E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white54,
                    ),
                    onPressed: () {
                      setState(() {
                        obscureText = !obscureText;
                      });
                    },
                  ),
                ),
                onChanged: (value) {
                  // 清除错误提示
                  if (errorText != null) {
                    setState(() {
                      errorText = null;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final password = passwordController.text;

                // 验证密码长度
                if (password.isEmpty) {
                  setState(() {
                    errorText = '请输入密码';
                  });
                  return;
                }

                if (password.length < 6) {
                  setState(() {
                    errorText = '密码至少需要6位';
                  });
                  return;
                }

                // 密码验证通过，关闭对话框
                Navigator.pop(context, password);
              },
              child: const Text('确认'),
            ),
          ],
        ),
      ),
    );
  }

  void _setMaxAmount() {
    // 使用 Decimal 进行精确计算，避免浮点数精度问题
    final balanceDecimal = AmountUtils.fromDouble(balance);
    final gasFeeDecimal = AmountUtils.fromDouble(gasFee);
    final maxAmountDecimal =
        AmountUtils.calculateMaxSendAmount(balanceDecimal, gasFeeDecimal);

    // 调试信息
    debugPrint('=== 点击全部按钮 ===');
    debugPrint('当前余额: ${AmountUtils.format(balanceDecimal)} (原始: $balance)');
    debugPrint('Gas费用: ${AmountUtils.format(gasFeeDecimal)} (原始: $gasFee)');
    debugPrint('最大金额: ${AmountUtils.format(maxAmountDecimal)}');

    if (AmountUtils.isPositive(maxAmountDecimal)) {
      setState(() {
        // 使用 Decimal 计算，不需要额外的安全边界
        _amountController.text = AmountUtils.format(maxAmountDecimal);
        // 锁定 Gas 费用，防止自动刷新导致余额不足
        _gasFeeLocked = true;
        // 清除之前的错误信息
        errorMessage = '';
      });

      // 验证计算是否正确
      final totalRequired = AmountUtils.add(maxAmountDecimal, gasFeeDecimal);
      debugPrint('验证: 最大金额 + Gas = ${AmountUtils.format(totalRequired)}');
      debugPrint(
          '验证: 是否 <= 余额? ${AmountUtils.lessThanOrEqual(totalRequired, balanceDecimal)}');
      debugPrint('Gas 费用已锁定');

      // 注意：这里不重新计算Gas费用，因为全部金额已经预留了手续费
      // 如果重新计算，可能会导致手续费变化，从而使余额不足
    } else {
      // 余额不足以支付手续费
      setState(() {
        errorMessage = '余额不足以支付手续费';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F23),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          title: Column(
            children: [
              const Text(
                '发送',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Token logo placeholder
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00D4AA),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    network?.symbol ?? 'USDT',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          InkWell(
                            onTap: _showContactSelector,
                            child: const Icon(
                              Icons.contacts,
                              color: Colors.white54,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          InkWell(
                            onTap: _scanQRCode,
                            child: const Icon(
                              Icons.qr_code_scanner,
                              color: Colors.white54,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 转账数量
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '转账数量',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '可用: ${balance.toString()} ${network?.symbol ?? 'USDT'}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ],
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
                      controller: _amountController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        hintText: '请输入转账数量',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      onChanged: (value) {
                        // 当输入金额变化时，解锁并重新计算Gas费用
                        setState(() {
                          _gasFeeLocked = false;
                        });
                        _loadGasFee();
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            network?.symbol ?? 'USDT',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 20,
                            width: 1,
                            color: Colors.white12,
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: _setMaxAmount,
                            child: const Text(
                              '全部',
                              style: TextStyle(
                                color: Color(0xFF6C5CE7),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Gas费用显示
              Row(
                children: [
                  const Text(
                    'Gas费',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 动画进度圆圈指示器
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: Stack(
                      children: [
                        // 背景圆圈
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 1),
                          ),
                        ),
                        // 进度圆圈
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: AnimatedBuilder(
                            animation: _progressAnimation,
                            builder: (context, child) {
                              return CircularProgressIndicator(
                                value: _progressAnimation.value,
                                strokeWidth: 1.5,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Colors.green),
                                backgroundColor: Colors.transparent,
                              );
                            },
                          ),
                        ),
                        // 中心数字
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: Center(
                            child: Text(
                              '$_gasRefreshCountdown',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_gasRefreshCountdown}s后更新',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${gasFee.toStringAsFixed(8)} ${network?.symbol ?? 'BNB'}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${(gasFee * 600).toStringAsFixed(5)}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${(gasFee * 1000000000).toStringAsFixed(0)} GWei',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                          ),
                          const Text(
                            '普通 (25秒)',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.white54,
                      size: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 错误信息
              if (errorMessage.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              // 发送按钮
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _sendTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          '下一步',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
