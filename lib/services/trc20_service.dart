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

class TRC20Service {
  /// 查询 TRC20 代币余额
  static Future<double> getBalance({
    required String contractAddress,
    required String ownerAddress,
    required String tronRpcBaseUrl,
    required int decimals,
  }) async {
    try {
      debugPrint('=== 查询 TRC20 余额 ===');
      debugPrint('合约地址: $contractAddress');
      debugPrint('持有者地址: $ownerAddress');

      // 调用 TriggerSmartContract 接口查询余额
      // balanceOf(address) 的函数选择器是 0x70a08231

      // 将地址转换为 32 字节的参数（去掉 T 前缀，转为 hex，补齐到 64 位）
      final addressParam = _encodeAddress(ownerAddress);

      debugPrint('编码后的地址参数: $addressParam');

      final requestBody = {
        'contract_address': contractAddress,
        'owner_address': ownerAddress,
        'function_selector': 'balanceOf(address)',
        'parameter': addressParam, // 只传地址参数，不包含函数选择器
        'visible': true,
      };

      debugPrint('请求参数: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$tronRpcBaseUrl/wallet/triggerconstantcontract'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        throw Exception('查询余额失败: HTTP ${response.statusCode}');
      }

      final result = jsonDecode(response.body) as Map<String, dynamic>;

      debugPrint('响应: ${jsonEncode(result)}');

      if (result.containsKey('constant_result') &&
          result['constant_result'] is List &&
          (result['constant_result'] as List).isNotEmpty) {
        final hexBalance = result['constant_result'][0] as String;
        final balanceInt = BigInt.parse(hexBalance, radix: 16);
        final balance = balanceInt.toDouble() / pow(10, decimals);

        debugPrint('余额: $balance');
        return balance;
      }

      return 0.0;
    } catch (e) {
      debugPrint('查询 TRC20 余额失败: $e');
      return 0.0;
    }
  }

