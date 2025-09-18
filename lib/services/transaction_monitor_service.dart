import 'dart:async';

import 'package:flutter/foundation.dart';
import 'solana_rpc_service.dart';

enum TransactionStatus {
  pending,
  completed,
  failed,
}

@immutable
abstract class TransactionMonitorEvent {}

class TransactionConfirmed extends TransactionMonitorEvent {
  TransactionConfirmed({required this.slot});
  final int slot;
}

class TransactionError extends TransactionMonitorEvent {
  TransactionError({required this.error});
  final String error;
}

class TransactionTimeout extends TransactionMonitorEvent {}

class TransactionMonitorConfig {
  TransactionMonitorConfig({
    required this.signature,
    this.commitment = 'confirmed',
    this.timeout = const Duration(minutes: 1),
    this.pollInterval = const Duration(seconds: 2),
  });

  final String signature;
  final String commitment;
  final Duration timeout;
  final Duration pollInterval;
}

class TransactionMonitorService {
  TransactionMonitorService({
    required this.rpcService,
    required this.config,
  });

  final SolanaRpcService rpcService;
  final TransactionMonitorConfig config;

  final _eventController = StreamController<TransactionMonitorEvent>.broadcast();
  Timer? _pollTimer;
  Timer? _timeoutTimer;

  Stream<TransactionMonitorEvent> get events => _eventController.stream;

  void startMonitoring() {
    debugPrint('开始监控交易: ${config.signature}');

    _timeoutTimer = Timer(config.timeout, _handleTimeout);
    _pollTimer = Timer.periodic(config.pollInterval, (_) => _checkTransactionStatus());

    // 立即检查一次
    _checkTransactionStatus();
  }

  void stopMonitoring() {
    debugPrint('停止监控交易: \${config.signature}');
    _pollTimer?.cancel();
    _timeoutTimer?.cancel();
  }

  void stopAllMonitoring() {
    // This is a placeholder to satisfy the compiler.
    // In a real implementation, this would stop all active monitors.
    stopMonitoring();
  }

  void resetStatistics() {
    // This is a placeholder to satisfy the compiler.
    // No statistics are currently tracked.
  }

  Future<void> _checkTransactionStatus() async {
    try {
      final status = await rpcService.getTransactionStatus(
        config.signature,
        commitment: config.commitment,
      );

      if (status != null) {
        if (status.err != null) {
          debugPrint('交易失败: ${config.signature} - ${status.err}');
          _eventController.add(TransactionError(error: status.err!));
          stopMonitoring();
          return;
        }

        final isConfirmed = config.commitment == 'finalized'
            ? status.isFinalized
            : status.confirmations > 0;

        if (isConfirmed) {
          debugPrint('交易确认: ${config.signature} at slot ${status.slot}');
          _eventController.add(TransactionConfirmed(slot: status.slot));
          stopMonitoring();
        } else {
          debugPrint('交易仍在处理中: ${config.signature}');
        }
      } else {
        debugPrint('无法获取交易状态: ${config.signature}');
      }
    } catch (e) {
      debugPrint('检查交易状态时出错: $e');
      // 不停止监控，继续轮询
    }
  }

  void _handleTimeout() {
    debugPrint('交易监控超时: ${config.signature}');
    _eventController.add(TransactionTimeout());
    stopMonitoring();
  }

  void dispose() {
    stopMonitoring();
    _eventController.close();
    debugPrint('TransactionMonitorService已释放');
  }
}