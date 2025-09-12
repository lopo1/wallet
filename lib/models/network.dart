class Network {
  final String id;
  final String name;
  final String symbol;
  final int chainId;
  final String rpcUrl; // 当前使用的RPC地址
  final List<String> rpcUrls; // 所有可用的RPC地址列表
  final String explorerUrl;
  final int color;
  
  Network({
    required this.id,
    required this.name,
    required this.symbol,
    required this.chainId,
    required this.rpcUrl,
    List<String>? rpcUrls,
    required this.explorerUrl,
    required this.color,
  }) : rpcUrls = rpcUrls ?? [rpcUrl];
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'symbol': symbol,
      'chainId': chainId,
      'rpcUrl': rpcUrl,
      'rpcUrls': rpcUrls,
      'explorerUrl': explorerUrl,
      'color': color,
    };
  }
  
  factory Network.fromJson(Map<String, dynamic> json) {
    return Network(
      id: json['id'],
      name: json['name'],
      symbol: json['symbol'],
      chainId: json['chainId'],
      rpcUrl: json['rpcUrl'],
      rpcUrls: List<String>.from(json['rpcUrls'] ?? [json['rpcUrl']]),
      explorerUrl: json['explorerUrl'],
      color: json['color'],
    );
  }
  
  // 创建一个新的Network实例，使用不同的RPC地址
  Network copyWith({
    String? id,
    String? name,
    String? symbol,
    int? chainId,
    String? rpcUrl,
    List<String>? rpcUrls,
    String? explorerUrl,
    int? color,
  }) {
    return Network(
      id: id ?? this.id,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      chainId: chainId ?? this.chainId,
      rpcUrl: rpcUrl ?? this.rpcUrl,
      rpcUrls: rpcUrls ?? this.rpcUrls,
      explorerUrl: explorerUrl ?? this.explorerUrl,
      color: color ?? this.color,
    );
  }
}