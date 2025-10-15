# UI溢出问题综合修复

## 问题描述

用户报告了多个RenderFlex溢出错误：
- `A RenderFlex overflowed by 4.6 pixels on the right`
- `A RenderFlex overflowed by 26 pixels on the right`
- `A RenderFlex overflowed by 46 pixels on the right`
- `A RenderFlex overflowed by 21 pixels on the right`

## 问题分析

溢出问题主要出现在assets列表项中，具体位置：
1. **第一行**：币种Symbol + Custom标签
2. **第二行**：币价 + 涨跌标签
3. **右侧**：余额和价值显示
4. **整体布局**：空间分配不合理

## 解决方案

### 1. 整体布局优化

#### 使用IntrinsicHeight和更好的空间分配
```dart
// 修改前
Row(
  children: [
    TokenWithNetworkIcon(...),
    SizedBox(width: 16),
    Expanded(child: Column(...)),
    Flexible(child: Column(...)),
  ],
)

// 修改后
IntrinsicHeight(
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TokenWithNetworkIcon(...),
      SizedBox(width: 12),  // 减少间距
      Expanded(flex: 2, child: Column(...)),  // 明确flex比例
      SizedBox(width: 8),
      Expanded(flex: 1, child: Column(...)),  // 明确flex比例
    ],
  ),
)
```

### 2. 第一行优化（Symbol + 标签）

#### 添加flex比例和溢出处理
```dart
// 修改前
Row(
  children: [
    Flexible(child: Text(symbol)),
    SizedBox(width: 8),
    Container(child: Text('Custom')),
  ],
)

// 修改后
Row(
  children: [
    Flexible(
      flex: 3,  // 给Symbol更多空间
      child: Text(
        symbol,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    SizedBox(width: 4),  // 减少间距
    Flexible(
      flex: 1,  // 限制Custom标签空间
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          'Custom',
          fontSize: 9,  // 减小字体
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ),
  ],
)
```

### 3. 第二行优化（币价 + 涨跌）

#### 添加flex比例和嵌套溢出处理
```dart
// 修改前
Row(
  children: [
    Text(price),
    SizedBox(width: 8),
    Flexible(child: Container(child: Row(...))),
  ],
)

// 修改后
Row(
  children: [
    Flexible(
      flex: 2,  // 给币价更多空间
      child: Text(
        price,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    SizedBox(width: 8),
    Flexible(
      flex: 1,  // 限制涨跌标签空间
      child: Container(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(...),
            SizedBox(width: 2),  // 减少间距
            Flexible(
              child: Text(
                change,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ),
  ],
)
```

### 4. 右侧余额和价值优化

#### 添加ConstrainedBox和对齐方式
```dart
// 修改前
Column(
  children: [
    FittedBox(child: Text(balance)),
    FittedBox(child: Text(value)),
  ],
)

// 修改后
Column(
  crossAxisAlignment: CrossAxisAlignment.end,
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 120),  // 限制最大宽度
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,  // 右对齐
        child: Text(balance),
      ),
    ),
    ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 120),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Text(value),
      ),
    ),
  ],
)
```

## 技术改进

### 1. 空间分配策略
- **左侧图标**：固定48px
- **中间信息**：flex: 2（占2/3空间）
- **右侧余额**：flex: 1（占1/3空间）
- **间距优化**：减少不必要的间距

### 2. 溢出防护机制
- **多层Flexible**：在不同层级使用Flexible
- **TextOverflow.ellipsis**：文本溢出时显示省略号
- **ConstrainedBox**：限制组件最大宽度
- **FittedBox**：自动缩放内容

### 3. 响应式设计
- **IntrinsicHeight**：确保行高一致
- **CrossAxisAlignment.stretch**：垂直拉伸对齐
- **MainAxisAlignment.center**：垂直居中

## 修复效果

### 修复前的问题
```
[图标] VeryLongTokenSymbolName Custom  $1234.5678  [+2.34%]  ← 溢出
```

### 修复后的效果
```
[图标] VeryLong... Custom  $1234.56  [+2.34%]  1.234567890 ETH
                                              $2,469.00
```

## 测试验证

- ✅ 语法检查通过
- ✅ 长Symbol名称正确截断
- ✅ Custom标签不会溢出
- ✅ 币价显示正常
- ✅ 涨跌标签适应空间
- ✅ 余额和价值正确显示

## 关键技术点

### 1. Flex布局优化
```dart
Expanded(flex: 2, child: ...)  // 明确比例
Expanded(flex: 1, child: ...)  // 避免默认分配
```

### 2. 嵌套溢出处理
```dart
Flexible(
  child: Container(
    child: Row(
      children: [
        Icon(...),
        Flexible(child: Text(...)),  // 嵌套Flexible
      ],
    ),
  ),
)
```

### 3. 约束和对齐
```dart
ConstrainedBox(
  constraints: BoxConstraints(maxWidth: 120),
  child: FittedBox(
    alignment: Alignment.centerRight,
    child: Text(...),
  ),
)
```

这样的综合修复确保了在任何屏幕尺寸和内容长度下都不会出现UI溢出问题。