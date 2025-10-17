import 'package:flutter/material.dart';

enum TransactionStatus {
  idle,
  loading,
  pending,
  submitted,
  confirmed,
  failed,
  cancelled,
}

class SwapQuote {
  final String fromToken;
  final String toToken;
  final double fromAmount;
  final double toAmount;
  final double price;
  final double guaranteedPrice;
  final double minimumToAmount;
  final double slippage;
  final double estimatedGas;
  final String route;
  final DateTime expiry;
  final double priceImpact;
  final Map<String, dynamic> rawData;

  const SwapQuote({
    required this.fromToken,
    required this.toToken,
    required this.fromAmount,
    required this.toAmount,
    required this.price,
    required this.guaranteedPrice,
    required this.minimumToAmount,
    required this.slippage,
    required this.estimatedGas,
    required this.route,
    required this.expiry,
    this.priceImpact = 0.0,
    this.rawData = const {},
  });

  SwapQuote copyWith({
    String? fromToken,
    String? toToken,
    double? fromAmount,
    double? toAmount,
    double? price,
    double? guaranteedPrice,
    double? minimumToAmount,
    double? slippage,
    double? estimatedGas,
    String? route,
    DateTime? expiry,
    double? priceImpact,
    Map<String, dynamic>? rawData,
  }) {
    return SwapQuote(
      fromToken: fromToken ?? this.fromToken,
      toToken: toToken ?? this.toToken,
      fromAmount: fromAmount ?? this.fromAmount,
      toAmount: toAmount ?? this.toAmount,
      price: price ?? this.price,
      guaranteedPrice: guaranteedPrice ?? this.guaranteedPrice,
      minimumToAmount: minimumToAmount ?? this.minimumToAmount,
      slippage: slippage ?? this.slippage,
      estimatedGas: estimatedGas ?? this.estimatedGas,
      route: route ?? this.route,
      expiry: expiry ?? this.expiry,
      priceImpact: priceImpact ?? this.priceImpact,
      rawData: rawData ?? this.rawData,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiry);
  
  double get estimatedValueUsd {
    // 简化的USD价值估算
    return toAmount * 1.0; // 实际应该基于代币价格计算
  }

  @override
  String toString() {
    return 'SwapQuote(fromToken: $fromToken, toToken: $toToken, fromAmount: $fromAmount, toAmount: $toAmount, price: $price)';
  }
}

class SwapTransaction {
  final String id;
  final String? txHash;
  final String fromToken;
  final String toToken;
  final double fromAmount;
  final double toAmount;
  final double price;
  final TransactionStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final String? networkId;
  final double? gasUsed;
  final double? gasPrice;

  SwapTransaction({
    required this.id,
    this.txHash,
    required this.fromToken,
    required this.toToken,
    required this.fromAmount,
    required this.toAmount,
    required this.price,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.errorMessage,
    this.networkId,
    this.gasUsed,
    this.gasPrice,
  });

  SwapTransaction copyWith({
    String? id,
    String? txHash,
    String? fromToken,
    String? toToken,
    double? fromAmount,
    double? toAmount,
    double? price,
    TransactionStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    String? errorMessage,
    String? networkId,
    double? gasUsed,
    double? gasPrice,
  }) {
    return SwapTransaction(
      id: id ?? this.id,
      txHash: txHash ?? this.txHash,
      fromToken: fromToken ?? this.fromToken,
      toToken: toToken ?? this.toToken,
      fromAmount: fromAmount ?? this.fromAmount,
      toAmount: toAmount ?? this.toAmount,
      price: price ?? this.price,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      networkId: networkId ?? this.networkId,
      gasUsed: gasUsed ?? this.gasUsed,
      gasPrice: gasPrice ?? this.gasPrice,
    );
  }

  Duration get elapsedTime {
    if (completedAt == null) return Duration.zero;
    return completedAt!.difference(createdAt);
  }

  bool get isCompleted => 
      status == TransactionStatus.confirmed || 
      status == TransactionStatus.failed || 
      status == TransactionStatus.cancelled;

  bool get isSuccessful => status == TransactionStatus.confirmed;

  bool get isFailed => status == TransactionStatus.failed;

  Color get statusColor {
    switch (status) {
      case TransactionStatus.confirmed:
        return Colors.green;
      case TransactionStatus.failed:
      case TransactionStatus.cancelled:
        return Colors.red;
      case TransactionStatus.pending:
      case TransactionStatus.submitted:
        return Colors.orange;
      case TransactionStatus.loading:
        return Colors.blue;
      case TransactionStatus.idle:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case TransactionStatus.confirmed:
        return Icons.check_circle;
      case TransactionStatus.failed:
      case TransactionStatus.cancelled:
        return Icons.error;
      case TransactionStatus.pending:
      case TransactionStatus.submitted:
        return Icons.schedule;
      case TransactionStatus.loading:
        return Icons.sync;
      case TransactionStatus.idle:
        return Icons.circle;
    }
  }

  @override
  String toString() {
    return 'SwapTransaction(id: $id, txHash: $txHash, fromToken: $fromToken, toToken: $toToken, status: $status)';
  }
}

// 兑换请求模型
class SwapRequest {
  final String fromToken;
  final String toToken;
  final double fromAmount;
  final double slippage;
  final String? userAddress;
  final String? networkId;

  const SwapRequest({
    required this.fromToken,
    required this.toToken,
    required this.fromAmount,
    this.slippage = 1.0,
    this.userAddress,
    this.networkId,
  });

  Map<String, dynamic> toJson() {
    return {
      'fromToken': fromToken,
      'toToken': toToken,
      'fromAmount': fromAmount,
      'slippage': slippage,
      'userAddress': userAddress,
      'networkId': networkId,
    };
  }

  @override
  String toString() {
    return 'SwapRequest(fromToken: $fromToken, toToken: $toToken, fromAmount: $fromAmount, slippage: $slippage)';
  }
}

// 价格影响等级
enum PriceImpactLevel {
  low,      // < 1%
  medium,   // 1% - 3%
  high,     // 3% - 5%
  veryHigh, // > 5%
}

PriceImpactLevel getPriceImpactLevel(double priceImpact) {
  if (priceImpact < 1.0) return PriceImpactLevel.low;
  if (priceImpact < 3.0) return PriceImpactLevel.medium;
  if (priceImpact < 5.0) return PriceImpactLevel.high;
  return PriceImpactLevel.veryHigh;
}

Color getPriceImpactColor(PriceImpactLevel level) {
  switch (level) {
    case PriceImpactLevel.low:
      return Colors.green;
    case PriceImpactLevel.medium:
      return Colors.orange;
    case PriceImpactLevel.high:
      return Colors.red;
    case PriceImpactLevel.veryHigh:
      return Colors.red.shade800;
  }
}

String getPriceImpactText(PriceImpactLevel level) {
  switch (level) {
    case PriceImpactLevel.low:
      return '低影响';
    case PriceImpactLevel.medium:
      return '中等影响';
    case PriceImpactLevel.high:
      return '高影响';
    case PriceImpactLevel.veryHigh:
      return '极高影响';
  }
}