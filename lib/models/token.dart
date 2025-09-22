class Token {
  final String address;
  final String name;
  final String symbol;
  final int decimals;
  final String? logoUrl;
  final String networkId;
  final bool isNative;
  final double balance;
  final double? price;

  Token({
    required this.address,
    required this.name,
    required this.symbol,
    required this.decimals,
    this.logoUrl,
    required this.networkId,
    this.isNative = false,
    this.balance = 0.0,
    this.price,
  });

  factory Token.fromJson(Map<String, dynamic> json) {
    return Token(
      address: json['address'] ?? '',
      name: json['name'] ?? '',
      symbol: json['symbol'] ?? '',
      decimals: json['decimals'] ?? 18,
      logoUrl: json['logoUrl'],
      networkId: json['networkId'] ?? '',
      isNative: json['isNative'] ?? false,
      balance: (json['balance'] ?? 0.0).toDouble(),
      price: json['price']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'name': name,
      'symbol': symbol,
      'decimals': decimals,
      'logoUrl': logoUrl,
      'networkId': networkId,
      'isNative': isNative,
      'balance': balance,
      'price': price,
    };
  }

  Token copyWith({
    String? address,
    String? name,
    String? symbol,
    int? decimals,
    String? logoUrl,
    String? networkId,
    bool? isNative,
    double? balance,
    double? price,
  }) {
    return Token(
      address: address ?? this.address,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      decimals: decimals ?? this.decimals,
      logoUrl: logoUrl ?? this.logoUrl,
      networkId: networkId ?? this.networkId,
      isNative: isNative ?? this.isNative,
      balance: balance ?? this.balance,
      price: price ?? this.price,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Token &&
        other.address == address &&
        other.networkId == networkId;
  }

  @override
  int get hashCode => address.hashCode ^ networkId.hashCode;

  @override
  String toString() {
    return 'Token(address: $address, name: $name, symbol: $symbol, networkId: $networkId)';
  }
}
