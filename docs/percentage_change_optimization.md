# 涨幅显示优化

## 需求描述

用户要求优化assets列表中的涨幅显示：
1. **尽量不要使用省略号**
2. **移除尾部的0**（如23.300% → 23.3%）

## 解决方案

### 1. 优化formatPercentageChange方法

#### 移除尾部0的逻辑
```dart
/// 格式化百分比变化（移除尾部的0）
static String formatPercentageChange(double change) {
  // 先检查特殊值
  if (change.isNaN || change.isInfinite) {
    return '0%';
  }

  // 格式化为2位小数
  String formatted = change.toStringAsFixed(2);

  // 移除尾部的0和小数点
  if (formatted.contains('.')) {
    formatted = formatted.replaceAll(RegExp(r'0+$'), '');
    formatted = formatted.replaceAll(RegExp(r'\.$'), '');
  }

  // 特殊处理0的情况
  if (change == 0.0 || formatted == '0') {
    return '0%';
  }

  return '${change > 0 ? '+' : ''}$formatted%';
}
```

#### 格式化效果对比
| 输入值 | 修改前 | 修改后 |
|--------|--------|--------|
| 23.300 | +23.30% | +23.3% |
| 23.000 | +23.00% | +23% |
| -1.500 | -1.50% | -1.5% |
| -2.000 | -2.00% | -2% |
| 23.450 | +23.45% | +23.45% |
| 0.000 | +0.00% | 0% |

### 2. 优化涨跌标签布局

#### 移除省略号设置
```dart
// 修改前
Flexible(
  child: Text(
    FormatUtils.formatChange(change24h),
    overflow: TextOverflow.ellipsis,  // 使用省略号
  ),
),

// 修改后
Text(
  FormatUtils.formatChange(change24h),
  // 移除overflow设置，让文本完整显示
),
```

#### 调整容器和字体大小
```dart
// 修改前
Container(
  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  child: Row(
    children: [
      Icon(size: 12),
      SizedBox(width: 2),
      Flexible(child: Text(fontSize: 11)),
    ],
  ),
),

// 修改后
Container(
  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),  // 减少padding
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(size: 10),  // 减小图标
      SizedBox(width: 2),
      Text(fontSize: 10),  // 减小字体，移除Flexible
    ],
  ),
),
```

#### 调整第二行空间分配
```dart
// 修改前
Row(
  children: [
    Flexible(flex: 2, child: Text(price)),
    SizedBox(width: 8),
    Flexible(flex: 1, child: changeWidget),
  ],
)

// 修改后
Row(
  children: [
    Expanded(child: Text(price)),  // 给币价更多空间
    SizedBox(width: 6),            // 减少间距
    changeWidget,                  // 涨跌标签使用自然宽度
  ],
)
```

## 技术改进

### 1. 字符串处理优化
- **正则表达式**：使用`RegExp(r'0+$')`移除尾部0
- **小数点处理**：使用`RegExp(r'\.$')`移除多余小数点
- **特殊值处理**：0值不显示+号

### 2. 布局空间优化
- **减少padding**：从6px减少到4px
- **减小图标**：从12px减少到10px
- **减小字体**：从11px减少到10px
- **移除Flexible**：让涨跌标签使用自然宽度

### 3. 显示逻辑优化
- **移除省略号**：确保涨幅数据完整显示
- **智能缩放**：通过减小元素尺寸来适应空间
- **自然宽度**：涨跌标签不再强制适应固定空间

## 测试验证

### 单元测试覆盖
```dart
test('formatPercentageChange should remove trailing zeros', () {
  expect(AmountUtils.formatPercentageChange(23.30), '+23.3%');
  expect(AmountUtils.formatPercentageChange(23.00), '+23%');
  expect(AmountUtils.formatPercentageChange(-1.50), '-1.5%');
  expect(AmountUtils.formatPercentageChange(-2.00), '-2%');
  expect(AmountUtils.formatPercentageChange(0), '0%');
});
```

### 边界情况测试
- ✅ 正数显示+号
- ✅ 负数显示-号
- ✅ 0不显示+号
- ✅ 移除尾部0
- ✅ 保留必要小数
- ✅ 处理特殊值（NaN, Infinity）

## 用户体验提升

### 1. 更清晰的数据显示
```
修改前：+23.30%  (可能被省略为 +23.3...)
修改后：+23.3%   (完整显示，更简洁)
```

### 2. 更紧凑的布局
- 减少了不必要的空间占用
- 涨跌标签更加紧凑
- 为其他内容留出更多空间

### 3. 更好的可读性
- 移除了多余的0，数据更简洁
- 完整显示涨跌数据，无省略号
- 视觉上更加清晰

## 实际效果

### Assets列表项显示
```
[图标] ETH                        1.123456789 ETH
      $2000.0000  +2.3%          $2,469.00
```

- **币价**：完整显示4位小数
- **涨跌**：简化显示，移除尾部0，无省略号
- **余额**：完整显示，最多9位小数
- **价值**：固定2位小数

这样的优化让涨幅显示更加简洁明了，同时确保数据的完整性。