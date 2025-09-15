/// Solana交易状态枚举
enum SolanaTransactionStatus {
  pending, // 待处理
  processing, // 处理中
  confirmed, // 已确认
  finalized, // 已最终确认
  failed, // 失败
  timeout, // 超时
}

/// Solana交易类型枚举
enum SolanaTransactionType {
  transfer, // 转账
  createAccount, // 创建账户
  dataStorage, // 数据存储
  tokenTransfer, // 代币转账
  custom, // 自定义
}

/// Solana交易优先级
enum SolanaTransactionPriority {
  low, // 低优先级
  medium, // 中等优先级
  high, // 高优先级
  veryHigh, // 极高优先级
}

/// Solana交易费用信息
class SolanaTransactionFee {
  final int baseFee; // 基础手续费 (lamports)
  final int priorityFee; // 优先费 (lamports)
  final int totalFee; // 总手续费 (lamports)
  final double priorityMultiplier; // 优先费倍数
  final int computeUnits; // 计算单元
  final int computeUnitPrice; // 计算单元价格

  const SolanaTransactionFee({
    required this.baseFee,
    required this.priorityFee,
    required this.totalFee,
    required this.priorityMultiplier,
    this.computeUnits = 200000,
    this.computeUnitPrice = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'baseFee': baseFee,
      'priorityFee': priorityFee,
      'totalFee': totalFee,
      'priorityMultiplier': priorityMultiplier,
      'computeUnits': computeUnits,
      'computeUnitPrice': computeUnitPrice,
    };
  }

  factory SolanaTransactionFee.fromJson(Map<String, dynamic> json) {
    return SolanaTransactionFee(
      baseFee: json['baseFee'],
      priorityFee: json['priorityFee'],
      totalFee: json['totalFee'],
      priorityMultiplier: json['priorityMultiplier'].toDouble(),
      computeUnits: json['computeUnits'] ?? 200000,
      computeUnitPrice: json['computeUnitPrice'] ?? 1,
    );
  }
}

/// Solana交易确认信息
class SolanaTransactionConfirmation {
  final int slot; // 区块槽位
  final int confirmations; // 确认数
  final String? blockHash; // 区块哈希
  final DateTime? blockTime; // 区块时间
  final bool isFinalized; // 是否最终确认
  final String? err; // 错误信息

  const SolanaTransactionConfirmation({
    required this.slot,
    required this.confirmations,
    this.blockHash,
    this.blockTime,
    this.isFinalized = false,
    this.err,
  });

  Map<String, dynamic> toJson() {
    return {
      'slot': slot,
      'confirmations': confirmations,
      'blockHash': blockHash,
      'blockTime': blockTime?.toIso8601String(),
      'isFinalized': isFinalized,
      'err': err,
    };
  }

  factory SolanaTransactionConfirmation.fromJson(Map<String, dynamic> json) {
    return SolanaTransactionConfirmation(
      slot: json['slot'],
      confirmations: json['confirmations'],
      blockHash: json['blockHash'],
      blockTime:
          json['blockTime'] != null ? DateTime.parse(json['blockTime']) : null,
      isFinalized: json['isFinalized'] ?? false,
      err: json['err'],
    );
  }
}

/// Solana交易主类
class SolanaTransaction {
  final String id; // 交易ID
  final String? signature; // 交易签名
  final SolanaTransactionType type; // 交易类型
  final SolanaTransactionStatus status; // 交易状态
  final String fromAddress; // 发送地址
  final String? toAddress; // 接收地址
  final int? amount; // 转账金额 (lamports)
  final List<dynamic> instructions; // 交易指令列表
  final SolanaTransactionFee fee; // 手续费信息
  final String recentBlockhash; // 最新区块哈希
  final SolanaTransactionPriority priority; // 交易优先级
  final String? memo; // 备注信息
  final Map<String, dynamic>? customData; // 自定义数据
  final DateTime createdAt; // 创建时间
  final DateTime? sentAt; // 发送时间
  final DateTime? confirmedAt; // 确认时间
  final SolanaTransactionConfirmation? confirmation; // 确认信息
  final String? errorMessage; // 错误信息
  final int retryCount; // 重试次数
  final int maxRetries; // 最大重试次数

  const SolanaTransaction({
    required this.id,
    this.signature,
    required this.type,
    required this.status,
    required this.fromAddress,
    this.toAddress,
    this.amount,
    required this.instructions,
    required this.fee,
    required this.recentBlockhash,
    this.priority = SolanaTransactionPriority.medium,
    this.memo,
    this.customData,
    required this.createdAt,
    this.sentAt,
    this.confirmedAt,
    this.confirmation,
    this.errorMessage,
    this.retryCount = 0,
    this.maxRetries = 3,
  });

  /// 创建转账交易
  factory SolanaTransaction.transfer({
    required String id,
    required String fromAddress,
    required String toAddress,
    required int amount,
    required SolanaTransactionFee fee,
    required String recentBlockhash,
    SolanaTransactionPriority priority = SolanaTransactionPriority.medium,
    String? memo,
  }) {
    return SolanaTransaction(
      id: id,
      type: SolanaTransactionType.transfer,
      status: SolanaTransactionStatus.pending,
      fromAddress: fromAddress,
      toAddress: toAddress,
      amount: amount,
      instructions: [], // 将在服务层填充
      fee: fee,
      recentBlockhash: recentBlockhash,
      priority: priority,
      memo: memo,
      createdAt: DateTime.now(),
    );
  }

