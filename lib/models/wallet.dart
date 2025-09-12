class Wallet {
  final String id;
  final String name;
  final String mnemonic;
  final Map<String, List<String>> addresses; // networkId -> List of addresses
  final Map<String, int> addressIndexes; // networkId -> next index to use
  final Map<String, String> addressNames; // address -> custom name
  final DateTime createdAt;
  
  Wallet({
    required this.id,
    required this.name,
    required this.mnemonic,
    required this.addresses,
    Map<String, int>? addressIndexes,
    Map<String, String>? addressNames,
    required this.createdAt,
  }) : addressIndexes = addressIndexes ?? {},
       addressNames = addressNames ?? {};
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mnemonic': mnemonic,
      'addresses': addresses,
      'addressIndexes': addressIndexes,
      'addressNames': addressNames,
      'createdAt': createdAt.toIso8601String(),
    };
  }
  
  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'],
      name: json['name'],
      mnemonic: json['mnemonic'] ?? '', // Default to empty string if mnemonic is not present
      addresses: Map<String, List<String>>.from(json['addresses'].map((key, value) => MapEntry(key, List<String>.from(value)))),
      addressIndexes: json['addressIndexes'] != null 
          ? Map<String, int>.from(json['addressIndexes'])
          : {},
      addressNames: json['addressNames'] != null 
          ? Map<String, String>.from(json['addressNames'])
          : {},
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
  
  Wallet copyWith({
    String? id,
    String? name,
    String? mnemonic,
    Map<String, List<String>>? addresses,
    Map<String, int>? addressIndexes,
    Map<String, String>? addressNames,
    DateTime? createdAt,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      mnemonic: mnemonic ?? this.mnemonic,
      addresses: addresses ?? this.addresses,
      addressIndexes: addressIndexes ?? this.addressIndexes,
      addressNames: addressNames ?? this.addressNames,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}