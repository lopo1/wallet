import 'package:flutter/foundation.dart';

class BlockchainAddress {
  final String chainId;
  final String chainName;
  final String chainSymbol;
  final String chainIcon;
  final List<String> addresses;
  final String primaryAddress;
  
  bool isExpanded;

  BlockchainAddress({
    required this.chainId,
    required this.chainName,
    required this.chainSymbol,
    required this.chainIcon,
    required this.addresses,
    required this.primaryAddress,
    this.isExpanded = false,
  });

  // 获取格式化的地址（前6位+省略号+后4位）
  String get formattedPrimaryAddress {
    if (primaryAddress.length <= 10) return primaryAddress;
    return '${primaryAddress.substring(0, 6)}...${primaryAddress.substring(primaryAddress.length - 4)}';
  }

  // 获取所有格式化的地址
  List<String> get formattedAddresses {
    return addresses.map((address) {
      if (address.length <= 10) return address;
      return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
    }).toList();
  }

  // 检查是否有多个地址
  bool get hasMultipleAddresses => addresses.length > 1;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BlockchainAddress &&
        other.chainId == chainId &&
        other.primaryAddress == primaryAddress;
  }

  @override
  int get hashCode => chainId.hashCode ^ primaryAddress.hashCode;

  @override
  String toString() {
    return 'BlockchainAddress(chainId: $chainId, chainName: $chainName, addresses: ${addresses.length})';
  }
}