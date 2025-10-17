import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/token_model.dart';
import '../models/swap_model.dart';

class SwapProvider with ChangeNotifier {
  // 状态管理
  bool _isLoading = false;
  String? _error;
  
  // 代币选择
  Token? _fromToken;
  Token? _toToken;
  
  // 输入金额
  double _fromAmount = 0.0;
  double _toAmount = 0.0;
  
  // 余额
  double _fromTokenBalance = 0.0;
  double _toTokenBalance = 0.0;
  
  // 兑换报价
  SwapQuote? _currentQuote;
  Timer? _quoteRefreshTimer;
  DateTime? _lastQuoteTime;
  
  // 交易设置
  double _slippageTolerance = 1.0; // 1% 默认滑点
  int _transactionDeadline = 20; // 20分钟默认期限
  
  // 交易状态
  TransactionStatus _transactionStatus = TransactionStatus.idle;
  SwapTransaction? _currentTransaction;
  
  // 地址验证
  String? _recipientAddress;
  bool _isAddressValid = false;
  
  // 价格影响
  double _priceImpact = 0.0;
  
  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Token? get fromToken => _fromToken;
  Token? get toToken => _toToken;
  
  double get fromAmount => _fromAmount;
  double get toAmount => _toAmount;
  
  double get fromTokenBalance => _fromTokenBalance;
  double get toTokenBalance => _toTokenBalance;
  
  SwapQuote? get currentQuote => _currentQuote;
  DateTime? get lastQuoteTime => _lastQuoteTime;
  
  double get slippageTolerance => _slippageTolerance;
  int get transactionDeadline => _transactionDeadline;
  
  TransactionStatus get transactionStatus => _transactionStatus;
  SwapTransaction? get currentTransaction => _currentTransaction;
  
  String? get recipientAddress => _recipientAddress;
  bool get isAddressValid => _isAddressValid;
  
  double get priceImpact => _priceImpact;
  
  // 计算属性
  bool get hasValidQuote => _currentQuote != null && !_currentQuote!.isExpired;
  bool get canExecuteSwap => _hasValidInput() && hasValidQuote && _isAddressValid;
  bool get isQuoteRefreshing => _quoteRefreshTimer?.isActive ?? false;
  
  bool get showPriceImpact => _priceImpact > 0.1; // 价格影响超过0.1%时显示
  PriceImpactLevel get priceImpactLevel => getPriceImpactLevel(_priceImpact);
  
  // 私有方法
  bool _hasValidInput() {
    return _fromAmount > 0 && 
           _fromToken != null && 
           _toToken != null && 
           _fromToken != _toToken &&
           _fromAmount <= _fromTokenBalance;
  }
  
  // 设置代币
  void setFromToken(Token token) {
    if (_fromToken?.id == token.id) return;
    
    _fromToken = token;
    _updateFromTokenBalance();
    notifyListeners();
    
    if (_hasValidInput()) {
      _fetchQuote();
    }
  }
  
  void setToToken(Token token) {
    if (_toToken?.id == token.id) return;
    
    _toToken = token;
    _updateToTokenBalance();
    notifyListeners();
    
    if (_hasValidInput()) {
      _fetchQuote();
    }
  }
  
  // 设置金额
  void setFromAmount(double amount) {
    if (_fromAmount == amount) return;
    
    _fromAmount = amount;
    notifyListeners();
    
    if (_hasValidInput()) {
      _fetchQuote();
    } else {
      _clearQuote();
    }
  }
  
  void setToAmount(double amount) {
    if (_toAmount == amount) return;
    
    _toAmount = amount;
    notifyListeners();
    
    // 反向计算（如果支持）
    if (_hasValidInput() && _currentQuote != null) {
      // 这里可以实现反向计算逻辑
      _fetchQuote();
    }
  }
  
  // 快捷按钮
  void setMaxAmount() {
    if (_fromTokenBalance > 0) {
      setFromAmount(_fromTokenBalance);
    }
  }
  
