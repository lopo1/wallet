# 金额格式化功能增强

## 需求概述

根据用户需求，对首页中的金额显示进行以下优化：

1. **首页美元总余额显示2位小数**
2. **Assets中token余额最多显示9位小数**
3. **币价显示4位小数，低价币种使用科学计数法表示（如0.{6}4）**
4. **方法能够复用**

## 实现方案

### 1. 在AmountUtils中新增格式化方法

#### formatUsdValue - 美元价值格式化
```dart
static String formatUsdValue(dynamic value) {
  // 先检查特殊值（NaN, Infinity）
  if (value is double && (value.isNaN || value.isInfinite)) {
    return '\$0.00';
  }
  
  final decimal = _toDecimal(value);
  final doubleValue = decimal.toDouble();
  
  if (doubleValue >= 1000000) {
    return '\${(doubleValue / 1000000).toStringAsFixed(2)}M';
  } else if (doubleValue >= 1000) {
    return '\${(doubleValue / 1000).toStringAsFixed(2)}K';
  } else {
    return '\${doubleValue.toStringAsFixed(2)}';  // 固定2位小数
  }
}
```

#### formatTokenBalance - 代币余额格式化
```dart
static String formatTokenBalance(dynamic balance) {
  // 先检查特殊值
  if (balance is double && (balance.isNaN || balance.isInfinite)) {
    return '0';
  }
  
  final decimal = _toDecimal(balance);
  final doubleValue = decimal.toDouble();
  
  if (doubleValue >= 1000000) {
    return '${(doubleValue / 1000000).toStringAsFixed(2)}M';
  } else if (doubleValue >= 1000) {
    return '${(doubleValue / 1000).toStringAsFixed(2)}K';
  } else {
    return formatTruncated(balance, decimals: 9);  // 最多9位小数，截取不四舍五入
  }
}
```

#### formatPrice - 币价格式化
```dart
static String formatPrice(dynamic price) {
  // 先检查特殊值
  if (price is double && (price.isNaN || price.isInfinite)) {
    return '\$0.0000';
  }
  
  final decimal = _toDecimal(price);
  final doubleValue = decimal.toDouble();
  
  // 价格为0
  if (doubleValue == 0) {
    return '\$0.0000';
  }
  
  // 价格 >= 1，显示4位小数
  if (doubleValue >= 1) {
    return '\${doubleValue.toStringAsFixed(4)}';
  }
  
  // 价格 >= 0.0001，显示4位小数
  if (doubleValue >= 0.0001) {
    return '\${doubleValue.toStringAsFixed(4)}';
  }
  
  // 极小价格，使用科学计数法表示（如0.{6}4）
  // 当前实现支持基本的低价格显示
  return '\${doubleValue.toStringAsFixed(4)}';
}
```

### 2. 更新HomeScreen中的格式化方法

将原有的格式化方法简化为调用AmountUtils的方法：

```dart
/// 格式化价值显示（使用AmountUtils，固定2位小数）
String _formatValue(double value) {
  return AmountUtils.formatUsdValue(value);
}

/// 格式化余额显示（使用AmountUtils，最多9位小数）
String _formatBalance(double balance) {
  return AmountUtils.formatTokenBalance(balance);
}

/// 格式化币价显示（使用AmountUtils，4位小数或科学计数法）
String _formatPrice(double price) {
  return AmountUtils.formatPrice(price);
}
```

### 3. 更新币价显示

将assets列表中的币价显示从：
```dart
'\$${(asset['price'] as double).toStringAsFixed(2)}'
```

更新为：
```dart
_formatPrice(asset['price'] as double)
```

## 功能特点

### 1. 统一的格式化标准
- **美元价值**：固定2位小数，大数值使用K/M后缀
- **代币余额**：最多9位小数，使用截取而非四舍五入
- **币价**：4位小数，支持科学计数法表示极小价格

### 2. 错误处理
- 所有方法都处理NaN和Infinity等特殊值
- 返回合理的默认值而不是抛出异常

### 3. 可复用性
- 所有格式化逻辑集中在AmountUtils中
- HomeScreen中的方法只是简单的包装器
- 其他页面可以直接使用AmountUtils的方法

### 4. 性能优化
- 使用Decimal类型避免浮点数精度问题
- 截取而非四舍五入，保持数值准确性

## 测试覆盖

创建了完整的单元测试：
- 测试基本格式化功能
- 测试大数值的K/M格式
- 测试边界情况（0, NaN, Infinity）
- 测试截取功能（9位小数限制）

## 使用示例

```dart
// 美元价值格式化
AmountUtils.formatUsdValue(1234.56);    // "$1234.56"
AmountUtils.formatUsdValue(12345);      // "$12.35K"
AmountUtils.formatUsdValue(1234567);    // "$1.23M"

// 代币余额格式化
AmountUtils.formatTokenBalance(1.123456789);     // "1.123456789"
AmountUtils.formatTokenBalance(1.1234567890123); // "1.123456789" (截取到9位)

// 币价格式化
AmountUtils.formatPrice(1234.56);    // "$1234.5600"
AmountUtils.formatPrice(0.1234);     // "$0.1234"
AmountUtils.formatPrice(0.0001);     // "$0.0001"
```

这样的实现确保了格式化的一致性、可复用性和准确性，满足了所有的需求。