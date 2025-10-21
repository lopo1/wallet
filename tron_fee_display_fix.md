# TRON 费用显示修复

## 问题描述

在 TRON 网络的发送界面中，费用显示区域出现了源代码文本：

```
0.10000000 TRX
${(gasFee * _getTokenPrice(network?.id ?? 
)).toStringAsFixed(5)}
```

## 问题原因

在 `_buildStandardFeeDisplay()` 方法中，USD 价格计算的字符串被错误地分成了两行：

```dart
Text(
  '\${(gasFee * _getTokenPrice(network?.id ?? '
  ')).toStringAsFixed(5)}',  // 字符串被分成两行
  ...
)
```

这导致字符串拼接不正确，显示了部分源代码。

## 修复方案

将字符串合并为一行：

```dart
Text(
  '\${(gasFee * _getTokenPrice(network?.id ?? '')).toStringAsFixed(5)}',
  style: const TextStyle(
    color: Colors.white54,
    fontSize: 14,
  ),
)
```

## 修复位置

**文件**: `lib/screens/send_detail_screen.dart`
**方法**: `_buildStandardFeeDisplay()`
**行号**: 约 1014-1016 行

## 修复后效果

现在费用显示应该正确显示为：

```
0.10000000 TRX
$0.01000
```

## 验证步骤

1. 打开发送界面
2. 选择 TRON 网络
3. 不输入收款地址（或输入地址）
4. 查看手续费显示
5. 确认显示正常的 USD 价格，而不是源代码

## 相关问题

### 为什么会出现"未提供目标地址，返回基础费用估算"的日志？

这是正常的行为。当用户还没有输入收款地址时，系统会：
1. 使用默认的基础费用估算（0.1 TRX）
2. 不显示详细的 TRON 费用明细
3. 显示标准费用界面

这个日志只是调试信息，不会影响用户体验。

### 如何触发详细的 TRON 费用显示？

当满足以下条件时，会显示详细的 TRON 费用明细：
1. 网络是 TRON
2. 用户已输入收款地址
3. 费用估算成功完成
4. `_tronFeeEstimate` 不为 null

## 代码改进建议

### 1. 避免字符串分行

在 Dart 中，如果字符串太长，建议使用以下方式：

```dart
// 方式 1: 使用字符串插值
final priceText = '\${(gasFee * _getTokenPrice(network?.id ?? '')).toStringAsFixed(5)}';

// 方式 2: 提前计算
final usdPrice = gasFee * _getTokenPrice(network?.id ?? '');
final priceText = '\$${usdPrice.toStringAsFixed(5)}';
```

### 2. 添加空值检查

```dart
final tokenPrice = _getTokenPrice(network?.id ?? '');
final usdPrice = gasFee * tokenPrice;
Text('\$${usdPrice.toStringAsFixed(5)}')
```

### 3. 使用常量

```dart
static const defaultTokenPrice = 1.0;

double _getTokenPrice(String networkId) {
  if (networkId.isEmpty) return defaultTokenPrice;
  // ... 其他逻辑
}
```

## 测试建议

### 测试场景 1: 无收款地址
1. 打开发送界面
2. 选择 TRON 网络
3. 不输入收款地址
4. 验证显示: `0.10000000 TRX` 和正确的 USD 价格

### 测试场景 2: 有收款地址（已激活）
1. 打开发送界面
2. 选择 TRON 网络
3. 输入已激活的地址
4. 验证显示: 详细的费用明细（带宽、总费用等）

### 测试场景 3: 有收款地址（未激活）
1. 打开发送界面
2. 选择 TRON 网络
3. 输入未激活的地址
4. 验证显示: 详细的费用明细 + 激活警告

### 测试场景 4: TRC20 转账
1. 打开发送界面
2. 选择 TRON 网络
3. 选择 TRC20 代币
4. 输入收款地址
5. 验证显示: 详细的费用明细（带宽 + 能量）

## 总结

这是一个简单的字符串格式问题，已通过合并字符串行修复。修复后，TRON 网络的费用显示应该正常工作，不再显示源代码文本。
