import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/solana_transaction.dart';

/// Solana交易监控服务
class SolanaTransactionMonitor {
  final String _rpcUrl;
  final Map<String, StreamController<SolanaTransaction>> _transactionStreams =
      {};
  final Map<String, Timer> _monitoringTimers = {};

  SolanaTransactionMonitor(this._rpcUrl);

  /// 开始监控交易
  Stream<SolanaTransaction> monitorTransaction(SolanaTransaction transaction) {
    final signature = transaction.signature;
    if (signature == null) {
      throw Exception('交易签名不能为空');
    }

    // 如果已经在监控，返回现有的流
    if (_transactionStreams.containsKey(signature)) {
      return _transactionStreams[signature]!.stream;
    }

    // 创建新的流控制器
    final controller = StreamController<SolanaTransaction>.broadcast();
    _transactionStreams[signature] = controller;

    // 开始监控
    _startMonitoring(transaction, controller);

    return controller.stream;
  }

  /// 开始监控单个交易
  void _startMonitoring(SolanaTransaction transaction,
      StreamController<SolanaTransaction> controller) {
    final signature = transaction.signature!;

    // 立即发送初始状态
    controller.add(transaction);

    // 创建定时器，每2秒检查一次
    final timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final updatedTransaction = await _checkTransactionStatus(transaction);
        controller.add(updatedTransaction);

        // 如果交易已完成或失败，停止监控
        if (updatedTransaction.isCompleted || updatedTransaction.isFailed) {
          timer.cancel();
          _transactionStreams.remove(signature);
          _monitoringTimers.remove(signature);

          // 延迟关闭控制器，让最后的状态能够被接收
          Future.delayed(const Duration(seconds: 1), () {
            if (!controller.isClosed) {
              controller.close();
            }
          });
        }
      } catch (e) {
        controller.addError('监控交易失败: $e');
      }
    });

    _monitoringTimers[signature] = timer;

    // 设置超时（5分钟）
    Timer(const Duration(minutes: 5), () {
      if (_monitoringTimers.containsKey(signature)) {
        timer.cancel();
        _transactionStreams.remove(signature);
        _monitoringTimers.remove(signature);

        if (!controller.isClosed) {
          controller.add(transaction.copyWith(
            status: SolanaTransactionStatus.timeout,
            errorMessage: '交易监控超时',
          ));
          controller.close();
        }
      }
    });
  }

  /// 检查交易状态并更新费用信息
  Future<SolanaTransaction> _checkTransactionStatus(
      SolanaTransaction transaction) async {
    final signature = transaction.signature!;

    try {
      // 获取交易状态
      final statusResponse = await http.post(
        Uri.parse(_rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'getSignatureStatuses',
          'params': [
            [signature]
          ]
        }),
      );

      if (statusResponse.statusCode == 200) {
        final statusData = jsonDecode(statusResponse.body);
        if (statusData['result'] != null &&
            statusData['result']['value'] != null &&
            statusData['result']['value'].isNotEmpty &&
            statusData['result']['value'][0] != null) {
          final status = statusData['result']['value'][0];

          // 检查是否有错误
          if (status['err'] != null) {
            return transaction.copyWith(
              status: SolanaTransactionStatus.failed,
              errorMessage: '交易失败: ${status['err']}',
            );
          }

          // 检查确认状态
          final confirmationStatus = status['confirmationStatus'];
          SolanaTransactionStatus newStatus;

          switch (confirmationStatus) {
            case 'processed':
              newStatus = SolanaTransactionStatus.processing;
              break;
            case 'confirmed':
              newStatus = SolanaTransactionStatus.confirmed;
              break;
            case 'finalized':
              newStatus = SolanaTransactionStatus.finalized;
              break;
            default:
              newStatus = SolanaTransactionStatus.processing;
          }

          // 如果交易已确认，获取详细信息包括费用
          if (newStatus == SolanaTransactionStatus.confirmed ||
              newStatus == SolanaTransactionStatus.finalized) {
            final transactionDetails = await _getTransactionDetails(signature);
            if (transactionDetails != null) {
              final actualFee = _parseTransactionFee(transactionDetails);

              return transaction.copyWith(
                status: newStatus,
                confirmedAt: DateTime.now(),
                fee: actualFee ?? transaction.fee,
                confirmation: SolanaTransactionConfirmation(
                  slot: transactionDetails['slot'] ?? 0,
                  confirmations: status['confirmations'] ?? 0,
                  blockTime: transactionDetails['blockTime'] != null
                      ? DateTime.fromMillisecondsSinceEpoch(
                          transactionDetails['blockTime'] * 1000)
                      : null,
                  isFinalized: newStatus == SolanaTransactionStatus.finalized,
                ),
              );
            }
          }

          return transaction.copyWith(status: newStatus);
        }
      }
    } catch (e) {
      print('检查交易状态失败: $e');
    }

    return transaction;
  }

  /// 获取交易详细信息
  Future<Map<String, dynamic>?> _getTransactionDetails(String signature) async {
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
        return data['result'];
      }
    } catch (e) {
      print('获取交易详情失败: $e');
    }

    return null;
  }

  /// 解析交易费用信息
  SolanaTransactionFee? _parseTransactionFee(
      Map<String, dynamic> transactionData) {
    try {
      final meta = transactionData['meta'];
      if (meta == null) return null;

      final totalFee = meta['fee'] as int? ?? 0;

      // 分析交易指令来确定基础费用和优先费
      final transaction = transactionData['transaction'];
      final message = transaction['message'];
      final instructions = message['instructions'] as List? ?? [];

      int baseFee = 5000; // 默认基础费用
      int priorityFee = 0;
      int computeUnits = 150;
      int computeUnitPrice = 0;

      // 查找计算预算指令
      for (final instruction in instructions) {
        final programIdIndex = instruction['programIdIndex'] as int;
        final accounts = message['accountKeys'] as List;

        if (programIdIndex < accounts.length) {
          final programId = accounts[programIdIndex];

          // 检查是否是计算预算程序
          if (programId == 'ComputeBudget111111111111111111111111111111') {
            final data = instruction['data'] as String;
            final decodedData = base64Decode(data);

            if (decodedData.isNotEmpty) {
              final instructionType = decodedData[0];

              // SetComputeUnitLimit (2)
              if (instructionType == 2 && decodedData.length >= 5) {
                computeUnits = _bytesToInt(decodedData.sublist(1, 5));
              }
              // SetComputeUnitPrice (3)
              else if (instructionType == 3 && decodedData.length >= 9) {
                computeUnitPrice = _bytesToInt(decodedData.sublist(1, 9));
                priorityFee =
                    (computeUnits * computeUnitPrice / 1000000).round();
              }
            }
          }
        }
      }

      // 如果没有找到优先费指令，从总费用中推算
      if (priorityFee == 0 && totalFee > baseFee) {
        priorityFee = totalFee - baseFee;
      }

      return SolanaTransactionFee(
        baseFee: baseFee,
        priorityFee: priorityFee,
        totalFee: totalFee,
        priorityMultiplier: priorityFee > 0 ? priorityFee / 1000.0 : 1.0,
        computeUnits: computeUnits,
        computeUnitPrice: computeUnitPrice,
      );
    } catch (e) {
      print('解析交易费用失败: $e');
      return null;
    }
  }

  /// 将字节数组转换为整数（小端序）
  int _bytesToInt(List<int> bytes) {
    int result = 0;
    for (int i = 0; i < bytes.length; i++) {
      result |= (bytes[i] & 0xFF) << (i * 8);
    }
    return result;
  }

  /// 停止监控交易
  void stopMonitoring(String signature) {
    final timer = _monitoringTimers.remove(signature);
    timer?.cancel();

    final controller = _transactionStreams.remove(signature);
    if (controller != null && !controller.isClosed) {
      controller.close();
    }
  }

  /// 停止所有监控
  void stopAllMonitoring() {
    for (final timer in _monitoringTimers.values) {
      timer.cancel();
    }
    _monitoringTimers.clear();

    for (final controller in _transactionStreams.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _transactionStreams.clear();
  }

  /// 释放资源
  void dispose() {
    stopAllMonitoring();
  }
}
