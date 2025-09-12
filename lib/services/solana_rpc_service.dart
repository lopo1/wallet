import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/solana_transaction.dart';

/// Solana RPC错误类
class SolanaRpcError implements Exception {
  final int code;
  final String message;
  final dynamic data;

  const SolanaRpcError({
    required this.code,
    required this.message,
    this.data,
  });

  @override
  String toString() => 'SolanaRpcError($code): $message';
}

/// RPC连接状态
enum RpcConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

/// RPC连接池配置
class RpcConnectionPoolConfig {
  final int maxConnections;
  final Duration connectionTimeout;
  final Duration idleTimeout;
  final int maxRetries;
  final Duration baseRetryDelay;
  final Duration healthCheckInterval;
  
  const RpcConnectionPoolConfig({
    this.maxConnections = 5,
    this.connectionTimeout = const Duration(seconds: 30),
    this.idleTimeout = const Duration(minutes: 5),
    this.maxRetries = 3,
    this.baseRetryDelay = const Duration(milliseconds: 1000),
    this.healthCheckInterval = const Duration(minutes: 2),
  });
}

/// RPC节点信息
class RpcNodeInfo {
  final String url;
  final DateTime lastHealthCheck;
  final bool isHealthy;
  final int failureCount;
  final Duration averageResponseTime;
  
  const RpcNodeInfo({
    required this.url,
    required this.lastHealthCheck,
    required this.isHealthy,
    this.failureCount = 0,
    this.averageResponseTime = Duration.zero,
  });
  
  RpcNodeInfo copyWith({
    String? url,
    DateTime? lastHealthCheck,
    bool? isHealthy,
    int? failureCount,
    Duration? averageResponseTime,
  }) {
    return RpcNodeInfo(
      url: url ?? this.url,
      lastHealthCheck: lastHealthCheck ?? this.lastHealthCheck,
      isHealthy: isHealthy ?? this.isHealthy,
      failureCount: failureCount ?? this.failureCount,
      averageResponseTime: averageResponseTime ?? this.averageResponseTime,
    );
  }
}

/// Solana RPC服务类
class SolanaRpcService {
  static const int _defaultTimeout = 30; // 默认超时时间（秒）
  
  final RpcConnectionPoolConfig _config;
  final List<String> _rpcUrls;
  int _currentRpcIndex = 0;
  RpcConnectionStatus _connectionStatus = RpcConnectionStatus.disconnected;
  final http.Client _httpClient;
  Timer? _healthCheckTimer;
  final Map<String, RpcNodeInfo> _rpcNodeStatus = {};
  final Map<String, int> _requestCounts = {};
  final Map<String, List<Duration>> _responseTimes = {};
  
  // 事件流控制器
  final StreamController<RpcConnectionStatus> _connectionStatusController = 
      StreamController<RpcConnectionStatus>.broadcast();
  final StreamController<Map<String, dynamic>> _transactionStatusController = 
      StreamController<Map<String, dynamic>>.broadcast();

  /// 构造函数
  SolanaRpcService({
    required List<String> rpcUrls,
    http.Client? httpClient,
    RpcConnectionPoolConfig? config,
  }) : _rpcUrls = List.from(rpcUrls),
       _httpClient = httpClient ?? http.Client(),
       _config = config ?? const RpcConnectionPoolConfig() {
    _initializeRpcNodes();
    _initializeHealthCheck();
  }

  /// 获取当前RPC URL
  String get currentRpcUrl => _rpcUrls[_currentRpcIndex];

  /// 获取连接状态
  RpcConnectionStatus get connectionStatus => _connectionStatus;

  /// 连接状态流
  Stream<RpcConnectionStatus> get connectionStatusStream => 
      _connectionStatusController.stream;

  /// 交易状态流
  Stream<Map<String, dynamic>> get transactionStatusStream => 
      _transactionStatusController.stream;

  /// 初始化RPC节点
  void _initializeRpcNodes() {
    for (final url in _rpcUrls) {
      _rpcNodeStatus[url] = RpcNodeInfo(
        url: url,
        lastHealthCheck: DateTime.now().subtract(const Duration(hours: 1)),
        isHealthy: true, // 初始假设健康
      );
      _requestCounts[url] = 0;
      _responseTimes[url] = [];
    }
  }
  
