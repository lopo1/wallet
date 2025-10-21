# TRON 费用功能使用示例

## 1. 在发送界面查看费用

### TRX 转账

当用户在发送界面输入收款地址后，系统会自动显示详细的费用信息：

```
手续费                    🔄 10s后更新

┌─────────────────────────────────────┐
│ 总费用                  0.000268 TRX │
│                         $0.0000      │
├─────────────────────────────────────┤
│ 带宽                                │
│ 使用免费资源                         │
│ 268 / 5000                          │
└─────────────────────────────────────┘
```

### 向未激活地址转账

```
手续费                    🔄 10s后更新

┌─────────────────────────────────────┐
│ 总费用                  1.000268 TRX │
│                         $0.1000      │
├─────────────────────────────────────┤
│ 带宽                                │
│ 使用免费资源                         │
│ 268 / 5000                          │
├─────────────────────────────────────┤
│ ⚠️ 激活新账户                        │
│ 目标地址未激活，需额外消耗 1.0 TRX    │
└─────────────────────────────────────┘
```

### TRC20 转账（能量不足）

```
手续费                    🔄 10s后更新

┌─────────────────────────────────────┐
│ 总费用                 13.745000 TRX │
│                         $1.3745      │
├─────────────────────────────────────┤
│ 带宽                                │
│ 使用免费资源                         │
│ 345 / 5000                          │
├─────────────────────────────────────┤
│ 能量                                │
│ 消耗 13.400000 TRX                  │
│ 31895 / 0                           │
└─────────────────────────────────────┘
```

## 2. 代码集成示例

### 在 WalletProvider 中获取费用估算

```dart
// TRX 转账费用估算
final walletProvider = Provider.of<WalletProvider>(context, listen: false);

final trxFee = await walletProvider.getNetworkFeeEstimate(
  'tron',
  amount: 10.0,
  toAddress: 'TYourRecipientAddress...',
);

print('TRX 转账费用: $trxFee TRX');
```

### TRC20 转账费用估算

```dart
// TRC20 转账费用估算
final trc20FeeEstimate = await walletProvider.getTrc20FeeEstimate(
  contractAddress: 'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t', // USDT
  toAddress: 'TYourRecipientAddress...',
  amount: 100.0,
  decimals: 6,
);

print('总费用: ${trc20FeeEstimate.totalFeeTrx} TRX');
print('带宽费用: ${trc20FeeEstimate.bandwidthFeeTrx} TRX');
print('能量费用: ${trc20FeeEstimate.energyFeeTrx} TRX');
print('激活费用: ${trc20FeeEstimate.activationFeeTrx} TRX');
print('需要激活: ${trc20FeeEstimate.needsActivation}');
```

### 直接使用 TronFeeService

```dart
import 'package:flutter_wallet/services/tron_fee_service.dart';

// 检查地址是否激活
final isActivated = await TronFeeService.isAccountActivated(
  address: 'TYourAddress...',
  tronRpcBaseUrl: 'https://nile.trongrid.io',
);

print('地址已激活: $isActivated');

// 获取账户资源
final resources = await TronFeeService.getAccountResources(
  address: 'TYourAddress...',
  tronRpcBaseUrl: 'https://nile.trongrid.io',
);

print('可用带宽: ${resources['availableBandwidth']}');
print('可用能量: ${resources['availableEnergy']}');

// TRX 转账费用估算
final feeEstimate = await TronFeeService.estimateTrxTransferFee(
  fromAddress: 'TYourFromAddress...',
  toAddress: 'TYourToAddress...',
  amountTRX: 10.0,
  tronRpcBaseUrl: 'https://nile.trongrid.io',
);

print('费用详情:');
print(feeEstimate.getDetailedDescription());
```

## 3. 费用估算结果对象

### TronFeeEstimate 属性

```dart
class TronFeeEstimate {
  final int bandwidthRequired;      // 需要的带宽
  final int bandwidthAvailable;     // 可用的带宽
  final double bandwidthFeeTrx;     // 带宽费用（TRX）
  final double activationFeeTrx;    // 激活费用（TRX）
  final double totalFeeTrx;         // 总费用（TRX）
  final bool isToAddressActivated;  // 目标地址是否已激活
  final int energyRequired;         // 需要的能量
  final int energyAvailable;        // 可用的能量
  final double energyFeeTrx;        // 能量费用（TRX）
  
  // 辅助方法
  String getDetailedDescription();  // 获取详细描述
  bool get needsActivation;         // 是否需要激活
  bool get needsBandwidthFee;       // 是否需要支付带宽费用
  bool get needsEnergyFee;          // 是否需要支付能量费用
}
```

## 4. 常见场景处理

### 场景 1：用户有足够的免费带宽

```dart
// 用户每日有 5000 点免费带宽
// TRX 转账需要约 268 点带宽
// 结果：使用免费带宽，无需支付费用

final estimate = await TronFeeService.estimateTrxTransferFee(...);
// estimate.bandwidthFeeTrx == 0.0
// estimate.totalFeeTrx == 0.0 (假设目标地址已激活)
```

### 场景 2：用户带宽不足

```dart
// 用户已用完免费带宽
// 需要支付带宽费用

final estimate = await TronFeeService.estimateTrxTransferFee(...);
// estimate.bandwidthFeeTrx == 0.268 TRX (268 × 0.001)
// estimate.totalFeeTrx == 0.268 TRX
```

### 场景 3：向未激活地址转账

