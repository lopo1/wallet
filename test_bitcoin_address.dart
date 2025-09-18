import 'dart:io';
import 'dart:typed_data';
import 'lib/services/address_service.dart';
import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:crypto/crypto.dart';
import 'package:pointycastle/digests/ripemd160.dart';

void main() async {
  // 测试助记词
  const testMnemonic =
      'what cloth hold life mammal patch aerobic fluid dry lobster ozone ring';

  // 期望的BTC地址
  const expectedAddress = 'bc1q6t3djkmdngf472a6efq9v2w9n8zjwwtzs8wxyq';

  print('=== Bitcoin地址生成测试 ===');
  print('助记词: $testMnemonic');
  print('期望地址: $expectedAddress');
  print('');

  try {
    // 测试不同的派生路径
    final testPaths = [
      "m/84'/0'/0'/0/0", // 标准P2WPKH路径
      "m/84'/0'/1'/0/0", // 不同账户索引
      "m/49'/0'/0'/0/0", // P2SH-P2WPKH路径
      "m/44'/0'/0'/0/0", // 传统P2PKH路径
    ];

    print('=== 测试不同派生路径 ===');
    for (final path in testPaths) {
      final address = await generateBitcoinAddressWithPath(testMnemonic, path);
      print('路径 $path: $address');
      if (address == expectedAddress) {
        print('✅ 找到匹配地址！路径: $path');
      }
    }

    print('');

    // 使用当前实现生成地址
    final generatedAddress = await AddressService.generateAddress(
      mnemonic: testMnemonic,
      network: 'bitcoin',
      index: 0,
    );

    print('当前实现生成地址: $generatedAddress');
    print('');

    // 比较地址
    if (generatedAddress == expectedAddress) {
      print('✅ 测试通过！地址生成正确');
    } else {
      print('❌ 测试失败！地址不匹配');
      print('期望: $expectedAddress');
      print('实际: $generatedAddress');
    }
  } catch (e) {
    print('❌ 错误: $e');
    exit(1);
  }
}

// 使用指定路径生成Bitcoin地址
Future<String> generateBitcoinAddressWithPath(
    String mnemonic, String path) async {
  try {
    // 1. 助记词转 seed
    final seed = bip39.mnemonicToSeed(mnemonic);

    // 2. 用 BIP32 推导指定路径的key
    final root = bip32.BIP32.fromSeed(seed);
    final child = root.derivePath(path);

    // 3. 生成 Bitcoin P2WPKH 地址 (bech32)
    final publicKey = child.publicKey;
    final publicKeyHash = hash160(publicKey);

    // 4. 生成 bech32 地址
    return encodeBech32('bc', 0, publicKeyHash);
  } catch (e) {
    throw Exception('Failed to generate Bitcoin address: $e');
  }
}

// RIPEMD160(SHA256(data))
List<int> hash160(List<int> data) {
  final sha256Hash = sha256.convert(data).bytes;
  final ripemd160 = RIPEMD160Digest();
  final sha256Uint8 = Uint8List.fromList(sha256Hash);
  ripemd160.update(sha256Uint8, 0, sha256Uint8.length);
  final result = Uint8List(20);
  ripemd160.doFinal(result, 0);
  return result.toList();
}

// Bech32编码实现
String encodeBech32(String hrp, int witver, List<int> witprog) {
  const charset = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';

  final spec = convertBits(witprog, 8, 5, true);
  if (spec == null) {
    throw Exception('Invalid witness program');
  }

  final data = [witver] + spec;
  final checksum = bech32Checksum(hrp, data);
  final combined = data + checksum;
  final encoded = combined.map((x) => charset[x]).join('');

  return hrp + '1' + encoded;
}

List<int>? convertBits(List<int> data, int frombits, int tobits, bool pad) {
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

List<int> bech32Checksum(String hrp, List<int> data) {
  const gen = [0x3b6a57b2, 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3];

  final values = hrpExpand(hrp) + [0] + data;
  final polymod = bech32Polymod(values + [0, 0, 0, 0, 0, 0]) ^ 1;

  final result = <int>[];
  for (int i = 0; i < 6; i++) {
    result.add((polymod >> (5 * (5 - i))) & 31);
  }

  return result;
}

List<int> hrpExpand(String hrp) {
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

int bech32Polymod(List<int> values) {
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
