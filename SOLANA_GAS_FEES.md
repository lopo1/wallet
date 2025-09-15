# Solana Gas费和优先费功能

本文档介绍了Flutter钱包应用中完善的Solana gas费和优先费功能。

## 功能特性

### 1. 智能费用估算
- **动态优先费计算**: 基于网络拥堵情况自动调整优先费
- **多优先级支持**: 提供低、中、高、极高四个优先级选项
- **实时网络状态**: 监控网络拥堵程度并提供建议

### 2. 费用优化
- **预算控制**: 在指定预算内选择最优优先级
- **计算单元优化**: 根据交易复杂度动态调整计算单元
- **成本效益分析**: 平衡费用和确认时间

### 3. 网络监控
- **拥堵检测**: 实时监控网络拥堵状态
- **性能统计**: 获取优先费统计信息
- **确认时间预测**: 基于网络状态预测交易确认时间

## 核心组件

### SolanaWalletService
增强的Solana钱包服务，提供：

```dart
// 估算交易费用
Future<SolanaTransactionFee> estimateTransactionFee({
  required String mnemonic,
  required String toAddress,
  required double amount,
  required SolanaTransactionPriority priority,
  int? customComputeUnits,
  int? customComputeUnitPrice,
});

// 获取所有优先级的费用估算
Future<Map<SolanaTransactionPriority, SolanaTransactionFee>> getAllPriorityFees({
  required String mnemonic,
  required String toAddress,
  required double amount,
});

// 获取网络状态
Future<Map<String, dynamic>> getNetworkStatus();

// 优化交易费用
Future<SolanaTransactionFee> optimizeTransactionFee({
  required String mnemonic,
  required String toAddress,
  required double amount,
  required double maxFeeInSol,
});

// 预测确认时间
Future<Map<SolanaTransactionPriority, Duration>> predictConfirmationTimes();
```

### SolanaTransactionFee模型
详细的费用信息结构：

```dart
class SolanaTransactionFee {
  final int baseFee;              // 基础手续费 (lamports)
  final int priorityFee;          // 优先费 (lamports)
  final int totalFee;             // 总手续费 (lamports)
  final double priorityMultiplier; // 优先费倍数
  final int computeUnits;         // 计算单元
  final int computeUnitPrice;     // 计算单元价格 (微lamports)
}
```

### 优先级系统
四个优先级级别：

- **低优先级 (Low)**: 1.0x 倍数，适合非紧急交易
- **中等优先级 (Medium)**: 1.5x 倍数，平衡费用和速度
- **高优先级 (High)**: 2.5x 倍数，快速确认
- **极高优先级 (VeryHigh)**: 4.0x 倍数，最快确认

## 使用示例

### 1. 基本费用估算

```dart
final walletProvider = Provider.of<WalletProvider>(context, listen: false);

// 获取所有优先级的费用估算
final feeEstimates = await walletProvider.getSolanaFeeEstimates(
  toAddress: 'recipient_address',
  amount: 0.1, // SOL
);

// 显示不同优先级的费用
for (final entry in feeEstimates.entries) {
  final priority = entry.key;
  final fee = entry.value;
  print('${priority.name}: ${fee.totalFee} lamports');
}
```

### 2. 费用优化

```dart
// 在预算内优化费用
final optimizedFee = await walletProvider.optimizeSolanaFee(
  toAddress: 'recipient_address',
  amount: 0.1,
  maxFeeInSol: 0.001, // 最大费用 0.001 SOL
);

print('优化后费用: ${optimizedFee.totalFee} lamports');
```

### 3. 发送交易

```dart
// 发送带有自定义优先费的交易
final transaction = await walletProvider.sendSolanaTransaction(
  toAddress: 'recipient_address',
  amount: 0.1,
  priority: SolanaTransactionPriority.high,
  memo: '转账备注',
  customComputeUnits: 150, // 可选：自定义计算单元
  customComputeUnitPrice: 5000, // 可选：自定义单元价格
);

print('交易签名: ${transaction.signature}');
```

### 4. 网络状态监控

```dart
// 获取网络状态
final networkStatus = await walletProvider.getSolanaNetworkStatus();

final congestionLevel = networkStatus['congestionLevel'];
final recommendedPriority = networkStatus['recommendedPriority'];

print('网络拥堵级别: $congestionLevel');
print('推荐优先级: $recommendedPriority');
```

## 费用计算逻辑

### 基础费用
- 每个签名收取 5,000 lamports 的基础费用
- 简单转账通常只需要一个签名

### 优先费计算
1. **获取网络统计**: 查询最近的优先费统计信息
2. **拥堵检测**: 分析网络性能数据计算拥堵倍数
3. **优先级调整**: 根据用户选择的优先级应用倍数
4. **计算单元**: 估算交易所需的计算单元数量
5. **最终费用**: 优先费 = 计算单元 × 单元价格 / 1,000,000

### 网络拥堵级别
- **无拥堵**: 交易/槽位比例 < 40%
- **轻微拥堵**: 40% ≤ 比例 < 60%
- **中等拥堵**: 60% ≤ 比例 < 80%
- **高拥堵**: 比例 ≥ 80%

## 最佳实践

### 1. 费用选择建议
- **日常转账**: 使用低或中等优先级
- **时间敏感**: 使用高优先级
- **紧急交易**: 使用极高优先级
- **网络拥堵时**: 参考系统推荐的优先级

### 2. 成本优化
- 在非高峰时段进行交易
- 使用费用优化功能在预算内选择最佳优先级
- 监控网络状态，选择合适的交易时机

### 3. 用户体验
- 显示预估确认时间帮助用户选择
- 提供费用对比让用户了解不同选项
- 在网络拥堵时给出明确提示

## 技术实现细节

### 计算预算指令
系统自动添加计算预算指令来优化交易：

```dart
// 设置计算单元限制
ComputeBudgetInstruction.setComputeUnitLimit(units: computeUnits)

// 设置计算单元价格（优先费）
ComputeBudgetInstruction.setComputeUnitPrice(microLamports: priorityFee)
```

### 错误处理
- 网络请求失败时使用默认费用
- 提供重试机制处理临时网络问题
- 优雅降级确保基本功能可用

### 性能优化
- 缓存网络状态减少重复请求
- 异步处理避免阻塞UI
- 批量获取多个优先级的费用估算

## 界面集成

项目包含了一个完整的费用估算界面 (`SolanaFeeEstimatorScreen`)，提供：

- 实时网络状态显示
- 交易信息输入表单
- 多优先级费用对比
- 费用优化功能
- 确认时间预测

这个界面可以作为独立工具使用，也可以集成到转账流程中。

## 总结

完善的Solana gas费和优先费功能为用户提供了：
- 透明的费用信息
- 灵活的优先级选择
- 智能的费用优化
- 实时的网络监控

这些功能确保用户能够在成本和速度之间做出明智的选择，提升整体的交易体验。