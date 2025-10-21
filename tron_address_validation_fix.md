# TRON 地址验证修复说明

## 问题描述

用户在发送 TRX 到地址 `TKveVhA3k4VPVWXPBHWkrZFCeDz3ZyyF5h` 时，收到错误提示："当前钱包TRON格式不正确"。

## 根本原因

经过调试发现，问题不是地址验证逻辑本身，而是**网络地址获取逻辑错误**：

1. 用户选择了 TRON 网络进行发送
2. 但是 `getCurrentNetworkAddress()` 返回的是以太坊地址 `0x85c88b777318df7f1115f6541d014fdbe6c0bddb`
3. 这是因为 `_selectedAddress` 可能是从其他网络选择的，而 `getCurrentNetworkAddress()` 没有验证地址是否属于当前网络

## 问题分析

经过测试验证，发现：

1. **收款地址有效**：`TKveVhA3k4VPVWXPBHWkrZFCeDz3ZyyF5h` 是一个完全有效的 TRON 地址
   - 长度：34 字符（标准 TRON 地址长度）
   - 格式：T + 33 个 Base58 字符
   - Checksum：验证通过
   - 地址前缀：0x41（TRON 标准前缀）

2. **钱包生成的地址有效**：钱包使用 BIP44 路径 `m/44'/195'/0'/0/0` 生成的 TRON 地址格式正确

3. **问题根源**：地址验证逻辑可能因为以下原因失败：
   - 地址包含不可见字符（空格、换行符等）
   - 验证逻辑缺少详细的错误信息
   - 异常处理不够完善

## 修复内容

### 1. 修复 `getCurrentNetworkAddress()` 方法（核心修复）

**问题**：该方法直接返回 `_selectedAddress`，没有验证它是否属于当前网络。

**修复**：
```dart
/// Get current network address for the current wallet
String? getCurrentNetworkAddress() {
  if (_currentWallet == null || _currentNetwork == null) {
    return null;
  }
  
  // 获取当前网络的地址列表
  final addressList = _currentWallet!.addresses[_currentNetwork!.id];
  if (addressList == null || addressList.isEmpty) {
    return null;
  }
  
  // 如果有选中的地址，检查它是否属于当前网络
  if (_selectedAddress != null && addressList.contains(_selectedAddress)) {
    return _selectedAddress;
  }
  
  // 否则返回第一个地址
  return addressList.first;
}
```

### 2. 改进 TRON 交易发送逻辑

**问题**：依赖 `getCurrentNetworkAddress()` 获取发送地址，但该方法可能返回错误网络的地址。

**修复**：直接从 TRON 网络的地址列表中获取地址，不依赖全局的 `_selectedAddress`。

```dart
case 'tron':
  // 获取 TRON 网络的地址列表
  final addresses = _currentWallet!.addresses[networkId];
  if (addresses == null || addresses.isEmpty) {
    throw Exception('当前钱包没有TRON地址');
  }
  
  // 确定使用哪个地址和索引
  int addressIndex = 0;
  String fromAddress = addresses.first;
  
  // 如果选中的地址在 TRON 地址列表中，使用选中的地址
  if (_selectedAddress != null && addresses.contains(_selectedAddress)) {
    fromAddress = _selectedAddress!;
    addressIndex = addresses.indexOf(_selectedAddress!);
  }
  
  debugPrint('=== TRON 交易发送 ===');
  debugPrint('网络ID: $networkId');
  debugPrint('发送地址: $fromAddress');
  debugPrint('地址索引: $addressIndex');
  debugPrint('TRON地址列表: $addresses');
```

### 3. 修复 `send_detail_screen.dart` 中的网络设置

**问题**：发送详情页面接收了 `network` 参数，但没有更新 WalletProvider 的当前网络。

**修复**：在加载初始数据时，设置正确的网络和地址。

```dart
Future<void> _loadInitialData() async {
  if (network == null || address == null) return;

  // 设置当前网络，确保 WalletProvider 使用正确的网络
  final walletProvider = Provider.of<WalletProvider>(context, listen: false);
  walletProvider.setCurrentNetwork(network!);
  
  // 如果提供了地址，设置为选中的地址
  if (address != null) {
    walletProvider.setSelectedAddress(address!);
  }

  await Future.wait([
    _loadRealBalance(),
    _loadGasFee(),
    _loadContacts(),
  ]);

  // 启动Gas费用自动刷新
  _startGasRefreshTimer();
}
```

### 4. 改进 `lib/providers/wallet_provider.dart` 中的地址验证

**修改位置**：`sendTransaction` 方法中的 TRON 交易处理部分

**改进内容**：
- 添加地址清理逻辑（去除空格和换行符）
- 添加详细的调试日志
- 改进错误消息，显示具体的地址和长度信息

```dart
// 清理地址（去除空格和换行符）
final cleanToAddress = toAddress.trim();
final cleanFromAddress = fromAddress.trim();

// 基本地址校验
debugPrint('验证收款地址: $cleanToAddress (长度: ${cleanToAddress.length})');
if (!AddressService.validateAddress(cleanToAddress, 'tron')) {
  throw Exception('收款地址格式无效: $cleanToAddress');
}

debugPrint('验证发送地址: $cleanFromAddress (长度: ${cleanFromAddress.length})');
if (!AddressService.validateAddress(cleanFromAddress, 'tron')) {
  throw Exception('当前钱包TRON地址格式无效: $cleanFromAddress');
}
```

### 2. 增强 `lib/services/address_service.dart` 中的验证逻辑

**修改位置**：`_isValidTronAddress` 方法

