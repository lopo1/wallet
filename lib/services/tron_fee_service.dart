import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// TRON 费用估算服务
class TronFeeService {
  /// 费用估算结果
  static const int sunPerTrx = 1000000; // 1 TRX = 1,000,000 SUN

  /// 检查地址是否已激活
  static Future<bool> isAccountActivated({
    required String address,
    required String tronRpcBaseUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$tronRpcBaseUrl/wallet/getaccount'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'address': address,
          'visible': true,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('查询账户状态失败: HTTP ${response.statusCode}');
        return false;
      }

      final result = jsonDecode(response.body) as Map<String, dynamic>;

      // 如果返回空对象或没有 address 字段，说明账户未激活
      final isActivated = result.containsKey('address') &&
          result['address'] != null &&
          result['address'].toString().isNotEmpty;

      debugPrint('地址 $address 激活状态: $isActivated');
      return isActivated;
    } catch (e) {
      debugPrint('检查账户激活状态失败: $e');
      return false; // 出错时假设未激活，更安全
    }
  }

  /// 获取账户资源信息（带宽和能量）
  static Future<Map<String, dynamic>> getAccountResources({
    required String address,
    required String tronRpcBaseUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$tronRpcBaseUrl/wallet/getaccountresource'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'address': address,
          'visible': true,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('查询账户资源失败: HTTP ${response.statusCode}');
        return _getDefaultResources();
      }

      final result = jsonDecode(response.body) as Map<String, dynamic>;

      // 解析带宽信息
      final freeNetUsed = result['freeNetUsed'] ?? 0;
      final freeNetLimit = result['freeNetLimit'] ?? 5000; // 默认每日免费带宽
      final netUsed = result['NetUsed'] ?? 0;
      final netLimit = result['NetLimit'] ?? 0;

      // 解析能量信息
      final energyUsed = result['EnergyUsed'] ?? 0;
      final energyLimit = result['EnergyLimit'] ?? 0;

      final availableBandwidth =
          (freeNetLimit - freeNetUsed) + (netLimit - netUsed);
      final availableEnergy = energyLimit - energyUsed;

      debugPrint('=== 账户资源信息 ===');
      debugPrint(
          '可用带宽: $availableBandwidth (免费: ${freeNetLimit - freeNetUsed}, 质押: ${netLimit - netUsed})');
      debugPrint('可用能量: $availableEnergy');

      return {
        'freeNetUsed': freeNetUsed,
        'freeNetLimit': freeNetLimit,
        'netUsed': netUsed,
        'netLimit': netLimit,
        'energyUsed': energyUsed,
        'energyLimit': energyLimit,
        'availableBandwidth': availableBandwidth,
        'availableEnergy': availableEnergy,
      };
    } catch (e) {
      debugPrint('获取账户资源失败: $e');
      return _getDefaultResources();
    }
  }

  static Map<String, dynamic> _getDefaultResources() {
    return {
      'freeNetUsed': 0,
      'freeNetLimit': 5000,
      'netUsed': 0,
      'netLimit': 0,
      'energyUsed': 0,
      'energyLimit': 0,
      'availableBandwidth': 5000,
      'availableEnergy': 0,
    };
  }

  /// 估算 TRX 转账费用
  static Future<TronFeeEstimate> estimateTrxTransferFee({
    required String fromAddress,
    required String toAddress,
    required double amountTRX,
    required String tronRpcBaseUrl,
  }) async {
    try {
      debugPrint('=== 估算 TRX 转账费用 ===');
      debugPrint('From: $fromAddress');
      debugPrint('To: $toAddress');
      debugPrint('Amount: $amountTRX TRX');

      // 1. 检查目标地址是否已激活
      final isToAddressActivated = await isAccountActivated(
        address: toAddress,
        tronRpcBaseUrl: tronRpcBaseUrl,
      );

      // 2. 获取发送方账户资源
      final resources = await getAccountResources(
        address: fromAddress,
        tronRpcBaseUrl: tronRpcBaseUrl,
      );

      // 3. 计算费用
      // TRX 转账通常需要约 268 带宽
      const requiredBandwidth = 268;
      final availableBandwidth = resources['availableBandwidth'] as int;

      double bandwidthFeeTrx = 0.0;
      double activationFeeTrx = 0.0;

      // 资源不足时不再“混合”，直接按全部需求燃烧TRX
      if (availableBandwidth < requiredBandwidth) {
        bandwidthFeeTrx = (requiredBandwidth * 1000) / sunPerTrx;
      } else {
        bandwidthFeeTrx = 0.0;
      }

      // 如果目标地址未激活，需要额外的激活费用
      if (!isToAddressActivated) {
        activationFeeTrx = 1.0; // 激活账户需要 1 TRX
      }

      final totalFeeTrx = bandwidthFeeTrx + activationFeeTrx;

      debugPrint('=== 费用估算结果 ===');
      debugPrint('目标地址已激活: $isToAddressActivated');
      debugPrint('需要带宽: $requiredBandwidth');
      debugPrint('可用带宽: $availableBandwidth');
      debugPrint('带宽费用: $bandwidthFeeTrx TRX');
      debugPrint('激活费用: $activationFeeTrx TRX');
      debugPrint('总费用: $totalFeeTrx TRX');

      return TronFeeEstimate(
        bandwidthRequired: requiredBandwidth,
        bandwidthAvailable: availableBandwidth,
        bandwidthFeeTrx: bandwidthFeeTrx,
        activationFeeTrx: activationFeeTrx,
        totalFeeTrx: totalFeeTrx,
        isToAddressActivated: isToAddressActivated,
        energyRequired: 0,
        energyAvailable: resources['availableEnergy'] as int,
        energyFeeTrx: 0.0,
      );
    } catch (e) {
      debugPrint('估算 TRX 转账费用失败: $e');
      // 返回保守的默认估算
      return TronFeeEstimate(
        bandwidthRequired: 268,
        bandwidthAvailable: 0,
        bandwidthFeeTrx: 0.268,
        activationFeeTrx: 1.0, // 假设需要激活
        totalFeeTrx: 1.268,
        isToAddressActivated: false,
        energyRequired: 0,
        energyAvailable: 0,
        energyFeeTrx: 0.0,
      );
    }
  }

  /// 估算 TRC20 转账费用
  static Future<TronFeeEstimate> estimateTrc20TransferFee({
    required String fromAddress,
    required String toAddress,
    required String contractAddress,
    required double amount,
    required int decimals,
    required String tronRpcBaseUrl,
  }) async {
    try {
      debugPrint('=== 估算 TRC20 转账费用 ===');
      debugPrint('From: $fromAddress');
      debugPrint('To: $toAddress');
      debugPrint('Contract: $contractAddress');
      debugPrint('Amount: $amount');

      // 1. 检查目标地址是否已激活
      final isToAddressActivated = await isAccountActivated(
        address: toAddress,
        tronRpcBaseUrl: tronRpcBaseUrl,
      );

      // 2. 获取发送方账户资源
      final resources = await getAccountResources(
        address: fromAddress,
        tronRpcBaseUrl: tronRpcBaseUrl,
      );

      // 3. 计算费用
      // TRC20 转账通常需要约 345 带宽和 31895 能量
      const requiredBandwidth = 345;
      const requiredEnergy = 31895;

      final availableBandwidth = resources['availableBandwidth'] as int;
      final availableEnergy = resources['availableEnergy'] as int;

      double bandwidthFeeTrx = 0.0;
      double energyFeeTrx = 0.0;
      double activationFeeTrx = 0.0;

      // 资源不足时不混合使用：直接按全部需求燃烧TRX
      if (availableBandwidth < requiredBandwidth) {
        bandwidthFeeTrx = (requiredBandwidth * 1000) / sunPerTrx;
      } else {
        bandwidthFeeTrx = 0.0;
      }

      if (availableEnergy < requiredEnergy) {
        energyFeeTrx = (requiredEnergy * 420) / sunPerTrx;
      } else {
        energyFeeTrx = 0.0;
      }

      // 如果目标地址未激活，需要额外的激活费用
      if (!isToAddressActivated) {
        activationFeeTrx = 1.0; // 激活账户需要 1 TRX
      }

      final totalFeeTrx = bandwidthFeeTrx + energyFeeTrx + activationFeeTrx;

      debugPrint('=== TRC20 费用估算结果 ===');
      debugPrint('目标地址已激活: $isToAddressActivated');
      debugPrint('需要带宽: $requiredBandwidth, 可用: $availableBandwidth');
      debugPrint('需要能量: $requiredEnergy, 可用: $availableEnergy');
      debugPrint('带宽费用: $bandwidthFeeTrx TRX');
      debugPrint('能量费用: $energyFeeTrx TRX');
      debugPrint('激活费用: $activationFeeTrx TRX');
      debugPrint('总费用: $totalFeeTrx TRX');

      return TronFeeEstimate(
        bandwidthRequired: requiredBandwidth,
        bandwidthAvailable: availableBandwidth,
        bandwidthFeeTrx: bandwidthFeeTrx,
        activationFeeTrx: activationFeeTrx,
        totalFeeTrx: totalFeeTrx,
        isToAddressActivated: isToAddressActivated,
        energyRequired: requiredEnergy,
        energyAvailable: availableEnergy,
        energyFeeTrx: energyFeeTrx,
      );
    } catch (e) {
      debugPrint('估算 TRC20 转账费用失败: $e');
      // 返回保守的默认估算
      return TronFeeEstimate(
        bandwidthRequired: 345,
        bandwidthAvailable: 0,
        bandwidthFeeTrx: 0.345,
        activationFeeTrx: 1.0, // 假设需要激活
        totalFeeTrx: 14.745, // 包含能量费用
        isToAddressActivated: false,
        energyRequired: 31895,
        energyAvailable: 0,
        energyFeeTrx: 13.4, // 约 13.4 TRX 的能量费用
      );
    }
  }
}

