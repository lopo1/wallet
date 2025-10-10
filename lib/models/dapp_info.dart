import 'package:flutter/material.dart';

/// DApp分类枚举
enum DAppCategory {
  recommended('推荐', Icons.star),
  defi('DeFi', Icons.trending_up),
  nft('NFT', Icons.image),
  gaming('游戏', Icons.games),
  tools('工具', Icons.build),
  social('社交', Icons.people);

  const DAppCategory(this.displayName, this.icon);

  final String displayName;
  final IconData icon;
}

/// DApp信息模型
class DAppInfo {
  final String id;
  final String name;
  final String description;
  final String url;
  final String iconUrl;
  final DAppCategory category;
  final List<String> supportedNetworks;
  final double rating;
  final bool isVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DAppInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    required this.iconUrl,
    required this.category,
    required this.supportedNetworks,
    this.rating = 0.0,
    this.isVerified = false,
    this.createdAt,
    this.updatedAt,
  });

  /// 从JSON创建DAppInfo实例
  factory DAppInfo.fromJson(Map<String, dynamic> json) {
    return DAppInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      url: json['url'] as String,
      iconUrl: json['iconUrl'] as String? ?? '',
      category: DAppCategory.values.firstWhere(
        (cat) => cat.name == json['category'],
        orElse: () => DAppCategory.recommended,
      ),
      supportedNetworks: List<String>.from(json['supportedNetworks'] ?? []),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      isVerified: json['isVerified'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'url': url,
      'iconUrl': iconUrl,
      'category': category.name,
      'supportedNetworks': supportedNetworks,
      'rating': rating,
      'isVerified': isVerified,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// 创建副本并修改部分属性
  DAppInfo copyWith({
    String? id,
    String? name,
    String? description,
    String? url,
    String? iconUrl,
    DAppCategory? category,
    List<String>? supportedNetworks,
    double? rating,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DAppInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      url: url ?? this.url,
      iconUrl: iconUrl ?? this.iconUrl,
      category: category ?? this.category,
      supportedNetworks: supportedNetworks ?? this.supportedNetworks,
      rating: rating ?? this.rating,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DAppInfo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'DAppInfo(id: $id, name: $name, url: $url, category: ${category.displayName})';
  }
}
