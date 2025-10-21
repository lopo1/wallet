# TRP 代币问题排查指南

## 已修复的问题

### 1. ✅ TRP 详情页显示 TRON 地址

**问题**: TRP 代币详情页面使用 `asset['id']` (即 'trp-tron') 来查找地址，但地址存储在 `addresses['tron']` 中。

**修复**: 修改了所有相关代码，使用 `networkId` 而不是 `id` 来获取地址：

```dart
// 对于代币，使用 networkId；对于原生币，使用 id
final networkId = (widget.asset['networkId'] as String?) ?? (widget.asset['id'] as String);
final addressList = currentWallet.addresses[networkId] ?? [];
```

**修改的文件**: `lib/screens/token_detail_screen.dart`

**修改的方法**:
- `_buildAccountItem()` - 显示账户列表
- `_addAccount()` - 添加新账户
- `_showSendScreen()` - 发送代币
- `_showReceiveScreen()` - 接收代币

### 2. ✅ TRP 余额查询逻辑

**实现**: 在 `home_screen.dart` 的 `_loadRealBalances()` 方法中添加了 TRC20 余额查询：

```dart
// 加载 TRC20 代币余额（TRP）
try {
  final trpBalance = await walletProvider.getTRC20Balance(
    contractAddress: 'TVcNAxqqVb3WmeGZ6PLPz8SfoTwJAHXgXQ',
    decimals: 6,
  );
  balances['trp-tron'] = trpBalance;
  debugPrint('TRP 余额: $trpBalance');
} catch (e) {
  debugPrint('获取 TRP 余额失败: $e');
  balances['trp-tron'] = 0.0;
}
```

## 调试步骤

### 1. 检查 TRP 是否显示在资产列表

**位置**: 主页资产列表

**预期**: 
- TRP 应该显示在 TRON (TRX) 下面
- 显示 "TRP" 符号
- 显示 "Custom" 标签
- 显示余额（可能为 0）

**检查方法**:
```
1. 启动应用
2. 查看主页资产列表
3. 找到 TRP 代币
4. 检查是否显示
```

### 2. 检查余额查询日志

**预期日志**:
```
flutter: === 查询 TRC20 余额 ===
flutter: 合约地址: TVcNAxqqVb3WmeGZ6PLPz8SfoTwJAHXgXQ
flutter: 持有者地址: TB6LhBWhBhmHA21bHjxNFKSEq6ZiruMzr7
flutter: 请求参数: {...}
flutter: 响应: {...}
flutter: 余额: 100.0
flutter: TRP 余额: 100.0
```

**如果看到错误**:
```
flutter: 获取 TRP 余额失败: Exception: ...
```

**可能的原因**:
1. 网络连接问题
2. RPC 节点不可用
3. 合约地址错误
4. 钱包地址格式问题

### 3. 检查 TRP 详情页地址显示

**操作**:
```
1. 点击 TRP 代币
2. 进入详情页
3. 查看 "我的账户" 部分
```

**预期**:
- 显示 TRON 地址列表
- 地址格式: T... (34个字符)
- 可以添加新地址
- 可以复制地址

**如果显示 "暂无地址"**:
- 检查是否有 TRON 钱包地址
- 尝试点击 "+" 添加新地址

### 4. 手动测试余额查询

**方法 1: 使用 Flutter DevTools**

1. 打开 Flutter DevTools
2. 在 Console 中输入:
```dart
final provider = Provider.of<WalletProvider>(context, listen: false);
final balance = await provider.getTRC20Balance(
  contractAddress: 'TVcNAxqqVb3WmeGZ6PLPz8SfoTwJAHXgXQ',
  decimals: 6,
);
print('TRP Balance: $balance');
```

**方法 2: 添加测试按钮**

在 home_screen.dart 中临时添加一个测试按钮：

```dart
ElevatedButton(
  onPressed: () async {
    final provider = Provider.of<WalletProvider>(context, listen: false);
    try {
      final balance = await provider.getTRC20Balance(
        contractAddress: 'TVcNAxqqVb3WmeGZ6PLPz8SfoTwJAHXgXQ',
        decimals: 6,
      );
      print('TRP Balance: $balance');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('TRP Balance: $balance')),
      );
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  },
  child: Text('Test TRP Balance'),
)
```

### 5. 检查 TRON RPC 连接

**测试 RPC 是否可用**:

```bash
curl -X POST https://nile.trongrid.io/wallet/triggerconstantcontract \
  -H "Content-Type: application/json" \
  -d '{
    "contract_address": "TVcNAxqqVb3WmeGZ6PLPz8SfoTwJAHXgXQ",
    "owner_address": "TB6LhBWhBhmHA21bHjxNFKSEq6ZiruMzr7",
    "function_selector": "balanceOf(address)",
    "parameter": "00000000000000000000000085c88b777318df7f1115f6541d014fdbe6c0bddb",
    "visible": true
  }'
```

**预期响应**:
```json
{
  "result": {
    "result": true
  },
  "constant_result": ["0000000000000000000000000000000000000000000000000000000005f5e100"]
}
```

## 常见问题

### Q1: TRP 余额始终显示 0

**可能原因**:
1. 钱包地址中确实没有 TRP 代币
2. 余额查询失败但被捕获了
3. RPC 节点返回错误

**解决方法**:
1. 检查控制台日志
2. 确认钱包地址是否正确
3. 在区块浏览器上查看地址余额: https://nile.tronscan.org

### Q2: 点击 TRP 后显示 "暂无地址"

**原因**: 代码使用了错误的 networkId

**已修复**: 现在使用 `asset['networkId']` 而不是 `asset['id']`

**验证**:
```dart
// 应该使用
final networkId = widget.asset['networkId']; // 'tron'

// 而不是
final networkId = widget.asset['id']; // 'trp-tron'
```

### Q3: 余额查询报错 "地址格式无效"

**可能原因**:
1. 钱包地址不是 TRON 格式
2. 地址验证逻辑有问题

**检查**:
```dart
// TRON 地址应该是 T 开头，34个字符
// 例如: TB6LhBWhBhmHA21bHjxNFKSEq6ZiruMzr7
```

### Q4: 如何获取测试 TRP 代币

**方法**:
1. 访问 TRON Nile 测试网水龙头获取 TRX
2. 联系 TRP 合约部署者获取测试代币
3. 或者使用合约的 mint 功能（如果有）

## 验证清单

- [ ] TRP 显示在资产列表中
- [ ] TRP 有 "Custom" 标签
- [ ] 点击 TRP 进入详情页
- [ ] 详情页显示 TRON 地址
- [ ] 可以添加新的 TRON 地址
- [ ] 余额查询有日志输出
- [ ] 余额显示正确（即使是 0）
- [ ] 可以复制 TRON 地址
- [ ] 可以点击发送按钮
- [ ] 发送页面显示 TRON 地址

## 相关代码位置

### 资产列表
- **文件**: `lib/screens/home_screen.dart`
- **方法**: `_getAllAssets()`, `_loadRealBalances()`

### 代币详情
- **文件**: `lib/screens/token_detail_screen.dart`
- **方法**: `_buildAccountItem()`, `_addAccount()`, `_showSendScreen()`

### TRC20 服务
- **文件**: `lib/services/trc20_service.dart`
- **方法**: `getBalance()`, `transfer()`

### 钱包提供者
- **文件**: `lib/providers/wallet_provider.dart`
- **方法**: `getTRC20Balance()`, `sendTRC20Token()`

## 下一步

如果问题仍然存在，请提供：
1. 控制台完整日志
2. 钱包地址
3. 具体的错误信息
4. 操作步骤

这将帮助进一步诊断问题。
