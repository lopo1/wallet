# 密码策略统一说明

## 概述
本文档说明了钱包应用中统一的密码长度要求和验证规则。

## 密码长度要求

### 统一标准
- **密码长度**: 8位（固定长度）
- **登录PIN码长度**: 8位（固定长度）

### 应用场景

#### 1. 创建钱包 (`create_wallet_screen.dart`)
- **要求**: 密码必须是8位
- **验证**: 只接受恰好8位长度的密码
- **用途**: 用于加密存储钱包数据

#### 2. 导入钱包 (`import_wallet_screen.dart`)
- **要求**: 密码必须是8位
- **验证**: 只接受恰好8位长度的密码
- **用途**: 用于加密存储导入的钱包数据

#### 3. 导入私钥 (`import_private_key_screen.dart`)
- **要求**: 密码必须是8位
- **验证**: 只接受恰好8位长度的密码
- **用途**: 用于加密存储私钥数据

#### 4. 登录验证 (`login_screen.dart`)
- **要求**: 密码必须是8位
- **验证**: 使用PIN码输入组件，固定8位长度
- **用途**: 快速解锁钱包访问

## 设计理念

### 为什么选择8位作为固定长度？
1. **安全性**: 8位密码提供足够的安全强度
2. **用户体验**: 固定长度简化用户记忆，提供一致的输入体验
3. **一致性**: 统一的固定长度要求避免用户混淆
4. **PIN码体验**: 类似银行PIN码的使用习惯

### 登录PIN码的特殊设计
- 使用固定8位PIN码设计，提供快速解锁体验
- PIN码输入界面使用专门的`PinCodeInput`组件
- 支持显示/隐藏密码功能

## 错误信息统一

所有密码相关的错误信息都通过`PasswordConstants`类统一管理：

```dart
class PasswordConstants {
  static const int passwordLength = 8;
  static const int pinCodeLength = 8;
  static const String passwordLengthError = '密码必须是8位';
  static const String pinCodeLengthError = '密码必须是8位';
  static const String passwordEmptyError = '请输入密码';
  static const String passwordMismatchError = '密码不匹配';
  static const String confirmPasswordEmptyError = '请确认密码';
}
```

## 后端验证

后端服务也遵循相同的8位固定长度要求：
- `StorageService`: 验证密码长度必须是8位
- `EncryptionService`: 验证密码长度必须是8位

## 实现文件

### 前端UI验证
- `lib/screens/create_wallet_screen.dart`
- `lib/screens/import_wallet_screen.dart`
- `lib/screens/import_private_key_screen.dart`
- `lib/screens/login_screen.dart`

### 后端服务验证
- `lib/services/storage_service.dart`
- `lib/services/encryption_service.dart`

### 常量定义
- `lib/constants/password_constants.dart`

### UI组件
- `lib/widgets/pin_code_input.dart`

## 用户体验考虑

1. **创建/导入时**: 要求用户设置8位密码，提供一致的安全标准
2. **日常使用**: 使用相同的8位密码快速解锁，简化用户体验
3. **错误提示**: 统一、清晰的错误信息帮助用户理解要求
4. **视觉反馈**: PIN码输入界面提供良好的视觉反馈和动画效果

## 安全考虑

1. **加密强度**: 8位密码配合适当的加密算法提供足够安全性
2. **存储安全**: 密码不以明文存储，使用哈希验证
3. **传输安全**: 密码仅在本地处理，不进行网络传输
4. **用户教育**: 通过UI提示引导用户设置强密码