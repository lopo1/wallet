import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;
import 'package:pointycastle/export.dart';
import 'package:web3dart/crypto.dart' as web3_crypto;
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:solana/solana.dart';
import '../constants/derivation_paths.dart';

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

  /// Generate Bitcoin address using proper BIP32 and secp256k1 (bech32 format)
  static Future<String> _generateBitcoinAddress(
      String mnemonic, int index) async {
    try {
      // 1. 助记词转 seed (明确传递空 passphrase)
      final seed = bip39.mnemonicToSeed(mnemonic, passphrase: "");

      // 2. 用 BIP32 (secp256k1) 推导 Bitcoin key (P2WPKH path)
      final root = bip32.BIP32.fromSeed(seed);
      final child = root.derivePath(DerivationPaths.bitcoinWithIndex(index));

      // 3. 生成 Bitcoin P2WPKH 地址 (bech32)
      final publicKey = child.publicKey;
      final publicKeyHash = _hash160(publicKey);

      // 4. 生成 bech32 地址
      return _encodeBech32('bc', 0, publicKeyHash);
    } catch (e) {
      throw Exception('Failed to generate Bitcoin address: $e');
    }
  }

  /// Generate Bitcoin address with specific derivation path
  static Future<String> generateBitcoinAddressWithPath({
    required String mnemonic,
    required String derivationPath,
    String passphrase = '',
  }) async {
    try {
      final seed = bip39.mnemonicToSeed(mnemonic, passphrase: passphrase);
      final root = bip32.BIP32.fromSeed(seed);
      final child = root.derivePath(derivationPath);
      final publicKey = child.publicKey;
      final publicKeyHash = _hash160(publicKey);
      return _encodeBech32('bc', 0, publicKeyHash);
    } catch (e) {
      throw Exception('Failed to generate Bitcoin address with path: $e');
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
    // Then RIPEMD160
    final ripemd160 = RIPEMD160Digest();
    final sha256Uint8 = Uint8List.fromList(sha256Hash);
    ripemd160.update(sha256Uint8, 0, sha256Uint8.length);
    final result = Uint8List(20);
    ripemd160.doFinal(result, 0);
    return result.toList();
  }

  /// Bech32 encoding for Bitcoin addresses
  static String _encodeBech32(String hrp, int witver, List<int> witprog) {
    const charset = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';

    // Convert witness program to 5-bit groups
    final spec = _convertBits(witprog, 8, 5, true);
    if (spec == null) {
      throw Exception('Invalid witness program');
    }

    // Create data part: witness version + converted program
    final data = [witver] + spec;

    // Calculate checksum
    final checksum = _bech32Checksum(hrp, data);

    // Combine all parts
    final combined = data + checksum;

    // Encode to bech32
    final encoded = combined.map((x) => charset[x]).join('');

    return '$hrp${'1'}$encoded';
  }

  /// Convert between bit groups
  static List<int>? _convertBits(
      List<int> data, int frombits, int tobits, bool pad) {
    var acc = 0;
    var bits = 0;
    final result = <int>[];
    final maxv = (1 << tobits) - 1;
    final maxAcc = (1 << (frombits + tobits - 1)) - 1;

    for (final value in data) {
      if (value < 0 || (value >> frombits) != 0) {
        return null;
      }
      acc = ((acc << frombits) | value) & maxAcc;
      bits += frombits;
      while (bits >= tobits) {
        bits -= tobits;
        result.add((acc >> bits) & maxv);
      }
    }

    if (pad) {
      if (bits > 0) {
        result.add((acc << (tobits - bits)) & maxv);
      }
    } else if (bits >= frombits || ((acc << (tobits - bits)) & maxv) != 0) {
      return null;
    }

    return result;
  }

  /// Calculate bech32 checksum
  static List<int> _bech32Checksum(String hrp, List<int> data) {
    final values = _hrpExpand(hrp) + data;
    final polymod = _bech32Polymod(values + [0, 0, 0, 0, 0, 0]) ^ 1;

    final result = <int>[];
    for (int i = 0; i < 6; i++) {
      result.add((polymod >> (5 * (5 - i))) & 31);
    }

    return result;
  }

  /// Expand HRP for bech32
  static List<int> _hrpExpand(String hrp) {
    final result = <int>[];
    for (int i = 0; i < hrp.length; i++) {
      result.add(hrp.codeUnitAt(i) >> 5);
    }
    result.add(0);
    for (int i = 0; i < hrp.length; i++) {
      result.add(hrp.codeUnitAt(i) & 31);
    }
    return result;
  }

  /// Bech32 polymod function
  static int _bech32Polymod(List<int> values) {
    const gen = [0x3b6a57b2, 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3];
    var chk = 1;

    for (final value in values) {
      final top = chk >> 25;
      chk = (chk & 0x1ffffff) << 5 ^ value;
      for (int i = 0; i < 5; i++) {
        chk ^= ((top >> i) & 1) != 0 ? gen[i] : 0;
      }
    }

    return chk;
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

  /// Validate Bitcoin address format (supports both legacy and bech32)
  static bool _isValidBitcoinAddress(String address) {
    // Legacy P2PKH/P2SH addresses (1... or 3...)
    final legacyPattern = RegExp(r'^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$');
    // Bech32 addresses (bc1...)
    final bech32Pattern = RegExp(r'^bc1[a-z0-9]{39,59}$');

    return legacyPattern.hasMatch(address) || bech32Pattern.hasMatch(address);
  }

  /// Validate Solana address format
  static bool _isValidSolanaAddress(String address) {
    return RegExp(r'^[1-9A-HJ-NP-Za-km-z]{32,44}$').hasMatch(address);
  }
}
