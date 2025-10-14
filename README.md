#  Wallet - 多链去中心化钱包

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)

一个功能完整的多链去中心化钱包，支持以太坊、Polygon、BSC、比特币和Solana网络。

[English](README_EN.md) | 中文

</div>

## ✨ 功能特性

### 🔐 钱包管理
- **多钱包支持** - 创建和管理多个钱包
- **助记词导入/导出** - 支持BIP39标准助记词
- **私钥导入** - 直接通过私钥导入钱包
- **安全存储** - 本地加密存储钱包数据

### 🌐 多链支持
- **以太坊 (Ethereum)** - 支持ETH和ERC-20代币
- **Polygon** - 支持MATIC和Polygon代币
- **币安智能链 (BSC)** - 支持BNB和BEP-20代币
- **比特币 (Bitcoin)** - 支持原生BTC交易
- **Solana** - 支持SOL和SPL代币

### 💰 资产管理
- **实时余额查询** - 多链资产余额实时更新
- **自定义代币** - 添加和管理自定义ERC-20/BEP-20代币
- **NFT收藏品** - 查看和管理NFT收藏品
- **交易历史** - 完整的交易记录查看

### 💸 交易功能
- **发送代币** - 支持多链代币转账
- **接收代币** - 生成收款地址和二维码
- **代币兑换** - 内置DEX交换功能
- **Gas费估算** - 智能Gas费用计算

### 🎨 用户体验
- **深色主题** - 现代化的深色界面设计
- **响应式布局** - 适配桌面和移动端
- **多语言支持** - 中文和英文界面
- **流畅动画** - 丰富的交互动画效果

## 🚀 快速开始

### 环境要求

- Flutter SDK >= 3.10.0
- Dart SDK >= 3.0.0
- Android Studio / VS Code
- iOS 11.0+ / Android 5.0+

### 安装步骤

1. **克隆项目**
   ```bash
   git clone https://github.com/your-username/harbor.git
   cd harbor
   ```

2. **安装依赖**
   ```bash
   flutter pub get
   ```

3. **运行应用**
   ```bash
   # 调试模式
   flutter run
   
   # 发布模式
   flutter run --release
   ```

### 支持平台

- ✅ **Android** - Android 5.0+ (API 21+)
- ✅ **iOS** - iOS 11.0+
- ✅ **macOS** - macOS 10.14+
- ✅ **Windows** - Windows 10+
- ✅ **Linux** - Ubuntu 18.04+
- ✅ **Web** - 现代浏览器支持

## 📱 应用截图

<div align="center">
  <img src="docs/screenshots/home.png" width="200" alt="主页面" />
  <img src="docs/screenshots/wallet.png" width="200" alt="钱包管理" />
  <img src="docs/screenshots/assets.png" width="200" alt="资产管理" />
  <img src="docs/screenshots/send.png" width="200" alt="发送代币" />
</div>

## 🏗️ 项目架构

### 目录结构
```
lib/
├── constants/          # 常量定义
├── models/            # 数据模型
├── providers/         # 状态管理
├── screens/           # 页面组件
├── services/          # 业务服务
├── widgets/           # 通用组件
└── main.dart          # 应用入口

docs/                  # 项目文档
├── api/              # API文档
├── screenshots/      # 应用截图
└── guides/           # 使用指南

test/                 # 测试文件
├── unit/            # 单元测试
├── widget/          # 组件测试
└── integration/     # 集成测试
```

### 核心技术栈

- **状态管理**: Provider
- **网络请求**: HTTP + Dio
- **本地存储**: SharedPreferences + SecureStorage
- **加密算法**: Crypto + PointyCastle
- **区块链**: Web3Dart + Solana
- **二维码**: QR Flutter
- **UI组件**: Material Design 3

## 🔧 开发指南

### 添加新的区块链网络

1. 在 `lib/constants/network_constants.dart` 中定义网络配置
2. 在 `lib/services/` 中创建对应的服务类
3. 在 `lib/providers/wallet_provider.dart` 中添加网络支持
4. 更新UI组件以支持新网络

### 添加新的代币类型

1. 扩展 `lib/models/token.dart` 模型
2. 在 `lib/services/token_service.dart` 中添加代币查询逻辑
3. 更新资产显示组件

### 自定义主题

修改 `lib/constants/theme_constants.dart` 中的主题配置：

```dart
// 自定义颜色
static const primaryColor = Color(0xFF6366F1);
static const backgroundColor = Color(0xFF1A1B23);
```

## 🧪 测试

### 运行测试

```bash
# 运行所有测试
flutter test

# 运行单元测试
flutter test test/unit/

# 运行组件测试
flutter test test/widget/

# 运行集成测试
flutter test test/integration/
```

### 测试覆盖率

```bash
# 生成测试覆盖率报告
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## 📚 API文档

详细的API文档请查看：
- [钱包服务API](docs/api/wallet_service.md)
- [代币服务API](docs/api/token_service.md)
- [交易服务API](docs/api/transaction_service.md)

## 🤝 贡献指南

我们欢迎所有形式的贡献！请查看 [CONTRIBUTING.md](CONTRIBUTING.md) 了解详细信息。

### 贡献流程

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 🔒 安全性

### 安全特性
- 🔐 本地加密存储私钥和助记词
- 🛡️ 安全的密码策略
- 🔒 交易签名本地完成
- 🚫 不上传敏感信息到服务器

### 安全建议
- 定期备份助记词
- 使用强密码保护钱包
- 在安全环境中使用应用
- 及时更新到最新版本

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🙏 致谢

感谢以下开源项目的支持：
- [Flutter](https://flutter.dev/) - Google的UI工具包
- [Web3Dart](https://pub.dev/packages/web3dart) - 以太坊Dart客户端
- [Solana](https://pub.dev/packages/solana) - Solana Dart SDK
- [BIP39](https://pub.dev/packages/bip39) - 助记词生成库

## 📞 联系我们

- **项目主页**: [GitHub Repository](https://github.com/your-username/harbor)
- **问题反馈**: [Issues](https://github.com/your-username/harbor/issues)
- **功能建议**: [Discussions](https://github.com/your-username/harbor/discussions)

---

<div align="center">
  <p>如果这个项目对你有帮助，请给我们一个 ⭐️</p>
  <p>Made with ❤️ by Harbor Team</p>
</div>