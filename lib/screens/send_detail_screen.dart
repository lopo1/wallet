import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/token.dart';
import '../models/network.dart';
import '../providers/wallet_provider.dart';
import '../services/solana_wallet_service.dart';
import '../services/token_service.dart';
import 'qr_scanner_screen.dart';

class SendDetailScreen extends StatefulWidget {
  const SendDetailScreen({super.key});

  @override
  State<SendDetailScreen> createState() => _SendDetailScreenState();
}

class _SendDetailScreenState extends State<SendDetailScreen> with TickerProviderStateMixin {
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
  
  int _gasRefreshCountdown = 8; // 倒计时秒数

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
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
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
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      
      // 使用统一的网络余额获取方法
      final realBalance = await walletProvider.getNetworkBalance(network!.id);
      
      setState(() {
        balance = realBalance;
      });
    } catch (e) {
      print('获取余额失败: $e');
      // 保持默认余额值
    }
  }

  Future<void> _loadGasFee() async {
    if (network == null || address == null) return;
    
    try {
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      
      // 获取当前输入的金额
      final amount = _amountController.text.isNotEmpty 
          ? double.tryParse(_amountController.text) ?? 0.001 
          : 0.001;
      
      // 使用WalletProvider的费用估算方法
      final feeEstimate = await walletProvider.getNetworkFeeEstimate(
        network!.id, 
        amount: amount
      );
      
      setState(() {
        gasFee = feeEstimate;
      });
    } catch (e) {
      print('获取Gas费用失败: $e');
      setState(() {
        gasFee = 0.000005; // 默认费用
      });
    }
  }

  void _startGasRefreshTimer() {
    _gasRefreshTimer?.cancel();
    _countdownTimer?.cancel();
    
    // 重置倒计时和动画
    _gasRefreshCountdown = 8;
    _progressAnimationController.reset();
    _progressAnimationController.forward();
    
    // 启动倒计时定时器，每秒更新一次
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _gasRefreshCountdown--;
      });
      
      if (_gasRefreshCountdown <= 0) {
        // 倒计时结束，刷新Gas费用
        _loadGasFee();
        _gasRefreshCountdown = 8; // 重置倒计时
        _progressAnimationController.reset();
        _progressAnimationController.forward();
      }
    });
    
    // 主刷新定时器，每8秒执行一次
    _gasRefreshTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      _loadGasFee();
      _gasRefreshCountdown = 8; // 重置倒计时
      _progressAnimationController.reset();
      _progressAnimationController.forward();
    });
  }

  Future<void> _loadContacts() async {
    // 模拟联系人数据
    setState(() {
      contacts = [
        {'name': '朋友A', 'address': '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa'},
        {'name': '朋友B', 'address': '3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy'},
        {'name': '交易所', 'address': 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh'},
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

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() {
        errorMessage = '请输入有效的发送数量';
      });
      return false;
    }

    // 检查余额是否足够（包含手续费）
    final totalRequired = amount + gasFee;
    if (totalRequired > balance) {
      setState(() {
        errorMessage = '余额不足（包含手续费）';
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

    setState(() {
      isLoading = true;
    });

    try {
      // 这里实现实际的发送逻辑
      await Future.delayed(const Duration(seconds: 2)); // 模拟网络请求
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('交易已提交'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = '发送失败: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _setMaxAmount() {
    // 设置为余额减去手续费的金额
    final maxAmount = balance - gasFee;
    if (maxAmount > 0) {
      setState(() {
        _amountController.text = maxAmount.toStringAsFixed(8);
      });
      // 重新计算Gas费用
      _loadGasFee();
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    '可用: ${balance.toStringAsFixed(2)} ${network?.symbol ?? 'USDT'}',
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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        hintText: '请输入转账数量',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      onChanged: (value) {
                        // 当输入金额变化时，重新计算Gas费用
                        _loadGasFee();
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                                backgroundColor: Colors.transparent,
                              );
                            },
                          ),
                        ),
                        // 中心数字
                        Container(
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
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
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