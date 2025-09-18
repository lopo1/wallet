import 'dart:typed_data';
import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:crypto/crypto.dart';
import 'package:pointycastle/digests/ripemd160.dart';

void main() async {
  print('=== Bitcoin地址生成标准验证 ===');

  // 测试助记词
  const testMnemonic =
      'what cloth hold life mammal patch aerobic fluid dry lobster ozone ring';

  // 期望地址和实际地址
  const expectedAddress = 'bc1q6t3djkmdngf472a6efq9v2w9n8zjwwtzs8wxyq';

  print('助记词: $testMnemonic');
  print('期望地址: $expectedAddress');
  print('');

  // 验证我们的实现
  await verifyImplementation(testMnemonic, expectedAddress);

  // 测试标准测试向量
  await testStandardVectors();
}

Future<void> verifyImplementation(
    String mnemonic, String expectedAddress) async {
  print('=== 验证我们的实现 ===');

  try {
    // 1. 生成seed
    final seed = bip39.mnemonicToSeed(mnemonic);
    print('Seed (hex): ${_bytesToHex(seed)}');

    // 2. 派生密钥
    final root = bip32.BIP32.fromSeed(seed);
    final path = "m/84'/0'/0'/0/0";
    final child = root.derivePath(path);

    print('派生路径: $path');
    print('私钥 (hex): ${_bytesToHex(child.privateKey!)}');
    print('公钥 (hex): ${_bytesToHex(child.publicKey)}');

    // 3. 计算公钥哈希
    final publicKeyHash = hash160(child.publicKey);
    print('公钥哈希 (hex): ${_bytesToHex(publicKeyHash)}');

    // 4. 生成bech32地址
    final ourAddress = encodeBech32('bc', 0, publicKeyHash);
    print('我们的地址: $ourAddress');

    // 5. 比较结果
    print('');
    print('=== 地址比较 ===');
    print('期望: $expectedAddress');
    print('实际: $ourAddress');
    print('匹配: ${ourAddress == expectedAddress ? '✅' : '❌'}');

    // 6. 详细分析差异
    if (ourAddress != expectedAddress) {
      print('');
      print('=== 差异分析 ===');
      analyzeAddressDifference(expectedAddress, ourAddress);
    }
  } catch (e) {
    print('❌ 错误: $e');
  }
}

void analyzeAddressDifference(String expected, String actual) {
  print('期望长度: ${expected.length}');
  print('实际长度: ${actual.length}');

  final minLength =
      expected.length < actual.length ? expected.length : actual.length;

  print('字符对比:');
  for (int i = 0; i < minLength; i++) {
    final expectedChar = expected[i];
    final actualChar = actual[i];
    final match = expectedChar == actualChar;

    if (!match) {
      print('位置 $i: 期望 "$expectedChar", 实际 "$actualChar" ❌');
    }
  }

  // 找到第一个不同的位置
  int firstDiff = -1;
  for (int i = 0; i < minLength; i++) {
    if (expected[i] != actual[i]) {
      firstDiff = i;
      break;
    }
  }

  if (firstDiff != -1) {
    print('第一个差异位置: $firstDiff');
    print('相同前缀: "${expected.substring(0, firstDiff)}"');
  }
}

Future<void> testStandardVectors() async {
  print('');
  print('=== 标准测试向量验证 ===');

  // BIP84标准测试向量
  const standardTests = [
    {
      'mnemonic':
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
      'path': "m/84'/0'/0'/0/0",
      'expected': 'bc1qcr8te4kr609gcawutmrza0j4xv80jy8z306fyu',
    },
  ];

  for (final test in standardTests) {
    print('测试: ${test['mnemonic']}');

    final seed = bip39.mnemonicToSeed(test['mnemonic'] as String);
    final root = bip32.BIP32.fromSeed(seed);
    final child = root.derivePath(test['path'] as String);
    final publicKeyHash = hash160(child.publicKey);
    final address = encodeBech32('bc', 0, publicKeyHash);

    print('期望: ${test['expected']}');
    print('实际: $address');
    print('匹配: ${address == test['expected'] ? '✅' : '❌'}');
    print('');
  }
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

String _bytesToHex(List<int> bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
}
