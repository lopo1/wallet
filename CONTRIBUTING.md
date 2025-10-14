# 贡献指南 / Contributing Guide

感谢您对 Harbor 项目的关注！我们欢迎所有形式的贡献。

Thank you for your interest in the Harbor project! We welcome all forms of contributions.

## 🌟 如何贡献 / How to Contribute

### 报告问题 / Reporting Issues

如果您发现了bug或有功能建议，请：
If you find a bug or have a feature suggestion, please:

1. 检查 [Issues](https://github.com/your-username/harbor/issues) 确保问题未被报告
   Check [Issues](https://github.com/your-username/harbor/issues) to ensure the issue hasn't been reported
2. 创建新的Issue，提供详细信息
   Create a new Issue with detailed information
3. 使用适当的标签标记问题
   Use appropriate labels to mark the issue

### 提交代码 / Submitting Code

1. **Fork 项目 / Fork the project**
   ```bash
   git clone https://github.com/your-username/harbor.git
   ```

2. **创建功能分支 / Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **进行更改 / Make your changes**
   - 遵循代码规范
   - 添加必要的测试
   - 更新相关文档

4. **提交更改 / Commit your changes**
   ```bash
   git commit -m "feat: add your feature description"
   ```

5. **推送分支 / Push the branch**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **创建 Pull Request / Create a Pull Request**

## 📝 代码规范 / Code Standards

### Dart 代码风格 / Dart Code Style

遵循 [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)：

```dart
// ✅ 好的命名
class WalletProvider extends ChangeNotifier {
  final List<Wallet> _wallets = [];
  
  Future<void> loadWallets() async {
    // 实现逻辑
  }
}

// ❌ 避免的命名
class wallet_provider extends ChangeNotifier {
  List wallets;
  
  loadwallets() {
    // 实现逻辑
  }
}
```

### 提交信息规范 / Commit Message Convention

使用 [Conventional Commits](https://www.conventionalcommits.org/) 格式：

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**类型 / Types:**
- `feat`: 新功能 / New feature
- `fix`: 修复bug / Bug fix
- `docs`: 文档更新 / Documentation update
- `style`: 代码格式 / Code formatting
- `refactor`: 重构 / Refactoring
- `test`: 测试相关 / Testing
- `chore`: 构建过程或辅助工具的变动 / Build process or auxiliary tool changes

**示例 / Examples:**
```
feat(wallet): add multi-signature wallet support
fix(transaction): resolve gas estimation error
docs(readme): update installation instructions
```

## 🧪 测试要求 / Testing Requirements

### 单元测试 / Unit Tests

为新功能添加单元测试：
Add unit tests for new features:

```dart
// test/unit/wallet_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/providers/wallet_provider.dart';

void main() {
  group('WalletProvider', () {
    test('should create wallet successfully', () async {
      final provider = WalletProvider();
      final wallet = await provider.createWallet('test-wallet');
      
      expect(wallet.name, equals('test-wallet'));
      expect(wallet.addresses, isNotEmpty);
    });
  });
}
```

### 运行测试 / Running Tests

```bash
# 运行所有测试
flutter test

# 运行特定测试文件
flutter test test/unit/wallet_provider_test.dart

# 生成覆盖率报告
flutter test --coverage
```

## 📚 文档要求 / Documentation Requirements

### 代码注释 / Code Comments

为公共API添加文档注释：
Add documentation comments for public APIs:

```dart
/// 钱包提供者，管理所有钱包相关操作
/// Wallet provider that manages all wallet-related operations
class WalletProvider extends ChangeNotifier {
  /// 创建新钱包
  /// Creates a new wallet
  /// 
  /// [name] 钱包名称 / Wallet name
  /// [password] 钱包密码 / Wallet password
  /// 
  /// Returns the created [Wallet] instance
  /// Throws [WalletException] if creation fails
  Future<Wallet> createWallet(String name, String password) async {
    // 实现逻辑
  }
}
```

### README 更新 / README Updates

如果您的更改影响用户使用方式，请更新README文档。
If your changes affect how users use the app, please update the README documentation.

## 🔍 代码审查 / Code Review

### 审查清单 / Review Checklist

在提交PR之前，请确保：
Before submitting a PR, please ensure:

- [ ] 代码遵循项目规范 / Code follows project conventions
- [ ] 添加了必要的测试 / Added necessary tests
- [ ] 测试全部通过 / All tests pass
- [ ] 更新了相关文档 / Updated relevant documentation
- [ ] 提交信息清晰明确 / Commit messages are clear
- [ ] 没有引入破坏性更改 / No breaking changes introduced

### 审查过程 / Review Process

1. 自动化检查 / Automated checks
   - 代码格式检查 / Code formatting check
   - 单元测试 / Unit tests
   - 集成测试 / Integration tests

2. 人工审查 / Manual review
   - 代码质量 / Code quality
   - 架构设计 / Architecture design
   - 安全性检查 / Security check

## 🚀 发布流程 / Release Process

### 版本号规范 / Version Numbering

遵循 [Semantic Versioning](https://semver.org/)：
Follow [Semantic Versioning](https://semver.org/):

- `MAJOR.MINOR.PATCH`
- `1.0.0` → `1.0.1` (补丁版本 / Patch version)
- `1.0.0` → `1.1.0` (次要版本 / Minor version)
- `1.0.0` → `2.0.0` (主要版本 / Major version)

### 发布检查清单 / Release Checklist

- [ ] 更新版本号 / Update version number
- [ ] 更新CHANGELOG / Update CHANGELOG
- [ ] 运行完整测试套件 / Run full test suite
- [ ] 构建发布版本 / Build release version
- [ ] 创建发布标签 / Create release tag

## 💬 社区准则 / Community Guidelines

### 行为准则 / Code of Conduct

我们致力于为每个人提供友好、安全和欢迎的环境。请：
We are committed to providing a friendly, safe and welcoming environment for everyone. Please:

- 使用友好和包容的语言 / Use friendly and inclusive language
- 尊重不同的观点和经验 / Respect different viewpoints and experiences
- 优雅地接受建设性批评 / Gracefully accept constructive criticism
- 专注于对社区最有利的事情 / Focus on what is best for the community

### 获取帮助 / Getting Help

如果您需要帮助：
If you need help:

- 查看 [文档](docs/) / Check the [documentation](docs/)
- 搜索现有的 [Issues](https://github.com/your-username/harbor/issues)
- 在 [Discussions](https://github.com/your-username/harbor/discussions) 中提问
- 联系维护者 / Contact maintainers

## 🎉 认可贡献者 / Recognizing Contributors

我们感谢所有贡献者的努力！贡献者将被列在：
We appreciate all contributors' efforts! Contributors will be listed in:

- README.md 的贡献者部分 / Contributors section in README.md
- 发布说明中 / Release notes
- 项目网站上 / Project website

---

再次感谢您的贡献！🙏
Thank you again for your contribution! 🙏