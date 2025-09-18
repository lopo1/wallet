import 'dart:io';
import 'dart:typed_data';
import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:crypto/crypto.dart';
import 'package:pointycastle/digests/ripemd160.dart';
import 'package:convert/convert.dart';

void main() async {
  const testMnemonic = 'what cloth hold life mammal patch aerobic fluid dry lobster ozone ring';
  const expectedAddress = 'bc1q6t3djkmdngf472a6efq9v2w9n8zjwwtzs8wxyq';
  
  print('=== 详细调试Bitcoin地址生成 ===');
  print('助记词: $testMnemonic');
  print('期望地址: $expectedAddress');
  print('');
  
  try {
    // 1. 生成seed
    final seed = bip39.mnemonicToSeed(testMnemonic);
    print('Seed (hex): ${hex.encode(seed)}');
    
    // 2. 生成根密钥
    final root = bip32.BIP32.fromSeed(seed);
    print('Root private key: ${hex.encode(root.privateKey!)}');
    print('Root public key: ${hex.encode(root.publicKey)}');
    
    // 3. 派生路径 m/84'/0'/0'/0/0
    final path = "m/84'/0'/0'/0/0";
    final child = root.derivePath(path);
    print('');
    print('派生路径: $path');
    print('Child private key: ${hex.encode(child.privateKey!)}');
    print('Child public key: ${hex.encode(child.publicKey)}');
    
    // 4. 计算公钥哈希
    final publicKey = child.publicKey;
    final sha256Hash = sha256.convert(publicKey).bytes;
    print('');
    print('SHA256(publicKey): ${hex.encode(sha256Hash)}');
    
    final ripemd160 = RIPEMD160Digest();
    final sha256Uint8 = Uint8List.fromList(sha256Hash);
    ripemd160.update(sha256Uint8, 0, sha256Uint8.length);
    final publicKeyHash = Uint8List(20);
    ripemd160.doFinal(publicKeyHash, 0);
    print('RIPEMD160(SHA256(publicKey)): ${hex.encode(publicKeyHash)}');
    
    // 5. 生成bech32地址
    final address = encodeBech32('bc', 0, publicKeyHash.toList());
    print('');
    print('生成的地址: $address');
    print('期望的地址: $expectedAddress');
    print('匹配: ${address == expectedAddress}');
    
    // 6. 解析期望地址来看看差异
    print('');
    print('=== 分析期望地址 ===');
    final expectedDecoded = decodeBech32(expectedAddress);
    if (expectedDecoded != null) {
      print('期望地址解码的公钥哈希: ${hex.encode(expectedDecoded)}');
      print('我们计算的公钥哈希: ${hex.encode(publicKeyHash)}');
      print('公钥哈希匹配: ${hex.encode(expectedDecoded) == hex.encode(publicKeyHash)}');
    }
    
  } catch (e) {
    print('错误: $e');
    exit(1);
  }
}

// 解码bech32地址
List<int>? decodeBech32(String address) {
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
    
    // 移除校验和 (最后6个字符)
    final payload = decoded.sublist(0, decoded.length - 6);
    
    // 移除witness version (第一个字符)
    final program = payload.sublist(1);
    
    // 转换回8位
    final converted = convertBits(program, 5, 8, false);
    return converted;
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