  /// 发送 TRC20 代币转账
  static Future<String> transfer({
    required String mnemonic,
    required int addressIndex,
    required String contractAddress,
    required String fromAddress,
    required String toAddress,
    required double amount,
    required int decimals,
    required String tronRpcBaseUrl,
  }) async {
    debugPrint('=== TRC20 转账 ===');
    debugPrint('合约地址: $contractAddress');
    debugPrint('From: $fromAddress');
    debugPrint('To: $toAddress');
    debugPrint('Amount: $amount');

    // 转换金额为最小单位
    final amountInt = (amount * pow(10, decimals)).round();

    // 构造 transfer(address,uint256) 函数调用
    final toAddressParam = _encodeAddress(toAddress);
    final amountParam = _encodeUint256(BigInt.from(amountInt));
    final parameter = toAddressParam + amountParam; // 只传参数，不包含函数选择器

    debugPrint('To Address Param: $toAddressParam');
    debugPrint('Amount Param: $amountParam');
    debugPrint('Full Parameter: $parameter');

    // 1) 创建智能合约调用交易
    final Map<String, dynamic> createBody = {
      'owner_address': fromAddress,
      'contract_address': contractAddress,
      'function_selector': 'transfer(address,uint256)',
      'parameter': parameter, // 只传参数，不包含函数选择器
      'fee_limit': 100000000, // 100 TRX 作为手续费上限
      'call_value': 0,
      'visible': true,
    };

    final createResp = await http.post(
      Uri.parse('$tronRpcBaseUrl/wallet/triggersmartcontract'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(createBody),
    );

    if (createResp.statusCode != 200) {
      throw Exception(
          '创建交易失败: HTTP ${createResp.statusCode} ${createResp.body}');
    }

    final raw = jsonDecode(createResp.body) as Map<String, dynamic>;

    if (!raw.containsKey('transaction')) {
      final code = raw['code'] ?? '';
      final message = raw['message'] ?? '';
      throw Exception('创建交易失败: $code $message');
    }

    final transaction = raw['transaction'] as Map<String, dynamic>;
    if (!transaction.containsKey('raw_data_hex')) {
      throw Exception('交易数据缺少 raw_data_hex');
    }

    // 2) 推导私钥
    final seed = bip39.mnemonicToSeed(mnemonic);
    final root = bip32.BIP32.fromSeed(seed);
    final derivationPath = DerivationPaths.tronWithIndex(addressIndex);
    final child = root.derivePath(derivationPath);
    final pkBytes = child.privateKey;

    if (pkBytes == null) {
      throw Exception('无法导出TRON私钥');
    }

    final publicKey = child.publicKey;

    // 2.1) 校验推导地址是否与 fromAddress 一致（防止签名权限错误）
    try {
      final derivedAddress = _deriveAddressFromPublicKey(publicKey);
      debugPrint('签名地址预校验(TRC20服务): 推导地址 $derivedAddress, 期望地址 $fromAddress');
      if (derivedAddress != fromAddress) {
        throw Exception('私钥推导错误: 期望地址 $fromAddress, 实际地址 $derivedAddress');
      }
    } catch (e) {
      debugPrint('TRC20 服务推导地址校验失败: $e');
      rethrow;
    }

    // 3) 签名
    final rawHex = transaction['raw_data_hex'] as String;
    final rawBytes = Uint8List.fromList(HEX.decode(rawHex));
    final digest = dart_crypto.sha256.convert(rawBytes).bytes;

    final signature =
        _signECDSA(Uint8List.fromList(digest), pkBytes, publicKey);
    final signatureHex = HEX.encode(signature);

    final signedTx = Map<String, dynamic>.from(transaction);
    signedTx['signature'] = [signatureHex];

    // 4) 广播交易
    final broadcastResp = await http.post(
      Uri.parse('$tronRpcBaseUrl/wallet/broadcasttransaction'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(signedTx),
    );

    if (broadcastResp.statusCode != 200) {
      throw Exception('广播交易失败: HTTP ${broadcastResp.statusCode}');
    }

    final broadcastResult =
        jsonDecode(broadcastResp.body) as Map<String, dynamic>;
    final bool success = broadcastResult['result'] == true;

    if (!success) {
      final code = broadcastResult['code'] ?? '';
      final message = broadcastResult['message'] ?? '';
      throw Exception('广播交易失败: $code $message');
    }

    final txId = broadcastResult['txid'] ?? transaction['txID'] ?? '';
    if (txId is String && txId.isNotEmpty) {
      debugPrint('TRC20 转账成功! TxID: $txId');
      return txId;
    }

    throw Exception('广播成功但未返回交易ID');
  }

  /// 将 TRON 地址编码为 32 字节参数
  static String _encodeAddress(String address) {
    // 将 Base58 地址解码为 hex
    final decoded = _base58Decode(address);
    if (decoded.length != 25) {
      throw Exception('无效的 TRON 地址');
    }

    // 取 21 字节的 payload（去掉 4 字节 checksum）
    final payload = decoded.sublist(0, 21);

    // 去掉 0x41 前缀，得到 20 字节的地址
    final addressBytes = payload.sublist(1);
    final addressHex = HEX.encode(addressBytes);

    // 补齐到 64 位（32 字节）
    return addressHex.padLeft(64, '0');
  }

  /// 将 uint256 编码为 32 字节参数
  static String _encodeUint256(BigInt value) {
    String hex = value.toRadixString(16);
    return hex.padLeft(64, '0');
  }

  /// Base58 解码
  static List<int> _base58Decode(String input) {
    const alphabet =
        '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
    final charIndex = <String, int>{};
    for (int i = 0; i < alphabet.length; i++) {
      charIndex[alphabet[i]] = i;
    }

    if (input.isEmpty) return <int>[];

    int leadingOnes = 0;
    for (int i = 0; i < input.length && input[i] == '1'; i++) {
      leadingOnes++;
    }

    var num = BigInt.zero;
    for (int i = leadingOnes; i < input.length; i++) {
      final ch = input[i];
      final val = charIndex[ch];
      if (val == null) {
        throw Exception('Invalid base58 character: $ch');
      }
      num = num * BigInt.from(58) + BigInt.from(val);
    }

    var bytes = <int>[];
    while (num > BigInt.zero) {
      final mod = num % BigInt.from(256);
      num = num ~/ BigInt.from(256);
      bytes.add(mod.toInt());
    }
    bytes = bytes.reversed.toList();

    if (leadingOnes > 0) {
      return List<int>.filled(leadingOnes, 0)..addAll(bytes);
    }
    return bytes;
  }

  /// ECDSA 签名（复用 TronService 的逻辑）
  static Uint8List _signECDSA(
    Uint8List messageHash,
    Uint8List privateKeyBytes,
    Uint8List publicKeyBytes,
  ) {
    final signer = ECDSASigner(null, HMac(SHA256Digest(), 64));
    final privateKeyInt = BigInt.parse(HEX.encode(privateKeyBytes), radix: 16);
    final key = ECPrivateKey(privateKeyInt, ECCurve_secp256k1());

    final params = ParametersWithRandom(
      PrivateKeyParameter(key),
      _getSecureRandom(),
    );

    signer.init(true, params);
    final sig = signer.generateSignature(messageHash) as ECSignature;

    final r = sig.r;
    final s = sig.s;
    final v = _findRecoveryId(messageHash, r, s, publicKeyBytes);

    final rBytes = _bigIntToBytes(r, 32);
    final sBytes = _bigIntToBytes(s, 32);

    return Uint8List.fromList([...rBytes, ...sBytes, v]);
  }

  static int _findRecoveryId(
    Uint8List messageHash,
    BigInt r,
    BigInt s,
    Uint8List expectedPublicKey,
  ) {
    for (int v = 0; v <= 3; v++) {
      try {
        final recovered = _tryRecoverPublicKey(messageHash, r, s, v);
        if (recovered != null &&
            _comparePublicKeys(recovered, expectedPublicKey)) {
          return v;
        }
      } catch (e) {
        // 继续尝试下一个 v 值
      }
    }
    return 0;
  }

  static Uint8List? _tryRecoverPublicKey(
    Uint8List messageHash,
    BigInt r,
    BigInt s,
    int v,
  ) {
    try {
      final curve = ECCurve_secp256k1();
      final n = curve.n;
      final x = r + (BigInt.from(v ~/ 2) * n);

      if (x >= BigInt.from(curve.curve.fieldSize)) return null;

      final prefix = (v & 1) == 0 ? 0x02 : 0x03;
      final xBytes = _bigIntToBytes(x, 32);
      final compressedKey = Uint8List.fromList([prefix, ...xBytes]);

      final point = curve.curve.decodePoint(compressedKey);
      if (point == null || point.isInfinity) return null;

      final e = BigInt.parse(HEX.encode(messageHash), radix: 16);
      final rInv = r.modInverse(n);

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

  static bool _comparePublicKeys(Uint8List pk1, Uint8List pk2) {
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


  // 复制 TronService 的地址推导逻辑，用于校验
  static String _deriveAddressFromPublicKey(Uint8List publicKey) {
    // 解压公钥（如果是压缩格式）
    Uint8List uncompressed;
    if (publicKey.length == 33) {
      final curve = ECCurve_secp256k1();
      final point = curve.curve.decodePoint(publicKey);
      if (point == null) {
        throw Exception('无法解压公钥');
      }
      uncompressed = point.getEncoded(false);
    } else if (publicKey.length == 65) {
      uncompressed = publicKey;
    } else {
      throw Exception('无效的公钥长度: ${publicKey.length}');
    }

    // 对非压缩公钥（去掉0x04前缀）做 keccak256
    final pkHash = web3_crypto.keccak256(uncompressed.sublist(1));
    final address20 = pkHash.sublist(12);

    // TRON 地址: 0x41 + 20字节地址
    final payload = Uint8List.fromList([0x41, ...address20]);

    // 计算 checksum（double sha256）
    final checksum = _doubleHash256(payload).sublist(0, 4);

    // Base58 编码
    final base58Address = _base58Encode([...payload, ...checksum]);
    return base58Address;
  }

  static Uint8List _doubleHash256(Uint8List input) {
    final first = dart_crypto.sha256.convert(input).bytes;
    final second = dart_crypto.sha256.convert(Uint8List.fromList(first)).bytes;
    return Uint8List.fromList(second);
  }

  static String _base58Encode(List<int> bytes) {
    const alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
    BigInt intData = BigInt.zero;
    for (final b in bytes) {
      intData = (intData << 8) | BigInt.from(b);
    }
    String result = '';
    while (intData > BigInt.zero) {
      final mod = intData % BigInt.from(58);
      intData = intData ~/ BigInt.from(58);
      result = alphabet[mod.toInt()] + result;
    }
    for (final b in bytes) {
      if (b == 0) {
        result = '1' + result;
      } else {
        break;
      }
    }
    return result;
  }
}
