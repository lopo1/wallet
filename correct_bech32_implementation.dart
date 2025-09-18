import 'dart:typed_data';

void main() {
  print('=== 正确的Bech32实现 ===');

  // 测试标准向量
  testStandardVectors();

  // 测试我们的案例
  testOurCase();
}

void testStandardVectors() {
  print('=== 测试BIP173标准向量 ===');

  // 标准测试向量
  final testVectors = [
    {
      'address': 'bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4',
      'hex': '751e76cbc6e8b4d0a669b1a69e427b85'
    },
    {
      'address':
          'bc1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3qccfmv3',
      'hex': '1863143c14c5166804bd19203356da136c985678cd4d27a1b8c6329604903262'
    }
  ];

  for (final test in testVectors) {
    final expectedAddress = test['address'] as String;
    final hexData = test['hex'] as String;
    final publicKeyHash = hexToBytes(hexData);

    print('测试向量: $expectedAddress');
    print('公钥哈希: $hexData');

    final generatedAddress = encodeBech32Address('bc', 0, publicKeyHash);
    print('生成地址: $generatedAddress');
    print('匹配: ${generatedAddress == expectedAddress ? '✅' : '❌'}');
    print('');
  }
}

void testOurCase() {
  print('=== 测试我们的案例 ===');

  final publicKeyHash = hexToBytes('d2e2d95b6d9a135f2bbaca405629c599c5273962');
  print('公钥哈希: ${bytesToHex(publicKeyHash)}');

  final address = encodeBech32Address('bc', 0, publicKeyHash);
  print('生成地址: $address');
  print('期望地址: bc1q6t3djkmdngf472a6efq9v2w9n8zjwwtzs8wxyq');
  print(
      '匹配: ${address == 'bc1q6t3djkmdngf472a6efq9v2w9n8zjwwtzs8wxyq' ? '✅' : '❌'}');

  // 如果不匹配，进行详细分析
  if (address != 'bc1q6t3djkmdngf472a6efq9v2w9n8zjwwtzs8wxyq') {
    print('');
    print('=== 详细分析 ===');
    analyzeAddress(address, 'bc1q6t3djkmdngf472a6efq9v2w9n8zjwwtzs8wxyq');
  }
}

void analyzeAddress(String actual, String expected) {
  print('实际: $actual');
  print('期望: $expected');

  // 解码两个地址
  final actualDecoded = decodeBech32(actual);
  final expectedDecoded = decodeBech32(expected);

  if (actualDecoded != null && expectedDecoded != null) {
    print('实际数据: ${actualDecoded['data']}');
    print('期望数据: ${expectedDecoded['data']}');
    print('实际校验和: ${actualDecoded['checksum']}');
    print('期望校验和: ${expectedDecoded['checksum']}');
  }
}

// 正确的Bech32地址编码
String encodeBech32Address(String hrp, int witver, List<int> witprog) {
  // 转换witness program为5位组
  final converted = convertBits(witprog, 8, 5, true);
  if (converted == null) {
    throw Exception('Invalid witness program');
  }

  // 创建数据: witness version + converted program
  final data = [witver] + converted;

  return encodeBech32(hrp, data);
}

// Bech32编码
String encodeBech32(String hrp, List<int> data) {
  const charset = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';

  final checksum = bech32Checksum(hrp, data);
  final combined = data + checksum;
  final encoded = combined.map((x) => charset[x]).join('');

  return '$hrp${'1'}$encoded';
}

// Bech32解码
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

  if (!bech32VerifyChecksum(hrp, data)) {
    return null;
  }

  final payload = data.sublist(0, data.length - 6);
  final checksum = data.sublist(data.length - 6);

  return {
    'hrp': hrp,
    'data': payload,
    'checksum': checksum,
  };
}

// 校验和验证
bool bech32VerifyChecksum(String hrp, List<int> data) {
  return bech32Polymod(hrpExpand(hrp) + [0] + data) == 1;
}

// 校验和计算
List<int> bech32Checksum(String hrp, List<int> data) {
  final values = hrpExpand(hrp) + [0] + data;
  final polymod = bech32Polymod(values + [0, 0, 0, 0, 0, 0]) ^ 1;

  final result = <int>[];
  for (int i = 0; i < 6; i++) {
    result.add((polymod >> (5 * (5 - i))) & 31);
  }

  return result;
}

// HRP扩展 - 按照BIP173规范
List<int> hrpExpand(String hrp) {
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

// Polymod算法
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