  /// 初始化健康检查
  void _initializeHealthCheck() {
    _healthCheckTimer = Timer.periodic(
      _config.healthCheckInterval,
      (_) => _performHealthCheck(),
    );
    
    // 立即执行一次健康检查
    _performHealthCheck();
  }

  /// 执行健康检查
  Future<void> _performHealthCheck() async {
    debugPrint('开始RPC节点健康检查...');
    
    final futures = _rpcUrls.asMap().entries.map((entry) async {
      final index = entry.key;
      final url = entry.value;
      
      try {
        final startTime = DateTime.now();
        await _makeRpcCall(
          'getHealth',
          [],
          rpcUrlIndex: index,
          timeout: 5,
        );
        final responseTime = DateTime.now().difference(startTime);
        
        // 更新响应时间统计
        _updateResponseTime(url, responseTime);
        
        // 更新节点状态
        final currentInfo = _rpcNodeStatus[url]!;
        _rpcNodeStatus[url] = currentInfo.copyWith(
          lastHealthCheck: DateTime.now(),
          isHealthy: true,
          failureCount: 0,
          averageResponseTime: _calculateAverageResponseTime(url),
        );
        
        debugPrint('RPC健康检查成功: $url (${responseTime.inMilliseconds}ms)');
      } catch (e) {
        debugPrint('RPC健康检查失败: $url - $e');
        
        final currentInfo = _rpcNodeStatus[url];
        if (currentInfo != null) {
          _rpcNodeStatus[url] = currentInfo.copyWith(
            lastHealthCheck: DateTime.now(),
            isHealthy: false,
            failureCount: currentInfo.failureCount + 1,
          );
        }
      }
    });
    
    await Future.wait(futures);
    
    // 如果当前节点不健康，切换到健康节点
    final currentUrl = _rpcUrls[_currentRpcIndex];
    final currentNodeInfo = _rpcNodeStatus[currentUrl];
    if (currentNodeInfo != null && !currentNodeInfo.isHealthy) {
      _switchToBestRpc();
    }
    
    debugPrint('RPC健康检查完成');
  }

  /// 切换到下一个RPC节点
  void _switchToNextRpc() {
    final originalIndex = _currentRpcIndex;
    
    do {
      _currentRpcIndex = (_currentRpcIndex + 1) % _rpcUrls.length;
      final nodeInfo = _rpcNodeStatus[_rpcUrls[_currentRpcIndex]];
      
      // 如果找到健康节点，使用它
      if (nodeInfo != null && nodeInfo.isHealthy) {
        debugPrint('切换到健康RPC节点: ${currentRpcUrl}');
        return;
      }
    } while (_currentRpcIndex != originalIndex);
    
    debugPrint('切换到RPC节点: ${currentRpcUrl} (无健康节点可用)');
  }
  
  /// 切换到最佳RPC节点
  void _switchToBestRpc() {
    final healthyNodes = _rpcNodeStatus.entries
        .where((entry) => entry.value.isHealthy)
        .toList();
    
    if (healthyNodes.isEmpty) {
      debugPrint('没有健康的RPC节点可用');
      return;
    }
    
    // 按平均响应时间排序，选择最快的节点
    healthyNodes.sort((a, b) => 
        a.value.averageResponseTime.compareTo(b.value.averageResponseTime));
    
    final bestNodeUrl = healthyNodes.first.key;
    final bestNodeIndex = _rpcUrls.indexOf(bestNodeUrl);
    
    if (bestNodeIndex != -1 && bestNodeIndex != _currentRpcIndex) {
      _currentRpcIndex = bestNodeIndex;
      debugPrint('切换到最佳RPC节点: $bestNodeUrl (${healthyNodes.first.value.averageResponseTime.inMilliseconds}ms)');
    }
  }
  
  /// 更新响应时间
  void _updateResponseTime(String url, Duration responseTime) {
    final times = _responseTimes[url] ?? [];
    times.add(responseTime);
    
    // 只保留最近20次的响应时间
    if (times.length > 20) {
      times.removeAt(0);
    }
    
    _responseTimes[url] = times;
  }
  
  /// 计算平均响应时间
  Duration _calculateAverageResponseTime(String url) {
    final times = _responseTimes[url] ?? [];
    if (times.isEmpty) return Duration.zero;
    
    final totalMs = times.fold<int>(0, (sum, time) => sum + time.inMilliseconds);
    return Duration(milliseconds: totalMs ~/ times.length);
  }

