# 钱包服务API文档 / Wallet Service API

## 概述 / Overview

WalletProvider 是应用的核心状态管理类，负责管理所有钱包相关的操作，包括钱包创建、导入、网络切换、余额查询等功能。

## 类定义 / Class Definition

```dart
class WalletProvider extends ChangeNotifier
```

## 属性 / Properties

### 公共属性 / Public Properties

| 属性名 | 类型 | 描述 |
|--------|------|------|
| `wallets` | `List<Wallet>` | 所有钱包列表 |
| `currentWallet` | `Wallet?` | 当前选中的钱包 |
| `supportedNetworks` | `List<Network>` | 支持的网络列表 |
| `currentNetwork` | `Network?` | 当前选中的网络 |
| `isLoading` | `bool` | 是否正在加载 |
| `selectedAddress` | `String?` | 当前选中的地址 |
| `customTokens` | `List<Token>` | 自定义代币列表 |

## 方法 / Methods

### 钱包管理 / Wallet Management

#### createWallet
创建新钱包

```dart
Future<Wallet> createWallet(String name, String password)
```

**参数 / Parameters:**
- `name`: 钱包名称
- `password`: 钱包密码（8位）

**返回值 / Returns:**
- `Future<Wallet>`: 创建的钱包对象

**异常 / Exceptions:**
- `Exception`: 钱包创建失败时抛出

**示例 / Example:**
```dart
try {
  final wallet = await walletProvider.createWallet('My Wallet', '12345678');
  print('钱包创建成功: ${wallet.name}');
} catch (e) {
  print('钱包创建失败: $e');
}
```

#### importWallet
导入钱包（通过助记词）

```dart
Future<Wallet> importWallet(String name, String mnemonic, String password)
```

**参数 / Parameters:**
- `name`: 钱包名称
- `mnemonic`: 助记词（12或24个单词）
- `password`: 钱包密码

**返回值 / Returns:**
- `Future<Wallet>`: 导入的钱包对象

#### importWalletFromPrivateKey
导入钱包（通过私钥）

```dart
Future<Wallet> importWalletFromPrivateKey(String name, String privateKey, String password, String networkId)
```

**参数 / Parameters:**
- `name`: 钱包名称
- `privateKey`: 私钥
- `password`: 钱包密码
- `networkId`: 网络ID

#### setCurrentWallet
设置当前钱包

```dart
void setCurrentWallet(Wallet wallet)
```

#### deleteWallet
删除钱包

```dart
Future<void> deleteWallet(String walletId, String password)
```

### 网络管理 / Network Management

#### setCurrentNetwork
设置当前网络

```dart
void setCurrentNetwork(Network network)
```

**参数 / Parameters:**
- `network`: 要切换到的网络对象

**示例 / Example:**
```dart
final ethereumNetwork = walletProvider.supportedNetworks
    .firstWhere((n) => n.id == 'ethereum');
walletProvider.setCurrentNetwork(ethereumNetwork);
```

#### getCurrentNetworkAddress
获取当前网络的地址

```dart
String? getCurrentNetworkAddress()
```

**返回值 / Returns:**
- `String?`: 当前网络的钱包地址，如果没有则返回null

### 余额查询 / Balance Queries

#### getNetworkBalance
获取指定网络的余额

```dart
Future<double> getNetworkBalance(String networkId)
```

**参数 / Parameters:**
- `networkId`: 网络ID ('ethereum', 'polygon', 'bsc', 'bitcoin', 'solana')

**返回值 / Returns:**
- `Future<double>`: 网络余额

**示例 / Example:**
```dart
final ethBalance = await walletProvider.getNetworkBalance('ethereum');
print('以太坊余额: $ethBalance ETH');
```

#### refreshAllBalances
刷新所有网络余额

```dart
Future<void> refreshAllBalances()
```

### 代币管理 / Token Management

#### addCustomToken
添加自定义代币

```dart
Future<bool> addCustomToken(Token token)
```

**参数 / Parameters:**
- `token`: 要添加的代币对象

**返回值 / Returns:**
- `Future<bool>`: 添加成功返回true，已存在返回false

#### removeCustomToken
移除自定义代币

```dart
Future<bool> removeCustomToken(Token token)
```

#### getCustomTokensForNetwork
获取指定网络的自定义代币

```dart
List<Token> getCustomTokensForNetwork(String networkId)
```

#### getAllAssets
获取所有资产（原生代币 + 自定义代币）

```dart
List<Map<String, dynamic>> getAllAssets()
```

### 交易功能 / Transaction Features

