# Gas 费用锁定修复

## 问题描述

用户点击"全部"按钮后，点击"下一步"仍然提示余额不足。

**根本原因**：
Gas 费用每8秒自动刷新。当用户点击"全部"后，如果 Gas 费用在用户点击"下一步"之前发生变化，就会导致：
- 原始计算：金额 = 余额 - Gas费A
- 验证时：金额 + Gas费B > 余额（如果 Gas费B > Gas费A）

## 解决方案

### 1. 添加 Gas 费用锁定标志

```dart
bool _gasFeeLocked = false; // Gas 费用锁定标志
```

### 2. 点击"全部"时锁定 Gas 费用

```dart
void _setMaxAmount() {
  // ... 计算最大金额 ...
  
  setState(() {
    _amountController.text = AmountUtils.format(maxAmountDecimal);
    _gasFeeLocked = true; // 锁定 Gas 费用
    errorMessage = '';
  });
  
  debugPrint('Gas 费用已锁定');
}
```

### 3. Gas 刷新定时器检查锁定状态

```dart
void _startGasRefreshTimer() {
  // 倒计时定时器
  _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
    if (!_gasFeeLocked) { // 只在未锁定时更新
      setState(() {
        _gasRefreshCountdown--;
      });
      
      if (_gasRefreshCountdown <= 0) {
        _loadGasFee();
        // ...
      }
    }
  });
  
  // 主刷新定时器
  _gasRefreshTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
    if (!_gasFeeLocked) { // 只在未锁定时刷新
      _loadGasFee();
      // ...
    }
  });
}
```

### 4. 用户修改金额时解锁

```dart
TextField(
  controller: _amountController,
  onChanged: (value) {
    // 解锁 Gas 费用
    setState(() {
      _gasFeeLocked = false;
    });
    _loadGasFee();
  },
)
```

## 工作流程

### 场景1：正常使用

1. 用户打开发送页面
2. Gas 费用每8秒自动刷新 ✅
3. 用户输入金额
4. Gas 费用继续刷新 ✅
5. 用户点击"下一步"
6. 验证通过 ✅

### 场景2：使用"全部"按钮

1. 用户打开发送页面
2. Gas 费用每8秒自动刷新 ✅
3. 用户点击"全部"
4. 计算最大金额 = 余额 - Gas费
5. **Gas 费用被锁定** 🔒
6. 用户等待（Gas 费用不再刷新）
7. 用户点击"下一步"
8. 验证通过 ✅（因为 Gas 费用没有变化）

### 场景3：点击"全部"后修改金额

1. 用户点击"全部"
2. Gas 费用被锁定 🔒
3. 用户修改金额
4. **Gas 费用解锁** 🔓
5. Gas 费用重新开始刷新 ✅
6. 用户点击"下一步"
7. 验证通过 ✅

## 优势

### 1. 解决余额不足问题
- 点击"全部"后 Gas 费用不变
- 确保 金额 + Gas费 = 余额
- 验证时不会出现余额不足

### 2. 保持 Gas 费用实时性
- 正常输入时 Gas 费用仍然自动刷新
- 用户修改金额后 Gas 费用重新刷新
- 不影响正常使用体验

### 3. 用户体验好
- 点击"全部"后立即可以发送
- 不需要担心 Gas 费用变化
- 倒计时停止，用户知道 Gas 已锁定

## 调试信息

### 点击"全部"时

```
=== 点击全部按钮 ===
当前余额: 0.25000000 (原始: 0.25)
Gas费用: 0.00000231 (原始: 0.00000231)
最大金额: 0.24999769
验证: 最大金额 + Gas = 0.25000000
验证: 是否 <= 余额? true
Gas 费用已锁定
```

### 点击"下一步"时

```
=== 余额验证 ===
输入金额: 0.24999769
Gas费用: 0.00000231
需要总额: 0.25000000
当前余额: 0.25000000
余额充足: true
```

## 测试步骤

### 测试1：正常发送
1. 输入金额 0.1
2. 等待10秒（让 Gas 刷新）
3. 点击"下一步"
4. ✅ 应该成功

### 测试2：全部按钮
1. 点击"全部"
2. 观察倒计时停止
3. 等待10秒
4. 点击"下一步"
5. ✅ 应该成功

### 测试3：全部后修改
1. 点击"全部"
2. 修改金额
3. 观察倒计时重新开始
4. 点击"下一步"
5. ✅ 应该成功

### 测试4：Gas 费用变化
1. 点击"全部"
2. 在控制台手动修改 Gas 费用（模拟网络变化）
3. 点击"下一步"
4. ✅ 应该仍然使用锁定的 Gas 费用

## 相关文件

- `lib/screens/send_detail_screen.dart` - 主要修改文件
- `lib/utils/amount_utils.dart` - Decimal 计算工具
- `DEBUG_BALANCE_ISSUE.md` - 调试指南

## 后续优化

### 1. 添加视觉提示

在 Gas 费用区域添加锁定图标：

```dart
Row(
  children: [
    Text('Gas费'),
    if (_gasFeeLocked)
      Icon(Icons.lock, size: 14, color: Colors.amber),
    // ...
  ],
)
```

### 2. 添加解锁按钮

允许用户手动解锁 Gas 费用：

```dart
if (_gasFeeLocked)
  TextButton(
    onPressed: () {
      setState(() {
        _gasFeeLocked = false;
      });
      _loadGasFee();
    },
    child: Text('刷新Gas'),
  )
```

### 3. 添加提示信息

```dart
if (_gasFeeLocked)
  Text(
    'Gas费用已锁定，确保余额充足',
    style: TextStyle(color: Colors.amber, fontSize: 12),
  )
```

## 总结

✅ **问题已解决**
- 点击"全部"后 Gas 费用被锁定
- 不会因为 Gas 变化导致余额不足
- 用户修改金额后自动解锁

🎯 **核心机制**
- 锁定标志控制 Gas 刷新
- 点击"全部"时锁定
- 修改金额时解锁

📝 **用户体验**
- 点击"全部"后可以立即发送
- 不需要担心 Gas 变化
- 正常使用不受影响

---

**修复者**: Kiro AI Assistant  
**修复日期**: 2025-10-14  
**版本**: 3.1.0
