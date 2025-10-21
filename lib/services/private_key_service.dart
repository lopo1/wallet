import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'mnemonic_service.dart';
import '../constants/derivation_paths.dart';

class PrivateKeyService {
  /// Generate private key for different blockchain networks
  static Future<String> generatePrivateKey({
    required String mnemonic,
    required String network,
    int index = 0,
  }) async {
    // Validate mnemonic first
    if (!MnemonicService.validateMnemonic(mnemonic)) {
      throw ArgumentError('Invalid mnemonic phrase');
    }

    switch (network.toLowerCase()) {
      case 'ethereum':
      case 'eth':
        return await _generateEthereumPrivateKey(mnemonic, index);
      case 'bitcoin':
      case 'btc':
        return await _generateBitcoinPrivateKey(mnemonic, index);
      case 'binance':
      case 'bsc':
        return await _generateBSCPrivateKey(mnemonic, index);
      case 'polygon':
      case 'matic':
        return await _generatePolygonPrivateKey(mnemonic, index);
      case 'solana':
      case 'sol':
        return await _generateSolanaPrivateKey(mnemonic, index);
      case 'tron':
      case 'trx':
        return await _generateTronPrivateKey(mnemonic, index);
      default:
        throw UnsupportedError('Network $network is not supported');
    }
  }

  /// Generate Ethereum private key using BIP32 and secp256k1
  static Future<String> _generateEthereumPrivateKey(String mnemonic, int index) async {
    try {
      // 1. Convert mnemonic to seed
      final seed = bip39.mnemonicToSeed(mnemonic);
      
      // 2. Derive key using BIP32 (secp256k1)
      final root = bip32.BIP32.fromSeed(seed);
      final child = root.derivePath(DerivationPaths.ethereumWithIndex(index));
      
      // 3. Get private key bytes
      final privateKeyBytes = child.privateKey;
      if (privateKeyBytes == null) {
        throw Exception('Failed to derive private key');
      }
      
      // 4. Convert to hex string
      return '0x${_bytesToHex(privateKeyBytes)}';
    } catch (e) {
      throw Exception('Failed to generate Ethereum private key: $e');
    }
  }

  /// Generate Bitcoin private key using BIP32 and secp256k1
  static Future<String> _generateBitcoinPrivateKey(String mnemonic, int index) async {
    try {
      // 1. Convert mnemonic to seed
      final seed = bip39.mnemonicToSeed(mnemonic);
      
      // 2. Derive Bitcoin key using BIP32 (secp256k1)
      final root = bip32.BIP32.fromSeed(seed);
      final child = root.derivePath(DerivationPaths.bitcoinWithIndex(index));
      
      // 3. Get private key bytes
      final privateKeyBytes = child.privateKey;
      if (privateKeyBytes == null) {
        throw Exception('Failed to derive private key');
      }
      
      // 4. Convert to WIF (Wallet Import Format) for Bitcoin
      return _toWIF(privateKeyBytes);
    } catch (e) {
      throw Exception('Failed to generate Bitcoin private key: $e');
    }
  }

  /// Generate BSC private key (same as Ethereum)
  static Future<String> _generateBSCPrivateKey(String mnemonic, int index) async {
    return await _generateEthereumPrivateKey(mnemonic, index);
  }

  /// Generate Polygon private key (same as Ethereum)
  static Future<String> _generatePolygonPrivateKey(String mnemonic, int index) async {
    return await _generateEthereumPrivateKey(mnemonic, index);
  }

  /// Generate TRON private key (secp256k1)
  static Future<String> _generateTronPrivateKey(String mnemonic, int index) async {
    final seed = bip39.mnemonicToSeed(mnemonic);
    final root = bip32.BIP32.fromSeed(seed);
    final child = root.derivePath(DerivationPaths.tronWithIndex(index));
    final priv = child.privateKey;
    if (priv == null) {
      throw Exception('Failed to derive TRON private key');
    }
    // Return hex with 0x prefix for consistency
    final hexStr = priv.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '0x$hexStr';
  }

  /// Generate Solana private key
  static Future<String> _generateSolanaPrivateKey(String mnemonic, int index) async {
    try {
      // Validate mnemonic
      if (!MnemonicService.validateMnemonic(mnemonic)) {
        throw ArgumentError('Invalid mnemonic phrase for Solana private key generation');
      }
      
      final seed = bip39.mnemonicToSeed(mnemonic);
      
      // For Solana, use hardened derivation path
      final path = DerivationPaths.solanaWithIndex(index);
      final derivedKey = await ED25519_HD_KEY.derivePath(path, seed);
      
      // Get the private key bytes
      final privateKeyBytes = derivedKey.key;
      
      if (privateKeyBytes.isEmpty) {
        throw Exception('Generated private key is empty');
      }
      
      // Convert to base58 for Solana
      return _base58Encode(privateKeyBytes);
    } catch (e) {
      if (e is ArgumentError) {
        rethrow;
      }
      throw Exception('Failed to generate Solana private key: $e');
    }
  }

  /// Convert bytes to hexadecimal string
  static String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }

  /// Convert private key to WIF format for Bitcoin
  static String _toWIF(Uint8List privateKey) {
    // Add version byte (0x80 for mainnet)
    final extended = [0x80] + privateKey;
    
    // Add compression flag (0x01 for compressed)
    extended.add(0x01);
    
    // Calculate checksum
    final checksum = _doubleHash256(extended).sublist(0, 4);
    
    // Combine and encode
    final fullKey = extended + checksum;
    return _base58Encode(fullKey);
  }

  /// Double SHA256 hash
  static List<int> _doubleHash256(List<int> data) {
    final firstHash = sha256.convert(data).bytes;
    final secondHash = sha256.convert(firstHash).bytes;
    return secondHash;
  }

  /// Base58 encoding
  static String _base58Encode(List<int> input) {
    const alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
    
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

  /// Get supported networks for private key generation
  static List<String> getSupportedNetworks() {
    return [
      'ethereum',
      'bitcoin',
      'binance',
      'polygon',
      'solana',
      'tron',
    ];
  }

  /// Validate private key format for different networks
  static bool validatePrivateKey(String privateKey, String network) {
    switch (network.toLowerCase()) {
      case 'ethereum':
      case 'binance':
      case 'polygon':
      case 'tron':
        return _isValidEthereumPrivateKey(privateKey);
      case 'bitcoin':
        return _isValidBitcoinPrivateKey(privateKey);
      case 'solana':
        return _isValidSolanaPrivateKey(privateKey);
      default:
        return false;
    }
  }

  /// Validate Ethereum private key format (hex)
  static bool _isValidEthereumPrivateKey(String privateKey) {
    return RegExp(r'^0x[a-fA-F0-9]{64}$').hasMatch(privateKey);
  }

  /// Validate Bitcoin private key format (WIF)
  static bool _isValidBitcoinPrivateKey(String privateKey) {
    return RegExp(r'^[5KL][1-9A-HJ-NP-Za-km-z]{50,51}$').hasMatch(privateKey);
  }

  /// Validate Solana private key format (base58)
  static bool _isValidSolanaPrivateKey(String privateKey) {
    return RegExp(r'^[1-9A-HJ-NP-Za-km-z]{32,88}$').hasMatch(privateKey);
  }
}