  /// 更新连接状态
  void _updateConnectionStatus(RpcConnectionStatus status) {
    if (_connectionStatus != status) {
      _connectionStatus = status;
      _connectionStatusController.add(status);
      debugPrint('RPC连接状态更新: ${status.name}');
    }
  }

  /// 执行RPC调用
  Future<Map<String, dynamic>> _makeRpcCall(
    String method,
    List<dynamic> params, {
    int? rpcUrlIndex,
    int timeout = _defaultTimeout,
  }) async {
    final url = _rpcUrls[rpcUrlIndex ?? _currentRpcIndex];
    final requestId = DateTime.now().millisecondsSinceEpoch;
    
    final requestBody = {
      'jsonrpc': '2.0',
      'id': requestId,
      'method': method,
      'params': params,
    };

    debugPrint('RPC请求: $method -> $url');
    debugPrint('请求参数: ${jsonEncode(params)}');

    final response = await _httpClient
        .post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(requestBody),
        )
        .timeout(Duration(seconds: timeout));

    if (response.statusCode != 200) {
      throw SolanaRpcError(
        code: response.statusCode,
        message: 'HTTP错误: ${response.statusCode} - ${response.reasonPhrase}',
        data: response.body,
      );
    }

    final responseData = jsonDecode(response.body) as Map<String, dynamic>;
    
    if (responseData.containsKey('error')) {
      final error = responseData['error'] as Map<String, dynamic>;
      throw SolanaRpcError(
        code: error['code'] ?? -1,
        message: error['message'] ?? '未知RPC错误',
        data: error['data'],
      );
    }

