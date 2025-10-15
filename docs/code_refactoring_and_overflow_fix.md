# 代码重构和UI溢出修复

## 问题描述

用户反馈了两个主要问题：
1. **Assets列表出现UI溢出**
2. **格式化方法代码冗余**，需要提取到utils中减少重复

## 解决方案

### 1. Assets列表UI溢出修复

#### 问题分析
- 余额和价值显示在小屏幕或大数值时可能溢出
- 缺少自适应缩放机制

#### 解决方案
为余额和价值显示添加`Flexible`和`FittedBox`包装：

```dart
// 修改前
Column(
  crossAxisAlignment: CrossAxisAlignment.end,
  children: [
    Text(isBalanceHidden ? '****' : _formatBalance(balance)),
    Text(isBalanceHidden ? '****' : _formatValue(value)),
  ],
),

// 修改后
Flexible(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(isBalanceHidden ? '****' : FormatUtils.formatBalance(balance)),
      ),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(isBalanceHidden ? '****' : FormatUtils.formatValue(value)),
      ),
    ],
  ),
),
```

### 2. 格式化方法重构

#### 问题分析
- HomeScreen中有重复的格式化方法
- 其他页面无法复用这些方法
- 代码维护困难

#### 解决方案

##### 2.1 在AmountUtils中添加FormatUtils工具类

```dart
/// 格式化工具类 - 提供便捷的静态方法
class FormatUtils {
  /// 格式化美元价值显示（固定2位小数）
  static String formatValue(double value) {
    return AmountUtils.formatUsdValue(value);
  }

  /// 格式化代币余额显示（最多9位小数）
  static String formatBalance(double balance) {
    return AmountUtils.formatTokenBalance(balance);
  }

  /// 格式化币价显示（4位小数或科学计数法）
  static String formatPrice(double price) {
    return AmountUtils.formatPrice(price);
  }

  /// 格式化百分比变化
  static String formatChange(double change) {
    return AmountUtils.formatPercentageChange(change);
  }
}
```

##### 2.2 删除HomeScreen中的冗余方法

删除了以下方法：
- `_formatValue(double value)`
- `_formatBalance(double balance)`
- `_formatPrice(double price)`
- `_formatChange(double change)`

##### 2.3 替换所有方法调用

将所有格式化方法调用替换为FormatUtils的静态方法：

```dart
// 修改前
_formatValue(_totalPortfolioValue)
_formatBalance(balance)
_formatPrice(asset['price'] as double)
_formatChange(change24h)

// 修改后
FormatUtils.formatValue(_totalPortfolioValue)
FormatUtils.formatBalance(balance)
FormatUtils.formatPrice(asset['price'] as double)
FormatUtils.formatChange(change24h)
```

## 技术优势

### 1. UI溢出防护
- **Flexible包装**：允许组件在空间不足时自适应
- **FittedBox缩放**：自动缩小内容以适应可用空间
- **响应式设计**：适应不同屏幕尺寸和数值大小

### 2. 代码复用性
- **统一入口**：所有格式化逻辑集中在FormatUtils
- **易于维护**：修改格式化逻辑只需更新一处
- **跨页面复用**：其他页面可直接使用FormatUtils

### 3. 代码简洁性
- **减少冗余**：删除了HomeScreen中的重复方法
- **清晰职责**：格式化逻辑与UI逻辑分离
- **更好的可读性**：方法调用更加直观

## 修改详情

### 1. Assets列表项结构优化

```dart
Row(
  children: [
    // 资产图标
    TokenWithNetworkIcon(...),
    
    // 资产信息（已有Expanded包装）
    Expanded(
      child: Column(
        children: [
          // Symbol和标签
          Row(children: [...]),
          // 币价和涨跌
          Row(children: [...]),
        ],
      ),
    ),
    
    // 余额和价值（新增Flexible包装）
    Flexible(
      child: Column(
        children: [
          FittedBox(child: Text(余额)),
          FittedBox(child: Text(价值)),
        ],
      ),
    ),
  ],
)
```

### 2. 格式化方法映射

| 原方法 | 新方法 | 功能 |
|--------|--------|------|
| `_formatValue()` | `FormatUtils.formatValue()` | 美元价值，2位小数 |
| `_formatBalance()` | `FormatUtils.formatBalance()` | 代币余额，最多9位小数 |
| `_formatPrice()` | `FormatUtils.formatPrice()` | 币价，4位小数 |
| `_formatChange()` | `FormatUtils.formatChange()` | 百分比变化 |

## 测试验证

- ✅ 所有单元测试通过
- ✅ 语法检查无错误
- ✅ 格式化功能正常
- ✅ UI溢出问题解决

## 使用示例

```dart
// 在任何页面中使用
import '../utils/amount_utils.dart';

// 格式化美元价值
String value = FormatUtils.formatValue(1234.56);  // "$1234.56"

// 格式化代币余额
String balance = FormatUtils.formatBalance(1.123456789);  // "1.123456789"

// 格式化币价
String price = FormatUtils.formatPrice(0.1234);  // "$0.1234"

// 格式化变化百分比
String change = FormatUtils.formatChange(2.34);  // "+2.34%"
```

这样的重构提高了代码的可维护性、复用性和用户体验，同时解决了UI溢出问题。