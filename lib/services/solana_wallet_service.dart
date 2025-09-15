import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:bip39/bip39.dart' as bip39;
import 'package:solana/solana.dart';
import 'package:flutter_wallet/services/wallet_service.dart';
import 'package:flutter_wallet/services/transaction_monitor_service.dart';
import 'package:flutter_wallet/services/mnemonic_service.dart';
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_wallet/models/solana_transaction.dart';

/// 计算预算指令类型
enum ComputeBudgetInstructionType {
  setComputeUnitLimit,
  setComputeUnitPrice,
}

class SolanaWalletService implements WalletService {
  late RpcClient _rpcClient;
  final String _rpcUrl;

  // 费用相关常量
  static const int _baseFeePerSignature = 5000; // 每个签名的基础费用 (lamports)
  static const int _defaultComputeUnits = 200000; // 默认计算单元
  static const int _maxComputeUnits = 1400000; // 最大计算单元

  // 优先费倍数配置
  static const Map<SolanaTransactionPriority, double> _priorityMultipliers = {
    SolanaTransactionPriority.low: 1.0,
    SolanaTransactionPriority.medium: 1.5,
    SolanaTransactionPriority.high: 2.5,
    SolanaTransactionPriority.veryHigh: 4.0,
  };

  SolanaWalletService(String rpcUrl) : _rpcUrl = rpcUrl {
    _rpcClient = RpcClient(rpcUrl);
  }

  @override
  Future<String> createWallet() async {
    return bip39.generateMnemonic();
  }

  @override
  Future<String> getAddress(String mnemonic) async {
    final keypair = await Ed25519HDKeyPair.fromMnemonic(mnemonic);
    return keypair.publicKey.toBase58();
  }

  @override
  Future<double> getBalance(String address) async {
    final balance = await _rpcClient.getBalance(address);
    return balance.value / lamportsPerSol;
  }

  @override
  Future<String> sendTransaction(
      String mnemonic, String toAddress, double amount) async {
    final fromKeypair = await Ed25519HDKeyPair.fromMnemonic(mnemonic);
    final lamports = (amount * lamportsPerSol).toInt();

    final instruction = SystemInstruction.transfer(
      fundingAccount: fromKeypair.publicKey,
      recipientAccount: Ed25519HDPublicKey.fromBase58(toAddress),
      lamports: lamports,
    );

    final recentBlockhash = await _rpcClient.getLatestBlockhash();
    final message = Message.only(instruction);

    final signedTx = await fromKeypair.signMessage(
      message: message,
      recentBlockhash: recentBlockhash.value.blockhash,
    );

    final signature = await _rpcClient.sendTransaction(signedTx.encode());

    return signature;
  }

  @override
  Future<double> estimateFee(
      String mnemonic, String toAddress, double amount) async {
    final feeInfo = await estimateTransactionFee(
      mnemonic: mnemonic,
      toAddress: toAddress,
      amount: amount,
      priority: SolanaTransactionPriority.medium,
    );
    return feeInfo.totalFee / lamportsPerSol;
  }

  /// 估算交易费用（增强版）
  Future<SolanaTransactionFee> estimateTransactionFee({
    required String mnemonic,
    required String toAddress,
    required double amount,
    required SolanaTransactionPriority priority,
    int? customComputeUnits,
    int? customComputeUnitPrice,
  }) async {
    try {
      // 使用与AddressService相同的方法生成密钥对
      final seed = MnemonicService.mnemonicToSeed(mnemonic);
      const path = "m/44'/501'/0'";
      final derivedKey = await ED25519_HD_KEY.derivePath(path, seed);
      final fromKeypair = await Ed25519HDKeyPair.fromPrivateKeyBytes(
          privateKey: derivedKey.key);

      final lamports = (amount * lamportsPerSol).toInt();

      // 创建转账指令
      final instruction = SystemInstruction.transfer(
        fundingAccount: fromKeypair.publicKey,
        recipientAccount: Ed25519HDPublicKey.fromBase58(toAddress),
        lamports: lamports,
      );

      // 计算指令数量：当前只有转账指令
      int instructionCount = 1; // 仅转账指令

      // 获取基础费用（每个签名的费用）
      final baseFee = _baseFeePerSignature;

      // 获取网络拥堵信息和推荐的优先费
      final networkInfo = await _getNetworkCongestionInfo();
      final recommendedPriorityFee =
          await _getRecommendedPriorityFee(priority, networkInfo);

      // 计算计算单元
      final computeUnits =
          customComputeUnits ?? await _estimateComputeUnits(instructionCount);
      final computeUnitPrice = customComputeUnitPrice ?? recommendedPriorityFee;

      // 计算优先费
      final priorityFee = (computeUnits * computeUnitPrice / 1000000).round();

      // 总费用
      final totalFee = baseFee + priorityFee;

      return SolanaTransactionFee(
        baseFee: baseFee,
        priorityFee: priorityFee,
        totalFee: totalFee,
        priorityMultiplier: _priorityMultipliers[priority] ?? 1.5,
        computeUnits: computeUnits,
        computeUnitPrice: computeUnitPrice,
      );
    } catch (e) {
      // 如果估算失败，返回默认费用
      return _getDefaultFee(priority);
    }
  }

