import 'package:flutter/material.dart';

class Token {
  final String id;
  final String symbol;
  final String name;
  final String? iconUrl;
  final String networkId;
  final String contractAddress;
  final int decimals;
  final bool isNative;
  final double? priceUsd;
  final Color? color;
  final IconData? icon;

  const Token({
    required this.id,
    required this.symbol,
    required this.name,
    this.iconUrl,
    required this.networkId,
    required this.contractAddress,
    required this.decimals,
    this.isNative = false,
    this.priceUsd,
    this.color,
    this.icon,
  });

  Token copyWith({
    String? id,
    String? symbol,
    String? name,
    String? iconUrl,
    String? networkId,
    String? contractAddress,
    int? decimals,
    bool? isNative,
    double? priceUsd,
    Color? color,
    IconData? icon,
  }) {
    return Token(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      iconUrl: iconUrl ?? this.iconUrl,
      networkId: networkId ?? this.networkId,
      contractAddress: contractAddress ?? this.contractAddress,
      decimals: decimals ?? this.decimals,
      isNative: isNative ?? this.isNative,
      priceUsd: priceUsd ?? this.priceUsd,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'name': name,
      'iconUrl': iconUrl,
      'networkId': networkId,
      'contractAddress': contractAddress,
      'decimals': decimals,
      'isNative': isNative,
      'priceUsd': priceUsd,
    };
  }

  factory Token.fromJson(Map<String, dynamic> json) {
    return Token(
      id: json['id'],
      symbol: json['symbol'],
      name: json['name'],
      iconUrl: json['iconUrl'],
      networkId: json['networkId'],
      contractAddress: json['contractAddress'],
      decimals: json['decimals'],
      isNative: json['isNative'] ?? false,
      priceUsd: json['priceUsd']?.toDouble(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Token &&
        other.id == id &&
        other.symbol == symbol &&
        other.networkId == networkId;
  }

  @override
  int get hashCode => id.hashCode ^ symbol.hashCode ^ networkId.hashCode;

  @override
  String toString() {
    return 'Token(id: $id, symbol: $symbol, name: $name, networkId: $networkId)';
  }
}

// 常用代币定义
class TokenPresets {
  // Ethereum tokens
  static final eth = Token(
    id: 'ethereum',
    symbol: 'ETH',
    name: 'Ethereum',
    networkId: 'ethereum',
    contractAddress: '0x0000000000000000000000000000000000000000',
    decimals: 18,
    isNative: true,
    color: const Color(0xFF627EEA),
    icon: Icons.currency_bitcoin,
  );

  static final usdt = Token(
    id: 'tether',
    symbol: 'USDT',
    name: 'Tether USD',
    networkId: 'ethereum',
    contractAddress: '0xdAC17F958D2ee523a2206206994597C13D831ec7',
    decimals: 6,
    color: const Color(0xFF26A17B),
    icon: Icons.attach_money,
  );

  static final usdc = Token(
    id: 'usd-coin',
    symbol: 'USDC',
    name: 'USD Coin',
    networkId: 'ethereum',
    contractAddress: '0xA0b86991c6218b36c1d19D4a2e9Eb4cF7b7c6D8E',
    decimals: 6,
    color: const Color(0xFF2775CA),
    icon: Icons.attach_money,
  );

  static final dai = Token(
    id: 'dai',
    symbol: 'DAI',
    name: 'Dai Stablecoin',
    networkId: 'ethereum',
    contractAddress: '0x6B175474E89094C44Da98b954EedeAC495271d0F',
    decimals: 18,
    color: const Color(0xFFF5AC37),
    icon: Icons.attach_money,
  );

  // Solana tokens
  static final sol = Token(
    id: 'solana',
    symbol: 'SOL',
    name: 'Solana',
    networkId: 'solana',
    contractAddress: 'So11111111111111111111111111111111111111112',
    decimals: 9,
    isNative: true,
    color: const Color(0xFF9945FF),
    icon: Icons.brightness_7,
  );

  static final usdtSol = Token(
    id: 'tether-sol',
    symbol: 'USDT',
    name: 'Tether USD (Solana)',
    networkId: 'solana',
    contractAddress: 'Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB',
    decimals: 6,
    color: const Color(0xFF26A17B),
    icon: Icons.attach_money,
  );

  // Polygon tokens
  static final matic = Token(
    id: 'polygon',
    symbol: 'MATIC',
    name: 'Polygon',
    networkId: 'polygon',
    contractAddress: '0x0000000000000000000000000000000000001010',
    decimals: 18,
    isNative: true,
    color: const Color(0xFF8247E5),
    icon: Icons.hexagon,
  );

  static final usdtPolygon = Token(
    id: 'tether-polygon',
    symbol: 'USDT',
    name: 'Tether USD (Polygon)',
    networkId: 'polygon',
    contractAddress: '0xc2132D05D31c914a87C1411A2fB12A4D2C6C1E8E',
    decimals: 6,
    color: const Color(0xFF26A17B),
    icon: Icons.attach_money,
  );

  // 常用代币列表
  static List<Token> get commonTokens => [
        eth,
        usdt,
        usdc,
        dai,
        sol,
        usdtSol,
        matic,
        usdtPolygon,
      ];

  // 按网络分组
  static Map<String, List<Token>> get tokensByNetwork {
    final Map<String, List<Token>> grouped = {};
    for (final token in commonTokens) {
      grouped.putIfAbsent(token.networkId, () => []).add(token);
    }
    return grouped;
  }
}