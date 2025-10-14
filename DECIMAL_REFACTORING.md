# 使用 Decimal 重构余额计算

## 重构时间
2025-10-14

## 重构目标

使用 `Decimal` 类型替代 `double` 进行金额计算，彻底解决浮点数精度问题。

## 问题背景

### 浮点数精度问题

JavaScript/Dart 使用 IEEE 754 双精度浮点数标准，存在固有的精度问题：

```dart
// 问题示例
print(0.1 + 0.2);  // 输出: 0.30000000000000004
print(0.1 + 0.2 == 0.3);  // 输出: false

// 实际场景
final balance = 0.12345678;
final gasFee = 0.00000496;
final maxAmount = balance - gasFee;  // 0.12345182
final total = maxAmount + gasFee;    // 0.12345678000000001 (!)
print(total == balance);  // false
```

### 影响

1. **"全部"按钮问题**：计算的最大金额加上手续费可能略大于余额
2. **余额验证失败**：由于精度误差导致验证失败
3. **用户体验差**：明明余额足够却提示余额不足

## 解决方案

### 1. 添加 Decimal 依赖

```yaml
# pubspec.yaml
dependencies:
  decimal: ^2.3.3
```

### 2. 创建 AmountUtils 工具类

创建 `lib/utils/amount_utils.dart`，提供：

#### 基本运算
- `add()` - 加法
- `subtract()` - 减法
- `multiply()` - 乘法
- `divide()` - 除法

#### 比较运算
- `greaterThan()` - 大于
- `greaterThanOrEqual()` - 大于等于
- `lessThan()` - 小于
- `lessThanOrEqual()` - 小于等于
- `equals()` - 等于

#### 格式化
- `format()` - 格式化为固定小数位
- `formatCompact()` - 紧凑格式化（移除尾部0）

#### 余额计算
- `calculateMaxSendAmount()` - 计算最大发送金额
- `isSufficientBalance()` - 验证余额是否足够

#### 单位转换
- `lamportsToSol()` / `solToLamports()` - Solana
- `weiToEth()` / `ethToWei()` - Ethereum
- `satoshiToBtc()` / `btcToSatoshi()` - Bitcoin

### 3. 更新 SendDetailScreen

#### 修改前（使用 double）

```dart
bool _validateInput() {
  final amount = double.tryParse(_amountController.text);
  final totalRequired = amount + gasFee;
  const tolerance = 0.00000001; // 需要容差
  
  if (totalRequired > balance + tolerance) {
    // 余额不足
  }
}

void _setMaxAmount() {
  final maxAmount = balance - gasFee;
  final safeAmount = maxAmount - 0.00000001; // 需要安全边界
  _amountController.text = safeAmount.toStringAsFixed(8);
}
```

#### 修改后（使用 Decimal）

```dart
bool _validateInput() {
  final amountDecimal = AmountUtils.fromString(_amountController.text);
  
  // 不需要容差，Decimal 精确计算
  if (!AmountUtils.isSufficientBalance(amountDecimal, gasFee, balance)) {
    // 余额不足
  }
}

void _setMaxAmount() {
  // 不需要安全边界，Decimal 精确计算
  final maxAmountDecimal = AmountUtils.calculateMaxSendAmount(balance, gasFee);
  _amountController.text = AmountUtils.format(maxAmountDecimal);
}
```

## 技术细节

### Decimal vs Double

| 特性 | Double | Decimal |
|------|--------|---------|
| 精度 | 有限（约15-17位） | 任意精度 |
| 0.1 + 0.2 | 0.30000000000000004 | 0.3 |
| 性能 | 快 | 较慢 |
| 内存 | 8字节 | 可变 |
| 适用场景 | 科学计算 | 金融计算 |

### 为什么选择 Decimal

1. **精确性**：金融计算需要绝对精确
2. **可预测性**：结果符合数学期望
3. **安全性**：避免精度误差导致的安全问题
4. **标准化**：金融行业标准做法

### Decimal 的限制

1. **性能**：比 double 慢（但对于钱包应用可接受）
2. **除法**：返回 Rational 类型，需要 `.toDecimal()` 转换
3. **序列化**：需要转换为 String 或 double 进行存储

## 测试验证

### 测试覆盖

创建了 `test/utils/amount_utils_test.dart`，包含 35 个测试用例：

1. **基本运算测试**（5个）
   - 加减乘除
   - 除以零异常

2. **比较运算测试**（5个）
   - 大于、小于、等于等

3. **格式化测试**（2个）
   - 固定小数位
   - 紧凑格式

4. **状态检查测试**（3个）
   - 零、正数、负数

5. **最大/最小值测试**（3个）
   - min、max、abs

6. **余额计算测试**（4个）
   - 最大发送金额
   - 余额验证

7. **浮点数精度问题测试**（3个）
   - 0.1 + 0.2 = 0.3
   - 余额往返计算
   - 全部按钮场景

8. **单位转换测试**（6个）
   - Solana、Ethereum、Bitcoin

9. **边界情况测试**（4个）
   - 极小数字、极大数字
   - 字符串输入、无效输入

### 测试结果

```bash
$ flutter test test/utils/amount_utils_test.dart
00:04 +35: All tests passed!
```

✅ **所有 35 个测试用例全部通过！**

## 使用示例

### 基本使用

```dart
import 'package:decimal/decimal.dart';
import '../utils/amount_utils.dart';

// 加法（精确）
final result = AmountUtils.add(0.1, 0.2);
print(AmountUtils.toDouble(result));  // 0.3

// 比较
if (AmountUtils.greaterThan(balance, amount)) {
  // 余额充足
}

// 格式化
final formatted = AmountUtils.format(0.123456789, decimals: 8);
print(formatted);  // "0.12345679"
```

