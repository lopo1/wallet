#  Wallet - Multi-Chain Decentralized Wallet

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)

A feature-complete multi-chain decentralized wallet supporting Ethereum, Polygon, BSC, Bitcoin, and Solana networks.

English | [中文](README.md)

</div>

## ✨ Features

### 🔐 Wallet Management
- **Multi-Wallet Support** - Create and manage multiple wallets
- **Mnemonic Import/Export** - Support for BIP39 standard mnemonics
- **Private Key Import** - Direct wallet import via private keys
- **Secure Storage** - Local encrypted storage of wallet data

### 🌐 Multi-Chain Support
- **Ethereum** - Support for ETH and ERC-20 tokens
- **Polygon** - Support for MATIC and Polygon tokens
- **Binance Smart Chain (BSC)** - Support for BNB and BEP-20 tokens
- **Bitcoin** - Support for native BTC transactions
- **Solana** - Support for SOL and SPL tokens

### 💰 Asset Management
- **Real-time Balance Queries** - Multi-chain asset balance updates
- **Custom Tokens** - Add and manage custom ERC-20/BEP-20 tokens
- **NFT Collectibles** - View and manage NFT collections
- **Transaction History** - Complete transaction record viewing

### 💸 Transaction Features
- **Send Tokens** - Multi-chain token transfers
- **Receive Tokens** - Generate receiving addresses and QR codes
- **Token Swapping** - Built-in DEX exchange functionality
- **Gas Fee Estimation** - Smart gas fee calculation

### 🎨 User Experience
- **Dark Theme** - Modern dark interface design
- **Responsive Layout** - Desktop and mobile adaptation
- **Multi-language Support** - Chinese and English interfaces
- **Smooth Animations** - Rich interactive animation effects

## 🚀 Quick Start

### Requirements

- Flutter SDK >= 3.10.0
- Dart SDK >= 3.0.0
- Android Studio / VS Code
- iOS 11.0+ / Android 5.0+

### Installation

1. **Clone the project**
   ```bash
   git clone https://github.com/your-username/harbor.git
   cd harbor
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   # Debug mode
   flutter run
   
   # Release mode
   flutter run --release
   ```

### Supported Platforms

- ✅ **Android** - Android 5.0+ (API 21+)
- ✅ **iOS** - iOS 11.0+
- ✅ **macOS** - macOS 10.14+
- ✅ **Windows** - Windows 10+
- ✅ **Linux** - Ubuntu 18.04+
- ✅ **Web** - Modern browser support

## 📱 Screenshots

<div align="center">
  <img src="docs/screenshots/home.png" width="200" alt="Home Screen" />
  <img src="docs/screenshots/wallet.png" width="200" alt="Wallet Management" />
  <img src="docs/screenshots/assets.png" width="200" alt="Asset Management" />
  <img src="docs/screenshots/send.png" width="200" alt="Send Tokens" />
</div>

## 🏗️ Architecture

### Directory Structure
```
lib/
├── constants/          # Constants definition
├── models/            # Data models
├── providers/         # State management
├── screens/           # Screen components
├── services/          # Business services
├── widgets/           # Common widgets
└── main.dart          # App entry point

docs/                  # Project documentation
├── api/              # API documentation
├── screenshots/      # App screenshots
└── guides/           # User guides

test/                 # Test files
├── unit/            # Unit tests
├── widget/          # Widget tests
└── integration/     # Integration tests
```

### Core Tech Stack

- **State Management**: Provider
- **Network Requests**: HTTP + Dio
- **Local Storage**: SharedPreferences + SecureStorage
- **Cryptography**: Crypto + PointyCastle
- **Blockchain**: Web3Dart + Solana
- **QR Code**: QR Flutter
- **UI Components**: Material Design 3

## 🔧 Development Guide

### Adding New Blockchain Networks

1. Define network configuration in `lib/constants/network_constants.dart`
2. Create corresponding service class in `lib/services/`
3. Add network support in `lib/providers/wallet_provider.dart`
4. Update UI components to support the new network

### Adding New Token Types

1. Extend the `lib/models/token.dart` model
2. Add token query logic in `lib/services/token_service.dart`
3. Update asset display components

### Custom Themes

Modify theme configuration in `lib/constants/theme_constants.dart`:

```dart
// Custom colors
static const primaryColor = Color(0xFF6366F1);
static const backgroundColor = Color(0xFF1A1B23);
```

## 🧪 Testing

### Running Tests

```bash
# Run all tests
flutter test

# Run unit tests
flutter test test/unit/

# Run widget tests
flutter test test/widget/

# Run integration tests
flutter test test/integration/
```

### Test Coverage

```bash
# Generate test coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## 📚 API Documentation

For detailed API documentation, see:
- [Wallet Service API](docs/api/wallet_service.md)
- [Token Service API](docs/api/token_service.md)
- [Transaction Service API](docs/api/transaction_service.md)

## 🤝 Contributing

We welcome all forms of contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

### Contribution Process

1. Fork the project
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Create a Pull Request

## 🔒 Security

### Security Features
- 🔐 Local encrypted storage of private keys and mnemonics
- 🛡️ Secure password policies
- 🔒 Local transaction signing
- 🚫 No sensitive information uploaded to servers

### Security Recommendations
- Regularly backup mnemonics
- Use strong passwords to protect wallets
- Use the app in secure environments
- Update to the latest version promptly

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

Thanks to the following open source projects:
- [Flutter](https://flutter.dev/) - Google's UI toolkit
- [Web3Dart](https://pub.dev/packages/web3dart) - Ethereum Dart client
- [Solana](https://pub.dev/packages/solana) - Solana Dart SDK
- [BIP39](https://pub.dev/packages/bip39) - Mnemonic generation library

## 📞 Contact Us

- **Project Homepage**: [GitHub Repository](https://github.com/your-username/harbor)
- **Issue Reports**: [Issues](https://github.com/your-username/harbor/issues)
- **Feature Requests**: [Discussions](https://github.com/your-username/harbor/discussions)

---

<div align="center">
  <p>If this project helps you, please give us a ⭐️</p>
  <p>Made with ❤️ by Harbor Team</p>
</div>