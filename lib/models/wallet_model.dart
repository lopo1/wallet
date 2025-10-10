class WalletModel {
  final String address;
  final String? name;
  final double balance;
  final String network;

  WalletModel({
    required this.address,
    this.name,
    required this.balance,
    required this.network,
  });

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'name': name,
      'balance': balance,
      'network': network,
    };
  }

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      address: json['address'],
      name: json['name'],
      balance: json['balance']?.toDouble() ?? 0.0,
      network: json['network'] ?? 'solana',
    );
  }

  WalletModel copyWith({
    String? address,
    String? name,
    double? balance,
    String? network,
  }) {
    return WalletModel(
      address: address ?? this.address,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      network: network ?? this.network,
    );
  }
}