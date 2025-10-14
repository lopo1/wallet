import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

import '../constants/password_constants.dart';

/// AES加密服务类
/// 提供安全的对称加密功能，用于助记词等敏感数据的加密存储
class EncryptionService {
  static const int _keyLength = 32; // AES-256
  static const int _ivLength = 16; // AES block size
  static const int _saltLength = 16;
  static const int _iterations = 10000; // PBKDF2 iterations

  /// 使用密码加密数据
  ///
  /// [data] 要加密的原始数据
  /// [password] 用于加密的密码
  /// 返回包含盐值、IV和加密数据的Base64编码字符串
  static String encrypt(String data, String password) {
    try {
      // 输入验证
      if (data.isEmpty) {
        throw const EncryptionException('明文不能为空');
      }
      if (password.length != PasswordConstants.passwordLength) {
        throw const EncryptionException(PasswordConstants.passwordLengthError);
      }

      // 生成随机盐值
      final salt = _generateRandomBytes(_saltLength);

      // 使用PBKDF2从密码派生密钥
      final key = _deriveKey(password, salt);

      // 生成随机IV
      final iv = _generateRandomBytes(_ivLength);

      // 执行AES加密
      final encryptedData = _aesEncrypt(utf8.encode(data), key, iv);

      // 验证加密结果
      if (encryptedData.isEmpty) {
        throw const EncryptionException('加密结果为空');
      }

      // 组合盐值、IV和加密数据
      final combined = Uint8List.fromList([
        ...salt,
        ...iv,
        ...encryptedData,
      ]);

      // 返回Base64编码的结果
      return base64.encode(combined);
    } catch (e) {
      if (e is EncryptionException) {
        rethrow;
      }
      throw EncryptionException('加密失败: $e');
    }
  }

  /// 使用密码解密数据
  ///
  /// [encryptedData] Base64编码的加密数据
  /// [password] 用于解密的密码
  /// 返回解密后的原始数据
  static String decrypt(String encryptedData, String password) {
    try {
      // 输入验证
      if (encryptedData.isEmpty) {
        throw const EncryptionException('加密数据不能为空');
      }
      if (password.length != PasswordConstants.passwordLength) {
        throw const EncryptionException(PasswordConstants.passwordLengthError);
      }

      // 解码Base64数据
      final combined = base64.decode(encryptedData);

      // 验证数据长度
      if (combined.length < _saltLength + _ivLength + 16) {
        throw const EncryptionException('加密数据格式无效或长度不足');
      }

      // 提取盐值、IV和加密数据
      final salt = combined.sublist(0, _saltLength);
      final iv = combined.sublist(_saltLength, _saltLength + _ivLength);
      final ciphertext = combined.sublist(_saltLength + _ivLength);

      // 验证密文长度是否为AES块大小的倍数
      if (ciphertext.length % 16 != 0) {
        throw const EncryptionException('密文长度无效');
      }

      // 使用PBKDF2从密码派生密钥
      final key = _deriveKey(password, salt);

      // 执行AES解密
      final decryptedBytes = _aesDecrypt(ciphertext, key, iv);

      // 验证解密结果
      if (decryptedBytes.isEmpty) {
        throw const EncryptionException('解密结果为空，可能密码错误');
      }

      // 返回解密后的字符串
      return utf8.decode(decryptedBytes);
    } catch (e) {
      if (e is EncryptionException) {
        rethrow;
      }
      if (e is FormatException) {
        throw const EncryptionException('Base64解码失败，数据格式错误');
      }
      throw EncryptionException('解密失败: $e');
    }
  }

  /// 生成随机字节数组
  static Uint8List _generateRandomBytes(int length) {
    try {
      if (length <= 0) {
        throw const EncryptionException('随机字节长度必须大于0');
      }
      if (length > 1024) {
        throw const EncryptionException('随机字节长度不能超过1024');
      }

      final random = Random.secure();
      final bytes = Uint8List(length);

      for (int i = 0; i < length; i++) {
        bytes[i] = random.nextInt(256);
      }

      // 验证随机性 - 检查是否全为零或全为同一值
      final firstByte = bytes[0];
      bool allSame = true;
      for (int i = 1; i < bytes.length; i++) {
        if (bytes[i] != firstByte) {
          allSame = false;
          break;
        }
      }

      if (allSame && length > 1) {
        throw const EncryptionException('随机数生成器可能存在问题');
      }

      return bytes;
    } catch (e) {
      if (e is EncryptionException) {
        rethrow;
      }
      throw EncryptionException('生成随机字节失败: $e');
    }
  }

  /// 使用PBKDF2从密码派生密钥
  static Uint8List _deriveKey(String password, Uint8List salt) {
    try {
      if (password.isEmpty) {
        throw const EncryptionException('密码不能为空');
      }
      if (salt.length != _saltLength) {
        throw const EncryptionException('盐值长度无效');
      }

      final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
      pbkdf2.init(Pbkdf2Parameters(salt, _iterations, _keyLength));
      final key = pbkdf2.process(utf8.encode(password));

      if (key.length != _keyLength) {
        throw const EncryptionException('密钥派生失败');
      }

      return key;
    } catch (e) {
      if (e is EncryptionException) {
        rethrow;
      }
      throw EncryptionException('密钥派生失败: $e');
    }
  }

