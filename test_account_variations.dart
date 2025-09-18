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
  
  print('=== 测试不同账户和地址索引组合 ===');
  print('助记词: $testMnemonic');
  print('期望地址: $expectedAddress');
  print('');
  
  // 测试不同的账户索引和地址索引组合
  final testCombinations = [
    // 格式: [账户索引, 地址索引, 描述]
    [0, 0, 'Account 0, Address 0 (最常见)'],
    [1, 0, 'Account 1, Address 0'],
    [0, 1, 'Account 0, Address 1'],
    [2, 0, 'Account 2, Address 0'],
    [0, 2, 'Account 0, Address 2'],
  ];
  
  bool found = false;
  
  for (final combo in testCombinations) {
    final accountIndex = combo[0] as int;
    final addressIndex = combo[1] as int;
    final description = combo[2] as String;
    
    // 构建派生路径: m/84'/0'/account'/0/address
    final path = "m/84'/0'/$accountIndex'/0/$addressIndex";
    
    try {
      final address = await generateBitcoinAddressWithPath(testMnemonic, path);
      print('$description');
      print('路径: $path');
      print('地址: $address');
      
      if (address == expectedAddress) {
        print('✅ 找到匹配！');
        found = true;
      }
      print('');
    } catch (e) {
      print('错误 ($description): $e');
      print('');
    }
  }
  
  if (!found) {
    print('=== 扩展搜索：测试更多组合 ===');
    // 如果还没找到，测试更多组合
    for (int account = 0; account < 5 && !found; account++) {
      for (int address = 0; address < 10 && !found; address++) {
        final path = "m/84'/0'/$account'/0/$address";
        try {
          final generatedAddress = await generateBitcoinAddressWithPath(testMnemonic, path);
          if (generatedAddress == expectedAddress) {
            print('✅ 找到匹配！');
            print('账户索引: $account');
            print('地址索引: $address');
            print('路径: $path');
            print('地址: $generatedAddress');
            found = true;
          }
        } catch (e) {
          // 忽略错误，继续搜索
        }
      }
    }
  }
  
  if (!found) {
    print('❌ 在测试的组合中未找到匹配的地址');
    print('可能的原因:');
    print('1. 其他钱包使用了不同的派生路径标准');
    print('2. 使用了不同的币种代码（非0）');
    print('3. 使用了passphrase');
    print('4. 地址生成算法有其他差异');
  }
}

// 使用指定路径生成Bitcoin地址
Future<String> generateBitcoinAddressWithPath(String mnemonic, String path) async {
  try {
    // 1. 助记词转 seed
    final seed = bip39.mnemonicToSeed(mnemonic);

    // 2. 用 BIP32 推导指定路径的key
    final root = bip32.BIP32.fromSeed(seed);
    final child = root.derivePath(path);

    // 3. 生成 Bitcoin P2WPKH 地址 (bech32)
    final publicKey = child.publicKey;
    final publicKeyHash = hash160(publicKey);

    // 4. 生成 bech32 地址
    return encodeBech32('bc', 0, publicKeyHash);
  } catch (e) {
    throw Exception('Failed to generate Bitcoin address: $e');
  }
}

// RIPEMD160(SHA256(data))
List<int> hash160(List<int> data) {
  final sha256Hash = sha256.convert(data).bytes;
  final ripemd160 = RIPEMD160Digest();
  final sha256Uint8 = Uint8List.fromList(sha256Hash);
  ripemd160.update(sha256Uint8, 0, sha256Uint8.length);
  final result = Uint8List(20);
  ripemd160.doFinal(result, 0);
  return result.toList();
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