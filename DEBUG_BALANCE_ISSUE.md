# 余额不足问题调试指南

## 问题描述

从用户截图看到：
- 页面顶部显示：可用 0.25 BNB
- 点击"全部"后设置的金额：0.24554096 BNB
- Gas费：0.00000231 BNB
- 错误信息显示：
  - 需要：0.24554327 BNB
  - 可用：0.24554327 BNB

**问题**：需要和可用的金额完全相同，但仍然提示余额不足。

## 可能的原因

### 1. 余额值不一致
页面顶部显示 0.25 BNB，但错误信息显示可用 0.24554327 BNB。这说明：
- `balance` 变量的实际值可能是 0.24554327
- 页面顶部显示使用了 `toStringAsFixed(2)`，所以显示为 0.25

### 2. 精度问题（已通过 Decimal 解决）
虽然我们已经使用了 Decimal，但如果 `balance` 和 `gasFee` 的原始值就是错误的，Decimal 也无法修复。

### 3. 余额获取问题
`getNetworkBalance()` 方法可能返回了错误的值。

## 调试步骤

### 步骤1：查看调试日志

运行应用后，查看控制台输出：

```
=== 加载余额 ===
网络: bsc
地址: 0x...
获取到的余额: 0.25
设置后的余额: 0.25
```

**检查点**：
- 获取到的余额是否正确？
- 设置后的余额是否与获取到的一致？

### 步骤2：点击"全部"按钮

查看控制台输出：

```
=== 点击全部按钮 ===
当前余额: 0.25000000 (原始: 0.25)
Gas费用: 0.00000231 (原始: 0.00000231)
最大金额: 0.24999769
验证: 最大金额 + Gas = 0.25000000
验证: 是否 <= 余额? true
```

**检查点**：
- 当前余额是否正确？
- 最大金额计算是否正确？
- 验证结果是否为 true？

### 步骤3：点击"下一步"

查看控制台输出：

```
=== 余额验证 ===
输入金额: 0.24999769
Gas费用: 0.00000231
需要总额: 0.25000000
当前余额: 0.25000000
余额充足: true
```

**检查点**：
- 输入金额是否与"全部"设置的一致？
- 当前余额是否正确？
- 余额充足的判断是否正确？

## 可能的问题和解决方案

### 问题1：余额获取返回错误值

**症状**：
- 页面显示 0.25 BNB
- 但实际 `balance` 变量是 0.24554327

**原因**：
`getNetworkBalance()` 方法可能返回了错误的值，或者在某个地方被修改了。

**解决方案**：
检查 `WalletProvider.getNetworkBalance()` 的实现，确保返回正确的余额。

### 问题2：Gas费用在点击"全部"后变化

**症状**：
- 点击"全部"时 Gas 费用是 A
- 验证时 Gas 费用变成了 B
- 导致总金额超过余额

**原因**：
Gas 费用每8秒自动刷新，可能在用户操作期间发生变化。

**解决方案**：
在点击"全部"时锁定 Gas 费用，不再自动刷新，直到用户修改金额或取消。

```dart
bool _gasFeeLocked = false;

void _setMaxAmount() {
  // ... 计算最大金额 ...
  
  setState(() {
    _amountController.text = AmountUtils.format(maxAmountDecimal);
    _gasFeeLocked = true; // 锁定 Gas 费用
    errorMessage = '';
  });
}

void _startGasRefreshTimer() {
  _gasRefreshTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
    if (!_gasFeeLocked) { // 只在未锁定时刷新
      _loadGasFee();
    }
  });
}
```

### 问题3：Decimal 比较问题

**症状**：
两个看起来相同的 Decimal 值比较时不相等。

**原因**：
虽然 Decimal 避免了浮点数精度问题，但如果原始值就有问题，Decimal 也无法修复。

**解决方案**：
确保所有金额都使用 Decimal 进行计算和存储。

```dart
// 不好的做法
double balance = 0.25;
final balanceDecimal = AmountUtils.fromDouble(balance);

// 好的做法
Decimal balance = Decimal.parse('0.25');
```

## 临时解决方案

如果问题持续存在，可以使用以下临时解决方案：