**改进内容**：
- 添加空地址检查
- 添加详细的验证步骤日志
- 改进错误处理，输出具体的失败原因

```dart
/// Validate Tron address format (Base58Check 'T...' or hex '41...')
static bool _isValidTronAddress(String address) {
  final trimmed = address.trim();

  // 检查空地址
  if (trimmed.isEmpty) {
    print('TRON地址验证失败: 地址为空');
    return false;
  }

  // Accept hex Tron address with '41' prefix
  final hexPattern = RegExp(r'^41[a-fA-F0-9]{40}$');
  if (hexPattern.hasMatch(trimmed)) {
    print('TRON地址验证通过: 十六进制格式 $trimmed');
    return true;
  }

  // Quick Base58 sanity check (length and alphabet)
  // TRON addresses are typically 34 characters (T + 33 chars)
  final base58Pattern = RegExp(r'^T[1-9A-HJ-NP-Za-km-z]{33}$');
  if (!base58Pattern.hasMatch(trimmed)) {
    // Also allow 32-34 characters after 'T' for edge cases
    final flexiblePattern = RegExp(r'^T[1-9A-HJ-NP-Za-km-z]{32,34}$');
    if (!flexiblePattern.hasMatch(trimmed)) {
      print('TRON地址验证失败: 格式不匹配 (地址: $trimmed, 长度: ${trimmed.length})');
      return false;
    }
  }

  // Full Base58Check validation: 0x41 prefix + checksum
  try {
    final decoded = _base58Decode(trimmed);
    if (decoded.length != 25) {
      print('TRON地址验证失败: 解码后长度不是25字节 (实际: ${decoded.length})');
      return false;
    }
    final payload = decoded.sublist(0, 21);
    final checksum = decoded.sublist(21, 25);
    if (payload[0] != 0x41) {
      print('TRON地址验证失败: 地址前缀不是0x41 (实际: 0x${payload[0].toRadixString(16)})');
      return false;
    }
    final expected = _doubleHash256(payload).sublist(0, 4);
    for (int i = 0; i < 4; i++) {
      if (checksum[i] != expected[i]) {
        print('TRON地址验证失败: Checksum不匹配');
        return false;
      }
    }
    print('TRON地址验证通过: Base58格式 $trimmed');
    return true;
  } catch (e) {
    print('TRON地址验证失败: $trimmed, 错误: $e');
    return false;
  }
}
```

## 验证结果

测试了以下地址，全部验证通过：

1. ✓ `TKveVhA3k4VPVWXPBHWkrZFCeDz3ZyyF5h` - 用户提供的收款地址
2. ✓ `TUEZSdKsoDHQMeZwihtdoBiN46zxhGWYdH` - 钱包生成的地址
3. ✓ `TNPeeaaFB7K9cmo4uQpcU32zGK8G1NYqeL` - 其他测试地址
4. ✓ 带空格的地址会被自动清理

## 使用建议

1. **调试模式**：修复后的代码会在控制台输出详细的验证日志，方便排查问题
2. **生产环境**：如果不需要详细日志，可以将 `print` 语句改为 `debugPrint`
3. **错误处理**：现在的错误消息会显示具体的地址和失败原因，便于用户理解

## TRON 地址格式说明

### Base58 格式（常用）
- 以 `T` 开头
- 总长度通常为 34 字符
- 使用 Base58 编码（不包含 0、O、I、l 等易混淆字符）
- 包含 4 字节的 checksum 用于验证

### 十六进制格式
- 以 `41` 开头
- 后跟 40 个十六进制字符
- 总长度为 42 字符

## 修复效果

修复后的日志输出示例：

```
flutter: === TRON 交易发送 ===
flutter: 网络ID: tron
flutter: 发送地址: TB6LhBWhBhmHA21bHjxNFKSEq6ZiruMzr7
flutter: 地址索引: 0
flutter: TRON地址列表: [TB6LhBWhBhmHA21bHjxNFKSEq6ZiruMzr7]
flutter: 验证收款地址: TUEZSdKsoDHQMeZwihtdoBiN46zxhGWYdH (长度: 34)
flutter: TRON地址验证通过: Base58格式 TUEZSdKsoDHQMeZwihtdoBiN46zxhGWYdH
flutter: 验证发送地址: TB6LhBWhBhmHA21bHjxNFKSEq6ZiruMzr7 (长度: 34)
flutter: TRON地址验证通过: Base58格式 TB6LhBWhBhmHA21bHjxNFKSEq6ZiruMzr7
```

## 相关文件

- `lib/providers/wallet_provider.dart` - 钱包提供者，包含发送交易逻辑和地址获取逻辑
- `lib/screens/send_detail_screen.dart` - 发送详情页面，需要正确设置当前网络
- `lib/services/address_service.dart` - 地址服务，包含地址生成和验证逻辑
- `lib/services/tron_service.dart` - TRON 服务，处理 TRON 交易

## 测试建议

1. **网络切换测试**：
   - 在以太坊网络选择一个地址
   - 切换到 TRON 网络
   - 尝试发送交易，确认使用的是 TRON 地址而不是以太坊地址

2. **地址验证测试**：
   - 测试正常的 TRON 地址发送
   - 测试带空格的地址（应该自动清理）
   - 测试无效地址（应该显示清晰的错误消息）

3. **日志检查**：
   - 检查控制台日志，确认网络ID、发送地址、地址索引都正确
   - 确认地址验证过程正常

4. **多地址测试**：
   - 如果钱包有多个 TRON 地址，测试选择不同地址发送