### 余额计算

```dart
// 计算最大发送金额
final balance = 0.12345678;
final gasFee = 0.00000496;
final maxAmount = AmountUtils.calculateMaxSendAmount(balance, gasFee);

// 验证余额
final amount = 0.1;
if (AmountUtils.isSufficientBalance(amount, gasFee, balance)) {
  // 可以发送
}
```

### 单位转换

```dart
// Solana: Lamports <-> SOL
final lamports = 1000000000;
final sol = AmountUtils.lamportsToSol(lamports);  // 1.0 SOL
final backToLamports = AmountUtils.solToLamports(sol);  // 1000000000

// Ethereum: Wei <-> ETH
final wei = BigInt.from(10).pow(18);
final eth = AmountUtils.weiToEth(wei);  // 1.0 ETH
final backToWei = AmountUtils.ethToWei(eth);  // 10^18
```

## 性能考虑

### 性能对比

```dart
// Double 运算（快）
final result1 = 0.1 + 0.2;  // ~1ns

// Decimal 运算（较慢）
final result2 = AmountUtils.add(0.1, 0.2);  // ~100ns
```

### 性能优化建议

1. **仅在关键计算中使用 Decimal**
   - 余额验证
   - 金额计算
   - 交易构建

2. **显示时转换为 double**
   ```dart
   final displayValue = AmountUtils.toDouble(decimalValue);
   ```

3. **批量计算时复用 Decimal 对象**
   ```dart
   final balanceDecimal = AmountUtils.fromDouble(balance);
   // 多次使用 balanceDecimal
   ```

## 迁移指南

### 步骤1：添加依赖

```bash
flutter pub add decimal
```

### 步骤2：导入工具类

```dart
import 'package:decimal/decimal.dart';
import '../utils/amount_utils.dart';
```

### 步骤3：替换计算逻辑

```dart
// 旧代码
final total = amount + gasFee;
if (total > balance) { }

// 新代码
if (!AmountUtils.isSufficientBalance(amount, gasFee, balance)) { }
```

### 步骤4：更新格式化

```dart
// 旧代码
final text = amount.toStringAsFixed(8);

// 新代码
final text = AmountUtils.format(amount, decimals: 8);
```

## 影响范围

### 已更新的文件

1. ✅ `pubspec.yaml` - 添加 decimal 依赖
2. ✅ `lib/utils/amount_utils.dart` - 新建工具类
3. ✅ `lib/screens/send_detail_screen.dart` - 更新余额计算
4. ✅ `test/utils/amount_utils_test.dart` - 新建测试

### 需要更新的文件（建议）

1. ⚠️ `lib/providers/wallet_provider.dart` - 余额获取和计算
2. ⚠️ `lib/screens/home_screen.dart` - 余额显示
3. ⚠️ `lib/services/solana_wallet_service.dart` - Solana 金额计算
4. ⚠️ 其他涉及金额计算的文件

## 后续优化建议

### 1. 全面迁移

将所有金额相关的计算都迁移到 Decimal：

```dart
class WalletProvider {
  // 使用 Decimal 存储余额
  Map<String, Decimal> _balances = {};
  
  // 获取余额（返回 Decimal）
  Decimal getBalance(String networkId) {
    return _balances[networkId] ?? Decimal.zero;
  }
  
  // 显示余额（转换为 double）
  double getDisplayBalance(String networkId) {
    return AmountUtils.toDouble(getBalance(networkId));
  }
}
```

### 2. 创建 Amount 类

封装金额和单位：

```dart
class Amount {
  final Decimal value;
  final String unit;  // 'SOL', 'ETH', 'BTC', etc.
  
  Amount(this.value, this.unit);
  
  String format({int decimals = 8}) {
    return '${AmountUtils.format(value, decimals: decimals)} $unit';
  }
  
  Amount operator +(Amount other) {
    if (unit != other.unit) {
      throw ArgumentError('Cannot add different units');
    }
    return Amount(value + other.value, unit);
  }
}
```

### 3. 添加货币转换

```dart
class CurrencyConverter {
  static Decimal toUSD(Decimal amount, String currency) {
    final rate = _getRateToUSD(currency);
    return AmountUtils.multiply(amount, rate);
  }
}
```

## 常见问题

### Q: Decimal 会影响性能吗？
A: 会有一定影响，但对于钱包应用来说完全可以接受。金额计算的准确性远比性能重要。

### Q: 需要更新数据库吗？
A: 不需要。可以继续使用 double 或 String 存储，只在计算时转换为 Decimal。

### Q: 如何处理除法？
A: Decimal 的除法返回 Rational 类型，需要调用 `.toDecimal()` 转换：
```dart
final result = (decimalA / decimalB).toDecimal();
```

### Q: 可以直接比较 Decimal 吗？
A: 可以，但建议使用 AmountUtils 的比较方法以保持一致性：
```dart
// 直接比较
if (decimalA > decimalB) { }

// 推荐方式
if (AmountUtils.greaterThan(decimalA, decimalB)) { }
```

## 总结

✅ **问题已彻底解决**
- 使用 Decimal 替代 double
- 创建了完整的工具类
- 编写了全面的测试
- 更新了发送页面

🎯 **核心优势**
- 精确计算，无精度误差
- 代码更清晰易懂
- 测试覆盖完整
- 易于维护和扩展

📝 **后续工作**
- 逐步迁移其他金额计算
- 考虑创建 Amount 类
- 添加货币转换功能

---

**重构者**: Kiro AI Assistant  
**重构日期**: 2025-10-14  
**版本**: 3.0.0
