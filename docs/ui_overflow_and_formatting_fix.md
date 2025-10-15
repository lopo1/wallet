# UI溢出和格式化修复

## 问题描述

用户反馈了两个问题：
1. `_formatBalance(_totalPortfolioValue)` 需要显示2位小数
2. 页面存在UI溢出问题

## 问题分析

### 1. 格式化方法使用错误
- `_formatBalance()` 用于代币余额，最多显示9位小数
- `_formatValue()` 用于美元价值，固定显示2位小数
- 总资产价值应该使用 `_formatValue()` 而不是 `_formatBalance()`

### 2. UI溢出问题
- 大数值的总资产显示可能超出屏幕宽度
- 24小时变化显示也可能在小屏幕上溢出
- 需要添加自适应缩放机制

## 解决方案

### 1. 修正格式化方法使用

#### 主要余额显示
```dart
// 修改前
Text(
  '\$${_formatBalance(_totalPortfolioValue)}',  // 错误：显示9位小数
  style: TextStyle(...),
),

// 修改后
FittedBox(
  fit: BoxFit.scaleDown,
  child: Text(
    _formatValue(_totalPortfolioValue),  // 正确：显示2位小数
    style: TextStyle(...),
  ),
),
```

#### 24小时变化显示
```dart
// 修改前
Text(
  '+\$${_formatBalance(_portfolioChange24h)}',  // 错误：显示9位小数
  style: TextStyle(...),
),

// 修改后
Text(
  '+${_formatValue(_portfolioChange24h)}',  // 正确：显示2位小数
  style: TextStyle(...),
),
```

### 2. 添加UI溢出保护

#### 使用FittedBox防止溢出
```dart
FittedBox(
  fit: BoxFit.scaleDown,  // 当内容超出时自动缩放
  child: Text(...),
)
```

#### 应用位置
1. **主要余额显示**：大字体（48-56px）容易溢出
2. **24小时变化行**：包含多个文本元素的Row
3. **钱包切换器中的总资产**：预防性保护

## 修改详情

### 1. 主要余额显示区域
```dart
// 总资产显示
FittedBox(
  fit: BoxFit.scaleDown,
  child: Text(
    _formatValue(_totalPortfolioValue),  // 2位小数
    style: TextStyle(
      fontSize: isMobile ? 48 : 56,  // 大字体
      fontWeight: FontWeight.w700,
    ),
  ),
),

// 24小时变化显示
FittedBox(
  fit: BoxFit.scaleDown,
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text('+${_formatValue(_portfolioChange24h)}'),  // 2位小数
      SizedBox(width: 8),
      Text('+100%'),
    ],
  ),
),
```

### 2. 钱包切换器中的显示
```dart
FittedBox(
  fit: BoxFit.scaleDown,
  child: Text(
    _formatValue(_totalPortfolioValue),  // 2位小数
    style: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
    ),
  ),
),
```

## 效果对比

### 修改前
- 总资产：`$1,234.123456789`（9位小数，可能溢出）
- 24小时变化：`+$12.123456789`（9位小数，可能溢出）

### 修改后
- 总资产：`$1,234.12`（2位小数，自动缩放）
- 24小时变化：`+$12.12`（2位小数，自动缩放）

## 技术特点

### 1. FittedBox的优势
- **自动缩放**：内容超出时自动缩小字体
- **保持比例**：缩放时保持文本的宽高比
- **响应式**：适应不同屏幕尺寸

### 2. 格式化一致性
- **美元价值**：统一使用`_formatValue()`，显示2位小数
- **代币余额**：使用`_formatBalance()`，最多9位小数
- **币价**：使用`_formatPrice()`，4位小数

### 3. 用户体验改善
- **无溢出**：任何数值都不会超出屏幕边界
- **清晰显示**：价值显示更加简洁易读
- **一致性**：所有美元价值都使用相同格式

## 测试建议

1. **大数值测试**：测试百万、十亿级别的总资产显示
2. **小屏幕测试**：在小屏幕设备上验证无溢出
3. **字体缩放测试**：验证系统字体缩放设置下的显示效果
4. **横竖屏切换**：确保不同方向下都正常显示

这样的修改确保了格式化的正确性和UI的稳定性，提供了更好的用户体验。