### 方案1：添加小的容差

```dart
if (AmountUtils.greaterThan(totalRequired, balanceDecimal)) {
  // 添加一个极小的容差（1 Satoshi）
  final tolerance = Decimal.parse('0.00000001');
  final balanceWithTolerance = AmountUtils.add(balanceDecimal, tolerance);
  
  if (AmountUtils.greaterThan(totalRequired, balanceWithTolerance)) {
    setState(() {
      errorMessage = '余额不足（包含手续费）\n需要: ${AmountUtils.format(totalRequired)}\n可用: ${AmountUtils.format(balanceDecimal)}';
    });
    return false;
  }
}
```

### 方案2：在"全部"时预留更多余量

```dart
void _setMaxAmount() {
  final balanceDecimal = AmountUtils.fromDouble(balance);
  final gasFeeDecimal = AmountUtils.fromDouble(gasFee);
  
  // 预留额外的 0.1% 作为安全边界
  final safetyMargin = AmountUtils.multiply(balanceDecimal, 0.001);
  final maxAmountDecimal = AmountUtils.subtract(
    AmountUtils.subtract(balanceDecimal, gasFeeDecimal),
    safetyMargin,
  );
  
  if (AmountUtils.isPositive(maxAmountDecimal)) {
    setState(() {
      _amountController.text = AmountUtils.format(maxAmountDecimal);
      errorMessage = '';
    });
  }
}
```

## 建议的修复

### 1. 锁定 Gas 费用

在点击"全部"后，锁定 Gas 费用不再自动刷新：

```dart
bool _gasFeeLocked = false;
double _lockedGasFee = 0.0;

void _setMaxAmount() {
  final balanceDecimal = AmountUtils.fromDouble(balance);
  final gasFeeDecimal = AmountUtils.fromDouble(gasFee);
  final maxAmountDecimal = AmountUtils.calculateMaxSendAmount(balanceDecimal, gasFeeDecimal);

  if (AmountUtils.isPositive(maxAmountDecimal)) {
    setState(() {
      _amountController.text = AmountUtils.format(maxAmountDecimal);
      _gasFeeLocked = true;
      _lockedGasFee = gasFee; // 保存当前的 Gas 费用
      errorMessage = '';
    });
  }
}

// 在用户修改金额时解锁
TextField(
  controller: _amountController,
  onChanged: (value) {
    setState(() {
      _gasFeeLocked = false; // 解锁 Gas 费用
    });
    _loadGasFee(); // 重新计算
  },
)
```

### 2. 使用 Decimal 存储余额

修改 `balance` 和 `gasFee` 的类型：

```dart
Decimal balance = Decimal.zero;
Decimal gasFee = Decimal.parse('0.00000496');

// 加载余额时
setState(() {
  balance = Decimal.parse(realBalance.toString());
});

// 显示时
Text('可用: ${AmountUtils.format(balance, decimals: 2)} ${network?.symbol}')
```

### 3. 添加详细的错误信息

```dart
if (AmountUtils.greaterThan(totalRequired, balanceDecimal)) {
  final difference = AmountUtils.subtract(totalRequired, balanceDecimal);
  setState(() {
    errorMessage =
        '余额不足（包含手续费）\n'
        '需要: ${AmountUtils.format(totalRequired)}\n'
        '可用: ${AmountUtils.format(balanceDecimal)}\n'
        '差额: ${AmountUtils.format(difference)}';
  });
  return false;
}
```

## 测试步骤

1. **清理并重新构建**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **测试场景1：正常发送**
   - 输入小于余额的金额
   - 点击"下一步"
   - 应该成功

3. **测试场景2：全部按钮**
   - 点击"全部"
   - 等待5秒（确保 Gas 不变）
   - 点击"下一步"
   - 应该成功

4. **测试场景3：Gas 变化**
   - 点击"全部"
   - 等待10秒（让 Gas 刷新）
   - 点击"下一步"
   - 检查是否仍然成功

## 下一步

1. 运行应用并查看调试日志
2. 根据日志确定问题所在
3. 应用相应的修复方案
4. 重新测试

---

**创建时间**: 2025-10-14  
**状态**: 待调试