/// TRON 费用估算结果
class TronFeeEstimate {
  final int bandwidthRequired;
  final int bandwidthAvailable;
  final double bandwidthFeeTrx;
  final double activationFeeTrx;
  final double totalFeeTrx;
  final bool isToAddressActivated;
  final int energyRequired;
  final int energyAvailable;
  final double energyFeeTrx;

  TronFeeEstimate({
    required this.bandwidthRequired,
    required this.bandwidthAvailable,
    required this.bandwidthFeeTrx,
    required this.activationFeeTrx,
    required this.totalFeeTrx,
    required this.isToAddressActivated,
    required this.energyRequired,
    required this.energyAvailable,
    required this.energyFeeTrx,
  });

  /// 获取费用详情描述
  String getDetailedDescription() {
    final parts = <String>[];

    if (bandwidthFeeTrx > 0) {
      parts.add('带宽费用 ${bandwidthFeeTrx.toStringAsFixed(6)} TRX');
    } else {
      parts.add('使用免费带宽');
    }

    if (energyRequired > 0) {
      if (energyFeeTrx > 0) {
        parts.add('能量费用 ${energyFeeTrx.toStringAsFixed(6)} TRX');
      } else {
        parts.add('使用质押能量');
      }
    }

    if (activationFeeTrx > 0) {
      parts.add('激活账户 ${activationFeeTrx.toStringAsFixed(1)} TRX');
    }

    return parts.join('\n');
  }

  /// 是否需要激活账户
  bool get needsActivation => activationFeeTrx > 0;

  /// 是否需要支付带宽费用
  bool get needsBandwidthFee => bandwidthFeeTrx > 0;

  /// 是否需要支付能量费用
  bool get needsEnergyFee => energyFeeTrx > 0;
}
