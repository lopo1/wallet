# UI对齐问题修复

## 问题描述

用户反馈了两个UI对齐问题：
1. **主要余额显示**：`_totalPortfolioValue`没有居中显示
2. **Assets列表**：右下角的链图标（移除按钮）位置偏下

## 解决方案

### 1. 主要余额显示居中修复

#### 问题分析
主要余额显示在Consumer<WalletProvider>内的Column中，但该Column缺少居中对齐设置。

#### 修复前
```dart
Consumer<WalletProvider>(
  builder: (context, walletProvider, _) {
    return Column(
      children: [  // 缺少crossAxisAlignment设置
        FittedBox(
          child: Text(
            FormatUtils.formatValue(_totalPortfolioValue),
            // 缺少textAlign设置
          ),
        ),
      ],
    );
  },
)
```

#### 修复后
```dart
Consumer<WalletProvider>(
  builder: (context, walletProvider, _) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,  // 添加居中对齐
      children: [
        FittedBox(
          child: Text(
            FormatUtils.formatValue(_totalPortfolioValue),
            textAlign: TextAlign.center,  // 添加文本居中
          ),
        ),
      ],
    );
  },
)
```

### 2. Assets列表链图标位置修复

#### 问题分析
Assets列表项使用了`crossAxisAlignment: CrossAxisAlignment.stretch`，导致PopupMenuButton被拉伸，图标位置偏下。

#### 修复前
```dart
IntrinsicHeight(
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,  // 拉伸对齐
    children: [
      // ... 其他组件
      PopupMenuButton(...),  // 被拉伸，位置偏下
    ],
  ),
)
```

#### 修复后
```dart
IntrinsicHeight(
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.center,  // 居中对齐
    children: [
      // ... 其他组件
      Align(
        alignment: Alignment.center,  // 确保按钮居中
        child: PopupMenuButton(...),
      ),
    ],
  ),
)
```

## 技术细节

### 1. Column居中对齐
- **crossAxisAlignment: CrossAxisAlignment.center**：确保Column内的子元素水平居中
- **textAlign: TextAlign.center**：确保文本内容本身也居中显示

### 2. Row对齐方式调整
- **从stretch改为center**：避免组件被不必要地拉伸
- **添加Align包装器**：为PopupMenuButton提供额外的居中保证

### 3. 布局层次结构

#### 主要余额显示
```
Container (padding + crossAxisAlignment.center)
  └── Column (crossAxisAlignment.center)
      └── Consumer<WalletProvider>
          └── Column (crossAxisAlignment.center) ← 修复点
              └── FittedBox
                  └── Text (textAlign.center) ← 修复点
```

#### Assets列表项
```
IntrinsicHeight
  └── Row (crossAxisAlignment.center) ← 修复点
      ├── TokenWithNetworkIcon
      ├── Expanded (资产信息)
      ├── Expanded (余额价值)
      └── Align (alignment.center) ← 修复点
          └── PopupMenuButton
```

## 修复效果

### 1. 主要余额显示
```
修复前：
    $1,234.56     ← 可能偏左或偏右
    +$12.34 +100%

修复后：
      $1,234.56   ← 完全居中
    +$12.34 +100%
```

### 2. Assets列表链图标
```
修复前：
[图标] ETH  $2000.00  +2.3%  1.23 ETH
                              $2,469.00
                                     ⋮  ← 偏下

修复后：
[图标] ETH  $2000.00  +2.3%  1.23 ETH
                              $2,469.00
                                  ⋮     ← 居中
```

## 验证检查

- ✅ 语法检查通过
- ✅ 主要余额完全居中显示
- ✅ 24小时变化行保持居中
- ✅ Assets列表链图标垂直居中
- ✅ 不影响其他布局元素
- ✅ 保持响应式设计

## 相关组件

### 受影响的组件
1. **主要余额显示区域**：Consumer<WalletProvider>内的Column
2. **Assets列表项**：IntrinsicHeight内的Row和PopupMenuButton

### 不受影响的组件
- 钱包切换器中的总资产显示（保持左对齐）
- Assets列表的其他元素（图标、文本、余额等）
- 整体页面布局结构

这些修复确保了UI元素的正确对齐，提供了更好的视觉体验和一致性。