  /// AES加密
  static Uint8List _aesEncrypt(List<int> data, Uint8List key, Uint8List iv) {
    try {
      if (data.isEmpty) {
        throw const EncryptionException('待加密数据不能为空');
      }
      if (key.length != _keyLength) {
        throw const EncryptionException('密钥长度无效');
      }
      if (iv.length != _ivLength) {
        throw const EncryptionException('IV长度无效');
      }

      final cipher = CBCBlockCipher(AESEngine());
      final params = ParametersWithIV(KeyParameter(key), iv);
      cipher.init(true, params);

      // 添加PKCS7填充
      final paddedData = _addPKCS7Padding(Uint8List.fromList(data), 16);

      final encrypted = Uint8List(paddedData.length);
      int offset = 0;

      while (offset < paddedData.length) {
        final processed =
            cipher.processBlock(paddedData, offset, encrypted, offset);
        if (processed == 0) {
          throw const EncryptionException('AES加密处理失败');
        }
        offset += processed;
      }

      return encrypted;
    } catch (e) {
      if (e is EncryptionException) {
        rethrow;
      }
      throw EncryptionException('AES加密失败: $e');
    }
  }

  /// AES解密
  static Uint8List _aesDecrypt(
      List<int> encryptedData, Uint8List key, Uint8List iv) {
    try {
      if (encryptedData.isEmpty) {
        throw const EncryptionException('加密数据不能为空');
      }
      if (key.length != _keyLength) {
        throw const EncryptionException('密钥长度无效');
      }
      if (iv.length != _ivLength) {
        throw const EncryptionException('IV长度无效');
      }
      if (encryptedData.length % 16 != 0) {
        throw const EncryptionException('加密数据长度必须是16的倍数');
      }

      final cipher = CBCBlockCipher(AESEngine());
      final params = ParametersWithIV(KeyParameter(key), iv);
      cipher.init(false, params);

      final decrypted = Uint8List(encryptedData.length);
      int offset = 0;

      while (offset < encryptedData.length) {
        final processed = cipher.processBlock(
            Uint8List.fromList(encryptedData), offset, decrypted, offset);
        if (processed == 0) {
          throw const EncryptionException('AES解密处理失败');
        }
        offset += processed;
      }

      // 移除PKCS7填充
      return _removePKCS7Padding(decrypted);
    } catch (e) {
      if (e is EncryptionException) {
        rethrow;
      }
      throw EncryptionException('AES解密失败: $e');
    }
  }

  /// 添加PKCS7填充
  static Uint8List _addPKCS7Padding(Uint8List data, int blockSize) {
    try {
      if (data.isEmpty) {
        throw const EncryptionException('待填充数据不能为空');
      }
      if (blockSize <= 0 || blockSize > 255) {
        throw const EncryptionException('块大小必须在1-255之间');
      }

      final padding = blockSize - (data.length % blockSize);
      final paddedData = Uint8List(data.length + padding);
      paddedData.setRange(0, data.length, data);

      for (int i = data.length; i < paddedData.length; i++) {
        paddedData[i] = padding;
      }

      // 验证填充结果
      if (paddedData.length % blockSize != 0) {
        throw const EncryptionException('填充后数据长度不是块大小的倍数');
      }

      return paddedData;
    } catch (e) {
      if (e is EncryptionException) {
        rethrow;
      }
      throw EncryptionException('添加填充失败: $e');
    }
  }

  /// 移除PKCS7填充
  static Uint8List _removePKCS7Padding(Uint8List data) {
    try {
      if (data.isEmpty) {
        throw const EncryptionException('数据为空，无法移除填充');
      }
      if (data.length < 16) {
        throw const EncryptionException('数据长度不足，无法移除填充');
      }

      final padding = data.last;
      if (padding < 1 || padding > 16) {
        throw EncryptionException('无效的填充值: $padding');
      }
      if (padding > data.length) {
        throw const EncryptionException('填充值大于数据长度');
      }

      // 验证填充的正确性
      for (int i = data.length - padding; i < data.length; i++) {
        if (data[i] != padding) {
          throw const EncryptionException('填充验证失败，可能密码错误');
        }
      }

      final result = data.sublist(0, data.length - padding);
      if (result.isEmpty) {
        throw const EncryptionException('移除填充后数据为空');
      }

      return result;
    } catch (e) {
      if (e is EncryptionException) {
        rethrow;
      }
      throw EncryptionException('移除填充失败: $e');
    }
  }

  /// 验证加密数据的完整性
  static bool isValidEncryptedData(String encryptedData) {
    try {
      final decoded = base64.decode(encryptedData);
      return decoded.length >= _saltLength + _ivLength + 16; // 至少包含一个AES块
    } catch (e) {
      return false;
    }
  }

  /// 生成安全的随机密码
  static String generateSecurePassword(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
    final random = Random.secure();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }
}

/// 加密异常类
class EncryptionException implements Exception {
  final String message;

  const EncryptionException(this.message);

  @override
  String toString() => 'EncryptionException: $message';
}
