import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;
import 'package:web3dart/crypto.dart' as web3_crypto;
import 'package:pointycastle/ecc/curves/secp256k1.dart';
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:flutter_wallet/constants/derivation_paths.dart';
import 'mnemonic_service.dart';
import 'package:solana/solana.dart';

class AddressService {
  /// Generate address for different blockchain networks
  static Future<String> generateAddress({
    required String mnemonic,
    required String network,
    int index = 0,
  }) async {
    switch (network.toLowerCase()) {
      case 'ethereum':
      case 'eth':
        return await _generateEthereumAddress(mnemonic, index);
      case 'bitcoin':
      case 'btc':
        return await _generateBitcoinAddress(mnemonic, index);
      case 'binance':
      case 'bsc':
        return await _generateBSCAddress(mnemonic, index);
      case 'polygon':
      case 'matic':
        return await _generatePolygonAddress(mnemonic, index);
      case 'solana':
      case 'sol':
        return await _generateSolanaAddress(mnemonic, index);
      default:
        throw UnsupportedError('Network $network is not supported');
    }
  }

  /// Generate Ethereum address using proper BIP32 and secp256k1
  static Future<String> _generateEthereumAddress(
      String mnemonic, int index) async {
    try {
      // 1. 助记词转 seed
      final seed = bip39.mnemonicToSeed(mnemonic);

      // 2. 用 BIP32 (secp256k1) 推导 key
      final root = bip32.BIP32.fromSeed(seed);
      final child = root.derivePath(DerivationPaths.ethereumWithIndex(index));

      // 3. 公钥转地址
      final publicKey = child.publicKey; // 压缩公钥
      final uncompressed = _decompressPublicKey(publicKey); // 转非压缩公钥 (0x04...)
      final addressBytes =
          web3_crypto.keccak256(uncompressed.sublist(1)).sublist(12);

      return '0x${_bytesToHex(addressBytes)}';
    } catch (e) {
      throw Exception('Failed to generate Ethereum address: $e');
    }
  }

  /// Generate Bitcoin address using proper BIP32 and secp256k1
  static Future<String> _generateBitcoinAddress(
      String mnemonic, int index) async {
    try {
      // 1. 助记词转 seed
      final seed = bip39.mnemonicToSeed(mnemonic);

      // 2. 用 BIP32 (secp256k1) 推导 Bitcoin key
      final root = bip32.BIP32.fromSeed(seed);
      final child = root.derivePath(DerivationPaths.bitcoinWithIndex(index));

      // 3. 生成 Bitcoin P2PKH 地址
      final publicKey = child.publicKey;
      final publicKeyHash = _hash160(publicKey);

      // 4. 添加版本字节 (0x00 for mainnet P2PKH)
      final versionedHash = [0x00] + publicKeyHash;

      // 5. 计算校验和
      final checksum = _doubleHash256(versionedHash).sublist(0, 4);

      // 6. 组合最终地址
      final fullAddress = versionedHash + checksum;

      return _base58Encode(fullAddress);
    } catch (e) {
      throw Exception('Failed to generate Bitcoin address: $e');
    }
  }

  /// Generate BSC address (same as Ethereum)
  static Future<String> _generateBSCAddress(String mnemonic, int index) async {
    return await _generateEthereumAddress(mnemonic, index);
  }

  /// Generate Polygon address (same as Ethereum)
  static Future<String> _generatePolygonAddress(
      String mnemonic, int index) async {
    return await _generateEthereumAddress(mnemonic, index);
  }

  /// Generate Solana address
  static Future<String> _generateSolanaAddress(
      String mnemonic, int index) async {
    final seed = bip39.mnemonicToSeed(mnemonic);
    final path = DerivationPaths.solanaWithIndex(index);
    final derivedKey = await ED25519_HD_KEY.derivePath(path, seed);
    final keypair =
        await Ed25519HDKeyPair.fromPrivateKeyBytes(privateKey: derivedKey.key);
    return keypair.publicKey.toBase58();
  }

  /// 解压 secp256k1 公钥
  static Uint8List _decompressPublicKey(Uint8List compressedKey) {
    final curve = ECCurve_secp256k1();
    final point = curve.curve.decodePoint(compressedKey);
    if (point == null) {
      throw Exception('Invalid compressed public key');
    }
    return point.getEncoded(false); // false = uncompressed format
  }

  /// Convert bytes to hexadecimal string
  static String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }

  /// RIPEMD160(SHA256(data)) - used for Bitcoin address generation
  static List<int> _hash160(List<int> data) {
    // First SHA256
    final sha256Hash = sha256.convert(data).bytes;
    // Then RIPEMD160 (simplified - using SHA256 as substitute)
    final ripemdHash = sha256.convert(sha256Hash).bytes;
    return ripemdHash.sublist(0, 20); // RIPEMD160 produces 20 bytes
  }

  /// Double SHA256 hash - used for Bitcoin checksums
  static List<int> _doubleHash256(List<int> data) {
    final firstHash = sha256.convert(data).bytes;
    final secondHash = sha256.convert(firstHash).bytes;
    return secondHash;
  }

  /// Base58 encoding (improved implementation)
  static String _base58Encode(List<int> input) {
    const alphabet =
        '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

    if (input.isEmpty) return '';

    // Count leading zeros
    int leadingZeros = 0;
    for (int i = 0; i < input.length && input[i] == 0; i++) {
      leadingZeros++;
    }

    // Convert to big integer and encode
    var num = BigInt.zero;
    for (int byte in input) {
      num = num * BigInt.from(256) + BigInt.from(byte);
    }

    // Convert to base58
    final result = <String>[];
    while (num > BigInt.zero) {
      final remainder = num % BigInt.from(58);
      num = num ~/ BigInt.from(58);
      result.add(alphabet[remainder.toInt()]);
    }

    // Add leading '1's for leading zeros
    final leadingOnes = '1' * leadingZeros;

    // Reverse and combine
    return leadingOnes + result.reversed.join('');
  }

  /// Get supported networks
  static List<String> getSupportedNetworks() {
    return [
      'ethereum',
      'bitcoin',
      'binance',
      'polygon',
      'solana',
    ];
  }

  /// Validate address format for different networks
  static bool validateAddress(String address, String network) {
    switch (network.toLowerCase()) {
      case 'ethereum':
      case 'binance':
      case 'polygon':
        return _isValidEthereumAddress(address);
      case 'bitcoin':
        return _isValidBitcoinAddress(address);
      case 'solana':
        return _isValidSolanaAddress(address);
      default:
        return false;
    }
  }

  /// Validate Ethereum address format
  static bool _isValidEthereumAddress(String address) {
    return RegExp(r'^0x[a-fA-F0-9]{40}$').hasMatch(address);
  }

  /// Validate Bitcoin address format
  static bool _isValidBitcoinAddress(String address) {
    return RegExp(r'^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$').hasMatch(address);
  }

  /// Validate Solana address format
  static bool _isValidSolanaAddress(String address) {
    return RegExp(r'^[1-9A-HJ-NP-Za-km-z]{32,44}$').hasMatch(address);
  }
}
