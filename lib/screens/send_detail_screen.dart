import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:decimal/decimal.dart';
import '../models/network.dart';
import '../providers/wallet_provider.dart';
import '../utils/amount_utils.dart';
import 'qr_scanner_screen.dart';
import '../services/tron_fee_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SendDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? preselectedToken;

  const SendDetailScreen({
    super.key,
    this.preselectedToken,
  });

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
  Map<String, dynamic>? _selectedToken; // 选中的代币
  TronFeeEstimate? _tronFeeEstimate; // Tron 费用估算详情
  int _availableBandwidth = 0; // Tron 可用带宽
  int _availableEnergy = 0; // Tron 可用能量
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
        // 避免在构建期间调用 setState：直接赋值后再加载数据
        network = args['network'] as Network?;
        address = args['address'] as String?;
        _selectedToken = args['preselectedToken'] as Map<String, dynamic>?;
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

    // 设置当前网络，确保 WalletProvider 使用正确的网络
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    walletProvider.setCurrentNetwork(network!);

    // 如果提供了地址，设置为选中的地址
    if (address != null) {
      walletProvider.setSelectedAddress(address!);
    }

    await Future.wait([
      _loadRealBalance(),
      _loadGasFee(),
      _loadContacts(),
      if (network?.id == 'tron') _loadTronResources(),
    ]);

    // 启动Gas费用自动刷新
    _startGasRefreshTimer();
  }

  Future<void> _loadRealBalance() async {
    if (network == null || address == null) return;

    try {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);

      double realBalance;

      // 判断是否为 TRC20 代币
      final isNative = _selectedToken?['isNative'] ?? true;
      final isTRC20 = !isNative &&
          _selectedToken?['networkId'] == 'tron' &&
          _selectedToken?['contractAddress'] != null;

      if (isTRC20) {
        // 获取 TRC20 代币余额
        final contractAddress = _selectedToken!['contractAddress'] as String;
        final decimals = (_selectedToken!['decimals'] as int?) ?? 6;

        debugPrint('=== 加载 TRC20 余额 ===');
        debugPrint('合约地址: $contractAddress');
        debugPrint('小数位: $decimals');

        realBalance = await walletProvider.getTRC20Balance(
          contractAddress: contractAddress,
          decimals: decimals,
        );
      } else {
        // 使用统一的网络余额获取方法
        realBalance = await walletProvider.getNetworkBalance(network!.id);
      }

      debugPrint('=== 加载余额 ===');
      debugPrint('网络: ${network!.id}');
      debugPrint('地址: $address');
      debugPrint('代币类型: ${isTRC20 ? "TRC20" : "原生"}');
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

      // 获取目标地址（用于 Tron 费用估算）
      final toAddress = _recipientController.text.trim();

      // 判断是否为 TRC20 代币
      final isNative = _selectedToken?['isNative'] ?? true;
      final isTRC20 = !isNative &&
          _selectedToken?['networkId'] == 'tron' &&
          _selectedToken?['contractAddress'] != null;

      if (network!.id == 'tron' && isTRC20) {
        // TRC20 代币费用估算
        if (toAddress.isNotEmpty) {
          final contractAddress = _selectedToken!['contractAddress'] as String;
          final decimals = (_selectedToken!['decimals'] as int?) ?? 6;

          final trc20FeeEstimate = await walletProvider.getTrc20FeeEstimate(
            contractAddress: contractAddress,
            toAddress: toAddress,
            amount: amount,
            decimals: decimals,
          );

          if (!mounted) return;
          setState(() {
            _tronFeeEstimate = trc20FeeEstimate;
            gasFee = trc20FeeEstimate.totalFeeTrx;
          });
        } else {
          if (!mounted) return;
          // 没有目标地址时使用默认估算
          setState(() {
            gasFee = 14.0; // TRC20 默认费用（包含能量）
            _tronFeeEstimate = null;
          });
        }
      } else {
        // 使用WalletProvider的费用估算方法
        final feeEstimate = await walletProvider.getNetworkFeeEstimate(
          network!.id,
          amount: amount,
          toAddress: toAddress.isNotEmpty ? toAddress : null,
        );

        if (!mounted) return;
        setState(() {
          gasFee = feeEstimate;
          // 如果是 Tron 原生转账且有目标地址，获取详细费用信息
          if (network!.id == 'tron' && toAddress.isNotEmpty) {
            _loadTronFeeDetails(toAddress, amount);
          } else {
            _tronFeeEstimate = null;
          }
        });
      }
    } catch (e) {
      debugPrint('获取Gas费用失败: $e');
      if (!mounted) return;
      setState(() {
        gasFee = network!.id == 'tron' ? 0.1 : 0.000005; // 默认费用
        _tronFeeEstimate = null;
      });
    }
  }

  Future<void> _loadTronFeeDetails(String toAddress, double amount) async {
    if (network?.id != 'tron') return;

    try {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      final fromAddress = walletProvider.getCurrentNetworkAddress();
      if (fromAddress == null) return;

      final tronNetwork =
          walletProvider.supportedNetworks.firstWhere((n) => n.id == 'tron');

      final feeEstimate = await TronFeeService.estimateTrxTransferFee(
        fromAddress: fromAddress,
        toAddress: toAddress,
        amountTRX: amount,
        tronRpcBaseUrl: tronNetwork.rpcUrl,
      );

      if (!mounted) return;
      setState(() {
        _tronFeeEstimate = feeEstimate;
      });

      // 同步刷新资源余额，保持与详情一致
      await _loadTronResources();
    } catch (e) {
      debugPrint('获取 Tron 费用详情失败: $e');
    }
  }

  Future<void> _loadTronResources() async {
    if (network?.id != 'tron') return;
    try {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      final fromAddress = walletProvider.getCurrentNetworkAddress();
      if (fromAddress == null) return;

      final tronNetwork =
          walletProvider.supportedNetworks.firstWhere((n) => n.id == 'tron');

      final resources = await TronFeeService.getAccountResources(
        address: fromAddress,
        tronRpcBaseUrl: tronNetwork.rpcUrl,
      );

      if (!mounted) return;
      setState(() {
        _availableBandwidth = (resources['availableBandwidth'] ?? 0) as int;
        _availableEnergy = (resources['availableEnergy'] ?? 0) as int;
      });
    } catch (e) {
      debugPrint('获取 Tron 资源失败: $e');
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
      if (!_gasFeeLocked && mounted) {
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
    if (!mounted) return;

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
    if (!mounted) return;

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

      String txHash;

      // 判断是否为 TRC20 代币
      final isNative = _selectedToken?['isNative'] ?? true;
      final isTRC20 = !isNative &&
          _selectedToken?['networkId'] == 'tron' &&
          _selectedToken?['contractAddress'] != null;

      if (isTRC20) {
        // 发送 TRC20 代币
        final contractAddress = _selectedToken!['contractAddress'] as String;
        final decimals = (_selectedToken!['decimals'] as int?) ?? 6;

        debugPrint('=== 发送 TRC20 代币 ===');
        debugPrint('合约地址: $contractAddress');
        debugPrint('接收地址: $recipient');
        debugPrint('金额: $amount');
        debugPrint('小数位: $decimals');

        txHash = await walletProvider.sendTRC20Token(
          contractAddress: contractAddress,
          toAddress: recipient,
          amount: amount,
          decimals: decimals,
          password: password,
        );
      } else {
        // 发送原生代币
        txHash = await walletProvider.sendTransaction(
          networkId: network!.id,
          toAddress: recipient,
          amount: amount,
          password: password,
          memo: memo.isNotEmpty ? memo : null,
        );
      }

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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SelectableText(
                      txHash,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.white70, size: 18),
                    tooltip: '复制',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: txHash));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('交易哈希已复制到剪贴板'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '金额: $amount ${_selectedToken?['symbol'] as String? ?? network!.symbol}',
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
              onPressed: () async {
                final url = buildTxExplorerUrl(network!.id, network!.explorerUrl, txHash);
                if (url != null) {
                  final uri = Uri.parse(url);
                  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('无法打开区块浏览器'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('当前网络不支持跳转到区块浏览器'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: InputDecoration(
                  hintText: '输入6位数字密码',
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

                // 验证密码长度与格式
                if (password.isEmpty) {
                  setState(() {
                    errorText = '请输入密码';
                  });
                  return;
                }

                if (password.length != 6) {
                  setState(() {
                    errorText = '密码必须为6位数字';
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

  double _getTokenPrice(String networkId) {
    switch (networkId) {
      case 'ethereum':
        return 2000.0;
      case 'bitcoin':
        return 45000.0;
      case 'solana':
        return 100.0;
      case 'polygon':
        return 0.8;
      case 'bsc':
        return 300.0;
      case 'avalanche':
        return 25.0;
      case 'arbitrum':
        return 2000.0;
      case 'optimism':
        return 2000.0;
      case 'base':
        return 2000.0;
      case 'tron':
        return 0.1;
      default:
        return 1.0;
    }
  }

  /// 构建 Tron 费用详情显示
  Widget _buildTronFeeDetails() {
    if (_tronFeeEstimate == null) {
      return _buildStandardFeeDisplay();
    }

    final estimate = _tronFeeEstimate!;
    final priceUsd = _getTokenPrice('tron');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 总费用
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '总费用',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${estimate.totalFeeTrx.toStringAsFixed(6)} TRX',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '\$${(estimate.totalFeeTrx * priceUsd).toStringAsFixed(4)}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),
          // 费用明细
          _buildFeeItem(
            '带宽',
            estimate.bandwidthRequired,
            estimate.bandwidthAvailable,
            estimate.bandwidthFeeTrx,
            'Bandwidth',
          ),
          if (estimate.energyRequired > 0) ...[
            const SizedBox(height: 8),
            _buildFeeItem(
              '能量',
              estimate.energyRequired,
              estimate.energyAvailable,
              estimate.energyFeeTrx,
              'Energy',
            ),
          ],
          if (estimate.needsActivation) ...[
            const SizedBox(height: 8),
            _buildActivationWarning(),
          ],
        ],
      ),
    );
  }

  /// 构建费用项
  Widget _buildFeeItem(
    String label,
    int required,
    int available,
    double feeTrx,
    String unit,
  ) {
    final hasEnough = available >= required;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hasEnough
                    ? '使用${available >= required ? "免费" : "质押"}资源'
                    : '消耗 ${feeTrx.toStringAsFixed(6)} TRX',
                style: TextStyle(
                  color: hasEnough ? Colors.green : Colors.orange,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Text(
          '$required / $available',
          style: TextStyle(
            color: hasEnough ? Colors.green : Colors.orange,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 构建激活警告
  Widget _buildActivationWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '激活新账户',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '目标地址未激活，需额外消耗 ${_tronFeeEstimate!.activationFeeTrx.toStringAsFixed(1)} TRX',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建标准费用显示（非 Tron）
  Widget _buildStandardFeeDisplay() {
    return Container(
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
                  '\$${(gasFee * _getTokenPrice(network?.id ?? '')).toStringAsFixed(5)}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (network?.id != 'tron')
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
    );
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
                    decoration: BoxDecoration(
                      color: (_selectedToken?['color'] as Color?) ??
                          const Color(0xFF00D4AA),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _selectedToken?['symbol'] as String? ??
                        network?.symbol ??
                        'USDT',
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13, // 减小字体大小以显示更多内容
                      ),
                      decoration: InputDecoration(
                        hintText: '请输入收款地址',
                        hintStyle: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        // 添加清除按钮
                        suffixIcon: _recipientController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.white54,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _recipientController.clear();
                                  });
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        // 触发重建以显示/隐藏清除按钮
                        setState(() {});
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // 地址簿图标
                          InkWell(
                            onTap: _showContactSelector,
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.contact_page_outlined,
                                color: Color(0xFF6C5CE7),
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // 扫描图标 - 四个角框的扫描图标
                          InkWell(
                            onTap: _scanQRCode,
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.crop_free,
                                color: Color(0xFF6C5CE7),
                                size: 24,
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
                    '可用: ${balance.toString()} ${_selectedToken?['symbol'] as String? ?? network?.symbol ?? 'USDT'}',
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
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Builder(
                          builder: (context) {
                            final amount =
                                double.tryParse(_amountController.text) ?? 0.0;
                            final networkId = network?.id ?? '';
                            final priceUsd = _getTokenPrice(networkId);
                            final usdValue = amount * priceUsd;
                            return Text(
                              '≈\$${usdValue.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            _selectedToken?['symbol'] as String? ??
                                network?.symbol ??
                                'USDT',
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
                          if (network?.id == 'tron') ...[
                            const Spacer(),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '带宽: $_availableBandwidth',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '能量: $_availableEnergy',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
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
                  Text(
                    network?.id == 'tron' ? '手续费' : 'Gas费',
                    style: const TextStyle(
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
              const SizedBox(height: 12),
              // Tron 费用详情显示
              if (network?.id == 'tron' && _tronFeeEstimate != null)
                _buildTronFeeDetails()
              else
                _buildStandardFeeDisplay(),
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

String? buildTxExplorerUrl(String networkId, String base, String txHash) {
  if (base.isEmpty) return null;
  switch (networkId) {
    case 'tron':
      return '$base/#/transaction/$txHash';
    case 'ethereum':
      return '$base/tx/$txHash';
    case 'bsc':
      return '$base/tx/$txHash';
    case 'polygon':
      return '$base/tx/$txHash';
    case 'solana':
      return '$base/tx/$txHash';
    case 'bitcoin':
      return '$base/tx/$txHash';
    default:
      return '$base/tx/$txHash';
  }
}