  /// 估算计算单元
  Future<int> _estimateComputeUnits(int instructionCount) async {
    try {
      // 基础计算单元估算 - 使用更保守的估算
      int baseUnits = 0;

      switch (instructionCount) {
        case 1:
          // 仅转账指令 - 增加到更安全的数值
          baseUnits = 1000;
          break;
        case 2:
          // 转账 + 1个指令
          baseUnits = 1500;
          break;
        case 3:
          // 转账 + 2个指令
          baseUnits = 2000;
          break;
        default:
          // 复杂交易
          baseUnits = min(instructionCount * 1000, _defaultComputeUnits);
      }

      // 确保不超过最大限制，但提供足够的计算单元
      return min(baseUnits, _maxComputeUnits);
    } catch (e) {
      // 返回一个安全的默认值
      return 5000;
    }
  }

  /// 获取网络拥堵信息
  Future<Map<String, dynamic>> _getNetworkCongestionInfo() async {
    try {
      final response = await http.post(
        Uri.parse(_rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'getRecentPerformanceSamples',
          'params': [1]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] != null && data['result'].isNotEmpty) {
          final sample = data['result'][0];
          return {
            'samplePeriodSecs': sample['samplePeriodSecs'] ?? 60,
            'numTransactions': sample['numTransactions'] ?? 0,
            'numSlots': sample['numSlots'] ?? 0,
            'maxTransactionsPerSlot': sample['maxTransactionsPerSlot'] ?? 0,
          };
        }
      }
    } catch (e) {
      print('获取网络拥堵信息失败: $e');
    }

