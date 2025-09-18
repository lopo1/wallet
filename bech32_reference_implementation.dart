// 基于BIP173标准的参考实现
import 'dart:typed_data';

void main() {
  print('=== Bech32参考实现测试 ===');

  // 测试我们的案例
  final publicKeyHash = hexToBytes('d2e2d95b6d9a135f2bbaca405629c599c5273962');
  print('公钥哈希: ${bytesToHex(publicKeyHash)}');

  final address = segwitAddrEncode('bc', 0, publicKeyHash);
  print('生成地址: $address');
  print('期望地址: bc1q6t3djkmdngf472a6efq9v2w9n8zjwwtzs8wxyq');
  print(
      '匹配: ${address == 'bc1q6t3djkmdngf472a6efq9v2w9n8zjwwtzs8wxyq' ? '✅' : '❌'}');

  // 测试标准向量
  print('');
  print('=== 测试BIP173标准向量 ===');
  testStandardVectors();
}

void testStandardVectors() {
  final testVectors = [
    {
      'hex': '751e76cbc6e8b4d0a669b1a69e427b85',
      'expected': 'bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4'
    },
    {
      'hex': '1863143c14c5166804bd19203356da136c985678cd4d27a1b8c6329604903262',
      'expected':
          'bc1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3qccfmv3'
    }
  ];

  for (final test in testVectors) {
    final hash = hexToBytes(test['hex'] as String);
    final expected = test['expected'] as String;
    final generated = segwitAddrEncode('bc', 0, hash);

    print('测试: ${test['hex']}');
    print('期望: $expected');
    print('生成: $generated');
    print('匹配: ${generated == expected ? '✅' : '❌'}');
    print('');
  }
}

// BIP173标准Segwit地址编码
String segwitAddrEncode(String hrp, int witver, List<int> witprog) {
  final ret = bech32Encode(hrp, [witver] + convertBits(witprog, 8, 5, true)!);
  if (segwitAddrDecode(hrp, ret) == null) {
    throw Exception('Invalid program');
  }
  return ret;
}

// Segwit地址解码（用于验证）
Map<String, dynamic>? segwitAddrDecode(String hrp, String addr) {
  final hrpgot = bech32Decode(addr);
  if (hrpgot == null || hrpgot['hrp'] != hrp) {
    return null;
  }

  final data = hrpgot['data'] as List<int>;
  if (data.isEmpty || data[0] > 16) {
    return null;
  }

  final decoded = convertBits(data.sublist(1), 5, 8, false);
  if (decoded == null || decoded.length < 2 || decoded.length > 40) {
    return null;
  }

  if (data[0] == 0 && decoded.length != 20 && decoded.length != 32) {
    return null;
  }

  return {'witver': data[0], 'witprog': decoded};
}

// Bech32编码
String bech32Encode(String hrp, List<int> data) {
  const charset = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';
  final combined = data + bech32CreateChecksum(hrp, data);
  return hrp + '1' + combined.map((d) => charset[d]).join('');
}

// Bech32解码
Map<String, dynamic>? bech32Decode(String bech) {
  if ((bech.toUpperCase() != bech) && (bech.toLowerCase() != bech)) {
    return null;
  }
  bech = bech.toLowerCase();

  final pos = bech.lastIndexOf('1');
  if (pos < 1 || pos + 7 > bech.length || bech.length > 90) {
    return null;
  }

  if (!bech
      .substring(pos + 1)
      .split('')
      .every((x) => 'qpzry9x8gf2tvdw0s3jn54khce6mua7l'.contains(x))) {
    return null;
  }

  final hrp = bech.substring(0, pos);
  final data = bech
      .substring(pos + 1)
      .split('')
      .map((x) => 'qpzry9x8gf2tvdw0s3jn54khce6mua7l'.indexOf(x))
      .toList();

  if (!bech32VerifyChecksum(hrp, data)) {
    return null;
  }

  return {'hrp': hrp, 'data': data.sublist(0, data.length - 6)};
}

// 校验和验证
bool bech32VerifyChecksum(String hrp, List<int> data) {
  return bech32Polymod(bech32HrpExpand(hrp) + [0] + data) == 1;
}

// 创建校验和
List<int> bech32CreateChecksum(String hrp, List<int> data) {
  final values = bech32HrpExpand(hrp) + [0] + data;
  final polymod = bech32Polymod(values + [0, 0, 0, 0, 0, 0]) ^ 1;
  return List.generate(6, (i) => (polymod >> 5 * (5 - i)) & 31);
}

// HRP扩展
List<int> bech32HrpExpand(String hrp) {
  return hrp.codeUnits.map((x) => x >> 5).toList() +
      [0] +
      hrp.codeUnits.map((x) => x & 31).toList();
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
  final ret = <int>[];
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
      ret.add((acc >> bits) & maxv);
    }
  }

  if (pad) {
    if (bits > 0) {
      ret.add((acc << (tobits - bits)) & maxv);
    }
  } else if (bits >= frombits || ((acc << (tobits - bits)) & maxv) != 0) {
    return null;
  }

  return ret;
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
