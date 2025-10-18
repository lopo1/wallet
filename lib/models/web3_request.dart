/// Web3方法枚举
enum Web3Method {
  ethRequestAccounts('eth_requestAccounts'),
  ethAccounts('eth_accounts'),
  ethChainId('eth_chainId'),
  netVersion('net_version'),
  ethSendTransaction('eth_sendTransaction'),
  ethSignTransaction('eth_signTransaction'),
  personalSign('personal_sign'),
  ethSign('eth_sign'),
  ethSignTypedData('eth_signTypedData'),
  ethSignTypedDataV4('eth_signTypedData_v4'),
  walletSwitchEthereumChain('wallet_switchEthereumChain'),
  walletAddEthereumChain('wallet_addEthereumChain'),
  walletWatchAsset('wallet_watchAsset'),
  walletRevokePermissions('wallet_revokePermissions');

  const Web3Method(this.methodName);

  final String methodName;

  /// 从方法名获取枚举值
  static Web3Method? fromString(String methodName) {
    for (final method in Web3Method.values) {
      if (method.methodName == methodName) {
        return method;
      }
    }
    return null;
  }

  /// 是否为只读方法（不需要用户确认）
  bool get isReadOnly {
    switch (this) {
      case Web3Method.ethAccounts:
      case Web3Method.ethChainId:
      case Web3Method.netVersion:
        return true;
      default:
        return false;
    }
  }

  /// 是否需要用户授权
  bool get requiresAuthorization {
    switch (this) {
      case Web3Method.ethRequestAccounts:
      case Web3Method.ethSendTransaction:
      case Web3Method.ethSignTransaction:
      case Web3Method.personalSign:
      case Web3Method.ethSign:
      case Web3Method.ethSignTypedData:
      case Web3Method.ethSignTypedDataV4:
      case Web3Method.walletSwitchEthereumChain:
      case Web3Method.walletAddEthereumChain:
      case Web3Method.walletWatchAsset:
      case Web3Method.walletRevokePermissions:
        return true;
      default:
        return false;
    }
  }
}

/// Web3请求状态枚举
enum Web3RequestStatus {
  pending('待处理'),
  approved('已批准'),
  rejected('已拒绝'),
  completed('已完成'),
  failed('失败');

  const Web3RequestStatus(this.displayName);

  final String displayName;
}

/// Web3请求模型
class Web3Request {
  final String id;
  final Web3Method method;
  final List<dynamic> params;
  final String origin;
  final DateTime createdAt;
  final Web3RequestStatus status;
  final String? error;
  final dynamic result;
  final Map<String, dynamic> metadata;

  const Web3Request({
    required this.id,
    required this.method,
    required this.params,
    required this.origin,
    required this.createdAt,
    this.status = Web3RequestStatus.pending,
    this.error,
    this.result,
    this.metadata = const {},
  });

  /// 从JSON创建Web3Request实例
  factory Web3Request.fromJson(Map<String, dynamic> json) {
    return Web3Request(
      id: json['id'] as String,
      method: Web3Method.fromString(json['method'] as String) ??
          Web3Method.ethRequestAccounts,
      params: List<dynamic>.from(json['params'] ?? []),
      origin: json['origin'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: Web3RequestStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => Web3RequestStatus.pending,
      ),
      error: json['error'] as String?,
      result: json['result'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'method': method.methodName,
      'params': params,
      'origin': origin,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'error': error,
      'result': result,
      'metadata': metadata,
    };
  }

  /// 创建副本并修改部分属性
  Web3Request copyWith({
    String? id,
    Web3Method? method,
    List<dynamic>? params,
    String? origin,
    DateTime? createdAt,
    Web3RequestStatus? status,
    String? error,
    dynamic result,
    Map<String, dynamic>? metadata,
  }) {
    return Web3Request(
      id: id ?? this.id,
      method: method ?? this.method,
      params: params ?? this.params,
      origin: origin ?? this.origin,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      error: error ?? this.error,
      result: result ?? this.result,
      metadata: metadata ?? this.metadata,
    );
  }

  /// 标记为已批准
  Web3Request approve({dynamic result}) {
    return copyWith(
      status: Web3RequestStatus.approved,
      result: result,
      error: null,
    );
  }

  /// 标记为已拒绝
  Web3Request reject(String errorMessage) {
    return copyWith(
      status: Web3RequestStatus.rejected,
      error: errorMessage,
      result: null,
    );
  }

  /// 标记为已完成
  Web3Request complete({dynamic result}) {
    return copyWith(
      status: Web3RequestStatus.completed,
      result: result,
    );
  }

  /// 标记为失败
  Web3Request fail(String errorMessage) {
    return copyWith(
      status: Web3RequestStatus.failed,
      error: errorMessage,
    );
  }

  /// 获取请求的显示名称
  String get displayName {
    switch (method) {
      case Web3Method.ethRequestAccounts:
        return '连接钱包';
      case Web3Method.ethSendTransaction:
        return '发送交易';
      case Web3Method.personalSign:
        return '签名消息';
      case Web3Method.ethSignTypedData:
      case Web3Method.ethSignTypedDataV4:
        return '签名数据';
      case Web3Method.walletSwitchEthereumChain:
        return '切换网络';
      case Web3Method.walletAddEthereumChain:
        return '添加网络';
      case Web3Method.walletWatchAsset:
        return '添加代币';
      default:
        return method.methodName;
    }
  }

  /// 检查请求是否已完成（成功或失败）
  bool get isCompleted {
    return status == Web3RequestStatus.completed ||
        status == Web3RequestStatus.failed ||
        status == Web3RequestStatus.rejected;
  }

  /// 检查请求是否成功
  bool get isSuccessful {
    return status == Web3RequestStatus.completed ||
        status == Web3RequestStatus.approved;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Web3Request && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Web3Request(id: $id, method: ${method.methodName}, origin: $origin, status: ${status.displayName})';
  }
}