  /// 创建数据存储交易
  factory SolanaTransaction.dataStorage({
    required String id,
    required String fromAddress,
    required Map<String, dynamic> data,
    required SolanaTransactionFee fee,
    required String recentBlockhash,
    SolanaTransactionPriority priority = SolanaTransactionPriority.medium,
    String? memo,
  }) {
    return SolanaTransaction(
      id: id,
      type: SolanaTransactionType.dataStorage,
      status: SolanaTransactionStatus.pending,
      fromAddress: fromAddress,
      instructions: [], // 将在服务层填充
      fee: fee,
      recentBlockhash: recentBlockhash,
      priority: priority,
      memo: memo,
      customData: data,
      createdAt: DateTime.now(),
    );
  }

  /// 复制并更新交易
  SolanaTransaction copyWith({
    String? id,
    String? signature,
    SolanaTransactionType? type,
    SolanaTransactionStatus? status,
    String? fromAddress,
    String? toAddress,
    int? amount,
    List<dynamic>? instructions,
    SolanaTransactionFee? fee,
    String? recentBlockhash,
    SolanaTransactionPriority? priority,
    String? memo,
    Map<String, dynamic>? customData,
    DateTime? createdAt,
    DateTime? sentAt,
    DateTime? confirmedAt,
    SolanaTransactionConfirmation? confirmation,
    String? errorMessage,
    int? retryCount,
    int? maxRetries,
  }) {
    return SolanaTransaction(
      id: id ?? this.id,
      signature: signature ?? this.signature,
      type: type ?? this.type,
      status: status ?? this.status,
      fromAddress: fromAddress ?? this.fromAddress,
      toAddress: toAddress ?? this.toAddress,
      amount: amount ?? this.amount,
      instructions: instructions ?? this.instructions,
      fee: fee ?? this.fee,
      recentBlockhash: recentBlockhash ?? this.recentBlockhash,
      priority: priority ?? this.priority,
      memo: memo ?? this.memo,
      customData: customData ?? this.customData,
      createdAt: createdAt ?? this.createdAt,
      sentAt: sentAt ?? this.sentAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      confirmation: confirmation ?? this.confirmation,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
    );
  }

  /// 检查交易是否可以重试
  bool get canRetry =>
      retryCount < maxRetries && status == SolanaTransactionStatus.failed;

  /// 检查交易是否已完成
  bool get isCompleted =>
      status == SolanaTransactionStatus.confirmed ||
      status == SolanaTransactionStatus.finalized;

  /// 检查交易是否失败
  bool get isFailed =>
      status == SolanaTransactionStatus.failed ||
      status == SolanaTransactionStatus.timeout;

  /// 获取交易状态描述
  String get statusDescription {
    switch (status) {
      case SolanaTransactionStatus.pending:
        return '待处理';
      case SolanaTransactionStatus.processing:
        return '处理中';
      case SolanaTransactionStatus.confirmed:
        return '已确认';
      case SolanaTransactionStatus.finalized:
        return '已最终确认';
      case SolanaTransactionStatus.failed:
        return '失败';
      case SolanaTransactionStatus.timeout:
        return '超时';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'signature': signature,
      'type': type.name,
      'status': status.name,
      'fromAddress': fromAddress,
      'toAddress': toAddress,
      'amount': amount,
      'fee': fee.toJson(),
      'recentBlockhash': recentBlockhash,
      'priority': priority.name,
      'memo': memo,
      'customData': customData,
      'createdAt': createdAt.toIso8601String(),
      'sentAt': sentAt?.toIso8601String(),
      'confirmedAt': confirmedAt?.toIso8601String(),
      'confirmation': confirmation?.toJson(),
      'errorMessage': errorMessage,
      'retryCount': retryCount,
      'maxRetries': maxRetries,
    };
  }

  factory SolanaTransaction.fromJson(Map<String, dynamic> json) {
    return SolanaTransaction(
      id: json['id'],
      signature: json['signature'],
      type: SolanaTransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SolanaTransactionType.custom,
      ),
      status: SolanaTransactionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SolanaTransactionStatus.pending,
      ),
      fromAddress: json['fromAddress'],
      toAddress: json['toAddress'],
      amount: json['amount'],
      instructions: [], // Instructions are not serialized
      fee: SolanaTransactionFee.fromJson(json['fee']),
      recentBlockhash: json['recentBlockhash'],
      priority: SolanaTransactionPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => SolanaTransactionPriority.medium,
      ),
      memo: json['memo'],
      customData: json['customData'],
      createdAt: DateTime.parse(json['createdAt']),
      sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt']) : null,
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.parse(json['confirmedAt'])
          : null,
      confirmation: json['confirmation'] != null
          ? SolanaTransactionConfirmation.fromJson(json['confirmation'])
          : null,
      errorMessage: json['errorMessage'],
      retryCount: json['retryCount'] ?? 0,
      maxRetries: json['maxRetries'] ?? 3,
    );
  }
}