  void setPercentageAmount(double percentage) {
    if (_fromTokenBalance > 0) {
      setFromAmount(_fromTokenBalance * percentage / 100);
    }
  }
  
  // 设置滑点和期限
  void setSlippageTolerance(double slippage) {
    if (_slippageTolerance == slippage) return;
    
    _slippageTolerance = math.max(0.1, math.min(5.0, slippage)); // 限制在0.1%-5%
    notifyListeners();
    
    if (_hasValidInput()) {
      _fetchQuote();
    }
  }
  
  void setTransactionDeadline(int minutes) {
    if (_transactionDeadline == minutes) return;
    
    _transactionDeadline = math.max(1, math.min(60, minutes)); // 限制在1-60分钟
    notifyListeners();
  }
  
  // 地址验证
  void setRecipientAddress(String? address) {
    _recipientAddress = address;
    _validateAddress();
    notifyListeners();
  }
  
  void _validateAddress() {
    if (_recipientAddress == null || _recipientAddress!.isEmpty) {
      _isAddressValid = false;
      return;
    }
    
    // 简化的地址验证逻辑
    _isAddressValid = _recipientAddress!.length > 20 && 
                     _recipientAddress!.startsWith('0x');
  }
  
  // 交换代币
  void swapTokens() {
    final tempToken = _fromToken;
    _fromToken = _toToken;
    _toToken = tempToken;
    
    final tempAmount = _fromAmount;
    _fromAmount = _toAmount;
    _toAmount = tempAmount;
    
    final tempBalance = _fromTokenBalance;
    _fromTokenBalance = _toTokenBalance;
    _toTokenBalance = tempBalance;
    
    notifyListeners();
    
    if (_hasValidInput()) {
      _fetchQuote();
    }
  }
  
