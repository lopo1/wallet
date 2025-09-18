import 'dart:typed_data';

void main() {
  print('=== 修复Bech32实现 ===');

  // 测试标准向量
  testStandardVector();

  // 测试我们的案例
  testOurCase();
}

void testStandardVector() {
  print('=== 测试BIP173标准向量 ===');

  // BIP173标准测试向量: "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
  // 这对应的是公钥哈希: 751e76cbc6e8b4d0a669b1a69e427b85
  final testHash = hexToBytes('751e76cbc6e8b4d0a669b1a69e427b85');

  print('测试公钥哈希: ${bytesToHex(testHash)}');

  final address = encodeBech32Witness('bc', 0, testHash);
  print('生成地址: $address');
  print('期望地址: bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4');
  print(
      '匹配: ${address == 'bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4' ? '✅' : '❌'}');
  print('');
}

void testOurCase() {
  print('=== 测试我们的案例 ===');

  final publicKeyHash = hexToBytes('d2e2d95b6d9a135f2bbaca405629c599c5273962');
  print('公钥哈希: ${bytesToHex(publicKeyHash)}');

  final address = encodeBech32Witness('bc', 0, publicKeyHash);
  print('生成地址: $address');
  print('期望地址: bc1q6t3djkmdngf472a6efq9v2w9n8zjwwtzs8wxyq');
  print(
      '匹配: ${address == 'bc1q6t3djkmdngf472a6efq9v2w9n8zjwwtzs8wxyq' ? '✅' : '❌'}');
}

// 正确的Bech32 witness地址编码
String encodeBech32Witness(String hrp, int witver, List<int> witprog) {
  // 转换witness program为5位组
  final spec = convertBits(witprog, 8, 5, true);
  if (spec == null) {
    throw Exception('Invalid witness program');
  }

  // 创建数据: witness version + converted program
  final data = [witver] + spec;

  return encodeBech32(hrp, data);
}

// 标准Bech32编码
String encodeBech32(String hrp, List<int> data) {
  const charset = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';

  final checksum = bech32Checksum(hrp, data);
  final combined = data + checksum;
  final encoded = combined.map((x) => charset[x]).join('');

  return '$hrp${'1'}$encoded';
}

// 修复的Bech32校验和计算
List<int> bech32Checksum(String hrp, List<int> data) {
  final values = hrpExpand(hrp) + [0] + data;
  final polymod = bech32Polymod(values + [0, 0, 0, 0, 0, 0]) ^ 1;

  final result = <int>[];
  for (int i = 0; i < 6; i++) {
    result.add((polymod >> (5 * (5 - i))) & 31);
  }

  return result;
}

// HRP扩展
List<int> hrpExpand(String hrp) {
  final hi = <int>[];
  final lo = <int>[];

  for (int i = 0; i < hrp.length; i++) {
    final c = hrp.codeUnitAt(i);
    hi.add(c >> 5);
    lo.add(c & 31);
  }

  return hi + [0] + lo;
}

// Bech32 polymod算法
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

// 位转换
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

// 工具函数
List<int> hexToBytes(String hex) {
  final result = <int>[];
  for (int i = 0; i < hex.length; i += 2) {
    result.add(int.parse(hex.substring(i, i + 2), radix: 16));
  }
  return result;
}

String bytesToHex(List<int> bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
}