    // 返回默认值
    return {
      'samplePeriodSecs': 60,
      'numTransactions': 1000,
      'numSlots': 30,
      'maxTransactionsPerSlot': 100,
    };
  }

  /// 获取推荐的优先费
  Future<int> _getRecommendedPriorityFee(
    SolanaTransactionPriority priority,
    Map<String, dynamic> networkInfo,
  ) async {
    try {
      // 获取最近的优先费统计
      final priorityFeeStats = await _getPriorityFeeStats();

      // 根据网络拥堵程度调整基础优先费
      final congestionMultiplier = _calculateCongestionMultiplier(networkInfo);
      final priorityMultiplier = _priorityMultipliers[priority] ?? 1.5;

      // 计算推荐的优先费（微lamports per compute unit）
      final basePriorityFee = priorityFeeStats['median'] ?? 1000;
      final recommendedFee =
          (basePriorityFee * congestionMultiplier * priorityMultiplier).round();

      // 确保费用在合理范围内
      return max(1, min(recommendedFee, 100000)); // 1 - 100,000 微lamports
    } catch (e) {
      // 如果获取失败，使用默认值
      return _getDefaultPriorityFee(priority);
    }
  }

  /// 获取优先费统计信息
  Future<Map<String, int>> _getPriorityFeeStats() async {
    try {
      final response = await http.post(
        Uri.parse(_rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'getRecentPrioritizationFees',
          'params': [
            [], // 空数组表示获取所有账户的费用信息
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] != null && data['result'].isNotEmpty) {
          final fees = (data['result'] as List)
              .map((fee) => fee['prioritizationFee'] as int)
              .where((fee) => fee > 0)
              .toList();

          if (fees.isNotEmpty) {
            fees.sort();
            final median = fees[fees.length ~/ 2];
            final percentile75 = fees[(fees.length * 0.75).round() - 1];
            final percentile90 = fees[(fees.length * 0.9).round() - 1];

            return {
              'median': median,
              'percentile75': percentile75,
              'percentile90': percentile90,
              'max': fees.last,
            };
          }
        }
      }
    } catch (e) {
      print('获取优先费统计失败: $e');
    }

    return {
      'median': 1000,
      'percentile75': 2000,
      'percentile90': 5000,
      'max': 10000,
    };
  }

  /// 计算网络拥堵倍数
  double _calculateCongestionMultiplier(Map<String, dynamic> networkInfo) {
    try {
      final numTransactions = networkInfo['numTransactions'] as int;
      final numSlots = networkInfo['numSlots'] as int;
      final maxTransactionsPerSlot =
          networkInfo['maxTransactionsPerSlot'] as int;

      if (numSlots > 0 && maxTransactionsPerSlot > 0) {
        final avgTransactionsPerSlot = numTransactions / numSlots;
        final congestionRatio = avgTransactionsPerSlot / maxTransactionsPerSlot;

        // 根据拥堵比例返回倍数
        if (congestionRatio > 0.8) return 3.0; // 高拥堵
        if (congestionRatio > 0.6) return 2.0; // 中等拥堵
        if (congestionRatio > 0.4) return 1.5; // 轻微拥堵
        return 1.0; // 无拥堵
      }
    } catch (e) {
      print('计算网络拥堵倍数失败: $e');
    }

    return 1.0;
  }

  /// 获取默认优先费
  int _getDefaultPriorityFee(SolanaTransactionPriority priority) {
    switch (priority) {
      case SolanaTransactionPriority.low:
        return 1000; // 1,000 微lamports
      case SolanaTransactionPriority.medium:
        return 2000; // 2,000 微lamports
      case SolanaTransactionPriority.high:
        return 5000; // 5,000 微lamports
      case SolanaTransactionPriority.veryHigh:
        return 10000; // 10,000 微lamports
    }
  }

  /// 获取默认费用
  SolanaTransactionFee _getDefaultFee(SolanaTransactionPriority priority) {
    final priorityFee = _getDefaultPriorityFee(priority);
    final computeUnits = 150; // 简单转账的计算单元
    final totalPriorityFee = (computeUnits * priorityFee / 1000000).round();

    return SolanaTransactionFee(
      baseFee: _baseFeePerSignature,
      priorityFee: totalPriorityFee,
      totalFee: _baseFeePerSignature + totalPriorityFee,
      priorityMultiplier: _priorityMultipliers[priority] ?? 1.5,
      computeUnits: computeUnits,
      computeUnitPrice: priorityFee,
    );
  }

  @override
  Future<TransactionStatus> getTransactionStatus(String signature) async {
    final result = await _rpcClient.getSignatureStatuses([signature]);
    if (result.value.isEmpty || result.value.first == null) {
      return TransactionStatus.pending;
    }
    final status = result.value.first!;
    if (status.err != null) {
      return TransactionStatus.failed;
    }
    if (status.confirmationStatus == Commitment.finalized) {
      return TransactionStatus.completed;
    }
    return TransactionStatus.pending;
  }

  void dispose() {
    // No resources to dispose of yet.
  }

  Future<SolanaTransaction> sendSolTransfer({
    required String mnemonic,
    required String fromAddress,
    required String toAddress,
    required double amount,
    required SolanaTransactionPriority priority,
    String? memo,
    int? customComputeUnits,
    int? customComputeUnitPrice,
  }) async {
    try {
      // 首先估算费用
      final feeInfo = await estimateTransactionFee(
        mnemonic: mnemonic,
        toAddress: toAddress,
        amount: amount,
        priority: priority,
        customComputeUnits: customComputeUnits,
        customComputeUnitPrice: customComputeUnitPrice,
      );

      // 使用与AddressService相同的方法生成密钥对
      final seed = MnemonicService.mnemonicToSeed(mnemonic);
      const path = "m/44'/501'/0'"; // 使用索引0，与AddressService相同
      final derivedKey = await ED25519_HD_KEY.derivePath(path, seed);

      // 从派生的私钥创建Ed25519HDKeyPair
      final fromKeypair = await Ed25519HDKeyPair.fromPrivateKeyBytes(
          privateKey: derivedKey.key);
      final lamports = (amount * lamportsPerSol).toInt();

      // 获取从助记词生成的地址
      final generatedAddress = fromKeypair.publicKey.toBase58();

      // 验证地址匹配
      if (generatedAddress != fromAddress) {
        throw Exception(
            '发送地址与助记词不匹配 - 生成地址: $generatedAddress, 传入地址: $fromAddress');
      }

      // 创建转账指令
      final transferInstruction = SystemInstruction.transfer(
        fundingAccount: fromKeypair.publicKey,
        recipientAccount: Ed25519HDPublicKey.fromBase58(toAddress),
        lamports: lamports,
      );

      // 4. 计算预算指令（优先费）
      final computeBudgetInstructions = [
        ComputeBudgetInstruction.setComputeUnitLimit(
          units: feeInfo.computeUnits ?? 200000,
        ),
        ComputeBudgetInstruction.setComputeUnitPrice(
          microLamports: feeInfo.computeUnitPrice ?? 15000,
        ),
      ];
      // 5. 组装所有指令
      final instructions = [
        ...computeBudgetInstructions,
        transferInstruction,
      ];

      print('交易构建信息:');
      print('  指令数量: ${instructions.length}');
      print('  计算单元估算: ${feeInfo.computeUnits}');
      print('  计算单元价格: ${feeInfo.computeUnitPrice} 微lamports');
      print('  预估优先费: ${feeInfo.priorityFee} lamports');
      print('  总费用: ${feeInfo.totalFee} lamports');

      // 获取最新区块哈希
      final recentBlockhash = await _rpcClient.getLatestBlockhash();

      // 创建消息
      final message = Message(instructions: instructions);

      // 签名交易
      final signedTx = await fromKeypair.signMessage(
        message: message,
        recentBlockhash: recentBlockhash.value.blockhash,
      );

      // 发送交易，使用自定义RPC调用来设置优先费
      final encodedTx = signedTx.encode();
      List<int> txBytes;
      if (encodedTx is String) {
        txBytes = base64Decode(encodedTx);
      } else if (encodedTx is List<int>) {
        txBytes = encodedTx as List<int>;
      } else {
        throw Exception('不支持的交易编码格式');
      }

      final signature = await _sendTransactionWithPriorityFee(
        txBytes,
        feeInfo.computeUnitPrice,
        feeInfo.computeUnits,
      );

      // 创建交易对象
      final transaction = SolanaTransaction.transfer(
        id: signature,
        fromAddress: fromAddress,
        toAddress: toAddress,
        amount: lamports,
        fee: feeInfo,
        recentBlockhash: recentBlockhash.value.blockhash,
        priority: priority,
        memo: memo,
      );

      final completedTransaction = transaction.copyWith(
        signature: signature,
        status: SolanaTransactionStatus.processing,
        sentAt: DateTime.now(),
      );

      // 异步更新交易费用信息（不阻塞返回）
      _updateTransactionFeeAsync(signature, completedTransaction);

      return completedTransaction;
    } catch (e) {
      throw Exception('发送SOL转账失败: $e');
    }
  }

  /// 获取优先级倍数
  double _getPriorityMultiplier(SolanaTransactionPriority priority) {
    return _priorityMultipliers[priority] ?? 1.5;
  }

  /// 获取不同优先级的费用预估
  Future<Map<SolanaTransactionPriority, SolanaTransactionFee>>
      getAllPriorityFees({
    required String mnemonic,
    required String toAddress,
    required double amount,
  }) async {
    final result = <SolanaTransactionPriority, SolanaTransactionFee>{};

    for (final priority in SolanaTransactionPriority.values) {
      try {
        final fee = await estimateTransactionFee(
          mnemonic: mnemonic,
          toAddress: toAddress,
          amount: amount,
          priority: priority,
        );
        result[priority] = fee;
      } catch (e) {
        result[priority] = _getDefaultFee(priority);
      }
    }

    return result;
  }

  /// 获取网络状态信息
  Future<Map<String, dynamic>> getNetworkStatus() async {
    try {
      final congestionInfo = await _getNetworkCongestionInfo();
      final priorityFeeStats = await _getPriorityFeeStats();

      // 计算网络拥堵级别
      final congestionLevel = _getNetworkCongestionLevel(congestionInfo);

      return {
        'congestionLevel': congestionLevel,
        'congestionInfo': congestionInfo,
        'priorityFeeStats': priorityFeeStats,
        'recommendedPriority':
            _getRecommendedPriorityForCongestion(congestionLevel),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'congestionLevel': 'unknown',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 获取网络拥堵级别
  String _getNetworkCongestionLevel(Map<String, dynamic> congestionInfo) {
    try {
      final numTransactions = congestionInfo['numTransactions'] as int;
      final numSlots = congestionInfo['numSlots'] as int;
      final maxTransactionsPerSlot =
          congestionInfo['maxTransactionsPerSlot'] as int;

      if (numSlots > 0 && maxTransactionsPerSlot > 0) {
        final avgTransactionsPerSlot = numTransactions / numSlots;
        final congestionRatio = avgTransactionsPerSlot / maxTransactionsPerSlot;

        if (congestionRatio > 0.8) return 'high';
        if (congestionRatio > 0.6) return 'medium';
        if (congestionRatio > 0.4) return 'low';
        return 'none';
      }
    } catch (e) {
      print('计算网络拥堵级别失败: $e');
    }

    return 'unknown';
  }

  /// 根据网络拥堵情况推荐优先级
  SolanaTransactionPriority _getRecommendedPriorityForCongestion(
      String congestionLevel) {
    switch (congestionLevel) {
      case 'high':
        return SolanaTransactionPriority.veryHigh;
      case 'medium':
        return SolanaTransactionPriority.high;
      case 'low':
        return SolanaTransactionPriority.medium;
      default:
        return SolanaTransactionPriority.low;
    }
  }

  /// 优化交易费用
  Future<SolanaTransactionFee> optimizeTransactionFee({
    required String mnemonic,
    required String toAddress,
    required double amount,
    required double maxFeeInSol,
  }) async {
    try {
      // 获取所有优先级的费用
      final allFees = await getAllPriorityFees(
        mnemonic: mnemonic,
        toAddress: toAddress,
        amount: amount,
      );

      final maxFeeInLamports = (maxFeeInSol * lamportsPerSol).toInt();

      // 找到在预算内的最高优先级
      SolanaTransactionPriority? bestPriority;
      SolanaTransactionFee? bestFee;

      for (final priority in [
        SolanaTransactionPriority.veryHigh,
        SolanaTransactionPriority.high,
        SolanaTransactionPriority.medium,
        SolanaTransactionPriority.low,
      ]) {
        final fee = allFees[priority];
        if (fee != null && fee.totalFee <= maxFeeInLamports) {
          bestPriority = priority;
          bestFee = fee;
          break;
        }
      }

      return bestFee ?? allFees[SolanaTransactionPriority.low]!;
    } catch (e) {
      return _getDefaultFee(SolanaTransactionPriority.low);
    }
  }

  /// 预测交易确认时间
  Future<Map<SolanaTransactionPriority, Duration>>
      predictConfirmationTimes() async {
    try {
      final networkStatus = await getNetworkStatus();
      final congestionLevel = networkStatus['congestionLevel'] as String;

      // 根据网络拥堵情况预测确认时间
      final baseTimes = <SolanaTransactionPriority, Duration>{
        SolanaTransactionPriority.low: const Duration(minutes: 2),
        SolanaTransactionPriority.medium: const Duration(seconds: 45),
        SolanaTransactionPriority.high: const Duration(seconds: 20),
        SolanaTransactionPriority.veryHigh: const Duration(seconds: 10),
      };

      // 根据拥堵情况调整时间
      final multiplier = switch (congestionLevel) {
        'high' => 3.0,
        'medium' => 2.0,
        'low' => 1.5,
        _ => 1.0,
      };

      return baseTimes.map((priority, duration) => MapEntry(
            priority,
            Duration(
                milliseconds: (duration.inMilliseconds * multiplier).round()),
          ));
    } catch (e) {
      // 返回默认预测时间
      return {
        SolanaTransactionPriority.low: const Duration(minutes: 2),
        SolanaTransactionPriority.medium: const Duration(seconds: 45),
        SolanaTransactionPriority.high: const Duration(seconds: 20),
        SolanaTransactionPriority.veryHigh: const Duration(seconds: 10),
      };
    }
  }

  Future<void> storeDataOnChain(
      String mnemonic, Map<String, dynamic> data) async {
    // Placeholder implementation
  }

  Future<void> waitForTransactionConfirmation(String signature) async {
    const maxAttempts = 30; // 最多等待30次
    const delayBetweenAttempts = Duration(seconds: 2); // 每次间隔2秒

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final result = await _rpcClient.getSignatureStatuses([signature]);

        if (result.value.isNotEmpty && result.value.first != null) {
          final status = result.value.first!;

          // 如果交易失败
          if (status.err != null) {
            throw Exception('交易失败: ${status.err}');
          }

          // 如果交易已确认
          if (status.confirmationStatus == Commitment.confirmed ||
              status.confirmationStatus == Commitment.finalized) {
            return; // 交易确认成功
          }
        }

        // 等待下一次检查
        await Future.delayed(delayBetweenAttempts);
      } catch (e) {
        if (attempt == maxAttempts - 1) {
          throw Exception('等待交易确认超时: $e');
        }
        await Future.delayed(delayBetweenAttempts);
      }
    }

    throw Exception('等待交易确认超时');
  }

  /// 获取交易的实际费用信息
  Future<SolanaTransactionFee?> getTransactionFee(String signature) async {
    try {
      final response = await http.post(
        Uri.parse(_rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'getTransaction',
          'params': [
            signature,
            {
              'encoding': 'json',
              'maxSupportedTransactionVersion': 0,
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] != null && data['result']['meta'] != null) {
          final meta = data['result']['meta'];
          final fee = meta['fee'] as int? ?? 0;

          // 尝试从交易中解析优先费信息
          int baseFee = _baseFeePerSignature;
          int priorityFee = fee - baseFee;

          // 如果优先费为负数，说明可能是简单交易，调整基础费用
          if (priorityFee < 0) {
            baseFee = fee;
            priorityFee = 0;
          }

          return SolanaTransactionFee(
            baseFee: baseFee,
            priorityFee: priorityFee,
            totalFee: fee,
            priorityMultiplier: 1.0,
            computeUnits: 150, // 默认值，实际值需要从交易日志中解析
            computeUnitPrice:
                priorityFee > 0 ? (priorityFee * 1000000 / 150).round() : 0,
          );
        }
      }
    } catch (e) {
      print('获取交易费用失败: $e');
    }

    return null;
  }

  /// 获取交易详细信息，包括费用
  Future<Map<String, dynamic>?> getTransactionDetails(String signature) async {
    try {
      final response = await http.post(
        Uri.parse(_rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'getTransaction',
          'params': [
            signature,
            {
              'encoding': 'json',
              'maxSupportedTransactionVersion': 0,
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] != null) {
          final result = data['result'];
          final meta = result['meta'];

          return {
            'signature': signature,
            'fee': meta['fee'] ?? 0,
            'slot': result['slot'] ?? 0,
            'blockTime': result['blockTime'],
            'confirmations': meta['confirmations'] ?? 0,
            'err': meta['err'],
            'status': meta['err'] == null ? 'success' : 'failed',
            'preBalances': meta['preBalances'] ?? [],
            'postBalances': meta['postBalances'] ?? [],
            'logMessages': meta['logMessages'] ?? [],
          };
        }
      }
    } catch (e) {
      print('获取交易详情失败: $e');
    }

    return null;
  }

  List<SolanaTransaction> getPendingTransactions() {
    // Placeholder implementation
    return [];
  }

  void cleanupCompletedTransactions() {
    // Placeholder implementation
  }

  /// 异步更新交易费用信息
  void _updateTransactionFeeAsync(
      String signature, SolanaTransaction transaction) {
    // 在后台异步更新费用信息
    Future.delayed(const Duration(seconds: 5), () async {
      try {
        // 等待交易确认
        await waitForTransactionConfirmation(signature);

        // 获取实际费用
        final actualFee = await getTransactionFee(signature);
        if (actualFee != null) {
          // 这里可以通过回调或事件通知UI更新费用信息
          print('交易 $signature 实际费用: ${actualFee.totalFee} lamports');
          print('  基础费用: ${actualFee.baseFee} lamports');
          print('  优先费: ${actualFee.priorityFee} lamports');
          print('  计算单元价格: ${actualFee.computeUnitPrice} 微lamports');
        }
      } catch (e) {
        print('更新交易费用失败: $e');
      }
    });
  }

  /// 发送带有优先费的交易
  /// 现在交易已经包含了计算预算指令，所以直接发送即可
  Future<String> _sendTransactionWithPriorityFee(
    List<int> serializedTransaction,
    int computeUnitPrice,
    int computeUnits,
  ) async {
    try {
      // 将字节数组转换为base64字符串
      final encodedTx = base64Encode(serializedTransaction);

      // 使用标准的 sendTransaction 方法
      // 优先费已经通过计算预算指令包含在交易中
      final signature = await _rpcClient.sendTransaction(
        encodedTx,
        preflightCommitment: Commitment.confirmed,
      );

      print('交易已发送，签名: $signature');
      print('计算单元限制: $computeUnits');
      print('计算单元价格: $computeUnitPrice 微lamports');

      return signature;
    } catch (e) {
      throw Exception('发送交易失败: $e');
    }
  }
}

/// 扩展int类型，添加转换为字节数组的方法
extension IntToBytes on int {
  List<int> toBytes(int length) {
    final bytes = <int>[];
    var value = this;

    for (int i = 0; i < length; i++) {
      bytes.add(value & 0xFF);
      value >>= 8;
    }

    return bytes;
  }
}
