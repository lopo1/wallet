import 'dart:io';
import 'package:convert/convert.dart';

void main() {
  // 已知正确的公钥哈希
  final publicKeyHash = hex.decode('d2e2d95b6d9a135f2bbaca405629c599c5273962');
  
  print('=== Bech32编码调试 ===');
  print('公钥哈希: ${hex.encode(publicKeyHash)}');
  
  // 测试我们的bech32编码
  final ourAddress = encodeBech32('bc', 0, publicKeyHash);
  print('我们的地址: $ourAddress');
  
  // 期望地址
  const expectedAddress = 'bc1q6t3djkmdngf472a6efq9v2w9n8zjwwtzs8wxyq';
  print('期望地址: $expectedAddress');
  
  // 详细分析编码过程
  print('');
  print('=== 详细编码过程 ===');
  
  // 1. 转换为5位组
  final spec = convertBits(publicKeyHash, 8, 5, true);
  print('转换为5位组: $spec');
  
  // 2. 添加witness version
  final data = [0] + spec!;
  print('添加witness version: $data');
  
  // 3. 计算校验和
  final checksum = bech32Checksum('bc', data);
  print('校验和: $checksum');
  
  // 4. 组合数据
  final combined = data + checksum;
  print('组合数据: $combined');
  
  // 5. 编码为字符
  const charset = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';
  final encoded = combined.map((x) => charset[x]).join('');
  print('编码字符: $encoded');
  
  final finalAddress = 'bc1' + encoded;
  print('最终地址: $finalAddress');
  
  // 解码期望地址来比较
  print('');
  print('=== 解码期望地址 ===');
  final expectedDecoded = decodeBech32Details(expectedAddress);
  if (expectedDecoded != null) {
    print('期望地址的数据部分: ${expectedDecoded['data']}');
    print('期望地址的校验和: ${expectedDecoded['checksum']}');
    print('我们计算的校验和: $checksum');
  }
}

// 详细解码bech32
Map<String, dynamic>? decodeBech32Details(String address) {
  try {
    const charset = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';
    
    if (!address.startsWith('bc1')) return null;
    
    final data = address.substring(3); // 移除 'bc1'
    final decoded = <int>[];
    
    for (int i = 0; i < data.length; i++) {
      final char = data[i];
      final index = charset.indexOf(char);
      if (index == -1) return null;
      decoded.add(index);
    }
    
    // 分离数据和校验和
    final payload = decoded.sublist(0, decoded.length - 6);
    final checksum = decoded.sublist(decoded.length - 6);
    
    return {
      'data': payload,
      'checksum': checksum,
      'full_decoded': decoded,
    };
  } catch (e) {
    return null;
  }
}

// Bech32编码
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