```dart
// 目标地址从未接收过任何资产
// 需要支付激活费用

final estimate = await TronFeeService.estimateTrxTransferFee(...);
// estimate.activationFeeTrx == 1.0 TRX
// estimate.totalFeeTrx == 1.268 TRX (带宽 + 激活)
```

### 场景 4：TRC20 转账（无能量）

```dart
// 用户没有质押 TRX 获取能量
// 需要支付高额能量费用

final estimate = await TronFeeService.estimateTrc20TransferFee(...);
// estimate.energyFeeTrx == 13.4 TRX (31895 × 0.00042)
// estimate.bandwidthFeeTrx == 0.345 TRX
// estimate.totalFeeTrx == 13.745 TRX
```

### 场景 5：TRC20 转账（有能量）

```dart
// 用户通过质押 TRX 获得了足够的能量
// 只需支付带宽费用

final estimate = await TronFeeService.estimateTrc20TransferFee(...);
// estimate.energyFeeTrx == 0.0 TRX (使用质押能量)
// estimate.bandwidthFeeTrx == 0.0 TRX (使用免费带宽)
// estimate.totalFeeTrx == 0.0 TRX
```

## 5. 错误处理

### 网络错误

```dart
try {
  final estimate = await TronFeeService.estimateTrxTransferFee(...);
  // 使用估算结果
} catch (e) {
  print('费用估算失败: $e');
  // 使用默认费用
  final defaultFee = 0.1; // TRX
}
```

### RPC 不可用

```dart
// WalletProvider 会自动尝试备用 RPC
final estimate = await walletProvider.getNetworkFeeEstimate(
  'tron',
  amount: 10.0,
  toAddress: 'TYourAddress...',
);
// 如果所有 RPC 都失败，返回默认值 0.1 TRX
```

## 6. 性能优化建议

### 缓存费用估算结果

```dart
// 在发送界面中
TronFeeEstimate? _cachedFeeEstimate;
String? _lastToAddress;

Future<void> _loadFee(String toAddress) async {
  // 如果地址没变，使用缓存
  if (toAddress == _lastToAddress && _cachedFeeEstimate != null) {
    return;
  }
  
  // 重新估算
  _cachedFeeEstimate = await TronFeeService.estimateTrxTransferFee(...);
  _lastToAddress = toAddress;
}
```

### 防抖动

```dart
// 用户输入地址时，延迟查询
Timer? _debounceTimer;

void _onAddressChanged(String address) {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(Duration(milliseconds: 500), () {
    _loadFee(address);
  });
}
```

## 7. UI 集成提示

### 显示加载状态

```dart
bool _isLoadingFee = false;

Widget build(BuildContext context) {
  return Column(
    children: [
      if (_isLoadingFee)
        CircularProgressIndicator()
      else if (_tronFeeEstimate != null)
        _buildTronFeeDetails()
      else
        Text('请输入收款地址以查看费用'),
    ],
  );
}
```

### 警告用户高额费用

```dart
if (_tronFeeEstimate != null && _tronFeeEstimate!.totalFeeTrx > 10.0) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('高额手续费警告'),
      content: Text(
        '此次转账需要支付 ${_tronFeeEstimate!.totalFeeTrx.toStringAsFixed(2)} TRX 的手续费。\n\n'
        '建议：质押 TRX 以获取能量，可大幅降低 TRC20 转账费用。'
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('我知道了'),
        ),
      ],
    ),
  );
}
```

## 8. 测试用例

### 单元测试示例

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wallet/services/tron_fee_service.dart';

void main() {
  group('TronFeeService', () {
    test('检查已激活地址', () async {
      final isActivated = await TronFeeService.isAccountActivated(
        address: 'TKnownActivatedAddress...',
        tronRpcBaseUrl: 'https://nile.trongrid.io',
      );
      expect(isActivated, true);
    });
    
    test('检查未激活地址', () async {
      final isActivated = await TronFeeService.isAccountActivated(
        address: 'TNewAddress...',
        tronRpcBaseUrl: 'https://nile.trongrid.io',
      );
      expect(isActivated, false);
    });
    
    test('TRX 转账费用估算', () async {
      final estimate = await TronFeeService.estimateTrxTransferFee(
        fromAddress: 'TYourFromAddress...',
        toAddress: 'TYourToAddress...',
        amountTRX: 10.0,
        tronRpcBaseUrl: 'https://nile.trongrid.io',
      );
      
      expect(estimate.bandwidthRequired, 268);
      expect(estimate.totalFeeTrx, greaterThanOrEqualTo(0.0));
    });
  });
}
```

## 9. 常见问题

### Q: 为什么 TRC20 转账费用这么高？
A: TRC20 转账需要消耗能量。如果没有质押 TRX 获取能量，需要按市场价格支付，约 13.4 TRX。建议质押 TRX 以获取免费能量。

### Q: 如何降低 TRC20 转账费用？
A: 
1. 质押 TRX 获取能量
2. 使用有能量的地址发送
3. 选择网络不拥堵的时间转账

### Q: 激活费用是什么？
A: TRON 网络要求每个地址在首次接收资产时需要被激活，激活费用为 1 TRX，由发送方支付。

### Q: 免费带宽什么时候重置？
A: 每个账户每日有 5000 点免费带宽，每 24 小时重置一次。

### Q: 费用估算准确吗？
A: 费用估算基于当前网络状态，实际费用可能略有差异（通常在 ±5% 范围内）。