  // 获取报价
  Future<void> _fetchQuote() async {
    if (!_hasValidInput()) {
      _clearQuote();
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // 模拟API调用
      await Future.delayed(const Duration(milliseconds: 800));
      
      // 模拟报价计算
      final mockPrice = _getMockPrice();
      final mockToAmount = _fromAmount * mockPrice * (1 - _slippageTolerance / 100);
      final mockPriceImpact = _calculatePriceImpact(_fromAmount, mockToAmount);
      
      _currentQuote = SwapQuote(
        fromToken: _fromToken!.symbol,
        toToken: _toToken!.symbol,
        fromAmount: _fromAmount,
        toAmount: mockToAmount,
        price: mockPrice,
        guaranteedPrice: mockPrice * 0.99,
        minimumToAmount: mockToAmount * 0.98,
        slippage: _slippageTolerance,
        estimatedGas: 0.001,
        route: '1inch',
        expiry: DateTime.now().add(const Duration(minutes: 2)),
        priceImpact: mockPriceImpact,
        rawData: {
          'source': 'mock',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      _toAmount = mockToAmount;
      _priceImpact = mockPriceImpact;
      _lastQuoteTime = DateTime.now();
      
      // 设置自动刷新
      _setupQuoteRefreshTimer();
      
    } catch (e) {
      _error = '获取报价失败: $e';
      _clearQuote();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void _clearQuote() {
    _currentQuote = null;
    _toAmount = 0.0;
    _priceImpact = 0.0;
    _quoteRefreshTimer?.cancel();
    _lastQuoteTime = null;
    notifyListeners();
  }
  
  void _setupQuoteRefreshTimer() {
    _quoteRefreshTimer?.cancel();
    _quoteRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_hasValidInput() && !isQuoteRefreshing) {
        _fetchQuote();
      }
    });
  }
  
  double _getMockPrice() {
    // 模拟价格 - 实际应该从API获取
    if (_fromToken?.symbol == 'ETH' && _toToken?.symbol == 'USDT') {
      return 2500.0;
    } else if (_fromToken?.symbol == 'USDT' && _toToken?.symbol == 'ETH') {
      return 0.0004;
    } else if (_fromToken?.symbol == 'SOL' && _toToken?.symbol == 'USDT') {
      return 150.0;
    } else if (_fromToken?.symbol == 'USDT' && _toToken?.symbol == 'SOL') {
      return 0.0067;
    }
    return 1.0; // 默认1:1
  }
  
  double _calculatePriceImpact(double fromAmount, double toAmount) {
    // 简化的价格影响计算
    if (fromAmount > 1000) return 2.5;
    if (fromAmount > 500) return 1.5;
    if (fromAmount > 100) return 0.8;
    return 0.1;
  }
  
  // 更新余额
  Future<void> _updateFromTokenBalance() async {
    if (_fromToken == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // 模拟余额获取
      await Future.delayed(const Duration(milliseconds: 300));
      _fromTokenBalance = _getMockBalance(_fromToken!.symbol);
    } catch (e) {
      _error = '获取余额失败: $e';
      _fromTokenBalance = 0.0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _updateToTokenBalance() async {
    if (_toToken == null) return;
    
    try {
      // 模拟余额获取
      await Future.delayed(const Duration(milliseconds: 300));
      _toTokenBalance = _getMockBalance(_toToken!.symbol);
    } catch (e) {
      _toTokenBalance = 0.0;
    }
  }
  
  double _getMockBalance(String symbol) {
    // 模拟余额 - 实际应该从区块链获取
    switch (symbol) {
      case 'ETH':
        return 5.0;
      case 'USDT':
        return 10000.0;
      case 'SOL':
        return 50.0;
      case 'MATIC':
        return 1000.0;
      default:
        return 100.0;
    }
  }
  
  // 执行兑换
  Future<void> executeSwap() async {
    if (!canExecuteSwap) return;
    
    _transactionStatus = TransactionStatus.loading;
    _error = null;
    notifyListeners();
    
    try {
      // 模拟交易提交
      await Future.delayed(const Duration(seconds: 2));
      
      final transactionId = 'swap_${DateTime.now().millisecondsSinceEpoch}';
      
      _currentTransaction = SwapTransaction(
        id: transactionId,
        fromToken: _fromToken!.symbol,
        toToken: _toToken!.symbol,
        fromAmount: _fromAmount,
        toAmount: _toAmount,
        price: _currentQuote!.price,
        status: TransactionStatus.submitted,
        createdAt: DateTime.now(),
      );
      
      _transactionStatus = TransactionStatus.submitted;
      notifyListeners();
      
      // 模拟交易确认
      await Future.delayed(const Duration(seconds: 3));
      
      _currentTransaction = _currentTransaction!.copyWith(
        txHash: '0x${math.Random().nextInt(999999999).toRadixString(16)}',
        status: TransactionStatus.confirmed,
        completedAt: DateTime.now(),
      );
      
      _transactionStatus = TransactionStatus.confirmed;
      
      // 更新余额
      await _updateFromTokenBalance();
      await _updateToTokenBalance();
      
    } catch (e) {
      _error = '交易失败: $e';
      _transactionStatus = TransactionStatus.failed;
      _currentTransaction = _currentTransaction?.copyWith(
        status: TransactionStatus.failed,
        errorMessage: e.toString(),
        completedAt: DateTime.now(),
      );
    } finally {
      notifyListeners();
    }
  }
  
  // 重置状态
  void reset() {
    _fromAmount = 0.0;
    _toAmount = 0.0;
    _clearQuote();
    _transactionStatus = TransactionStatus.idle;
    _currentTransaction = null;
    _error = null;
    _recipientAddress = null;
    _isAddressValid = false;
    notifyListeners();
  }
  
  // 手动刷新报价
  Future<void> refreshQuote() async {
    if (_hasValidInput()) {
      await _fetchQuote();
    }
  }
  
  @override
  void dispose() {
    _quoteRefreshTimer?.cancel();
    super.dispose();
  }
}