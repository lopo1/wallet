import 'package:flutter/material.dart';

class Asset {
  final String id;
  final String name;
  final String symbol;
  final IconData icon;
  final Color color;
  final double balance;
  final double usdValue;
  final String network;

  Asset({
    required this.id,
    required this.name,
    required this.symbol,
    required this.icon,
    required this.color,
    required this.balance,
    required this.usdValue,
    required this.network,
  });

  double get totalValue => balance * usdValue;

  String get formattedBalance {
    if (balance >= 1000000) {
      return '${(balance / 1000000).toStringAsFixed(2)}M';
    } else if (balance >= 1000) {
      return '${(balance / 1000).toStringAsFixed(2)}K';
    } else {
      return balance.toStringAsFixed(4);
    }
  }

  String get formattedValue {
    if (totalValue >= 1000000) {
      return '\$${(totalValue / 1000000).toStringAsFixed(2)}M';
    } else if (totalValue >= 1000) {
      return '\$${(totalValue / 1000).toStringAsFixed(2)}K';
    } else {
      return '\$${totalValue.toStringAsFixed(2)}';
    }
  }
}

class AssetService {
  static final AssetService _instance = AssetService._internal();
  factory AssetService() => _instance;
  AssetService._internal();

  // 获取资产数据（使用真实余额）
  List<Asset> _getAssetsWithBalance(Function(String) getBalance) {
    return [
      Asset(
        id: 'eth',
        name: 'Ethereum',
        symbol: 'ETH',
        icon: Icons.currency_bitcoin,
        color: const Color(0xFF627EEA),
        balance: getBalance('ethereum'),
        usdValue: 2000.0,
        network: 'ethereum',
      ),
      Asset(
        id: 'matic',
        name: 'Polygon',
        symbol: 'MATIC',
        icon: Icons.hexagon,
        color: const Color(0xFF8247E5),
        balance: getBalance('polygon'),
        usdValue: 0.8,
        network: 'polygon',
      ),
      Asset(
        id: 'bnb',
        name: 'BNB',
        symbol: 'BNB',
        icon: Icons.currency_exchange,
        color: const Color(0xFFF3BA2F),
        balance: getBalance('bsc'),
        usdValue: 300.0,
        network: 'bsc',
      ),
      Asset(
        id: 'btc',
        name: 'Bitcoin',
        symbol: 'BTC',
        icon: Icons.currency_bitcoin,
        color: const Color(0xFFF7931A),
        balance: getBalance('bitcoin'),
        usdValue: 45000.0,
        network: 'bitcoin',
      ),
      Asset(
        id: 'sol',
        name: 'Solana',
        symbol: 'SOL',
        icon: Icons.wb_sunny,
        color: const Color(0xFF9945FF),
        balance: getBalance('solana'),
        usdValue: 100.0,
        network: 'solana',
      ),
    ];
  }

  // 模拟资产数据（向后兼容）
  List<Asset> _getDefaultAssets() {
    return [
      Asset(
        id: 'eth',
        name: 'Ethereum',
        symbol: 'ETH',
        icon: Icons.currency_bitcoin,
        color: const Color(0xFF627EEA),
        balance: 2.5,
        usdValue: 2000.0,
        network: 'ethereum',
      ),
      Asset(
        id: 'matic',
        name: 'Polygon',
        symbol: 'MATIC',
        icon: Icons.hexagon,
        color: const Color(0xFF8247E5),
        balance: 1500.0,
        usdValue: 0.8,
        network: 'polygon',
      ),
      Asset(
        id: 'bnb',
        name: 'BNB',
        symbol: 'BNB',
        icon: Icons.currency_exchange,
        color: const Color(0xFFF3BA2F),
        balance: 5.2,
        usdValue: 300.0,
        network: 'bsc',
      ),
      Asset(
        id: 'btc',
        name: 'Bitcoin',
        symbol: 'BTC',
        icon: Icons.currency_bitcoin,
        color: const Color(0xFFF7931A),
        balance: 0.15,
        usdValue: 45000.0,
        network: 'bitcoin',
      ),
      Asset(
        id: 'sol',
        name: 'Solana',
        symbol: 'SOL',
        icon: Icons.wb_sunny,
        color: const Color(0xFF9945FF),
        balance: 25.0,
        usdValue: 100.0,
        network: 'solana',
      ),
    ];
  }

  // 获取所有资产
  List<Asset> getAllAssets() {
    return _getDefaultAssets();
  }
  
  // 获取所有资产（使用真实余额）
  List<Asset> getAllAssetsWithBalance(Function(String) getBalance) {
    return _getAssetsWithBalance(getBalance);
  }

  // 根据网络获取资产
  List<Asset> getAssetsByNetwork(String networkId) {
    return _getDefaultAssets()
        .where((asset) => asset.network == networkId)
        .toList();
  }
  
  // 根据网络获取资产（使用真实余额）
  List<Asset> getAssetsByNetworkWithBalance(String networkId, Function(String) getBalance) {
    return _getAssetsWithBalance(getBalance)
        .where((asset) => asset.network == networkId)
        .toList();
  }

  // 获取总投资组合价值
  double getTotalPortfolioValue() {
    return _getDefaultAssets()
        .fold(0.0, (sum, asset) => sum + asset.totalValue);
  }
  
  // 获取总投资组合价值（使用真实余额）
  double getTotalPortfolioValueWithBalance(Function(String) getBalance) {
    return _getAssetsWithBalance(getBalance)
        .fold(0.0, (sum, asset) => sum + asset.totalValue);
  }

  // 获取特定网络的总价值
  double getNetworkTotalValue(String networkId) {
    return getAssetsByNetwork(networkId)
        .fold(0.0, (sum, asset) => sum + asset.totalValue);
  }
  
  // 获取特定网络的总价值（使用真实余额）
  double getNetworkTotalValueWithBalance(String networkId, Function(String) getBalance) {
    return getAssetsByNetworkWithBalance(networkId, getBalance)
        .fold(0.0, (sum, asset) => sum + asset.totalValue);
  }

  // 格式化价值显示
  String formatValue(double value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(2)}K';
    } else {
      return '\$${value.toStringAsFixed(2)}';
    }
  }
}