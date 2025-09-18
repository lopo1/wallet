import 'dart:typed_data';

void main() {
  print('=== Bech32编码测试 ===');

  // 测试已知的bech32编码
  testKnownBech32();

  // 测试我们的具体案例
  testOurCase();
}

void testKnownBech32() {
  print('=== 测试已知bech32编码 ===');

  // BIP173标准测试向量
  final testVectors = [
    {
      'hrp': 'bc',
      'data': [
        0,
        14,
        20,
        15,
        7,
        13,
        26,
        0,
        25,
        18,
        6,
        11,
        13,
        21,
        31,
        16,
        18,
        29,
        3,
        17,
        2,
        29,
        3,
        12,
        29,
        3,
        4,
        15,
        24,
        20,
        6,
        14,
        30,
        22
      ],
      'expected': 'bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4'
    }
  ];

  for (final test in testVectors) {
    final hrp = test['hrp'] as String;
    final data = test['data'] as List<int>;
    final expected = test['expected'] as String;

    final result = encodeBech32Raw(hrp, data);
    print('HRP: $hrp');
    print('数据: $data');
    print('期望: $expected');
    print('实际: $result');
    print('匹配: ${result == expected ? '✅' : '❌'}');
    print('');
  }
}

void testOurCase() {
  print('=== 测试我们的案例 ===');

  // 我们的公钥哈希
  final publicKeyHashHex = 'd2e2d95b6d9a135f2bbaca405629c599c5273962';
  final publicKeyHash = hexToBytes(publicKeyHashHex);

  print('公钥哈希 (hex): $publicKeyHashHex');
  print('公钥哈希 (bytes): $publicKeyHash');

  // 转换为5位组
  final converted = convertBits(publicKeyHash, 8, 5, true);
  print('转换为5位组: $converted');

  // 添加witness version
  final data = [0] + converted!;
  print('添加witness version: $data');

  // 编码
  final result = encodeBech32Raw('bc', data);
  print('编码结果: $result');

  // 期望地址
  const expected = 'bc1q6t3djkmdngf472a6efq9v2w9n8zjwwtzs8wxyq';
  print('期望地址: $expected');
  print('匹配: ${result == expected ? '✅' : '❌'}');

  // 详细分析
  if (result != expected) {
    print('');
    print('=== 详细分析 ===');
    analyzeEncodingSteps('bc', data, expected);
  }
}

void analyzeEncodingSteps(String hrp, List<int> data, String expected) {
  print('HRP: $hrp');
  print('数据: $data');

  // 计算校验和
  final checksum = bech32Checksum(hrp, data);
  print('我们的校验和: $checksum');

  // 解码期望地址来获取其校验和
  final expectedDecoded = decodeBech32(expected);
  if (expectedDecoded != null) {
    print('期望的校验和: ${expectedDecoded['checksum']}');

    // 比较数据部分
    final expectedData = expectedDecoded['data'] as List<int>;
    print('期望的数据: $expectedData');
    print('我们的数据: $data');
    print('数据匹配: ${listEquals(data, expectedData) ? '✅' : '❌'}');
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

String encodeBech32Raw(String hrp, List<int> data) {
  const charset = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';

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

List<int> hexToBytes(String hex) {
  final result = <int>[];
  for (int i = 0; i < hex.length; i += 2) {
    result.add(int.parse(hex.substring(i, i + 2), radix: 16));
  }
  return result;
}

bool listEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
