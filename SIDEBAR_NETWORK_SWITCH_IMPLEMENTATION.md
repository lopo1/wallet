# 侧边栏网络地址切换功能实现

## 问题描述
在左边的网络列表中，点击选择地址时需要同时切换到对应的网络和地址。

## 问题修复
修复了EVM网络（Ethereum、Polygon、BSC）地址相同时，总是切换到第一个匹配网络（通常是Ethereum）的问题。

## 解决方案

### 修改的文件
- `lib/widgets/sidebar.dart`

### 主要修改内容

#### 1. 添加导入
```dart
import '../models/network.dart';
```

#### 2. 修改地址下拉菜单构建
在网络列表构建中，为地址下拉菜单传递网络上下文：

**修改前：**
```dart
...addressList.map((address) => _buildAddressDropdown(address)),
```

**修改后：**
```dart
...addressList.map((address) => _buildAddressDropdown(address, network)),
```

#### 3. 修改地址点击逻辑
在 `_buildAddressDropdown` 方法中，直接使用传入的网络上下文：

**修改前：**
```dart
Widget _buildAddressDropdown(String address) {
  // ... 查找网络逻辑
}
```

**修改后：**
```dart
Widget _buildAddressDropdown(String address, Network network) {
  return GestureDetector(
    onTap: () {
      // 直接使用传入的网络上下文，避免EVM网络地址相同的问题
      walletProvider.setCurrentNetwork(network);
      walletProvider.setSelectedAddress(address);
    },
    // ...
  );
}
```

## 功能说明

### 工作流程
1. 用户在特定网络下展开地址列表
2. 用户点击该网络下的某个地址
3. 系统直接切换到该网络（使用上下文信息）
4. 设置选中的地址

### 优势
- **精确网络切换**：使用网络上下文，避免EVM地址相同导致的错误切换
- **简化逻辑**：不需要查找网络，直接使用上下文信息
- **保持一致性**：确保选中的地址和当前网络保持一致
- **解决EVM问题**：正确处理Ethereum、Polygon、BSC等网络的相同地址

### 使用场景
- 用户展开Ethereum网络，点击其地址，切换到Ethereum网络
- 用户展开Polygon网络，点击其地址，切换到Polygon网络（即使地址与Ethereum相同）
- 用户展开BSC网络，点击其地址，切换到BSC网络（即使地址与其他EVM网络相同）
- 支持所有已配置的网络（Ethereum、Bitcoin、Solana、Polygon、BSC）

## 测试建议

### 手动测试步骤
1. 创建或导入一个包含多个网络地址的钱包
2. 验证EVM网络（Ethereum、Polygon、BSC）是否使用相同地址
3. 在侧边栏中展开Ethereum网络的地址列表，点击地址
4. 验证是否切换到Ethereum网络
5. 展开Polygon网络的地址列表，点击相同的地址
6. 验证是否正确切换到Polygon网络（而不是Ethereum）
7. 重复测试BSC网络

### 预期结果
- 点击地址后，当前网络应该切换到该地址所在的网络上下文
- 即使EVM网络地址相同，也能正确切换到对应的网络
- 选中的地址应该更新为点击的地址
- UI 应该正确反映当前的网络和地址状态

## 注意事项
- 该功能使用网络上下文信息，避免了地址查找的复杂性
- 特别解决了EVM网络地址相同的问题
- 依赖于 `WalletProvider` 中的 `setCurrentNetwork` 和 `setSelectedAddress` 方法
- 地址在特定网络上下文中显示，确保了切换的准确性