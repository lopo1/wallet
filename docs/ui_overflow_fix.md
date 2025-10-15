# UI溢出修复和布局优化

## 问题描述

用户反馈首页assets列表出现UI溢出问题，并且不需要显示网络名称（因为图标已经可以区分）。

## 解决方案

### 1. 移除网络名称显示

- 将第一行从显示"币种名称"改为显示"币种Symbol"
- 移除了地址数量显示（这个信息不是必需的）
- 保留了自定义代币的"Custom"标签

### 2. 简化布局结构

**修改前的布局：**
```
第一行：币种名称 + 地址数量标签 + Custom标签
第二行：Symbol + 币价 + 涨跌标签
```

**修改后的布局：**
```
第一行：Symbol + Custom标签（如果是自定义代币）
第二行：币价 + 涨跌标签
```

### 3. 防止UI溢出

- 在第一行的Symbol文本使用`Flexible`包装，添加`overflow: TextOverflow.ellipsis`
- 在第二行的涨跌标签使用`Flexible`包装
- 调整币价字体大小从13提升到14，保持一致性

### 4. 具体修改内容

#### 第一行优化
```dart
Row(
  children: [
    Flexible(
      child: Text(
        asset['symbol'] as String,  // 直接显示Symbol而不是name
        style: const TextStyle(
          color: _HomeScreenState.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,  // 防止溢出
      ),
    ),
    // 只保留Custom标签，移除地址数量显示
    if (asset['isNative'] == false) ...[
      // Custom标签代码
    ],
  ],
),
```

#### 第二行优化
```dart
Row(
  children: [
    // 币价显示，字体大小调整为14
    Text(
      '\$${(asset['price'] as double).toStringAsFixed(2)}',
      style: TextStyle(
        color: _HomeScreenState.textSecondary.withOpacity(0.8),
        fontSize: 14,  // 从13调整为14
        fontWeight: FontWeight.w500,
      ),
    ),
    const SizedBox(width: 8),
    // 涨跌标签用Flexible包装防止溢出
    Flexible(
      child: Container(
        // 涨跌标签内容
      ),
    ),
  ],
),
```

## 效果

修改后的assets列表项显示：

```
[图标] ETH                        1.2345 ETH
      $2000.00  [+2.34%]         $2,469.00
```

- **左侧**：资产图标
- **中间上方**：币种Symbol（ETH、BTC等）
- **中间下方**：币价和涨跌情况
- **右侧**：账户余额和价值

## 优势

1. **解决溢出问题**：使用Flexible和ellipsis处理长文本
2. **简化信息展示**：移除不必要的网络名称和地址数量
3. **保持核心信息**：Symbol、币价、涨跌、余额、价值都清晰可见
4. **提升可读性**：布局更加简洁，信息层次更清晰
5. **图标区分**：通过TokenWithNetworkIcon组件的图标来区分不同网络，无需文字说明

这样的修改既解决了UI溢出问题，又让界面更加简洁易读。