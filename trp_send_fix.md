# TRP 发送功能修复

## 问题描述

点击 TRP 代币时进入的是 TRX 原生币发送界面，而不是 TRC20 代币发送界面。

## 问题分析

1. **TokenDetailScreen** 正确传递了 `preselectedToken` 参数
2. **SendDetailScreen** 没有接收和处理 `preselectedToken` 参数
3. **SendDetailScreen** 只调用 `sendTransaction()`，这个方法只能发送原生币

## 修复内容

### 1. 修改 SendDetailScreen 构造函数

**文件**: `lib/screens/send_detail_screen.dart`

```dart
class SendDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? preselectedToken;

  const SendDetailScreen({
    super.key,
    this.preselectedToken,
  });
}
```

### 2. 添加代币状态变量

```dart
Map<String, dynamic>? _selectedToken; // 选中的代币
```

### 3. 初始化时接收 preselectedToken

```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
  if (args != null) {
    setState(() {
      network = args['network'] as Network?;
      address = args['address'] as String?;
      _selectedToken = args['preselectedToken'] as Map<String, dynamic>?;
    });
    _loadInitialData();
  }
});
```

### 4. 修改余额加载逻辑

```dart
Future<void> _loadRealBalance() async {
  // ...
  
  // 判断是否为 TRC20 代币
  final isNative = _selectedToken?['isNative'] ?? true;
  final isTRC20 = !isNative && 
                  _selectedToken?['networkId'] == 'tron' && 
                  _selectedToken?['contractAddress'] != null;

  if (isTRC20) {
    // 获取 TRC20 代币余额
    realBalance = await walletProvider.getTRC20Balance(
      contractAddress: contractAddress,
      decimals: decimals,
    );
  } else {
    // 获取原生币余额
    realBalance = await walletProvider.getNetworkBalance(network!.id);
  }
}
```

### 5. 修改发送交易逻辑

```dart
Future<void> _sendTransaction() async {
  // ...
  
  // 判断是否为 TRC20 代币
  final isNative = _selectedToken?['isNative'] ?? true;
  final isTRC20 = !isNative && 
                  _selectedToken?['networkId'] == 'tron' && 
                  _selectedToken?['contractAddress'] != null;

  if (isTRC20) {
    // 发送 TRC20 代币
    txHash = await walletProvider.sendTRC20Token(
      contractAddress: contractAddress,
      toAddress: recipient,
      amount: amount,
      decimals: decimals,
      password: password,
    );
  } else {
    // 发送原生代币
    txHash = await walletProvider.sendTransaction(
      networkId: network!.id,
      toAddress: recipient,
      amount: amount,
      password: password,
      memo: memo.isNotEmpty ? memo : null,
    );
  }
}
```

## 工作流程

### 点击 TRP 代币

1. **HomeScreen** → 点击 TRP 资产卡片
2. **TokenDetailScreen** → 显示 TRP 详情
3. 点击"发送"按钮 → 调用 `_navigateToSend()`
4. 传递参数：
   ```dart
   {
     'network': tronNetwork,
     'address': tronAddress,
     'preselectedToken': {
       'id': 'trp-tron',
       'name': 'TRP Token',
       'symbol': 'TRP',
       'isNative': false,
       'networkId': 'tron',
       'contractAddress': 'TVcNAxqqVb3WmeGZ6PLPz8SfoTwJAHXgXQ',
       'decimals': 6,
     }
   }
   ```
5. **SendDetailScreen** → 接收参数并识别为 TRC20 代币
6. 加载 TRC20 余额
7. 发送时调用 `sendTRC20Token()` 而不是 `sendTransaction()`

### 点击 TRX 原生币

1. **HomeScreen** → 点击 TRX 资产卡片
2. **TokenDetailScreen** → 显示 TRX 详情
3. 点击"发送"按钮
4. 传递参数：
   ```dart
   {
     'network': tronNetwork,
     'address': tronAddress,
     'preselectedToken': {
       'id': 'tron',
       'symbol': 'TRX',
       'isNative': true,
     }
   }
   ```
5. **SendDetailScreen** → 识别为原生币
6. 加载原生币余额
7. 发送时调用 `sendTransaction()`

## 代币识别逻辑

```dart
final isNative = _selectedToken?['isNative'] ?? true;
final isTRC20 = !isNative && 
                _selectedToken?['networkId'] == 'tron' && 
                _selectedToken?['contractAddress'] != null;
```

- **原生币**: `isNative == true`
- **TRC20 代币**: `isNative == false` + `networkId == 'tron'` + 有 `contractAddress`

## UI 显示修复

### 修改代币名称显示

**AppBar 标题**:
```dart
Text(
  _selectedToken?['symbol'] as String? ?? network?.symbol ?? 'USDT',
  style: const TextStyle(
    color: Colors.white70,
    fontSize: 14,
  ),
),
```

**余额显示**:
```dart
Text(
  '可用: ${balance.toString()} ${_selectedToken?['symbol'] as String? ?? network?.symbol ?? 'USDT'}',
  style: const TextStyle(color: Colors.white54),
),
```

**金额输入区域**:
```dart
Text(
  _selectedToken?['symbol'] as String? ?? network?.symbol ?? 'USDT',
  style: const TextStyle(
    color: Colors.white54,
    fontSize: 16,
  ),
),
```

**确认对话框**:
```dart
Text(
  '金额: $amount ${_selectedToken?['symbol'] as String? ?? network!.symbol}',
  style: const TextStyle(color: Colors.white70),
),
```

**注意**: Gas 费用始终显示网络原生代币符号（如 TRX），因为 TRC20 转账需要 TRX 作为 Gas。

## 测试步骤

1. **重启应用**
2. **点击 TRP 代币**
3. **点击"发送"按钮**
4. **验证**:
   - ✅ AppBar 显示 "TRP"（不是 TRX）
   - ✅ 余额显示 "可用: xxx TRP"
   - ✅ 金额输入区域显示 "TRP"
   - ✅ 显示的余额是 TRP 余额（不是 TRX）
   - ✅ 控制台日志显示"加载 TRC20 余额"
   - ✅ Gas 费用显示 "TRX"（正确，因为需要 TRX 支付 Gas）
   - 输入接收地址和金额
   - 点击发送
   - ✅ 确认对话框显示 "金额: xxx TRP"
   - ✅ 控制台日志显示"发送 TRC20 代币"
   - 交易成功提交

5. **点击 TRX 原生币**
6. **点击"发送"按钮**
7. **验证**:
   - ✅ AppBar 显示 "TRX"
   - ✅ 余额显示 "可用: xxx TRX"
   - ✅ 显示的余额是 TRX 余额
   - ✅ 控制台日志显示原生币余额加载
   - ✅ 发送时调用原生币发送方法

## 相关文件

- `lib/screens/token_detail_screen.dart` - 代币详情页，传递 preselectedToken
- `lib/screens/send_detail_screen.dart` - 发送详情页，处理 TRC20 和原生币
- `lib/providers/wallet_provider.dart` - 提供 getTRC20Balance 和 sendTRC20Token 方法
- `lib/services/trc20_service.dart` - TRC20 服务实现

## 注意事项

1. **地址验证**: TRC20 转账使用 TRON 地址格式（T 开头）
2. **余额精度**: TRP 使用 6 位小数
3. **Gas 费用**: TRC20 转账需要 TRX 作为 Gas 费用
4. **合约地址**: TRP 合约地址 `TVcNAxqqVb3WmeGZ6PLPz8SfoTwJAHXgXQ`

---

**状态**: ✅ 已修复
**测试**: 待验证
**影响**: TRC20 代币发送功能
