# TRC20 代币支持文档

## 概述

已成功添加 TRC20 代币支持，包括 TRP 测试代币。

## 添加的代币

### TRP Token
- **合约地址**: `TVcNAxqqVb3WmeGZ6PLPz8SfoTwJAHXgXQ`
- **名称**: TRP Token
- **符号**: TRP
- **小数位**: 6
- **网络**: TRON (Nile 测试网)
- **颜色**: #00D4AA

## 实现的功能

### 1. 代币模型 (`lib/models/token_model.dart`)

添加了 TRON 原生代币和 TRP 代币到 `TokenPresets`:

```dart
// TRON 原生代币
static final trx = Token(
  id: 'tron',
  symbol: 'TRX',
  name: 'TRON',
  networkId: 'tron',
  contractAddress: 'T9yD14Nj9j7xAB4dbGeiX9h8unkKHxuWwb',
  decimals: 6,
  isNative: true,
  color: const Color(0xFFEB0029),
  icon: Icons.flash_on,
);

// TRP 代币
static final trp = Token(
  id: 'trp-tron',
  symbol: 'TRP',
  name: 'TRP Token',
  networkId: 'tron',
  contractAddress: 'TVcNAxqqVb3WmeGZ6PLPz8SfoTwJAHXgXQ',
  decimals: 6,
  color: const Color(0x00D4AA),
  icon: Icons.token,
);
```

### 2. TRC20 服务 (`lib/services/trc20_service.dart`)

实现了完整的 TRC20 代币操作：

#### 查询余额
```dart
Future<double> getBalance({
  required String contractAddress,
  required String ownerAddress,
  required String tronRpcBaseUrl,
  required int decimals,
})
```

**功能**:
- 调用智能合约的 `balanceOf(address)` 方法
- 使用 `triggerconstantcontract` API（只读调用，不消耗能量）
- 自动转换单位（根据 decimals）

#### 转账
```dart
Future<String> transfer({
  required String mnemonic,
  required int addressIndex,
  required String contractAddress,
  required String fromAddress,
  required String toAddress,
  required double amount,
  required int decimals,
  required String tronRpcBaseUrl,
})
```

**功能**:
- 构造 `transfer(address,uint256)` 函数调用
- 创建智能合约交易
- 使用 ECDSA 签名
- 广播交易到 TRON 网络

### 3. WalletProvider 集成 (`lib/providers/wallet_provider.dart`)

#### 查询 TRC20 余额
```dart
Future<double> getTRC20Balance({
  required String contractAddress,
  required int decimals,
  String? rpcUrl,
})
```

**使用示例**:
```dart
final balance = await walletProvider.getTRC20Balance(
  contractAddress: 'TVcNAxqqVb3WmeGZ6PLPz8SfoTwJAHXgXQ',
  decimals: 6,
);
```

#### 发送 TRC20 代币
```dart
Future<String> sendTRC20Token({
  required String contractAddress,
  required String toAddress,
  required double amount,
  required int decimals,
  required String password,
  String? rpcUrl,
})
```

**使用示例**:
```dart
final txId = await walletProvider.sendTRC20Token(
  contractAddress: 'TVcNAxqqVb3WmeGZ6PLPz8SfoTwJAHXgXQ',
  toAddress: 'TKveVhA3k4VPVWXPBHWkrZFCeDz3ZyyF5h',
  amount: 10.0,
  decimals: 6,
  password: '123456',
);
```

## 技术细节

### TRC20 标准

TRC20 是 TRON 网络上的代币标准，类似于以太坊的 ERC20。

#### 主要方法

1. **balanceOf(address)**
   - 函数选择器: `0x70a08231`
   - 参数: 地址（32字节）
   - 返回: uint256 余额

2. **transfer(address,uint256)**
   - 函数选择器: `0xa9059cbb`
   - 参数: 
     - 接收地址（32字节）
     - 转账金额（32字节）
   - 返回: bool 成功标志

### 地址编码

TRON 地址需要特殊处理：

1. **Base58 解码**: 将 `T...` 格式的地址解码为字节
2. **去除前缀**: 去掉 `0x41` 前缀和 4 字节 checksum
3. **补齐长度**: 将 20 字节地址补齐到 32 字节（左侧填充 0）

```dart
static String _encodeAddress(String address) {
  final decoded = _base58Decode(address);
  final payload = decoded.sublist(0, 21);
  final addressBytes = payload.sublist(1);
  final addressHex = HEX.encode(addressBytes);
  return addressHex.padLeft(64, '0');
}
```

### 金额编码

金额需要转换为最小单位并编码为 uint256：

```dart
static String _encodeUint256(BigInt value) {
  String hex = value.toRadixString(16);
  return hex.padLeft(64, '0');
}
```

### 签名

TRC20 转账使用与原生 TRX 转账相同的签名方法：
- ECDSA 签名
- secp256k1 曲线
- SHA256 哈希
- Recovery ID 计算

## 使用指南

### 1. 在资产列表中显示 TRP

```dart
// 获取 TRP 代币
final trpToken = TokenPresets.trp;

// 查询余额
final balance = await walletProvider.getTRC20Balance(
  contractAddress: trpToken.contractAddress,
  decimals: trpToken.decimals,
);

// 显示
Text('${balance.toStringAsFixed(2)} ${trpToken.symbol}');
```

### 2. 发送 TRP 代币

```dart
try {
  final txId = await walletProvider.sendTRC20Token(
    contractAddress: TokenPresets.trp.contractAddress,
    toAddress: recipientAddress,
    amount: amount,
    decimals: TokenPresets.trp.decimals,
    password: userPassword,
  );
  
  print('交易成功! TxID: $txId');
} catch (e) {
  print('交易失败: $e');
}
```

### 3. 添加自定义 TRC20 代币

```dart
final customToken = Token(
  id: 'custom-token',
  symbol: 'CTK',
  name: 'Custom Token',
  networkId: 'tron',
  contractAddress: 'T...',  // 合约地址
  decimals: 18,
  color: const Color(0xFF123456),
  icon: Icons.token,
);

await walletProvider.addCustomToken(customToken);
```

## 测试建议

1. **余额查询测试**:
   - 查询 TRP 代币余额
   - 验证余额显示正确
   - 测试多个地址的余额查询

2. **转账测试**:
   - 小额转账测试（如 1 TRP）
   - 验证交易哈希返回
   - 在区块浏览器确认交易
   - 测试余额更新

3. **错误处理测试**:
   - 余额不足
   - 无效的合约地址
   - 无效的接收地址
   - 网络错误

## 注意事项

1. **手续费**: TRC20 转账需要消耗 TRX 作为手续费（能量/带宽）
2. **测试网**: 当前使用 Nile 测试网，合约地址仅在测试网有效
3. **精度**: TRP 使用 6 位小数，与 TRX 相同
4. **RPC 限制**: 公共 RPC 可能有速率限制

## 相关文件

- `lib/models/token_model.dart` - 代币模型和预设
- `lib/services/trc20_service.dart` - TRC20 服务实现
- `lib/providers/wallet_provider.dart` - 钱包提供者集成
- `lib/services/tron_service.dart` - TRON 原生交易服务

## 区块浏览器

- **Nile 测试网**: https://nile.tronscan.org
- **主网**: https://tronscan.org

查看 TRP 合约: https://nile.tronscan.org/#/contract/TVcNAxqqVb3WmeGZ6PLPz8SfoTwJAHXgXQ
