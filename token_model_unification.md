# Token 模型统一说明

## 问题

项目中存在两个不同的 Token 类：
1. `lib/models/token.dart` - 旧版本，使用 `address` 属性
2. `lib/models/token_model.dart` - 新版本，使用 `contractAddress` 属性

这导致了类型冲突错误：
```
Error: The argument type 'Token/*1*/' can't be assigned to the parameter type 'Token/*2*/'.
```

## 解决方案

### 1. 统一使用 `token_model.dart`

删除了旧的 `lib/models/token.dart`，统一使用 `lib/models/token_model.dart`。

### 2. 添加兼容性属性

在 `Token` 类中添加了 getter 方法来兼容旧代码：

```dart
class Token {
  final String contractAddress;
  final String? iconUrl;
  final double? priceUsd;
  final double balance;
  
  // 兼容旧代码的别名
  String get address => contractAddress;
  String? get logoUrl => iconUrl;
  double? get price => priceUsd;
}
```

### 3. 更新 JSON 序列化

`toJson` 方法同时输出新旧格式的字段：

```dart
Map<String, dynamic> toJson() {
  return {
    // 新格式
    'contractAddress': contractAddress,
    'iconUrl': iconUrl,
    'priceUsd': priceUsd,
    'balance': balance,
    
    // 兼容旧格式
    'address': contractAddress,
    'logoUrl': iconUrl,
    'price': priceUsd,
  };
}
```

`fromJson` 方法支持读取新旧两种格式：

```dart
factory Token.fromJson(Map<String, dynamic> json) {
  return Token(
    contractAddress: json['contractAddress'] ?? json['address'] ?? '',
    iconUrl: json['iconUrl'] ?? json['logoUrl'],
    priceUsd: json['priceUsd']?.toDouble() ?? json['price']?.toDouble(),
    balance: json['balance']?.toDouble() ?? 0.0,
  );
}
```

### 4. 更新所有导入

更新了以下文件的导入语句：

- `lib/screens/home_screen.dart`
- `lib/screens/token_detail_screen.dart`
- `lib/screens/add_token_screen.dart`
- `lib/providers/wallet_provider.dart`
- `lib/services/token_service.dart`

从：
```dart
import '../models/token.dart';
```

改为：
```dart
import '../models/token_model.dart';
```

## Token 类完整定义

```dart
class Token {
  final String id;
  final String symbol;
  final String name;
  final String? iconUrl;
  final String networkId;
  final String contractAddress;
  final int decimals;
  final bool isNative;
  final double? priceUsd;
  final Color? color;
  final IconData? icon;
  final double balance;

  const Token({
    required this.id,
    required this.symbol,
    required this.name,
    this.iconUrl,
    required this.networkId,
    required this.contractAddress,
    required this.decimals,
    this.isNative = false,
    this.priceUsd,
    this.color,
    this.icon,
    this.balance = 0.0,
  });

  // 兼容旧代码的别名
  String get address => contractAddress;
  String? get logoUrl => iconUrl;
  double? get price => priceUsd;
}
```

## 属性映射

| 旧属性名 | 新属性名 | 说明 |
|---------|---------|------|
| `address` | `contractAddress` | 代币合约地址 |
| `logoUrl` | `iconUrl` | 代币图标 URL |
| `price` | `priceUsd` | 代币价格（美元） |
| - | `id` | 代币唯一标识 |
| - | `color` | 代币颜色 |
| - | `icon` | 代币图标（IconData） |

## 向后兼容

通过 getter 方法，旧代码仍然可以使用：

```dart
// 旧代码仍然有效
final address = token.address;  // 实际访问 contractAddress
final logo = token.logoUrl;     // 实际访问 iconUrl
final price = token.price;      // 实际访问 priceUsd
```

## 预设代币

`TokenPresets` 类包含常用代币：

- **Ethereum**: ETH, USDT, USDC, DAI
- **Solana**: SOL, USDT
- **Polygon**: MATIC, USDT
- **TRON**: TRX, TRP

使用方式：

```dart
final ethToken = TokenPresets.eth;
final trpToken = TokenPresets.trp;
```

## 迁移指南

如果你的代码使用了旧的 Token 类：

1. **更新导入**：
   ```dart
   // 旧
   import '../models/token.dart';
   
   // 新
   import '../models/token_model.dart';
   ```

2. **更新属性访问**（可选，因为有兼容性 getter）：
   ```dart
   // 推荐使用新属性名
   final address = token.contractAddress;
   final logo = token.iconUrl;
   final price = token.priceUsd;
   ```

3. **更新构造函数**：
   ```dart
   // 旧
   Token(
     address: '0x...',
     logoUrl: 'https://...',
     price: 100.0,
   )
   
   // 新
   Token(
     contractAddress: '0x...',
     iconUrl: 'https://...',
     priceUsd: 100.0,
   )
   ```

## 测试

编译项目确认没有类型错误：

```bash
flutter run
```

应该不再出现 Token 类型冲突的错误。
