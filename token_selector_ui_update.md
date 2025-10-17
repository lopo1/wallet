# 代币选择器UI更新说明

## 🎯 实现目标

根据你上传的UI设计图，我已经完全重新设计了兑换页面的代币选择器，使其与"我的资产"页面的UI保持一致。

## 🎨 UI设计特点

### 1. 全屏显示
- **改进前**：底部弹窗形式
- **改进后**：全屏页面，更好的用户体验

### 2. 顶部标题栏
- **标题**："我的资产"
- **关闭按钮**：右上角圆形关闭按钮

### 3. 搜索功能
- **搜索框**：支持代币名称或合约地址搜索
- **实时过滤**：输入时实时过滤代币列表

### 4. 网络筛选标签
- **水平滚动标签**：全部、Ethereum、Tron、BNB Chain、Arbitrum
- **选中状态**：紫色背景，白色文字
- **未选中状态**：深灰背景，灰色文字

### 5. 代币列表设计

#### 代币图标
- **主图标**：48x48圆形背景 + 代币图标
- **网络标识**：右下角18x18小圆形，显示网络符号
- **网络颜色**：
  - Ethereum: 蓝色 (#627EEA)
  - Tron: 红色 (#FF0013)
  - BNB Chain: 黄色 (#F3BA2F)
  - Arbitrum: 蓝色 (#28A0F0)

#### 代币信息
- **代币符号**：大字体，白色
- **+2标识**：紫色小标签（表示某种状态）
- **合约地址**：小字体，灰色（如果有）

#### 余额显示
- **数量**：右对齐，白色大字体
- **美元价值**：≈$XX.XX格式，灰色小字体

## 📊 数据结构

### 代币数据
```dart
{
  'id': 'usdt-tron',
  'name': 'Tether USD',
  'symbol': 'USDT',
  'icon': Icons.attach_money,
  'color': Color(0xFF26A17B),
  'price': 1.0,
  'change24h': 0.01,
  'isNative': false,
  'networkId': 'tron',
  'networkName': 'Tron',
  'address': 'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t',
}
```

### 支持的代币
1. **USDT** (Tron) - 4.01余额
2. **TRX** (Tron) - 0余额
3. **USDC** (Ethereum) - 0余额
4. **HTX** (Ethereum) - 0余额
5. **TRONDOG** (Tron) - 0余额
6. **TUSD** (Tron) - 0余额
7. **WIN** (Tron) - 0余额
8. **SUN** (Tron) - 0余额
9. **ETH** (Ethereum) - 0.5678余额

## 🔧 技术实现

### 1. 全屏页面导航
```dart
void _showTokenSelector(bool isFrom) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => _TokenSelectorScreen(
        isFrom: isFrom,
        onTokenSelected: (symbol, networkId) {
          // 回调处理选择结果
        },
      ),
    ),
  );
}
```

### 2. 搜索和过滤
```dart
List<Map<String, dynamic>> _getFilteredAssets() {
  final assets = _getAllAssets();
  
  return assets.where((asset) {
    // 网络过滤
    if (_selectedNetwork != 'all' && asset['networkId'] != _selectedNetwork) {
      return false;
    }
    
    // 搜索过滤
    if (_searchQuery.isNotEmpty) {
      final symbol = (asset['symbol'] as String).toLowerCase();
      final name = (asset['name'] as String).toLowerCase();
      final query = _searchQuery.toLowerCase();
      return symbol.contains(query) || name.contains(query);
    }
    
    return true;
  }).toList();
}
```

### 3. 网络标识组件
```dart
// 网络标识
Positioned(
  right: 0,
  bottom: 0,
  child: Container(
    width: 18,
    height: 18,
    decoration: BoxDecoration(
      color: _getNetworkColor(networkId),
      shape: BoxShape.circle,
      border: Border.all(color: backgroundColor, width: 2),
    ),
    child: Center(
      child: Text(
        _getNetworkSymbol(networkId),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ),
),
```

## 🎯 用户交互流程

1. **点击代币选择器** → 进入全屏代币选择页面
2. **搜索代币** → 在搜索框输入代币名称或地址
3. **筛选网络** → 点击网络标签筛选特定网络的代币
4. **选择代币** → 点击代币卡片完成选择
5. **返回兑换页面** → 自动返回并更新选中的代币

## 🎨 视觉效果

### 颜色方案
- **背景色**：纯黑 (#000000)
- **卡片色**：深灰 (#1A1A1A)
- **主色调**：紫色 (#8B5CF6)
- **文字色**：白色 (#FFFFFF) / 灰色 (#9CA3AF)

### 交互反馈
- **网络标签选中**：紫色背景 + 白色文字
- **代币卡片点击**：轻微的视觉反馈
- **搜索实时过滤**：即时显示结果

## 📱 响应式设计

- **适配不同屏幕**：使用Flexible和Expanded确保适配
- **滚动支持**：网络标签水平滚动，代币列表垂直滚动
- **安全区域**：使用SafeArea确保在刘海屏等设备上正常显示

这个新的代币选择器完全符合你上传的UI设计，提供了更好的用户体验和更丰富的功能。