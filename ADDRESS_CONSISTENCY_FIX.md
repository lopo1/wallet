# 助记词地址一致性修复

## 问题描述

相同助记词在不同钱包中生成的 Solana 地址不一致，这是由于 `SolanaWalletService` 中的地址生成方法与标准 BIP44 派生路径不一致导致的。

## 问题原因

1. **`getAddress` 方法**: 直接使用 `Ed25519HDKeyPair.fromMnemonic(mnemonic)` 而不是标准的 BIP44 路径
2. **`sendTransaction` 方法**: 也使用了相同的非标准方法
3. **`sendSolTransfer` 方法**: 使用了正确的 BIP44 路径 `"m/44'/501'/0'"`
4. **`AddressService`**: 使用了正确的 BIP44 路径 `"m/44'/501'/$index'"`

这导致了同一个助记词在不同方法中生成不同的地址。

## 修复方案

### 修复前的代码

```dart
@override
Future<String> getAddress(String mnemonic) async {
  final keypair = await Ed25519HDKeyPair.fromMnemonic(mnemonic);
  return keypair.publicKey.toBase58();
}

@override
Future<String> sendTransaction(
    String mnemonic, String toAddress, double amount) async {
  final fromKeypair = await Ed25519HDKeyPair.fromMnemonic(mnemonic);
  // ...
}
```

### 修复后的代码

```dart
@override
Future<String> getAddress(String mnemonic) async {
  // 使用与AddressService相同的标准BIP44路径
  final seed = MnemonicService.mnemonicToSeed(mnemonic);
  const path = "m/44'/501'/0'"; // 使用索引0作为默认地址
  final derivedKey = await ED25519_HD_KEY.derivePath(path, seed);
  final keypair = await Ed25519HDKeyPair.fromPrivateKeyBytes(
      privateKey: derivedKey.key);
  return keypair.publicKey.toBase58();
}

@override
Future<String> sendTransaction(
    String mnemonic, String toAddress, double amount) async {
  // 使用与getAddress相同的方法生成密钥对
  final seed = MnemonicService.mnemonicToSeed(mnemonic);
  const path = "m/44'/501'/0'";
  final derivedKey = await ED25519_HD_KEY.derivePath(path, seed);
  final fromKeypair = await Ed25519HDKeyPair.fromPrivateKeyBytes(
      privateKey: derivedKey.key);
  // ...
}
```

## 标准化的派生路径

现在所有方法都使用标准的 BIP44 派生路径：

- **Solana 标准路径**: `m/44'/501'/account'/change/address_index`
- **本项目使用**: `m/44'/501'/0'` (account=0, 省略 change 和 address_index，默认为0)

这与其他主流 Solana 钱包（如 Phantom、Solflare 等）保持一致。

## 验证结果

通过测试验证，修复后：

1. ✅ `SolanaWalletService.getAddress()` 与 `AddressService.generateAddress()` 生成相同地址
2. ✅ 相同助记词在不同方法中生成一致的地址
3. ✅ 与其他标准 Solana 钱包兼容

## 测试用例

```dart
// 测试助记词
const testMnemonic = 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

// 预期地址（使用 m/44'/501'/0' 路径）
const expectedAddress = 'GjJyeC1r2RgkuoCWMyPYkCWSGSGLcz266EaAkLA27AhL';
```

## 影响范围

此修复影响以下功能：
- 钱包地址显示
- 交易发送
- 余额查询
- 所有依赖助记词生成地址的功能

## 兼容性

- ✅ 与其他 Solana 钱包兼容
- ✅ 符合 BIP44 标准
- ✅ 符合 Solana 生态系统标准

## 注意事项

1. 如果用户之前使用了旧版本创建的钱包，可能需要重新导入助记词
2. 建议在生产环境部署前进行充分测试
3. 考虑为用户提供地址迁移工具（如果需要）