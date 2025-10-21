import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;
import 'package:web3dart/crypto.dart' as web3_crypto;
import 'package:crypto/crypto.dart' as dart_crypto;
import 'package:hex/hex.dart';
import 'package:pointycastle/export.dart';
import '../constants/derivation_paths.dart';
import '../constants/network_constants.dart';

class TronService {
  /// 发送TRX转账（Shasta测试网）
  static Future<String> sendTrxTransfer({
    required String mnemonic,
    required int addressIndex,
    required String fromAddress,
    required String toAddress,
    required double amountTRX,
    required String tronRpcBaseUrl,
  }) async {
    // 转成SUN（1 TRX = 1_000_000 SUN）
    final int amountSun =
        (amountTRX * NetworkConstants.tronDecimalFactor).round();

    // 1) 创建未签名交易
    final Map<String, dynamic> createBody = {
      'to_address': toAddress,
      'owner_address': fromAddress,
      'amount': amountSun,
      'visible': true, // 使用Base58地址
    };
    final createResp = await http.post(
      Uri.parse('$tronRpcBaseUrl/wallet/createtransaction'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(createBody),
    );
    if (createResp.statusCode != 200) {
      throw Exception(
          '创建TRON交易失败: HTTP ${createResp.statusCode} ${createResp.body}');
    }
    final raw = jsonDecode(createResp.body) as Map<String, dynamic>;
    if (!raw.containsKey('raw_data_hex')) {
      final code = raw['code'] ?? '';
      final message = raw['message'] ?? '';
      throw Exception('创建TRON交易失败: $code $message');
    }

    // 2) 推导私钥
    final seed = bip39.mnemonicToSeed(mnemonic);
    final root = bip32.BIP32.fromSeed(seed);
    final derivationPath = DerivationPaths.tronWithIndex(addressIndex);
    debugPrint('=== TRON 私钥推导 ===');
    debugPrint('地址索引: $addressIndex');
    debugPrint('推导路径: $derivationPath');
    debugPrint('期望地址: $fromAddress');

    final child = root.derivePath(derivationPath);
    final pkBytes = child.privateKey;
    if (pkBytes == null) {
      throw Exception('无法导出TRON私钥');
    }
    final pkHex = HEX.encode(pkBytes);

    // 验证推导的私钥是否对应正确的地址
    final publicKey = child.publicKey;
    final derivedAddress = _deriveAddressFromPublicKey(publicKey);
    debugPrint('推导的地址: $derivedAddress');

    if (derivedAddress != fromAddress) {
      throw Exception('私钥推导错误: 期望地址 $fromAddress, 实际地址 $derivedAddress');
    }

    // 3) 对raw_data_hex做sha256并签名
    final rawHex = raw['raw_data_hex'] as String;
    final rawBytes = Uint8List.fromList(HEX.decode(rawHex));
    final digest = dart_crypto.sha256.convert(rawBytes).bytes;

    debugPrint('=== TRON 签名 ===');
    debugPrint('Raw data hex: ${rawHex.substring(0, 64)}...');
    debugPrint('SHA256 digest: ${HEX.encode(digest)}');

    // 使用 secp256k1 直接签名
    final signature = _signWithSecp256k1(Uint8List.fromList(digest), pkBytes);
    final signatureHex = HEX.encode(signature);

    debugPrint('签名长度: ${signature.length} 字节');
    debugPrint('签名 hex: ${signatureHex.substring(0, 64)}...');

    final signedTx = Map<String, dynamic>.from(raw);
    signedTx['signature'] = [signatureHex];

    // 4) 广播交易
    final broadcastResp = await http.post(
      Uri.parse('$tronRpcBaseUrl/wallet/broadcasttransaction'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(signedTx),
    );
    if (broadcastResp.statusCode != 200) {
      throw Exception(
          '广播TRON交易失败: HTTP ${broadcastResp.statusCode} ${broadcastResp.body}');
    }
    final broadcastResult =
        jsonDecode(broadcastResp.body) as Map<String, dynamic>;
    final bool success = broadcastResult['result'] == true;
    if (!success) {
      final code = broadcastResult['code'] ?? '';
      final message = broadcastResult['message'] ?? '';
      throw Exception('广播TRON交易失败: $code $message');
    }

    // 优先返回broadcast返回的txid；否则用创建时的txID
    final txId = broadcastResult['txid'] ?? raw['txID'] ?? '';
    if (txId is String && txId.isNotEmpty) {
      return txId;
    }
    throw Exception('广播成功但未返回交易ID');
  }

  static List<int> _bigIntToBytes(BigInt value, int size) {
    // 先将BigInt转为hex，再转为bytes
    String hexStr = value.toRadixString(16);
    if (hexStr.length % 2 != 0) {
      hexStr = '0$hexStr';
    }
    final list = HEX.decode(hexStr);
    if (list.length > size) {
      return list.sublist(list.length - size);
    }
    if (list.length < size) {
      return List<int>.filled(size - list.length, 0)..addAll(list);
    }
    return list;
  }

  /// 从公钥推导 TRON 地址
  static String _deriveAddressFromPublicKey(Uint8List publicKey) {
    // 解压公钥（如果是压缩格式）
    Uint8List uncompressed;
    if (publicKey.length == 33) {
      // 压缩公钥，需要解压
      final curve = ECCurve_secp256k1();
      final point = curve.curve.decodePoint(publicKey);
      if (point == null) {
        throw Exception('无法解压公钥');
      }
      uncompressed = point.getEncoded(false);
    } else if (publicKey.length == 65) {
      // 已经是非压缩格式
      uncompressed = publicKey;
    } else {
      throw Exception('无效的公钥长度: ${publicKey.length}');
    }

    // 对非压缩公钥（去掉0x04前缀）做 keccak256
    final pkHash = web3_crypto.keccak256(uncompressed.sublist(1));
    final address20 = pkHash.sublist(12); // 取后20字节

    // TRON 地址: 0x41 + 20字节地址
    final payload = Uint8List.fromList([0x41, ...address20]);

    // 计算 checksum
    final checksum = _doubleHash256(payload).sublist(0, 4);

    // Base58 编码
    final base58Address = _base58Encode([...payload, ...checksum]);
    return base58Address;
  }

  /// Double SHA256 hash
  static List<int> _doubleHash256(List<int> data) {
    final first = dart_crypto.sha256.convert(data).bytes;
    final second = dart_crypto.sha256.convert(first).bytes;
    return second;
  }

  /// Base58 编码
  static String _base58Encode(List<int> input) {
    const alphabet =
        '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
    if (input.isEmpty) return '';

    int leadingZeros = 0;
    for (int i = 0; i < input.length && input[i] == 0; i++) {
      leadingZeros++;
    }

    var num = BigInt.zero;
    for (int byte in input) {
      num = num * BigInt.from(256) + BigInt.from(byte);
    }

    final result = <String>[];
    while (num > BigInt.zero) {
      final remainder = num % BigInt.from(58);
      num = num ~/ BigInt.from(58);
      result.add(alphabet[remainder.toInt()]);
    }

    final leadingOnes = '1' * leadingZeros;
    return leadingOnes + result.reversed.join('');
  }

  /// 使用 secp256k1 签名（TRON 格式）
  static Uint8List _signWithSecp256k1(
      Uint8List messageHash, Uint8List privateKey) {
    // 使用 pointycastle 进行 secp256k1 签名
    final signer = ECDSASigner(null, HMac(SHA256Digest(), 64));
    final key = ECPrivateKey(
      BigInt.parse(HEX.encode(privateKey), radix: 16),
      ECCurve_secp256k1(),
    );

    final params = ParametersWithRandom(
      PrivateKeyParameter(key),
      _getSecureRandom(),
    );

    signer.init(true, params);

    final sig = signer.generateSignature(messageHash) as ECSignature;

    // 转换为 TRON 格式的签名 (r + s + v)
    final r = sig.r;
    final s = sig.s;

    // 计算 recovery id (v)
    // TRON 使用 0 或 1 作为 recovery id
    int v = 0;

    // 尝试恢复公钥来确定正确的 v 值
    final publicKey = _recoverPublicKey(messageHash, r, s, 0, privateKey);
    if (publicKey == null) {
      v = 1;
    }

    // 组装签名: r (32 bytes) + s (32 bytes) + v (1 byte)
    final rBytes = _bigIntToBytes(r, 32);
    final sBytes = _bigIntToBytes(s, 32);

    return Uint8List.fromList([...rBytes, ...sBytes, v]);
  }

  /// 恢复公钥以验证 recovery id
  static Uint8List? _recoverPublicKey(
    Uint8List messageHash,
    BigInt r,
    BigInt s,
    int recoveryId,
    Uint8List privateKey,
  ) {
    try {
      final curve = ECCurve_secp256k1();
      final n = curve.n;
      final G = curve.G;

      // 从私钥计算期望的公钥
      final d = BigInt.parse(HEX.encode(privateKey), radix: 16);
      final expectedPublicKey = (G * d)!;

      // 尝试从签名恢复公钥
      final x = r + (BigInt.from(recoveryId ~/ 2) * n);
      final ySquared =
          (x * x * x + curve.curve.a! * x + curve.curve.b!) % curve.curve.p!;

      // 检查是否匹配
      final recoveredPoint = curve.curve.decompressPoint(recoveryId & 1, x);
      if (recoveredPoint == null) return null;

      // 验证恢复的公钥是否与期望的公钥匹配
      if (recoveredPoint == expectedPublicKey) {
        return recoveredPoint.getEncoded(false);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// 获取安全随机数生成器
  static SecureRandom _getSecureRandom() {
    final secureRandom = FortunaRandom();
    final random = Random.secure();
    final seeds = <int>[];
    for (int i = 0; i < 32; i++) {
      seeds.add(random.nextInt(256));
    }
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }
}
