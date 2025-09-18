import 'dart:typed_data';

void main() {
  print('=== 逐步调试Bech32编码 ===');

  // 使用已知的测试向量
  debugKnownVector();

  // 调试我们的案例
  debugOurCase();
}

void debugKnownVector() {
  print('=== 调试已知向量 ===');

  // BIP173测试向量
  const expectedAddress = 'bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4';
  final publicKeyHash = hexToBytes('751e76cbc6e8b4d0a669b1a69e427b85');

  print('期望地址: $expectedAddress');
  print('公钥哈希: ${bytesToHex(publicKeyHash)}');
  print('');

  // 步骤1: 转换为5位组
  final converted = convertBits(publicKeyHash, 8, 5, true);
  print('步骤1 - 转换为5位组: $converted');

  // 步骤2: 添加witness version
  final data = [0] + converted!;
  print('步骤2 - 添加witness version: $data');

  // 步骤3: 解码期望地址来获取正确的数据
  final expectedDecoded = decodeBech32(expectedAddress);
  if (expectedDecoded != null) {
    print('期望的数据部分: ${expectedDecoded['data']}');
    print('期望的校验和: ${expectedDecoded['checksum']}');
    print(
        '数据匹配: ${listEquals(data, expectedDecoded['data'] as List<int>) ? '✅' : '❌'}');
  }

  // 步骤4: 计算我们的校验和
  final ourChecksum = bech32Checksum('bc', data);
  print('我们的校验和: $ourChecksum');

  // 步骤5: 编码
  const charset = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';
  final combined = data + ourChecksum;
  final encoded = combined.map((x) => charset[x]).join('');
  final ourAddress = 'bc1$encoded';

  print('我们的地址: $ourAddress');
  print('匹配: ${ourAddress == expectedAddress ? '✅' : '❌'}');
  print('');
}

void debugOurCase() {
  print('=== 调试我们的案例 ===');

  const expectedAddress = 'bc1q6t3djkmdngf472a6efq9v2w9n8zjwwtzs8wxyq';
  final publicKeyHash = hexToBytes('d2e2d95b6d9a135f2bbaca405629c599c5273962');

  print('期望地址: $expectedAddress');
  print('公钥哈希: ${bytesToHex(publicKeyHash)}');
  print('');

  // 解码期望地址
  final expectedDecoded = decodeBech32(expectedAddress);
  if (expectedDecoded != null) {
    print('期望的数据部分: ${expectedDecoded['data']}');
    print('期望的校验和: ${expectedDecoded['checksum']}');

    // 从期望的数据部分重建witness program
    final expectedData = expectedDecoded['data'] as List<int>;
    if (expectedData.isNotEmpty) {
      final witver = expectedData[0];
      final witprog = convertBits(expectedData.sublist(1), 5, 8, false);

      print('Witness version: $witver');
      print(
          'Witness program: ${witprog != null ? bytesToHex(witprog) : 'null'}');

      if (witprog != null) {
        print('重建的公钥哈希: ${bytesToHex(witprog)}');
        print('原始公钥哈希: ${bytesToHex(publicKeyHash)}');
        print('公钥哈希匹配: ${listEquals(witprog, publicKeyHash) ? '✅' : '❌'}');
      }
    }
  }

  // 测试我们的编码
  final converted = convertBits(publicKeyHash, 8, 5, true);
  final data = [0] + converted!;
  final ourChecksum = bech32Checksum('bc', data);

  print('');
  print('我们的数据: $data');
  print('我们的校验和: $ourChecksum');

  const charset = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';
  final combined = data + ourChecksum;
  final encoded = combined.map((x) => charset[x]).join('');
  final ourAddress = 'bc1$encoded';

  print('我们的地址: $ourAddress');
  print('匹配: ${ourAddress == expectedAddress ? '✅' : '❌'}');
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

  if (data.length < 6) return null;

  final payload = data.sublist(0, data.length - 6);
  final checksum = data.sublist(data.length - 6);

  return {
    'hrp': hrp,
    'data': payload,
    'checksum': checksum,
  };
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

// HRP扩展
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

bool listEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
