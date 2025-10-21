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
  /// 发送TRX转账
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

    debugPrint('=== 创建 TRON 交易 ===');
    debugPrint('From: $fromAddress');
    debugPrint('To: $toAddress');
    debugPrint('Amount: $amountSun SUN ($amountTRX TRX)');

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
    debugPrint(
        'Raw data hex (前64字符): ${rawHex.substring(0, min(64, rawHex.length))}...');
    debugPrint('SHA256 digest: ${HEX.encode(digest)}');

    // 使用 ECDSA 签名
    final signature =
        _signECDSA(Uint8List.fromList(digest), pkBytes, publicKey);
    final signatureHex = HEX.encode(signature);

    debugPrint('签名长度: ${signature.length} 字节');
    debugPrint('签名 hex: $signatureHex');

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
      debugPrint('交易成功! TxID: $txId');
      return txId;
    }
    throw Exception('广播成功但未返回交易ID');
  }

  /// 使用 ECDSA 签名（TRON 格式）
  static Uint8List _signECDSA(
    Uint8List messageHash,
    Uint8List privateKeyBytes,
    Uint8List publicKeyBytes,
  ) {
    // 使用 pointycastle 进行 secp256k1 签名
    final signer = ECDSASigner(null, HMac(SHA256Digest(), 64));
    final privateKeyInt = BigInt.parse(HEX.encode(privateKeyBytes), radix: 16);
    final key = ECPrivateKey(privateKeyInt, ECCurve_secp256k1());

    final params = ParametersWithRandom(
      PrivateKeyParameter(key),
      _getSecureRandom(),
    );

    signer.init(true, params);
    final sig = signer.generateSignature(messageHash) as ECSignature;

    // 获取 r 和 s
    final r = sig.r;
    final s = sig.s;

    // 计算 recovery id (v)
    // 尝试两个可能的 v 值 (0 和 1)，看哪个能恢复出正确的公钥
    int v = _findRecoveryId(messageHash, r, s, publicKeyBytes);

    debugPrint('签名 r: ${r.toRadixString(16).substring(0, 16)}...');
    debugPrint('签名 s: ${s.toRadixString(16).substring(0, 16)}...');
    debugPrint('Recovery ID (v): $v');

    // 组装签名: r (32 bytes) + s (32 bytes) + v (1 byte)
    final rBytes = _bigIntToBytes(r, 32);
    final sBytes = _bigIntToBytes(s, 32);

    return Uint8List.fromList([...rBytes, ...sBytes, v]);
  }

  /// 查找正确的 recovery id
  static int _findRecoveryId(
    Uint8List messageHash,
    BigInt r,
    BigInt s,
    Uint8List expectedPublicKey,
  ) {
    // 尝试 v = 0 和 v = 1
    for (int v = 0; v <= 3; v++) {
      try {
        final recovered = _tryRecoverPublicKey(messageHash, r, s, v);
        if (recovered != null) {
          // 比较恢复的公钥与期望的公钥
          if (_comparePublicKeys(recovered, expectedPublicKey)) {
            debugPrint('找到正确的 recovery id: $v');
            return v;
          }
        }
      } catch (e) {
        debugPrint('尝试 v=$v 失败: $e');
      }
    }

    // 默认返回 0
    debugPrint('警告: 无法找到正确的 recovery id，使用默认值 0');
    return 0;
  }

  /// 尝试从签名恢复公钥
  static Uint8List? _tryRecoverPublicKey(
    Uint8List messageHash,
    BigInt r,
    BigInt s,
    int v,
  ) {
    try {
      final curve = ECCurve_secp256k1();
      final n = curve.n;

      // 计算 x 坐标
      final x = r + (BigInt.from(v ~/ 2) * n);
      // fieldSize 是 int 类型，需要转换为 BigInt 进行比较
      if (x >= BigInt.from(curve.curve.fieldSize)) return null;

      // 从 x 恢复点
      // 构造压缩公钥格式: 02/03 + x (32 bytes)
      final prefix = (v & 1) == 0 ? 0x02 : 0x03;
      final xBytes = _bigIntToBytes(x, 32);
      final compressedKey = Uint8List.fromList([prefix, ...xBytes]);

      final point = curve.curve.decodePoint(compressedKey);
      if (point == null) return null;
      if (point.isInfinity) return null;

      // 计算 e = messageHash
      final e = BigInt.parse(HEX.encode(messageHash), radix: 16);

      // 计算 r^-1 mod n
      final rInv = r.modInverse(n);

      // 恢复公钥: Q = r^-1 * (s*R - e*G)
      final sR = point * s;
      final eG = curve.G * e;
      if (sR == null || eG == null) return null;

      final negEG = eG * (n - BigInt.one);
      if (negEG == null) return null;

      final sRMinusEG = sR + negEG;
      if (sRMinusEG == null) return null;

      final Q = sRMinusEG * rInv;
      if (Q == null || Q.isInfinity) return null;

      return Q.getEncoded(false);
    } catch (e) {
      return null;
    }
  }

  /// 比较两个公钥是否相同
  static bool _comparePublicKeys(Uint8List pk1, Uint8List pk2) {
    // 确保都是非压缩格式
    Uint8List uncompressed1 = pk1;
    Uint8List uncompressed2 = pk2;

    if (pk1.length == 33) {
      final curve = ECCurve_secp256k1();
      final point = curve.curve.decodePoint(pk1);
      if (point != null) {
        uncompressed1 = point.getEncoded(false);
      }
    }

    if (pk2.length == 33) {
      final curve = ECCurve_secp256k1();
      final point = curve.curve.decodePoint(pk2);
      if (point != null) {
        uncompressed2 = point.getEncoded(false);
      }
    }

    if (uncompressed1.length != uncompressed2.length) return false;

    for (int i = 0; i < uncompressed1.length; i++) {
      if (uncompressed1[i] != uncompressed2[i]) return false;
    }

    return true;
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
}
