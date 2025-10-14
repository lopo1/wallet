# 项目架构文档 / Project Architecture

## 📁 目录结构 / Directory Structure

```
harbor/
├── android/                    # Android平台配置
├── ios/                       # iOS平台配置
├── macos/                     # macOS平台配置
├── web/                       # Web平台配置
├── lib/                       # 主要源代码
│   ├── constants/             # 常量定义
│   │   ├── derivation_paths.dart
│   │   ├── network_constants.dart
│   │   └── password_constants.dart
│   ├── models/                # 数据模型
│   │   ├── network.dart
│   │   ├── token.dart
│   │   ├── wallet.dart
│   │   └── solana_transaction.dart
│   ├── providers/             # 状态管理
│   │   ├── wallet_provider.dart
│   │   └── theme_provider.dart
│   ├── screens/               # 页面组件
│   │   ├── home_screen.dart
│   │   ├── add_token_screen.dart
│   │   ├── create_wallet_screen.dart
│   │   ├── import_wallet_screen.dart
│   │   ├── send_screen.dart
│   │   ├── receive_screen.dart
│   │   └── settings_screen.dart
│   ├── services/              # 业务服务
│   │   ├── storage_service.dart
│   │   ├── token_service.dart
│   │   ├── solana_wallet_service.dart
│   │   └── transaction_monitor.dart
│   ├── widgets/               # 通用组件
│   │   └── sidebar.dart
│   └── main.dart              # 应用入口
├── test/                      # 测试文件
│   ├── unit/                  # 单元测试
│   ├── widget/                # 组件测试
│   ├── integration/           # 集成测试
│   └── debug/                 # 调试工具
├── docs/                      # 项目文档
│   ├── api/                   # API文档
│   ├── guides/                # 使用指南
│   ├── screenshots/           # 应用截图
│   └── architecture/          # 架构文档
├── examples/                  # 示例代码
└── assets/                    # 静态资源
```

## 🏗️ 架构设计 / Architecture Design

### MVVM 架构模式

```
View (Screens/Widgets)
    ↕
ViewModel (Providers)
    ↕
Model (Services/Models)
```

### 数据流向 / Data Flow

```
User Input → Screen → Provider → Service → API/Storage
                ↓
User Interface ← Screen ← Provider ← Service ← Response
```

## 📦 核心模块 / Core Modules

### 1. 状态管理 (State Management)

**Provider Pattern**
- `WalletProvider`: 钱包状态管理
- `ThemeProvider`: 主题状态管理

```dart
// 使用示例
Consumer<WalletProvider>(
  builder: (context, walletProvider, child) {
    return Text(walletProvider.currentWallet?.name ?? 'No Wallet');
  },
)
```

### 2. 数据模型 (Data Models)

**核心模型类**
- `Wallet`: 钱包数据模型
- `Network`: 网络配置模型
- `Token`: 代币数据模型
- `SolanaTransaction`: Solana交易模型

### 3. 服务层 (Service Layer)

**业务服务**
- `StorageService`: 本地存储服务
- `TokenService`: 代币相关服务
- `SolanaWalletService`: Solana钱包服务
- `TransactionMonitor`: 交易监控服务

### 4. 界面层 (UI Layer)

**页面组件**
- 主页面 (`HomeScreen`)
- 钱包管理 (`CreateWalletScreen`, `ImportWalletScreen`)
- 资产管理 (`AddTokenScreen`)
- 交易功能 (`SendScreen`, `ReceiveScreen`)

## 🔄 生命周期管理 / Lifecycle Management

### 应用生命周期

```dart
class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 处理应用状态变化
  }
}
```

### 资源管理

- 自动释放网络连接
- 清理定时器和监听器
- 安全存储敏感数据

## 🔐 安全架构 / Security Architecture

### 数据安全

```
Private Keys → AES Encryption → Secure Storage
Mnemonics → AES Encryption → Secure Storage
Passwords → SHA256 Hash → Local Storage
```

### 网络安全

- HTTPS通信
- 证书验证
- 请求签名验证

### 本地安全

- 生物识别认证
- 应用锁定机制
- 敏感数据加密存储

## 🌐 网络架构 / Network Architecture

### 多链支持

```
Application Layer
    ↓
Network Abstraction Layer
    ↓
┌─────────┬─────────┬─────────┬─────────┐
│Ethereum │ Polygon │   BSC   │ Solana  │
└─────────┴─────────┴─────────┴─────────┘
    ↓         ↓         ↓         ↓
┌─────────┬─────────┬─────────┬─────────┐
│Web3Dart │Web3Dart │Web3Dart │ Solana  │
│   RPC   │   RPC   │   RPC   │   RPC   │
└─────────┴─────────┴─────────┴─────────┘
```

### RPC 配置

```dart
// 网络配置示例
static const networks = {
  'ethereum': {
    'name': 'Ethereum',
    'rpcUrl': 'https://ethereum.blockpi.network/v1/rpc/...',
    'chainId': 1,
  },
  'polygon': {
    'name': 'Polygon',
    'rpcUrl': 'https://polygon-rpc.com',
    'chainId': 137,
  },
};
```

## 📱 UI架构 / UI Architecture

### 响应式设计

```dart
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final isMobile = screenWidth < 768;
  
  return isMobile ? _buildMobileLayout() : _buildDesktopLayout();
}
```

### 主题系统

```dart
// 主题配置
ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF6366F1),
    brightness: Brightness.dark,
  ),
)
```

### 组件层次

```
MaterialApp
├── ThemeProvider
├── WalletProvider
└── Router
    ├── HomeScreen
    │   ├── Sidebar
    │   ├── AssetsList
    │   └── ActionButtons
    ├── WalletScreens
    └── SettingsScreen
```

## 🧪 测试架构 / Testing Architecture

### 测试金字塔

```
    E2E Tests (少量)
       ↑
  Integration Tests (适量)
       ↑
   Unit Tests (大量)
```

### 测试分类

- **单元测试**: 业务逻辑、工具函数
- **组件测试**: Widget行为、UI交互
- **集成测试**: 端到端用户流程
- **调试工具**: 开发调试辅助

## 🔧 构建架构 / Build Architecture

### 多平台构建

```yaml
# pubspec.yaml
flutter:
  platforms:
    android:
      package: com.example.harbor
    ios:
      bundle-id: com.example.flutter-wallet
    macos:
      bundle-id: com.example.flutter-wallet
    web:
      renderer: canvaskit
```

### 环境配置

- **开发环境**: 测试网络、调试模式
- **测试环境**: 模拟数据、自动化测试
- **生产环境**: 主网、性能优化

## 📊 性能架构 / Performance Architecture

### 优化策略

1. **懒加载**: 按需加载页面和资源
2. **缓存机制**: 本地缓存网络请求
3. **虚拟化**: 大列表虚拟化渲染
4. **图片优化**: 压缩和缓存图片资源

### 监控指标

- 应用启动时间
- 页面渲染性能
- 内存使用情况
- 网络请求延迟

## 🔮 扩展架构 / Extension Architecture

### 插件系统

```dart
// 插件接口
abstract class WalletPlugin {
  String get name;
  Future<void> initialize();
  Future<void> dispose();
}

// 插件管理器
class PluginManager {
  final List<WalletPlugin> _plugins = [];
  
  void registerPlugin(WalletPlugin plugin) {
    _plugins.add(plugin);
  }
}
```

### 模块化设计

- 核心模块: 基础功能
- 网络模块: 区块链集成
- UI模块: 界面组件
- 工具模块: 辅助功能

---

这个架构设计确保了代码的可维护性、可扩展性和安全性，为项目的长期发展奠定了坚实的基础。