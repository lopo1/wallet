# TRON 签名验证错误修复

## 问题描述

在 TRON 地址验证通过后，交易广播时出现签名验证错误：

```
SIGERROR Validate signature error: ... is signed by TJ2voLitMNM5SaNPUpGNY495ytN2RcS8zg 
but it is not contained of permission.
```

## 问题分析

错误信息表明：
1. 交易创建时使用的地址是 `TB6LhBWhBhmHA21bHjxNFKSEq6ZiruMzr7`
2. 但签名时使用的私钥对应的地址是 `TJ2voLitMNM5SaNPUpGNY495ytN2RcS8zg`（不匹配）

这说明**私钥推导的地址索引与实际地址不匹配**。

## 根本原因

可能的原因：
1. 地址索引计算错误
2. 钱包中存储的地址与推导路径不一致
3. 地址生成时使用的推导路径与签名时不同

## 修复方案

### 1. 添加私钥验证机制

在签名前验证推导的私钥是否对应正确的地址：

```dart
// 2) 推导私钥
final seed = bip39.mnemonicToSeed(mnemonic);
final root = bip32.BIP32.fromSeed(seed);
final derivationPath = DerivationPaths.tronWithIndex(addressIndex);
debugPrint('=== TRON 私钥推导 ===');
debugPrint('地址索引: $addressIndex');
debugPrint('推导路径: $derivationPath');
debugPrint('期望地址: $fromAddress');

final child = root.derivePath(derivationPath);
final pkBytes = child.privateKey;
if (pkBytes == null) {
  throw Exception('无法导出TRON私钥');
}
final pkHex = HEX.encode(pkBytes);

// 验证推导的私钥是否对应正确的地址
final publicKey = child.publicKey;
final derivedAddress = _deriveAddressFromPublicKey(publicKey);
debugPrint('推导的地址: $derivedAddress');

if (derivedAddress != fromAddress) {
  throw Exception('私钥推导错误: 期望地址 $fromAddress, 实际地址 $derivedAddress');
}
```

### 2. 实现地址推导验证方法

添加 `_deriveAddressFromPublicKey` 方法来从公钥推导 TRON 地址：

```dart
/// 从公钥推导 TRON 地址
static String _deriveAddressFromPublicKey(Uint8List publicKey) {
  // 解压公钥（如果是压缩格式）
  Uint8List uncompressed;
  if (publicKey.length == 33) {
    // 压缩公钥，需要解压
    final curve = ECCurve_secp256k1();
    final point = curve.curve.decodePoint(publicKey);
    if (point == null) {
      throw Exception('无法解压公钥');
    }
    uncompressed = point.getEncoded(false);
  } else if (publicKey.length == 65) {
    // 已经是非压缩格式
    uncompressed = publicKey;
  } else {
    throw Exception('无效的公钥长度: ${publicKey.length}');
  }

  // 对非压缩公钥（去掉0x04前缀）做 keccak256
  final pkHash = web3_crypto.keccak256(uncompressed.sublist(1));
  final address20 = pkHash.sublist(12); // 取后20字节

  // TRON 地址: 0x41 + 20字节地址
  final payload = Uint8List.fromList([0x41, ...address20]);

  // 计算 checksum
  final checksum = _doubleHash256(payload).sublist(0, 4);

  // Base58 编码
  final base58Address = _base58Encode([...payload, ...checksum]);
  return base58Address;
}
```

### 3. 添加必要的导入

```dart
import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart';
```

## 调试信息

修复后会输出详细的调试信息：

```
flutter: === TRON 私钥推导 ===
flutter: 地址索引: 0
flutter: 推导路径: m/44'/195'/0'/0/0
flutter: 期望地址: TB6LhBWhBhmHA21bHjxNFKSEq6ZiruMzr7
flutter: 推导的地址: TB6LhBWhBhmHA21bHjxNFKSEq6ZiruMzr7
```

如果地址不匹配，会抛出明确的错误：
```
Exception: 私钥推导错误: 期望地址 TB6LhBWhBhmHA21bHjxNFKSEq6ZiruMzr7, 实际地址 TJ2voLitMNM5SaNPUpGNY495ytN2RcS8zg
```

## 可能的问题场景

### 场景 1：地址索引错误

如果钱包中的地址不是按照标准索引生成的，需要：
1. 检查地址生成时使用的索引
2. 确保发送交易时使用相同的索引

### 场景 2：推导路径不一致

如果地址生成和签名使用了不同的推导路径，需要：
1. 统一使用 `DerivationPaths.tronWithIndex(index)`
2. 确保路径格式为 `m/44'/195'/0'/0/{index}`

### 场景 3：钱包导入方式不同

如果钱包是通过私钥导入的，而不是助记词生成的：
1. 需要单独存储私钥
2. 签名时直接使用存储的私钥，而不是从助记词推导

## 下一步

1. **运行测试**：查看调试日志，确认推导的地址是否匹配
2. **如果地址不匹配**：
   - 检查钱包地址是如何生成的
   - 确认地址索引是否正确
   - 验证推导路径是否一致
3. **如果地址匹配但仍然签名失败**：
   - 可能是签名算法问题
   - 检查 TRON 网络的签名要求

## 相关文件

- `lib/services/tron_service.dart` - TRON 服务，包含交易签名逻辑
- `lib/services/address_service.dart` - 地址服务，包含地址生成逻辑
- `lib/constants/derivation_paths.dart` - 推导路径常量
- `lib/providers/wallet_provider.dart` - 钱包提供者，管理地址和索引
