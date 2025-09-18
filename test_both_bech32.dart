import 'dart:io';
import 'package:convert/convert.dart';

void main() {
  // 已知正确的公钥哈希
  final publicKeyHash = hex.decode('d2e2d95b6d9a135f2bbaca405629c599c5273962');
  
  print('=== 测试Bech32和Bech32m编码 ===');
  print('公钥哈希: ${hex.encode(publicKeyHash)}');
  
  // 期望地址
  const expectedAddress = 'bc1q6t3djkmdngf472a6efq9v2w9n8zjwwtzs8wxyq';
  print('期望地址: $expectedAddress');
  print('');
  
  // 测试原始Bech32 (常数 = 1)
  final bech32Address = encodeBech32('bc', 0, publicKeyHash, useBech32m: false);
  print('Bech32编码 (常数=1): $bech32Address');
  print('匹配: ${bech32Address == expectedAddress}');
  
  // 测试Bech32m (常数 = 0x2bc830a3)
  final bech32mAddress = encodeBech32('bc', 0, publicKeyHash, useBech32m: true);
  print('Bech32m编码 (常数=0x2bc830a3): $bech32mAddress');
  print('匹配: ${bech32mAddress == expectedAddress}');
  
  print('');
  print('=== 验证期望地址使用的编码方式 ===');
  final verification = verifyBech32Checksum('bc', expectedAddress);
  print('期望地址验证结果: $verification');
}

// 验证地址使用的编码方式
String verifyBech32Checksum(String hrp, String address) {
  try {
    const charset = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';
    
    if (!address.startsWith(hrp + '1')) return 'Invalid HRP';
    
    final data = address.substring(hrp.length + 1);
    final decoded = <int>[];
    
    for (int i = 0; i < data.length; i++) {
      final char = data[i];
      final index = charset.indexOf(char);
      if (index == -1) return 'Invalid character';
      decoded.add(index);
    }
    
    final values = hrpExpand(hrp) + decoded;
    final polymod = bech32Polymod(values);
    
    if (polymod == 1) {
      return 'Bech32 (常数=1)';
    } else if (polymod == 0x2bc830a3) {
      return 'Bech32m (常数=0x2bc830a3)';
    } else {
      return 'Invalid checksum (polymod=$polymod)';
    }
  } catch (e) {
    return 'Error: $e';
  }
}

// Bech32编码（支持两种常数）
String encodeBech32(String hrp, int witver, List<int> witprog, {bool useBech32m = false}) {
  const charset = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';
  
  final spec = convertBits(witprog, 8, 5, true);
  if (spec == null) {
    throw Exception('Invalid witness program');
  }
  
  final data = [witver] + spec;
  final checksum = bech32Checksum(hrp, data, useBech32m: useBech32m);
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

List<int> bech32Checksum(String hrp, List<int> data, {bool useBech32m = false}) {
  final values = hrpExpand(hrp) + [0] + data;
  final constant = useBech32m ? 0x2bc830a3 : 1;
  final polymod = bech32Polymod(values + [0, 0, 0, 0, 0, 0]) ^ constant;
  
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