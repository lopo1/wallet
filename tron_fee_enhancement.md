# TRON 转账费用增强

## 概述

为 TRON 链的转账功能添加了详细的费用估算和显示，包括：
1. 向未激活地址转账时的激活费用（1 TRX）
2. 带宽消耗和费用显示
3. TRC20 代币转账的能量消耗和费用显示

## 实现的功能

### 1. TRON 费用估算服务 (`lib/services/tron_fee_service.dart`)

新增了 `TronFeeService` 类，提供以下功能：

#### 账户激活检查
- `isAccountActivated()`: 检查目标地址是否已在链上激活
- 未激活的地址需要额外支付 1 TRX 的激活费用

#### 资源查询
- `getAccountResources()`: 查询账户的带宽和能量资源
  - 免费带宽：每日 5000 点
  - 质押带宽：通过质押 TRX 获得
  - 质押能量：通过质押 TRX 获得

#### TRX 转账费用估算
- `estimateTrxTransferFee()`: 估算 TRX 原生代币转账费用
  - 带宽需求：约 268 点
  - 如果带宽不足，按 1000 SUN/点 计算费用
  - 如果目标地址未激活，额外 1 TRX

#### TRC20 转账费用估算
- `estimateTrc20TransferFee()`: 估算 TRC20 代币转账费用
  - 带宽需求：约 345 点
  - 能量需求：约 31895 点
  - 如果资源不足，按市场价格计算费用
  - 如果目标地址未激活，额外 1 TRX

### 2. WalletProvider 集成

在 `lib/providers/wallet_provider.dart` 中添加：

#### TRON 费用估算方法
```dart
Future<double> _getTronFeeEstimate({
  String? rpcUrl,
  double? amount,
  String? toAddress,
})
```
- 集成到 `getNetworkFeeEstimate()` 方法中
- 根据目标地址动态计算费用

#### TRC20 费用估算方法
```dart
Future<TronFeeEstimate> getTrc20FeeEstimate({
  required String contractAddress,
  required String toAddress,
  required double amount,
  required int decimals,
  String? rpcUrl,
})
```
- 专门用于 TRC20 代币的费用估算
- 返回详细的费用信息对象

### 3. 发送界面增强 (`lib/screens/send_detail_screen.dart`)

#### 新增状态变量
```dart
TronFeeEstimate? _tronFeeEstimate; // Tron 费用估算详情
```

#### 费用加载逻辑更新
- `_loadGasFee()`: 增加对 TRON 和 TRC20 的特殊处理
- `_loadTronFeeDetails()`: 加载 TRON 详细费用信息

#### UI 显示增强

##### TRON 费用详情显示 (`_buildTronFeeDetails()`)
显示内容包括：
1. **总费用**：以 TRX 和 USD 显示
2. **带宽消耗**：
   - 显示需求量和可用量
   - 如果使用免费/质押资源，显示"使用免费资源"
   - 如果需要支付，显示具体 TRX 金额
3. **能量消耗**（仅 TRC20）：
   - 显示需求量和可用量
   - 如果使用质押资源，显示"使用质押资源"
   - 如果需要支付，显示具体 TRX 金额
4. **激活警告**（如果需要）：
   - 橙色警告框
   - 说明需要激活新账户及费用

##### 标准费用显示 (`_buildStandardFeeDisplay()`)
用于非 TRON 网络的费用显示，保持原有样式

## 费用计算规则

### TRX 转账
```
总费用 = 带宽费用 + 激活费用

带宽费用 = max(0, (需要带宽 - 可用带宽) × 0.001 TRX)
激活费用 = 目标地址未激活 ? 1 TRX : 0 TRX
```

### TRC20 转账
```
总费用 = 带宽费用 + 能量费用 + 激活费用

带宽费用 = max(0, (需要带宽 - 可用带宽) × 0.001 TRX)
能量费用 = max(0, (需要能量 - 可用能量) × 0.00042 TRX)
激活费用 = 目标地址未激活 ? 1 TRX : 0 TRX
```

## 用户体验改进

### 1. 实时费用更新
- 当用户输入收款地址后，自动查询目标地址状态
- 动态显示是否需要激活费用
- 每 10 秒自动刷新费用估算

### 2. 清晰的费用明细
- 分项显示各项费用
- 用颜色区分：
  - 绿色：使用免费/质押资源
  - 橙色：需要支付 TRX
- 显示资源使用情况（已用/总量）

### 3. 激活警告
- 醒目的橙色警告框
- 明确说明激活费用
- 帮助用户理解额外费用的原因

## 技术细节

### API 调用
1. `/wallet/getaccount`: 检查账户是否激活
2. `/wallet/getaccountresource`: 查询账户资源

### 资源类型
- **免费带宽**：每个账户每日 5000 点
- **质押带宽**：通过质押 TRX 获得
- **质押能量**：通过质押 TRX 获得

### 费用单位
- 1 TRX = 1,000,000 SUN
- 带宽：约 1000 SUN/点
- 能量：约 420 SUN/点

## 测试建议

### 测试场景

1. **向已激活地址转账 TRX**
   - 应显示较低费用（仅带宽）
   - 不显示激活警告

2. **向未激活地址转账 TRX**
   - 应显示激活警告
   - 总费用应包含 1 TRX 激活费

3. **TRC20 转账（有足够能量）**
   - 显示能量使用情况
   - 显示"使用质押资源"

4. **TRC20 转账（能量不足）**
   - 显示能量费用（约 13.4 TRX）
   - 总费用较高

5. **输入地址前**
   - 显示默认估算费用
   - 不显示详细明细

6. **输入地址后**
   - 自动更新费用
   - 显示详细明细

## 注意事项

1. **网络延迟**：费用查询需要调用 TRON RPC，可能有延迟
2. **费用波动**：能量和带宽价格可能随市场波动
3. **资源消耗**：实际消耗可能略有差异
4. **测试网络**：当前使用 Nile 测试网，主网费用可能不同

## 未来改进

1. 添加费用历史记录
2. 支持自定义费用限制
3. 显示预计交易时间
4. 添加资源租赁建议
5. 支持批量转账费用估算
