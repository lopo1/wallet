# TRP 代币资产列表集成

## 完成的工作

已成功将 TRP 代币添加到资产列表中。

## 修改内容

### 1. 在资产列表中添加 TRP

**文件**: `lib/screens/home_screen.dart`

在 `_getAllAssets()` 方法的原生资产列表中添加了 TRP 代币：

```dart
{
  'id': 'trp-tron',
  'name': 'TRP Token',
  'symbol': 'TRP',
  'icon': Icons.token,
  'color': const Color(0xFF00D4AA),
  'price': 0.0,
  'change24h': 0.0,
  'isNative': false,
  'networkId': 'tron',
  'contractAddress': 'TVcNAxqqVb3WmeGZ6PLPz8SfoTwJAHXgXQ',
  'decimals': 6,
},
```

### 2. 添加 TRP 余额查询

在 `_loadRealBalances()` 方法中添加了 TRC20 代币余额查询：

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

## TRP 代币信息

- **ID**: `trp-tron`
- **名称**: TRP Token
- **符号**: TRP
- **合约地址**: `TVcNAxqqVb3WmeGZ6PLPz8SfoTwJAHXgXQ`
- **网络**: TRON (Nile 测试网)
- **小数位**: 6
- **颜色**: #00D4AA
- **图标**: Icons.token

## 功能特性

### 1. 显示在资产列表

TRP 代币现在会显示在主页的资产列表中，位于 TRON (TRX) 之后。

### 2. 实时余额查询

- 应用启动时自动查询 TRP 余额
- 下拉刷新时更新余额
- 使用 `getTRC20Balance()` 方法查询

### 3. 资产详情

点击 TRP 代币可以查看详细信息：
- 当前余额
- USD 价值（当前为 $0，可以后续更新）
- 24小时变化

### 4. 标记为自定义代币

TRP 显示 "Custom" 标签，表明它是一个自定义/非原生代币。

## 使用流程

1. **启动应用**
   - 应用自动加载所有资产余额
   - 包括 TRP 代币余额

2. **查看余额**
   - 在主页资产列表中找到 TRP
   - 显示当前持有的 TRP 数量

3. **刷新余额**
   - 下拉刷新资产列表
   - TRP 余额会重新查询

4. **查看详情**
   - 点击 TRP 资产项
   - 进入代币详情页面

## 余额查询流程

```
启动应用
  ↓
_loadRealBalances()
  ↓
查询原生代币余额 (ETH, BTC, SOL, TRX...)
  ↓
查询 TRC20 代币余额 (TRP)
  ↓
walletProvider.getTRC20Balance()
  ↓
TRC20Service.getBalance()
  ↓
调用 TRON RPC: triggerconstantcontract
  ↓
balanceOf(address)
  ↓
返回余额并显示
```

## 调试信息

应用会输出以下调试日志：

```
flutter: === 查询 TRC20 余额 ===
flutter: 合约地址: TVcNAxqqVb3WmeGZ6PLPz8SfoTwJAHXgXQ
flutter: 持有者地址: TB6LhBWhBhmHA21bHjxNFKSEq6ZiruMzr7
flutter: 请求参数: {...}
flutter: 响应: {...}
flutter: 余额: 100.0
flutter: TRP 余额: 100.0
```

## 扩展其他 TRC20 代币

如果要添加更多 TRC20 代币，按照相同的模式：

### 1. 在资产列表中添加

```dart
{
  'id': 'token-id',
  'name': 'Token Name',
  'symbol': 'SYMBOL',
  'icon': Icons.token,
  'color': const Color(0xFFXXXXXX),
  'price': 0.0,
  'change24h': 0.0,
  'isNative': false,
  'networkId': 'tron',
  'contractAddress': 'T...',
  'decimals': 6,
},
```

### 2. 在余额加载中添加查询

```dart
try {
  final balance = await walletProvider.getTRC20Balance(
    contractAddress: 'T...',
    decimals: 6,
  );
  balances['token-id'] = balance;
} catch (e) {
  debugPrint('获取余额失败: $e');
  balances['token-id'] = 0.0;
}
```

## 注意事项

1. **网络要求**: 确保连接到 TRON Nile 测试网
2. **RPC 限制**: 公共 RPC 可能有速率限制
3. **余额更新**: 余额不会实时更新，需要手动刷新
4. **价格数据**: 当前价格为 $0，需要集成价格 API

## 测试建议

1. **获取测试代币**:
   - 访问 TRON Nile 测试网水龙头
   - 获取一些 TRP 测试代币

2. **验证余额显示**:
   - 启动应用
   - 检查 TRP 是否显示在资产列表中
   - 验证余额是否正确

3. **测试刷新**:
   - 下拉刷新资产列表
   - 验证 TRP 余额是否更新

4. **测试转账**:
   - 点击 TRP 资产
   - 尝试发送 TRP 代币
   - 验证交易是否成功

## 相关文件

- `lib/screens/home_screen.dart` - 主页和资产列表
- `lib/providers/wallet_provider.dart` - TRC20 余额查询方法
- `lib/services/trc20_service.dart` - TRC20 服务实现
- `lib/models/token_model.dart` - Token 模型定义

## 区块浏览器

查看 TRP 合约和交易：
- **合约地址**: https://nile.tronscan.org/#/contract/TVcNAxqqVb3WmeGZ6PLPz8SfoTwJAHXgXQ
- **测试网浏览器**: https://nile.tronscan.org

---

**状态**: ✅ 已完成
**测试**: 待测试
**下一步**: 获取测试代币并验证功能
