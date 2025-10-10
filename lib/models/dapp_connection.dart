/// DApp连接状态枚举
enum DAppConnectionStatus {
  connecting('连接中'),
  connected('已连接'),
  disconnected('已断开'),
  error('连接错误');

  const DAppConnectionStatus(this.displayName);

  final String displayName;
}

/// DApp权限枚举
enum DAppPermission {
  readAccounts('读取账户'),
  sendTransactions('发送交易'),
  signMessages('签名消息'),
  switchNetworks('切换网络'),
  addTokens('添加代币');

  const DAppPermission(this.displayName);

  final String displayName;
}

/// DApp连接模型
class DAppConnection {
  final String origin;
  final String name;
  final String iconUrl;
  final List<String> connectedAddresses;
  final String networkId;
  final DateTime connectedAt;
  final DateTime lastUsedAt;
  final List<DAppPermission> permissions;
  final DAppConnectionStatus status;
  final Map<String, dynamic> metadata;

  const DAppConnection({
    required this.origin,
    required this.name,
    required this.iconUrl,
    required this.connectedAddresses,
    required this.networkId,
    required this.connectedAt,
    required this.lastUsedAt,
    required this.permissions,
    this.status = DAppConnectionStatus.connected,
    this.metadata = const {},
  });

  /// 从JSON创建DAppConnection实例
  factory DAppConnection.fromJson(Map<String, dynamic> json) {
    return DAppConnection(
      origin: json['origin'] as String,
      name: json['name'] as String,
      iconUrl: json['iconUrl'] as String? ?? '',
      connectedAddresses: List<String>.from(json['connectedAddresses'] ?? []),
      networkId: json['networkId'] as String,
      connectedAt: DateTime.parse(json['connectedAt'] as String),
      lastUsedAt: DateTime.parse(json['lastUsedAt'] as String),
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((p) => DAppPermission.values.firstWhere(
                    (perm) => perm.name == p,
                    orElse: () => DAppPermission.readAccounts,
                  ))
              .toList() ??
          [],
      status: DAppConnectionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => DAppConnectionStatus.connected,
      ),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'origin': origin,
      'name': name,
      'iconUrl': iconUrl,
      'connectedAddresses': connectedAddresses,
      'networkId': networkId,
      'connectedAt': connectedAt.toIso8601String(),
      'lastUsedAt': lastUsedAt.toIso8601String(),
      'permissions': permissions.map((p) => p.name).toList(),
      'status': status.name,
      'metadata': metadata,
    };
  }

  /// 创建副本并修改部分属性
  DAppConnection copyWith({
    String? origin,
    String? name,
    String? iconUrl,
    List<String>? connectedAddresses,
    String? networkId,
    DateTime? connectedAt,
    DateTime? lastUsedAt,
    List<DAppPermission>? permissions,
    DAppConnectionStatus? status,
    Map<String, dynamic>? metadata,
  }) {
    return DAppConnection(
      origin: origin ?? this.origin,
      name: name ?? this.name,
      iconUrl: iconUrl ?? this.iconUrl,
      connectedAddresses: connectedAddresses ?? this.connectedAddresses,
      networkId: networkId ?? this.networkId,
      connectedAt: connectedAt ?? this.connectedAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      permissions: permissions ?? this.permissions,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }

  /// 更新最后使用时间
  DAppConnection updateLastUsed() {
    return copyWith(lastUsedAt: DateTime.now());
  }

  /// 检查是否有特定权限
  bool hasPermission(DAppPermission permission) {
    return permissions.contains(permission);
  }

  /// 添加权限
  DAppConnection addPermission(DAppPermission permission) {
    if (hasPermission(permission)) return this;
    return copyWith(permissions: [...permissions, permission]);
  }

  /// 移除权限
  DAppConnection removePermission(DAppPermission permission) {
    return copyWith(
      permissions: permissions.where((p) => p != permission).toList(),
    );
  }

  /// 获取域名（从origin提取）
  String get domain {
    try {
      final uri = Uri.parse(origin);
      return uri.host;
    } catch (e) {
      return origin;
    }
  }

  /// 检查连接是否活跃（最近24小时内使用过）
  bool get isActive {
    final now = DateTime.now();
    final difference = now.difference(lastUsedAt);
    return difference.inHours < 24;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DAppConnection && other.origin == origin;
  }

  @override
  int get hashCode => origin.hashCode;

  @override
  String toString() {
    return 'DAppConnection(origin: $origin, name: $name, status: ${status.displayName})';
  }
}