    debugPrint('RPC响应成功: $method');
    return responseData;
  }

  /// 带重试机制的RPC调用
  Future<Map<String, dynamic>> makeRpcCallWithRetry(
    String method,
    List<dynamic> params, {
    int? maxRetries,
    Duration? timeout,
    bool enableNodeSwitching = true,
  }) async {
    final actualMaxRetries = maxRetries ?? _config.maxRetries;
    final actualTimeout = timeout ?? _config.connectionTimeout;
    
    _updateConnectionStatus(RpcConnectionStatus.connecting);
    
    Exception? lastException;
    final attemptedNodes = <String>{};
    
    for (int attempt = 0; attempt <= actualMaxRetries; attempt++) {
      final currentUrl = _rpcUrls[_currentRpcIndex];
      attemptedNodes.add(currentUrl);
      
      try {
        final startTime = DateTime.now();
        final result = await _makeRpcCall(
          method, 
          params, 
          timeout: actualTimeout.inSeconds,
        );
        
        // 记录成功的请求
        final responseTime = DateTime.now().difference(startTime);
        _updateResponseTime(currentUrl, responseTime);
        _requestCounts[currentUrl] = (_requestCounts[currentUrl] ?? 0) + 1;
        
        // 更新节点健康状态
        final nodeInfo = _rpcNodeStatus[currentUrl];
        if (nodeInfo != null) {
          _rpcNodeStatus[currentUrl] = nodeInfo.copyWith(
            isHealthy: true,
            failureCount: 0,
            averageResponseTime: _calculateAverageResponseTime(currentUrl),
          );
        }
        
        _updateConnectionStatus(RpcConnectionStatus.connected);
        debugPrint('RPC调用成功: $method -> $currentUrl (${responseTime.inMilliseconds}ms)');
        return result;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        debugPrint('RPC调用失败 (尝试 ${attempt + 1}/${actualMaxRetries + 1}): $method -> $currentUrl - $e');
        
        // 更新节点失败计数
        final nodeInfo = _rpcNodeStatus[currentUrl];
        if (nodeInfo != null) {
          _rpcNodeStatus[currentUrl] = nodeInfo.copyWith(
            failureCount: nodeInfo.failureCount + 1,
            isHealthy: nodeInfo.failureCount < 3, // 连续3次失败后标记为不健康
          );
        }
        
        if (attempt < actualMaxRetries) {
          if (enableNodeSwitching) {
            // 智能节点切换：优先选择未尝试过的健康节点
            _switchToNextAvailableRpc(attemptedNodes);
          }
          
          // 智能退避延迟：根据错误类型调整延迟时间
          final delay = _calculateRetryDelay(attempt, e);
          debugPrint('等待 ${delay.inMilliseconds}ms 后重试...');
          await Future.delayed(delay);
        }
      }
    }
    
    _updateConnectionStatus(RpcConnectionStatus.error);
    debugPrint('所有RPC调用尝试失败: $method');
    throw SolanaRpcError(
      code: -1,
      message: 'RPC调用失败，已尝试 ${attemptedNodes.length} 个节点: ${attemptedNodes.join(", ")}',
      data: lastException,
    );
  }
  
  /// 切换到下一个可用的RPC节点
  void _switchToNextAvailableRpc(Set<String> attemptedNodes) {
    // 首先尝试找到未尝试过的健康节点
    for (int i = 0; i < _rpcUrls.length; i++) {
      final index = (_currentRpcIndex + i + 1) % _rpcUrls.length;
      final url = _rpcUrls[index];
      final nodeInfo = _rpcNodeStatus[url];
      
      if (!attemptedNodes.contains(url) && 
          nodeInfo != null && 
          nodeInfo.isHealthy) {
        _currentRpcIndex = index;
        debugPrint('切换到未尝试的健康节点: $url');
        return;
      }
    }
    
    // 如果没有未尝试的健康节点，选择最佳的已尝试节点
    _switchToBestRpc();
  }
  
  /// 计算重试延迟
  Duration _calculateRetryDelay(int attempt, dynamic error) {
    // 基础延迟
    var baseDelay = _config.baseRetryDelay.inMilliseconds;
    
    // 根据错误类型调整延迟
    if (error is SolanaRpcError) {
      switch (error.code) {
        case 429: // 速率限制
          baseDelay *= 3;
          break;
        case -32005: // 节点同步中
          baseDelay *= 2;
          break;
        case -32603: // 内部错误
          baseDelay *= 1.5.toInt();
          break;
      }
    }
    
    // 指数退避
    final exponentialDelay = baseDelay * pow(1.5, attempt).toInt();
    
    // 添加随机抖动，避免雷群效应
    final jitter = Random().nextInt(baseDelay ~/ 2);
    
    final totalDelay = exponentialDelay + jitter;
    
    // 限制最大延迟时间
    const maxDelay = 30000; // 30秒
    return Duration(milliseconds: min(totalDelay, maxDelay));
  }

  /// 获取最新区块哈希
  Future<String> getLatestBlockhash() async {
    try {
      final response = await makeRpcCallWithRetry('getLatestBlockhash', []);
      final result = response['result'];
      
      if (result == null || result['value'] == null) {
        throw const SolanaRpcError(
          code: -1,
          message: '获取区块哈希失败：响应格式错误',
        );
      }
      
      final blockhash = result['value']['blockhash'];
      if (blockhash == null || blockhash.isEmpty) {
        throw const SolanaRpcError(
          code: -1,
          message: '获取区块哈希失败：区块哈希为空',
        );
      }
      
      debugPrint('获取最新区块哈希成功: $blockhash');
      return blockhash;
    } catch (e) {
      debugPrint('获取最新区块哈希失败: $e');
      rethrow;
    }
  }

  /// 获取账户余额
  Future<int> getBalance(String address) async {
    try {
      final response = await makeRpcCallWithRetry('getBalance', [address]);
      final balance = response['result']['value'] as int;
      debugPrint('获取账户余额成功: $address -> $balance lamports');
      return balance;
    } catch (e) {
      debugPrint('获取账户余额失败: $address - $e');
      rethrow;
    }
  }

  /// 获取账户信息
  Future<Map<String, dynamic>?> getAccountInfo(String address) async {
    try {
      final response = await makeRpcCallWithRetry('getAccountInfo', [
        address,
        {'encoding': 'base64'}
      ]);
      final accountInfo = response['result']['value'];
      debugPrint('获取账户信息成功: $address');
      return accountInfo;
    } catch (e) {
      debugPrint('获取账户信息失败: $address - $e');
      rethrow;
    }
  }

  /// 发送交易
  Future<String> sendTransaction(
    String serializedTransaction, {
    Map<String, dynamic>? options,
  }) async {
    try {
      final params = <dynamic>[serializedTransaction];
      if (options != null) {
        params.add(options);
      }
      
      final response = await makeRpcCallWithRetry('sendTransaction', params);
      final signature = response['result'].toString();
      
      debugPrint('交易发送成功: $signature');
      
      // 发送交易状态事件
      _transactionStatusController.add({
        'signature': signature,
        'status': 'sent',
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      return signature;
    } catch (e) {
      debugPrint('发送交易失败: $e');
      rethrow;
    }
  }

  /// 模拟交易
  Future<Map<String, dynamic>> simulateTransaction(
    String serializedTransaction, {
    Map<String, dynamic>? options,
  }) async {
    try {
      final params = <dynamic>[serializedTransaction];
      if (options != null) {
        params.add(options);
      }
      
      final response = await makeRpcCallWithRetry('simulateTransaction', params);
      final result = response['result'] as Map<String, dynamic>;
      
      debugPrint('交易模拟成功');
      return result;
    } catch (e) {
      debugPrint('交易模拟失败: $e');
      rethrow;
    }
  }

  /// 获取交易状态
  Future<SolanaTransactionConfirmation?> getTransactionStatus(
    String signature, {
    String commitment = 'confirmed',
  }) async {
    try {
      final response = await makeRpcCallWithRetry('getSignatureStatus', [
        signature,
        {'searchTransactionHistory': true}
      ]);
      
      final result = response['result'];
      if (result == null || result['value'] == null) {
        return null;
      }
      
      final status = result['value'];
      final confirmations = status['confirmations'] ?? 0;
      final slot = status['slot'] ?? 0;
      final err = status['err'];
      
      return SolanaTransactionConfirmation(
        slot: slot,
        confirmations: confirmations,
        isFinalized: commitment == 'finalized' && confirmations >= 31,
        err: err?.toString(),
      );
    } catch (e) {
      debugPrint('获取交易状态失败: $signature - $e');
      return null;
    }
  }

  /// 等待交易确认
  Future<SolanaTransactionConfirmation> waitForConfirmation(
    String signature, {
    String commitment = 'confirmed',
    Duration timeout = const Duration(minutes: 2),
    Duration pollInterval = const Duration(seconds: 2),
  }) async {
    final startTime = DateTime.now();
    
    while (DateTime.now().difference(startTime) < timeout) {
      try {
        final confirmation = await getTransactionStatus(signature, commitment: commitment);
        
        if (confirmation != null) {
          if (confirmation.err != null) {
            throw SolanaRpcError(
              code: -1,
              message: '交易失败: ${confirmation.err}',
              data: confirmation,
            );
          }
          
          final isConfirmed = commitment == 'finalized' 
              ? confirmation.isFinalized
              : confirmation.confirmations > 0;
              
          if (isConfirmed) {
            debugPrint('交易确认成功: $signature');
            
            // 发送交易确认事件
            _transactionStatusController.add({
              'signature': signature,
              'status': 'confirmed',
              'confirmation': confirmation.toJson(),
              'timestamp': DateTime.now().toIso8601String(),
            });
            
            return confirmation;
          }
        }
        
        await Future.delayed(pollInterval);
      } catch (e) {
        debugPrint('检查交易确认状态时出错: $e');
        await Future.delayed(pollInterval);
      }
    }
    
    throw const SolanaRpcError(
      code: -1,
      message: '等待交易确认超时',
    );
  }

  /// 获取最近的性能样本
  Future<List<Map<String, dynamic>>> getRecentPerformanceSamples() async {
    try {
      final response = await makeRpcCallWithRetry('getRecentPerformanceSamples', [5]);
      final samples = response['result'] as List;
      return samples.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('获取性能样本失败: $e');
      return [];
    }
  }

  /// 估算交易费用
  Future<int> estimateTransactionFee(String serializedTransaction) async {
    try {
      final response = await makeRpcCallWithRetry('getFeeForMessage', [
        serializedTransaction,
        {'commitment': 'processed'}
      ]);
      
      final fee = response['result']['value'] as int?;
      return fee ?? 5000; // 默认费用
    } catch (e) {
      debugPrint('估算交易费用失败: $e');
      return 5000; // 返回默认费用
    }
  }

  /// 获取推荐的优先费
  Future<int> getRecommendedPriorityFee() async {
    try {
      final samples = await getRecentPerformanceSamples();
      if (samples.isEmpty) return 1;
      
      // 计算平均优先费
      final totalFees = samples.fold<int>(0, (sum, sample) {
        return sum + (sample['prioritizationFee'] as int? ?? 0);
      });
      
      final avgFee = totalFees ~/ samples.length;
      return avgFee > 0 ? avgFee : 1;
    } catch (e) {
      debugPrint('获取推荐优先费失败: $e');
      return 1;
    }
  }

  /// 获取健康的RPC节点列表
  List<String> getHealthyRpcUrls() {
    final now = DateTime.now();
    return _rpcUrls.where((url) {
      final nodeInfo = _rpcNodeStatus[url];
      if (nodeInfo == null) return false;
      
      // 检查节点是否健康且最近检查过
      return nodeInfo.isHealthy && 
             now.difference(nodeInfo.lastHealthCheck).inMinutes < 10;
    }).toList();
  }
  
  /// 获取RPC节点统计信息
  Map<String, dynamic> getRpcStatistics() {
    final stats = <String, dynamic>{};
    
    for (final url in _rpcUrls) {
      final nodeInfo = _rpcNodeStatus[url];
      final requestCount = _requestCounts[url] ?? 0;
      final responseTimes = _responseTimes[url] ?? [];
      
      stats[url] = {
        'isHealthy': nodeInfo?.isHealthy ?? false,
        'failureCount': nodeInfo?.failureCount ?? 0,
        'averageResponseTime': nodeInfo?.averageResponseTime.inMilliseconds ?? 0,
        'lastHealthCheck': nodeInfo?.lastHealthCheck.toIso8601String(),
        'requestCount': requestCount,
        'recentResponseTimes': responseTimes.map((t) => t.inMilliseconds).toList(),
      };
    }
    
    return {
      'currentRpcUrl': currentRpcUrl,
      'currentRpcIndex': _currentRpcIndex,
      'connectionStatus': _connectionStatus.name,
      'totalRpcUrls': _rpcUrls.length,
      'healthyRpcUrls': getHealthyRpcUrls().length,
      'nodes': stats,
    };
  }
  
  /// 获取最佳RPC节点
  String? getBestRpcUrl() {
    final healthyNodes = _rpcNodeStatus.entries
        .where((entry) => entry.value.isHealthy)
        .toList();
    
    if (healthyNodes.isEmpty) return null;
    
    // 按平均响应时间排序
    healthyNodes.sort((a, b) => 
        a.value.averageResponseTime.compareTo(b.value.averageResponseTime));
    
    return healthyNodes.first.key;
  }

  /// 清理响应时间缓存
  void _cleanupResponseTimeCache() {
    final now = DateTime.now();
    var cleanedCount = 0;
    
    for (final url in _rpcUrls) {
      final times = _responseTimes[url];
      if (times != null && times.length > 10) {
        // 只保留最近10次的响应时间
        _responseTimes[url] = times.sublist(times.length - 10);
        cleanedCount++;
      }
      
      // 重置请求计数（如果过大）
      final requestCount = _requestCounts[url] ?? 0;
      if (requestCount > 10000) {
        _requestCounts[url] = requestCount ~/ 2; // 减半
        cleanedCount++;
      }
    }
    
    if (cleanedCount > 0) {
      debugPrint('清理了 $cleanedCount 个RPC节点的缓存数据');
    }
  }
  
  /// 获取内存使用统计
  Map<String, dynamic> getMemoryUsage() {
    var totalResponseTimes = 0;
    var totalRequestCounts = 0;
    
    for (final url in _rpcUrls) {
      totalResponseTimes += (_responseTimes[url]?.length ?? 0);
      totalRequestCounts += (_requestCounts[url] ?? 0);
    }
    
    return {
      'rpcNodes': _rpcUrls.length,
      'nodeStatusEntries': _rpcNodeStatus.length,
      'totalResponseTimeEntries': totalResponseTimes,
      'totalRequestCounts': totalRequestCounts,
      'connectionStatus': _connectionStatus.name,
    };
  }
  
  /// 释放资源
  void dispose() {
    debugPrint('开始释放SolanaRpcService资源...');
    
    // 停止健康检查
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
    
    // 清理所有缓存数据
    _rpcNodeStatus.clear();
    _requestCounts.clear();
    _responseTimes.clear();
    
    // 关闭事件流
    _connectionStatusController.close();
    _transactionStatusController.close();
    
    // 关闭HTTP客户端
    _httpClient.close();
    
    debugPrint('SolanaRpcService资源释放完成');
  }
}