#### sendTransaction
发送交易

```dart
Future<String> sendTransaction({
  required String toAddress,
  required double amount,
  required String networkId,
  String? tokenAddress,
  double? gasPrice,
  int? gasLimit,
})
```

**参数 / Parameters:**
- `toAddress`: 接收地址
- `amount`: 发送数量
- `networkId`: 网络ID
- `tokenAddress`: 代币合约地址（可选，发送代币时需要）
- `gasPrice`: Gas价格（可选）
- `gasLimit`: Gas限制（可选）

**返回值 / Returns:**
- `Future<String>`: 交易哈希

#### estimateGasFee
估算Gas费用

```dart
Future<double> estimateGasFee(String networkId, {String? tokenAddress})
```

### 安全功能 / Security Features

#### validatePassword
验证钱包密码

```dart
Future<bool> validatePassword(String walletId, String password)
```

#### exportPrivateKey
导出私钥

```dart
Future<String> exportPrivateKey(String walletId, String password, String networkId)
```

#### exportMnemonic
导出助记词

```dart
Future<String> exportMnemonic(String walletId, String password)
```

## 事件监听 / Event Listening

### 状态变化监听

```dart
// 监听钱包状态变化
walletProvider.addListener(() {
  print('钱包状态已更新');
  print('当前钱包: ${walletProvider.currentWallet?.name}');
  print('当前网络: ${walletProvider.currentNetwork?.name}');
});
```

### 使用Consumer监听

```dart
Consumer<WalletProvider>(
  builder: (context, walletProvider, child) {
    return Text('余额: ${walletProvider.currentBalance}');
  },
)
```

## 错误处理 / Error Handling

### 常见异常类型

| 异常类型 | 描述 | 处理方式 |
|----------|------|----------|
| `WalletException` | 钱包操作异常 | 检查参数和网络状态 |
| `NetworkException` | 网络请求异常 | 重试或切换网络 |
| `ValidationException` | 参数验证异常 | 检查输入参数格式 |
| `StorageException` | 存储操作异常 | 检查存储权限 |

### 错误处理示例

```dart
try {
  await walletProvider.sendTransaction(
    toAddress: '0x...',
    amount: 1.0,
    networkId: 'ethereum',
  );
} on WalletException catch (e) {
  print('钱包错误: ${e.message}');
} on NetworkException catch (e) {
  print('网络错误: ${e.message}');
} catch (e) {
  print('未知错误: $e');
}
```

## 最佳实践 / Best Practices

### 1. 状态管理

```dart
// ✅ 正确的使用方式
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
        if (walletProvider.isLoading) {
          return CircularProgressIndicator();
        }
        return WalletList(wallets: walletProvider.wallets);
      },
    );
  }
}
```

### 2. 异步操作

```dart
// ✅ 正确的异步处理
Future<void> createNewWallet() async {
  try {
    setState(() => isLoading = true);
    
    final wallet = await walletProvider.createWallet(
      name: nameController.text,
      password: passwordController.text,
    );
    
    // 成功处理
    Navigator.pushReplacementNamed(context, '/home');
  } catch (e) {
    // 错误处理
    showErrorDialog(e.toString());
  } finally {
    setState(() => isLoading = false);
  }
}
```

### 3. 资源清理

```dart
// ✅ 正确的资源管理
class WalletScreen extends StatefulWidget {
  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late WalletProvider walletProvider;
  
  @override
  void initState() {
    super.initState();
    walletProvider = Provider.of<WalletProvider>(context, listen: false);
    walletProvider.addListener(_onWalletStateChanged);
  }
  
  @override
  void dispose() {
    walletProvider.removeListener(_onWalletStateChanged);
    super.dispose();
  }
  
  void _onWalletStateChanged() {
    // 处理状态变化
  }
}
```

## 性能优化 / Performance Optimization

### 1. 避免不必要的重建

```dart
// ✅ 使用Selector优化性能
Selector<WalletProvider, String?>(
  selector: (context, provider) => provider.currentWallet?.name,
  builder: (context, walletName, child) {
    return Text(walletName ?? 'No Wallet');
  },
)
```

### 2. 批量操作

```dart
// ✅ 批量更新状态
Future<void> initializeWallets() async {
  // 禁用通知
  notifyListeners = false;
  
  await _loadWallets();
  await _loadNetworks();
  await _loadTokens();
  
  // 重新启用并通知
  notifyListeners = true;
  notifyListeners();
}
```

---

这个API文档提供了WalletProvider的完整使用指南，包括所有公共方法、属性、事件处理和最佳实践。