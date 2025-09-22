import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wallet.dart';
import 'encryption_service.dart';

class StorageService {
  static const String _walletsKey = 'wallets';
  static const String _currentWalletKey = 'current_wallet';
  static const String _passwordHashKey = 'password_hash';
  static const String _saltKey = 'salt';
  static const String _encryptedMnemonicPrefix = 'encrypted_mnemonic_';
  static const String _customTokensKey = 'custom_tokens';

  Future<List<Wallet>> getWallets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final walletsJson = prefs.getStringList(_walletsKey) ?? [];

      final wallets = <Wallet>[];
      for (final walletJson in walletsJson) {
        final walletData = json.decode(walletJson);
        wallets.add(Wallet.fromJson(walletData));
      }

      return wallets;
    } catch (e) {
      return [];
    }
  }

  Future<void> saveWallet(Wallet wallet, String password) async {
    try {
      // 输入验证
      if (wallet.id.isEmpty) {
        throw Exception('钱包ID不能为空');
      }
      if (wallet.mnemonic.isEmpty) {
        throw Exception('助记词不能为空');
      }
      if (password.length != 8) {
        throw Exception('密码必须是8位');
      }

      final prefs = await SharedPreferences.getInstance();

      // 保存密码哈希
      await savePasswordHash(wallet.id, password);

      // 使用AES加密助记词并存储到SharedPreferences中
      final encryptedMnemonic =
          EncryptionService.encrypt(wallet.mnemonic, password);

      // 验证加密结果
      if (encryptedMnemonic.isEmpty) {
        throw Exception('助记词加密失败');
      }

      await prefs.setString(
        '$_encryptedMnemonicPrefix${wallet.id}',
        encryptedMnemonic,
      );

      // 验证存储是否成功
      final storedMnemonic = prefs.getString(
        '$_encryptedMnemonicPrefix${wallet.id}',
      );
      if (storedMnemonic != encryptedMnemonic) {
        throw Exception('助记词存储验证失败');
      }

      // 保存钱包元数据（不包含助记词）
      final wallets = await getWallets();
      final existingIndex = wallets.indexWhere((w) => w.id == wallet.id);

      // 创建不包含助记词的钱包副本
      final walletJson = wallet.toJson();
      walletJson.remove('mnemonic');
      final walletWithoutMnemonic = Wallet.fromJson(walletJson);

      if (existingIndex >= 0) {
        wallets[existingIndex] = walletWithoutMnemonic;
      } else {
        wallets.add(walletWithoutMnemonic);
      }

      final walletsJson = wallets.map((w) => json.encode(w.toJson())).toList();
      await prefs.setStringList(_walletsKey, walletsJson);

      debugPrint('钱包保存成功: ${wallet.id}');
    } catch (e) {
      debugPrint('保存钱包失败: $e');
      // 清理可能的部分数据
      try {
        final cleanupPrefs = await SharedPreferences.getInstance();
        await cleanupPrefs.remove('$_encryptedMnemonicPrefix${wallet.id}');
      } catch (_) {
        // 忽略清理错误
      }
      rethrow;
    }
  }

  Future<String?> getMnemonic(String walletId, String password) async {
    try {
      // 输入验证
      if (walletId.isEmpty) {
        throw Exception('钱包ID不能为空');
      }
      if (password.length != 8) {
        throw Exception('密码必须是8位');
      }

      // 从SharedPreferences中获取加密的助记词
      final prefs = await SharedPreferences.getInstance();
      final encryptedMnemonic = prefs.getString(
        '$_encryptedMnemonicPrefix$walletId',
      );

      if (encryptedMnemonic == null || encryptedMnemonic.isEmpty) {
        debugPrint('未找到钱包 $walletId 的加密助记词');
        return null;
      }

      // 使用AES解密助记词
      final decryptedMnemonic =
          EncryptionService.decrypt(encryptedMnemonic, password);

      // 验证解密结果
      if (decryptedMnemonic.isEmpty) {
        throw Exception('助记词解密失败');
      }

      // 清理助记词（去除多余空格和换行符）
      final cleanedMnemonic =
          decryptedMnemonic.trim().replaceAll(RegExp(r'\s+'), ' ');

      // 验证助记词格式
      final words = cleanedMnemonic.split(' ');
      if (words.length != 12 && words.length != 24) {
        throw Exception('助记词格式无效: 期望12或24个单词，实际${words.length}个');
      }

      return cleanedMnemonic;
    } catch (e) {
      debugPrint('获取助记词失败: $e');
      if (e.toString().contains('密码错误') || e.toString().contains('填充验证失败')) {
        rethrow;
      }
      return null;
    }
  }

  Future<String?> getWalletMnemonic(String walletId, [String? password]) async {
    try {
      if (password == null) {
        debugPrint('Password is required to decrypt mnemonic');
        return null;
      }

      return await getMnemonic(walletId, password);
    } catch (e) {
      debugPrint('Error getting wallet mnemonic: $e');
      return null;
    }
  }

  Future<void> deleteWallet(String walletId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Remove encrypted mnemonic from SharedPreferences
      await prefs.remove('$_encryptedMnemonicPrefix$walletId');

      // Remove wallet from wallets list
      final walletsJson = prefs.getStringList(_walletsKey) ?? [];
      walletsJson.removeWhere((walletJson) {
        final walletData = json.decode(walletJson);
        return walletData['id'] == walletId;
      });

      await prefs.setStringList(_walletsKey, walletsJson);
    } catch (e) {
      throw Exception('Failed to delete wallet: $e');
    }
  }

  Future<void> updateWalletAddresses(
      String walletId, Map<String, List<String>> addresses) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final walletsJson = prefs.getStringList(_walletsKey) ?? [];

      // Find and update the wallet
      for (int i = 0; i < walletsJson.length; i++) {
        final walletData = json.decode(walletsJson[i]);
        if (walletData['id'] == walletId) {
          walletData['addresses'] = addresses;
          walletsJson[i] = json.encode(walletData);
          break;
        }
      }

      await prefs.setStringList(_walletsKey, walletsJson);
    } catch (e) {
      throw Exception('Failed to update wallet addresses: $e');
    }
  }

  Future<void> updateWalletAddressesAndIndexes(String walletId,
      Map<String, List<String>> addresses, Map<String, int> addressIndexes,
      [Map<String, String>? addressNames]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final walletsJson = prefs.getStringList(_walletsKey) ?? [];

      // Find and update the wallet
      for (int i = 0; i < walletsJson.length; i++) {
        final walletData = json.decode(walletsJson[i]);
        if (walletData['id'] == walletId) {
          walletData['addresses'] = addresses;
          walletData['addressIndexes'] = addressIndexes;
          if (addressNames != null) {
            walletData['addressNames'] = addressNames;
          }
          walletsJson[i] = json.encode(walletData);
          break;
        }
      }

      await prefs.setStringList(_walletsKey, walletsJson);
    } catch (e) {
      throw Exception('Failed to update wallet addresses and indexes: $e');
    }
  }

  Future<void> updateWalletName(String walletId, String newName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final walletsJson = prefs.getStringList(_walletsKey) ?? [];

      // Find and update the wallet name
      for (int i = 0; i < walletsJson.length; i++) {
        final walletData = json.decode(walletsJson[i]);
        if (walletData['id'] == walletId) {
          walletData['name'] = newName;
          walletsJson[i] = json.encode(walletData);
          break;
        }
      }

      await prefs.setStringList(_walletsKey, walletsJson);
    } catch (e) {
      throw Exception('Failed to update wallet name: $e');
    }
  }

  Future<void> setCurrentWallet(String walletId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentWalletKey, walletId);
  }

  Future<String?> getCurrentWalletId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentWalletKey);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Verify if the provided password is correct for the given wallet
  Future<bool> verifyPassword(String walletId, String password) async {
    try {
      // 首先尝试使用密码哈希验证（更快）
      final hashValid = await verifyPasswordHash(walletId, password);
      if (hashValid) {
        return true;
      }

      // 如果哈希验证失败，尝试通过解密助记词验证（兼容性）
      try {
        final prefs = await SharedPreferences.getInstance();
        final encryptedMnemonic =
            prefs.getString('$_encryptedMnemonicPrefix$walletId');
        if (encryptedMnemonic != null) {
          final decrypted =
              EncryptionService.decrypt(encryptedMnemonic, password);
          return decrypted.isNotEmpty;
        }
      } catch (e) {
        // 解密失败说明密码错误
        return false;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check if there are any stored wallets
  Future<bool> hasStoredWallets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final walletsJson = prefs.getStringList(_walletsKey) ?? [];
      return walletsJson.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get the first stored wallet (for login purposes)
  Future<Wallet?> getFirstWallet() async {
    try {
      final wallets = await getWallets();
      return wallets.isNotEmpty ? wallets.first : null;
    } catch (e) {
      return null;
    }
  }

  /// Save password hash for verification (optional security enhancement)
  Future<void> savePasswordHash(String walletId, String password) async {
    try {
      final passwordHash = sha256.convert(password.codeUnits).toString();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('password_hash_$walletId', passwordHash);
    } catch (e) {
      // Password hash saving is optional, don't throw error
      debugPrint('Failed to save password hash: $e');
    }
  }

  /// Verify password using stored hash (faster verification)
  Future<bool> verifyPasswordHash(String walletId, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedHash = prefs.getString('password_hash_$walletId');
      if (storedHash == null) {
        return false;
      }
      final passwordHash = sha256.convert(password.codeUnits).toString();
      return storedHash == passwordHash;
    } catch (e) {
      return false;
    }
  }

  /// 保存自定义代币
  Future<void> saveCustomTokens(List<Map<String, dynamic>> tokens) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tokensJson = tokens.map((token) => json.encode(token)).toList();
      await prefs.setStringList(_customTokensKey, tokensJson);
    } catch (e) {
      debugPrint('保存自定义代币失败: $e');
      rethrow;
    }
  }

  /// 获取自定义代币
  Future<List<Map<String, dynamic>>> getCustomTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tokensJson = prefs.getStringList(_customTokensKey) ?? [];

      return tokensJson.map((tokenJson) {
        return json.decode(tokenJson) as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      debugPrint('获取自定义代币失败: $e');
      return [];
    }
  }

  /// 清除自定义代币
  Future<void> clearCustomTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_customTokensKey);
    } catch (e) {
      debugPrint('清除自定义代币失败: $e');
    }
  }
}
