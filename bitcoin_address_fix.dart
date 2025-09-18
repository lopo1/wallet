import 'dart:typed_data';
import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:crypto/crypto.dart';
import 'package:pointycastle/digests/ripemd160.dart';

void main() async {
  print('=== Bitcoin地址修复方案 ===');

  const testMnemonic =
      'what cloth hold life mammal patch aerobic fluid dry lobster ozone ring';
  const expectedAddress = 'bc1q6t3djkmdngf472a6efq9v2w9n8zjwwtzs8wxyq';

  print('助记词: $testMnemonic');
  print('期望地址: $expectedAddress');
  print('');

  // 测试修复后的实现
  final fixedAddress = await generateBitcoinAddressFixed(testMnemonic, 0);
  print('修复后地址: $fixedAddress');
  print('匹配结果: ${fixedAddress == expectedAddress ? '✅ 成功' : '❌ 仍不匹配'}');

  if (fixedAddress != expectedAddress) {
    print('');
    print('=== 尝试其他可能的解决方案 ===');
    await tryAlternativeSolutions(testMnemonic, expectedAddress);
  }
}

// 修复后的Bitcoin地址生成
Future<String> generateBitcoinAddressFixed(String mnemonic, int index) async {
  try {
    // 1. 助记词转 seed
    final seed = bip39.mnemonicToSeed(mnemonic);

    // 2. 用 BIP32 推导 Bitcoin key
    final root = bip32.BIP32.fromSeed(seed);
    final path = "m/84'/0'/0'/0/$index";
    final child = root.derivePath(path);

    // 3. 生成 Bitcoin P2WPKH 地址
    final publicKey = child.publicKey;
    final publicKeyHash = hash160(publicKey);

    // 4. 使用修复的bech32编码
    return encodeBech32Fixed('bc', 0, publicKeyHash);
  } catch (e) {
    throw Exception('Failed to generate Bitcoin address: $e');
  }
}

// 修复的Bech32编码实现
String encodeBech32Fixed(String hrp, int witver, List<int> witprog) {
  const charset = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';

  // 转换witness program为5位组
  final converted = convertBits(witprog, 8, 5, true);
  if (converted == null) {
    throw Exception('Invalid witness program');
  }

  // 创建数据: witness version + converted program
  final data = [witver] + converted;

  // 计算校验和
  final checksum = bech32ChecksumFixed(hrp, data);

  // 组合所有部分
  final combined = data + checksum;

  // 编码为bech32
  final encoded = combined.map((x) => charset[x]).join('');

  return '$hrp${'1'}$encoded';
}

// 修复的校验和计算
List<int> bech32ChecksumFixed(String hrp, List<int> data) {
  final values = hrpExpandFixed(hrp) + [0] + data;
  final polymod = bech32PolymodFixed(values + [0, 0, 0, 0, 0, 0]) ^ 1;

  final result = <int>[];
  for (int i = 0; i < 6; i++) {
    result.add((polymod >> (5 * (5 - i))) & 31);
  }

  return result;
}

// 修复的HRP扩展
List<int> hrpExpandFixed(String hrp) {
  final result = <int>[];

  // 高位部分
  for (int i = 0; i < hrp.length; i++) {
    result.add(hrp.codeUnitAt(i) >> 5);
  }

  // 分隔符
  result.add(0);

  // 低位部分
  for (int i = 0; i < hrp.length; i++) {
    result.add(hrp.codeUnitAt(i) & 31);
  }

  return result;
}

// 修复的Polymod算法
int bech32PolymodFixed(List<int> values) {
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

// 尝试其他解决方案
Future<void> tryAlternativeSolutions(
    String mnemonic, String expectedAddress) async {
  print('1. 尝试不同的派生路径...');

  final alternativePaths = [
    "m/84'/0'/0'/0/0", // 标准路径
    "m/84'/0'/1'/0/0", // 不同账户
    "m/49'/0'/0'/0/0", // P2SH-P2WPKH
    "m/44'/0'/0'/0/0", // 传统路径
  ];

  for (final path in alternativePaths) {
    final address = await generateWithPath(mnemonic, path);
    print('路径 $path: $address');
    if (address == expectedAddress) {
      print('✅ 找到匹配路径: $path');
      return;
    }
  }

  print('');
  print('2. 尝试使用passphrase...');

  // 尝试常见的passphrase
  final commonPassphrases = ['', 'test', 'password', '123456'];

  for (final passphrase in commonPassphrases) {
    final seed = bip39.mnemonicToSeed(mnemonic, passphrase: passphrase);
    final root = bip32.BIP32.fromSeed(seed);
    final child = root.derivePath("m/84'/0'/0'/0/0");
    final publicKeyHash = hash160(child.publicKey);
    final address = encodeBech32Fixed('bc', 0, publicKeyHash);

    print('Passphrase "$passphrase": $address');
    if (address == expectedAddress) {
      print('✅ 找到匹配passphrase: "$passphrase"');
      return;
    }
  }

  print('');
  print('3. 分析期望地址的来源...');
  analyzeExpectedAddress(expectedAddress);
}

Future<String> generateWithPath(String mnemonic, String path) async {
  final seed = bip39.mnemonicToSeed(mnemonic);
  final root = bip32.BIP32.fromSeed(seed);
  final child = root.derivePath(path);
  final publicKeyHash = hash160(child.publicKey);
  return encodeBech32Fixed('bc', 0, publicKeyHash);
}

void analyzeExpectedAddress(String address) {
  print('期望地址: $address');
  print('长度: ${address.length}');
  print('前缀: ${address.substring(0, 3)}');

  // 解码地址
  final decoded = decodeBech32(address);
  if (decoded != null) {
    final data = decoded['data'] as List<int>;
    final checksum = decoded['checksum'] as List<int>;

    print('数据部分: $data');
    print('校验和: $checksum');

    if (data.isNotEmpty) {
      final witver = data[0];
      final witprog = convertBits(data.sublist(1), 5, 8, false);

      print('Witness版本: $witver');
      if (witprog != null) {
        print('公钥哈希: ${bytesToHex(witprog)}');
      }
    }
  }
}

Map<String, dynamic>? decodeBech32(String bech) {
  const charset = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';

  final pos = bech.lastIndexOf('1');
  if (pos < 1 || pos + 7 > bech.length || bech.length > 90) {
    return null;
  }

  final hrp = bech.substring(0, pos);
  final data = <int>[];

  for (int i = pos + 1; i < bech.length; i++) {
    final d = charset.indexOf(bech[i]);
    if (d == -1) return null;
    data.add(d);
  }

  if (data.length < 6) return null;

  final payload = data.sublist(0, data.length - 6);
  final checksum = data.sublist(data.length - 6);

  return {
    'hrp': hrp,
    'data': payload,
    'checksum': checksum,
  };
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

String bytesToHex(List<int> bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
}
