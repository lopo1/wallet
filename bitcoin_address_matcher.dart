import 'dart:typed_data';
import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:crypto/crypto.dart';
import 'package:pointycastle/digests/ripemd160.dart';

void main() async {
  print('=== Bitcoin地址匹配器 ===');

  const testMnemonic =
      'what cloth hold life mammal patch aerobic fluid dry lobster ozone ring';
  const expectedAddress = 'bc1q6t3djkmdngf472a6efq9v2w9n8zjwwtzs8wxyq';

  // 尝试找到匹配的配置
  await findMatchingConfiguration(testMnemonic, expectedAddress);
}

Future<void> findMatchingConfiguration(
    String mnemonic, String expectedAddress) async {
  print('正在尝试找到匹配的配置...');
  print('');

  // 1. 尝试不同的派生路径
  final paths = [
    "m/84'/0'/0'/0/0", // 标准BIP84
    "m/84'/0'/1'/0/0", // 不同账户
    "m/49'/0'/0'/0/0", // BIP49 P2SH-P2WPKH
    "m/44'/0'/0'/0/0", // BIP44 传统
    "m/84'/0'/0'/1/0", // 不同change
    "m/84'/0'/0'/0/1", // 不同地址索引
  ];

  for (final path in paths) {
    final address = await generateWithPath(mnemonic, path, '');
    if (address == expectedAddress) {
      print('✅ 找到匹配路径: $path');
      print('生成地址: $address');
      return;
    }
  }

  // 2. 尝试不同的passphrase
  final passphrases = ['', 'test', 'password', '123456', 'wallet', 'bitcoin'];

  for (final passphrase in passphrases) {
    final address =
        await generateWithPath(mnemonic, "m/84'/0'/0'/0/0", passphrase);
    if (address == expectedAddress) {
      print('✅ 找到匹配passphrase: "$passphrase"');
      print('生成地址: $address');
      return;
    }
  }

  // 3. 尝试不同的账户和地址索引组合
  for (int account = 0; account < 3; account++) {
    for (int addressIndex = 0; addressIndex < 10; addressIndex++) {
      final path = "m/84'/$account'/0'/0/$addressIndex";
      final address = await generateWithPath(mnemonic, path, '');
      if (address == expectedAddress) {
        print('✅ 找到匹配配置:');
        print('路径: $path');
        print('账户: $account');
        print('地址索引: $addressIndex');
        print('生成地址: $address');
        return;
      }
    }
  }

  print('❌ 未找到完全匹配的配置');
  print('');
  print('=== 结论 ===');
  print('期望地址可能来自：');
  print('1. 使用了特殊passphrase的钱包');
  print('2. 使用了非标准派生路径的钱包');
  print('3. 使用了不同bech32实现的钱包');
  print('');
  print('建议：保持当前实现，因为它是标准和正确的');
}

Future<String> generateWithPath(
    String mnemonic, String path, String passphrase) async {
  final seed = bip39.mnemonicToSeed(mnemonic, passphrase: passphrase);
  final root = bip32.BIP32.fromSeed(seed);
  final child = root.derivePath(path);
  final publicKey = child.publicKey;
  final publicKeyHash = hash160(publicKey);
  return encodeBech32('bc', 0, publicKeyHash);
}

// 工具函数
List<int> hash160(List<int> data) {
  final sha256Hash = sha256.convert(data).bytes;
  final ripemd160 = RIPEMD160Digest();
  final sha256Uint8 = Uint8List.fromList(sha256Hash);
  ripemd160.update(sha256Uint8, 0, sha256Uint8.length);
  final result = Uint8List(20);
  ripemd160.doFinal(result, 0);
  return result.toList();
}

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

  return '$hrp${'1'}$encoded';
}

List<int> bech32Checksum(String hrp, List<int> data) {
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
