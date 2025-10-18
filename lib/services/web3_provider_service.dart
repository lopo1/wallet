import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;
import 'package:hex/hex.dart' as hex;
import 'package:web3dart/web3dart.dart' as web3;
import '../constants/derivation_paths.dart';
import '../models/web3_request.dart';
import '../models/dapp_connection.dart';
import '../providers/wallet_provider.dart';
import 'dapp_connection_service.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/crypto.dart' as web3_crypto;

/// Web3 Provider服务
///
/// 负责处理DApp与钱包之间的Web3交互，包括：
/// - 注入Web3 Provider到WebView
/// - 处理Web3方法调用
/// - 管理区块链交互
class Web3ProviderService {
  final WalletProvider _walletProvider;
  final DAppConnectionService _connectionService;
  final Map<String, Function(dynamic)> _pendingCallbacks = {};

  WebViewController? _webViewController;
  String? _currentOrigin;

  Web3ProviderService({
    required WalletProvider walletProvider,
    required DAppConnectionService connectionService,
  })  : _walletProvider = walletProvider,
        _connectionService = connectionService;

  /// 设置WebView控制器
  void setWebViewController(WebViewController? controller, String origin) {
    _webViewController = controller;
    _currentOrigin = origin;
  }

  /// 注入Web3 Provider到WebView
  Future<void> injectProvider() async {
    if (_webViewController == null || _currentOrigin == null) {
      debugPrint('WebView controller or origin not set');
      return;
    }

    try {
      final connection = _connectionService.getConnection(_currentOrigin!);
      if (connection == null) {
        debugPrint('No connection found for origin: $_currentOrigin');
        return;
      }

      final currentNetwork = _walletProvider.currentNetwork;
      if (currentNetwork == null) {
        debugPrint('No current network selected');
        return;
      }

      final chainIdHex = '0x${currentNetwork.chainId.toRadixString(16)}';
      final selectedAddress = connection.connectedAddresses.isNotEmpty
          ? connection.connectedAddresses.first
          : '';

      final providerJS = _buildWeb3ProviderJS(chainIdHex, selectedAddress);
      await _webViewController!.runJavaScript(providerJS);

      debugPrint('Web3 Provider injected successfully for $_currentOrigin');
    } catch (e) {
      debugPrint('Failed to inject Web3 Provider: $e');
    }
  }

  /// 处理Web3请求
  Future<dynamic> handleWeb3Request(Map<String, dynamic> requestData) async {
    try {
      final method = requestData['method'] as String?;
      final params = requestData['params'] as List<dynamic>? ?? [];
      final id = requestData['id'];

      if (method == null || _currentOrigin == null) {
        throw Exception('Invalid request: missing method or origin');
      }

      final web3Method = Web3Method.fromString(method);
      if (web3Method == null) {
        throw Exception('Unsupported method: $method');
      }

      final request = Web3Request(
        id: id?.toString() ?? _generateRequestId(),
        method: web3Method,
        params: params,
        origin: _currentOrigin!,
        createdAt: DateTime.now(),
      );

      debugPrint('Handling Web3 request: ${request.method.methodName}');

      // 检查连接状态
      if (!_connectionService.isConnected(_currentOrigin!)) {
        throw Exception('DApp not connected');
      }

      // 处理不同的Web3方法
      switch (web3Method) {
        case Web3Method.ethRequestAccounts:
          return await _handleRequestAccounts(request);
        case Web3Method.ethAccounts:
          return await _handleAccounts(request);
        case Web3Method.ethChainId:
          return await _handleChainId(request);
        case Web3Method.netVersion:
          return await _handleNetVersion(request);
        case Web3Method.ethSendTransaction:
          return await _handleSendTransaction(request);
        case Web3Method.ethSignTransaction:
          return await _handleSignTransaction(request);
        case Web3Method.personalSign:
          return await _handlePersonalSign(request);
        case Web3Method.ethSignTypedData:
        case Web3Method.ethSignTypedDataV4:
          return await _handleSignTypedData(request);
        case Web3Method.walletSwitchEthereumChain:
          return await _handleSwitchChain(request);
        case Web3Method.walletAddEthereumChain:
          return await _handleAddChain(request);
        case Web3Method.walletWatchAsset:
          return await _handleWatchAsset(request);
        case Web3Method.walletRevokePermissions:
          return await _handleRevokePermissions(request);
        default:
          throw Exception('Method not implemented: $method');
      }
    } catch (e) {
      debugPrint('Error handling Web3 request: $e');
      rethrow;
    }
  }

  /// 发送响应到WebView
  Future<void> sendResponse(String requestId, dynamic result,
      [String? error, int? code]) async {
    if (_webViewController == null) return;

    try {
      final response = {
        'id': requestId,
        'result': result,
        'error': error,
        'code': code,
      };

      final responseJS = '''
        if (window.handleFlutterWeb3Response) {
          window.handleFlutterWeb3Response(${jsonEncode(response)});
        } else {
          console.error('[FlutterWeb3] handleFlutterWeb3Response not found');
        }
      ''';

      await _webViewController!.runJavaScript(responseJS);
      debugPrint('Response sent for request: $requestId');
    } catch (e) {
      debugPrint('Failed to send response: $e');
    }
  }

  /// 处理账户请求
  Future<List<String>> _handleRequestAccounts(Web3Request request) async {
    final connection = _connectionService.getConnection(_currentOrigin!);
    if (connection == null || connection.connectedAddresses.isEmpty) {
      throw Exception('No accounts connected');
    }

    // 更新最后使用时间
    await _connectionService.updateLastUsed(_currentOrigin!);

    return connection.connectedAddresses;
  }

  /// 处理获取账户
  Future<List<String>> _handleAccounts(Web3Request request) async {
    final connection = _connectionService.getConnection(_currentOrigin!);
    if (connection == null) {
      return [];
    }

    return connection.connectedAddresses;
  }

  /// 处理获取链ID
  Future<String> _handleChainId(Web3Request request) async {
    final currentNetwork = _walletProvider.currentNetwork;
    if (currentNetwork == null) {
      throw Exception('No network selected');
    }

    return '0x${currentNetwork.chainId.toRadixString(16)}';
  }

  /// 处理获取网络版本
  Future<String> _handleNetVersion(Web3Request request) async {
    final currentNetwork = _walletProvider.currentNetwork;
    if (currentNetwork == null) {
      throw Exception('No network selected');
    }

    return currentNetwork.chainId.toString();
  }

  /// 处理发送交易
  Future<String> _handleSendTransaction(Web3Request request) async {
    if (request.params.isEmpty) {
      throw Exception('Transaction parameters required');
    }

    final txParams = request.params.first as Map<String, dynamic>;

    // 验证交易参数
    final from = txParams['from'] as String?;
    final to = txParams['to'] as String?;
    final value = txParams['value'] as String?;
    final data = txParams['data'] as String?;
    final gas = txParams['gas'] as String?;
    final gasPrice = txParams['gasPrice'] as String?;

    if (from == null) {
      throw Exception('From address is required');
    }

    if (to == null) {
      throw Exception('To address is required');
    }

    // 检查地址权限 - 使用小写比较避免大小写问题
    final connection = _connectionService.getConnection(_currentOrigin!);
    final fromLower = from.toLowerCase();
    final connectedAddressesLower = connection?.connectedAddresses.map((addr) => addr.toLowerCase()).toList() ?? [];
    
    if (connection == null || !connectedAddressesLower.contains(fromLower)) {
      debugPrint('Address authorization failed. From: $from, Connected: ${connection?.connectedAddresses}');
      throw Exception('Address not authorized');
    }

    // 检查发送交易权限
    if (!connection.hasPermission(DAppPermission.sendTransactions)) {
      throw Exception('Send transaction permission not granted');
    }

    try {
      // 解析交易金额
      double amount = 0.0;
      if (value != null && value.isNotEmpty) {
        // 移除 '0x' 前缀并转换为 BigInt
        final hexValue = value.startsWith('0x') ? value.substring(2) : value;
        if (hexValue.isNotEmpty) {
          final weiAmount = BigInt.parse(hexValue, radix: 16);
          // 转换为以太币（1 ETH = 10^18 Wei）
          amount = weiAmount.toDouble() / BigInt.from(10).pow(18).toDouble();
        }
      }

      // 获取当前网络ID
      // 注意：这里需要从外部传入 WalletProvider 或通过其他方式获取
      // 暂时使用默认值
      final networkId = 'ethereum';

      debugPrint('=== DApp 交易请求 ===');
      debugPrint('来源: $_currentOrigin');
      debugPrint('网络: $networkId');
      debugPrint('发送地址: $from');
      debugPrint('接收地址: $to');
      debugPrint('金额: $amount');
      debugPrint('数据: $data');
      debugPrint('Gas: $gas');
      debugPrint('Gas价格: $gasPrice');

      // 这里应该显示交易确认对话框，让用户确认并输入密码
      // 由于这是一个服务类，无法直接显示UI
      // 实际实现应该通过回调或事件通知UI层显示确认对话框

      // 暂时抛出异常，提示需要用户确认
      throw Exception('需要用户确认交易 - 请在钱包UI中实现交易确认对话框');

      // 实际实现应该是：
      // 1. 通过回调通知UI层显示交易确认对话框
      // 2. 用户确认并输入密码
      // 3. 调用 WalletProvider 的 sendTransaction 方法
      // final txHash = await walletProvider.sendTransaction(
      //   networkId: networkId,
      //   toAddress: to,
      //   amount: amount,
      //   password: password, // 从用户输入获取
      // );
      // return txHash;
    } catch (e) {
      debugPrint('处理发送交易请求失败: $e');
      rethrow;
    }
  }

  /// 处理个人签名
  Future<String> _handlePersonalSign(Web3Request request) async {
    if (request.params.length < 2) {
      throw Exception('Personal sign requires message and address');
    }

    final message = request.params[0] as String;
    final address = request.params[1] as String;

    // 检查地址权限 - 使用小写比较避免大小写问题
    final connection = _connectionService.getConnection(_currentOrigin!);
    final addressLower = address.toLowerCase();
    final connectedAddressesLower = connection?.connectedAddresses.map((addr) => addr.toLowerCase()).toList() ?? [];
    
    if (connection == null || !connectedAddressesLower.contains(addressLower)) {
      debugPrint('Address authorization failed for signing. Address: $address, Connected: ${connection?.connectedAddresses}');
      throw Exception('Address not authorized');
    }

    // 检查签名权限
    if (!connection.hasPermission(DAppPermission.signMessages)) {
      throw Exception('Sign message permission not granted');
    }

    // 获取当前钱包与网络
    final currentWallet = _walletProvider.currentWallet;
    final currentNetwork = _walletProvider.currentNetwork;
    if (currentWallet == null || currentNetwork == null) {
      throw Exception('No active wallet or network selected');
    }

    // 确认该地址属于当前钱包并取得索引 - 使用小写比较
    final addresses = currentWallet.addresses[currentNetwork.id];
    final addressesLower = addresses?.map((addr) => addr.toLowerCase()).toList();
    if (addresses == null || addressesLower == null || !addressesLower.contains(addressLower)) {
      debugPrint('Address not found in wallet. Address: $address, Wallet addresses: $addresses');
      throw Exception('Address not found in current wallet for network');
    }
    final addressIndex = addressesLower.indexOf(addressLower);

    // 解析消息（支持 0x十六进制、Base64、或直接UTF-8字符串）
    Uint8List messageBytes;
    try {
      if (message.startsWith('0x')) {
        final hexStr = message.substring(2);
        messageBytes = Uint8List.fromList(hex.HEX.decode(hexStr));
      } else {
        try {
          // 尝试Base64
          messageBytes = base64.decode(message);
        } catch (_) {
          // 回退为UTF-8
          messageBytes = Uint8List.fromList(utf8.encode(message));
        }
      }
    } catch (e) {
      throw Exception('Invalid message format for personal_sign: $e');
    }

    // 获取私钥（助记词导入场景下从助记词派生）
    final mnemonic = currentWallet.mnemonic;
    if (mnemonic.isEmpty) {
      // 私钥导入钱包的私钥需要密码回调支持，此处先抛出合理错误
      throw Exception('Unable to access signing key. Please implement password callback for private-key wallets.');
    }

    try {
      // 助记词 -> seed -> BIP32 -> 对应索引的以太坊私钥
      final seed = bip39.mnemonicToSeed(mnemonic);
      final root = bip32.BIP32.fromSeed(seed);
      final derivationPath = DerivationPaths.ethereumWithIndex(addressIndex);
      final child = root.derivePath(derivationPath);
      final privateKeyBytes = child.privateKey;
      if (privateKeyBytes == null) {
        throw Exception('Failed to derive private key');
      }

      final privateKeyHex = hex.HEX.encode(privateKeyBytes);
      final credentials = web3.EthPrivateKey.fromHex(privateKeyHex);

      // 执行 EIP-191 personal_sign（web3dart会处理前缀与哈希）
      var signature = await credentials.signPersonalMessage(messageBytes);
      // 调整 v 至 27/28 以兼容常见验证实现
      final v = signature[64];
      if (v < 27) {
        signature[64] = (v + 27);
      }

      final signatureHex = '0x${hex.HEX.encode(signature)}';
      debugPrint('Message signed (personal_sign). Address: $address, Index: $addressIndex');
      return signatureHex;
    } catch (e) {
      debugPrint('Failed to sign personal message: $e');
      throw Exception('personal_sign failed: $e');
    }
  }

  /// 处理类型化数据签名
  Future<String> _handleSignTypedData(Web3Request request) async {
    if (request.params.length < 2) {
      throw Exception('Sign typed data requires address and data');
    }

    final address = request.params[0] as String;
    final typedDataParam = request.params[1];

    // 检查地址权限 - 使用小写比较避免大小写问题
    final connection = _connectionService.getConnection(_currentOrigin!);
    final addressLower = address.toLowerCase();
    final connectedAddressesLower = connection?.connectedAddresses.map((addr) => addr.toLowerCase()).toList() ?? [];
    
    if (connection == null || !connectedAddressesLower.contains(addressLower)) {
      debugPrint('Address authorization failed for typed data signing. Address: $address, Connected: ${connection?.connectedAddresses}');
      throw Exception('Address not authorized');
    }

    // 检查签名权限
    if (!connection.hasPermission(DAppPermission.signMessages)) {
      throw Exception('Sign message permission not granted');
    }

    // 获取当前钱包与网络
    final currentWallet = _walletProvider.currentWallet;
    final currentNetwork = _walletProvider.currentNetwork;
    if (currentWallet == null || currentNetwork == null) {
      throw Exception('No active wallet or network selected');
    }

    // 确认该地址属于当前钱包并取得索引 - 使用小写比较
    final addresses = currentWallet.addresses[currentNetwork.id];
    final addressesLower = addresses?.map((addr) => addr.toLowerCase()).toList();
    if (addresses == null || addressesLower == null || !addressesLower.contains(addressLower)) {
      debugPrint('Address not found in wallet for typed data signing. Address: $address, Wallet addresses: $addresses');
      throw Exception('Address not found in current wallet for network');
    }
    final addressIndex = addressesLower.indexOf(addressLower);

    // 解析 typedData（支持字符串或对象）
    Map<String, dynamic> typedData;
    try {
      if (typedDataParam is String) {
        typedData = json.decode(typedDataParam) as Map<String, dynamic>;
      } else if (typedDataParam is Map<String, dynamic>) {
        typedData = typedDataParam;
      } else {
        throw Exception('Invalid typed data format');
      }
    } catch (e) {
      throw Exception('Failed to parse typed data: $e');
    }

    // 校验基本结构
    if (typedData['types'] == null || typedData['primaryType'] == null || typedData['domain'] == null || typedData['message'] == null) {
      throw Exception('Typed data must include types, primaryType, domain and message');
    }

    // 可选：校验 chainId 与当前网络一致
    final tdChainId = _tryParseChainId(typedData['domain']);
    if (tdChainId != null && tdChainId != currentNetwork.chainId) {
      throw Exception('Typed data chainId mismatch with current network');
    }

    try {
      // 助记词 -> seed -> BIP32 -> 对应索引的以太坊私钥
      final mnemonic = currentWallet.mnemonic;
      if (mnemonic.isEmpty) {
        throw Exception('Unable to access signing key. Please implement password callback for private-key wallets.');
      }

      final seed = bip39.mnemonicToSeed(mnemonic);
      final root = bip32.BIP32.fromSeed(seed);
      final derivationPath = DerivationPaths.ethereumWithIndex(addressIndex);
      final child = root.derivePath(derivationPath);
      final privateKeyBytes = child.privateKey;
      if (privateKeyBytes == null) {
        throw Exception('Failed to derive private key');
      }

      final privateKeyHex = hex.HEX.encode(privateKeyBytes);
      final credentials = web3.EthPrivateKey.fromHex(privateKeyHex);

      // 计算 EIP-712 摘要
      final digest = _computeEip712Digest(typedData);

      // 使用私钥对摘要签名，返回 r||s||v
      final msgSig = await credentials.signToSignature(digest);
      final r = _padUint8ListTo32(web3_crypto.intToBytes(msgSig.r));
      final s = _padUint8ListTo32(web3_crypto.intToBytes(msgSig.s));
      var vByte = msgSig.v;
      if (vByte < 27) { vByte += 27; }
      final v = Uint8List.fromList([vByte]);

      final signatureBytes = Uint8List.fromList([...r, ...s, ...v]);
      final signatureHex = '0x${hex.HEX.encode(signatureBytes)}';

      debugPrint('Typed data signed (EIP-712). Address: $address, Index: $addressIndex');
      return signatureHex;
    } catch (e) {
      debugPrint('Failed to sign typed data: $e');
      throw Exception('eth_signTypedData failed: $e');
    }
  }

  // 计算 EIP-712 摘要: keccak256("\x19\x01" || domainSeparator || hashStruct(message))
  Uint8List _computeEip712Digest(Map<String, dynamic> typedData) {
    final types = Map<String, dynamic>.from(typedData['types'] as Map);
    final primaryType = typedData['primaryType'] as String;
    final domain = Map<String, dynamic>.from(typedData['domain'] as Map);
    final message = Map<String, dynamic>.from(typedData['message'] as Map);

    // 计算域分隔符
    final domainSeparator = _hashStruct('EIP712Domain', domain, types);
    // 计算消息哈希
    final messageHash = _hashStruct(primaryType, message, types);

    // 拼接并取 keccak256
    final prefix = Uint8List.fromList([0x19, 0x01]);
    final data = Uint8List.fromList([...prefix, ...domainSeparator, ...messageHash]);
    return web3_crypto.keccak256(data);
  }

  // 计算某结构体的 hashStruct(s): keccak256(typeHash || encodeData(fields))
  Uint8List _hashStruct(String typeName, Map<String, dynamic> data, Map<String, dynamic> types) {
    final typeHash = web3_crypto.keccak256(Uint8List.fromList(utf8.encode(_encodeType(typeName, types))));
    final encodedData = _encodeData(typeName, data, types);
    final bytes = Uint8List.fromList([...typeHash, ...encodedData]);
    return web3_crypto.keccak256(bytes);
  }

  // encodeType(primaryType) = primaryType(...) + 依赖类型定义（按字母排序）
  String _encodeType(String primaryType, Map<String, dynamic> types) {
    final deps = _findTypeDependencies(primaryType, types);
    deps.remove(primaryType);
    final sorted = deps.toList()..sort();
    final all = [primaryType, ...sorted];

    String encodeOne(String name) {
      final fields = List<Map<String, dynamic>>.from(types[name] as List);
      final params = fields.map((f) => '${f['type']} ${f['name']}').join(',');
      return '$name($params)';
    }

    return all.map(encodeOne).join('');
  }

  // 返回 typeName 的依赖类型集合（包含自身）
  Set<String> _findTypeDependencies(String typeName, Map<String, dynamic> types) {
    final result = <String>{typeName};
    final fields = List<Map<String, dynamic>>.from(types[typeName] as List);

    for (final f in fields) {
      final t = f['type'] as String;
      final base = _baseType(t);
      if (types.containsKey(base)) {
        result.add(base);
        result.addAll(_findTypeDependencies(base, types));
      }
    }
    return result;
  }

  // 提取基础类型（去掉数组标记）
  String _baseType(String type) {
    final match = RegExp(r'^(.*?)(\[.*\])?$').firstMatch(type);
    if (match != null) {
      return match.group(1)!;
    }
    return type;
  }

  // 编码数据字段，返回拼接后的 bytes（不含最终 keccak256）
  Uint8List _encodeData(String typeName, Map<String, dynamic> data, Map<String, dynamic> types) {
    final fields = List<Map<String, dynamic>>.from(types[typeName] as List);
    final encoded = <Uint8List>[];

    for (final f in fields) {
      final fType = f['type'] as String;
      final fName = f['name'] as String;
      final value = data[fName];
      if (value == null) {
        // 缺失字段视为空值（编码为 0）
        encoded.add(Uint8List(32));
        continue;
      }

      final isArray = fType.endsWith(']');
      if (isArray) {
        // 处理数组：对每个元素分别编码/哈希，再对拼接结果 keccak256
        final base = _baseType(fType);
        final list = List.from(value as List);
        final itemEncoded = <Uint8List>[];
        for (final item in list) {
          if (types.containsKey(base)) {
            final structHash = _hashStruct(base, Map<String, dynamic>.from(item as Map), types);
            itemEncoded.add(structHash);
          } else if (base == 'string') {
            itemEncoded.add(web3_crypto.keccak256(Uint8List.fromList(utf8.encode(item as String))));
          } else if (base == 'bytes') {
            itemEncoded.add(web3_crypto.keccak256(_parseBytes(item)));
          } else {
            itemEncoded.add(_encodePrimitive(base, item));
          }
        }
        final concatenated = Uint8List.fromList(itemEncoded.expand((b) => b).toList());
        encoded.add(web3_crypto.keccak256(concatenated));
      } else if (types.containsKey(fType)) {
        // 嵌套结构：encodeData 然后取 keccak256
        final structHash = _hashStruct(fType, Map<String, dynamic>.from(value as Map), types);
        encoded.add(structHash);
      } else if (fType == 'string') {
        encoded.add(web3_crypto.keccak256(Uint8List.fromList(utf8.encode(value as String))));
      } else if (fType == 'bytes') {
        encoded.add(web3_crypto.keccak256(_parseBytes(value)));
      } else {
        // 原子类型：直接 ABI 风格编码为 32 字节
        encoded.add(_encodePrimitive(fType, value));
      }
    }

    return Uint8List.fromList(encoded.expand((b) => b).toList());
  }

  // 编码原子类型为 32 字节
  Uint8List _encodePrimitive(String type, dynamic value) {
    switch (type) {
      case 'address':
        final bytes = _parseAddress(value);
        return _padUint8ListTo32(bytes);
      case 'bool':
        final v = (value is bool) ? (value ? 1 : 0) : (value.toString() == 'true' ? 1 : 0);
        return _padUint8ListTo32(web3_crypto.intToBytes(BigInt.from(v)));
      default:
        if (type.startsWith('uint') || type.startsWith('int')) {
          final bi = _parseBigInt(value);
          return _padUint8ListTo32(web3_crypto.intToBytes(bi));
        }
        if (type == 'bytes') {
          final b = _parseBytes(value);
          return web3_crypto.keccak256(b);
        }
        if (type.startsWith('bytes')) {
          final b = _parseBytes(value);
          return _rightPadUint8ListTo32(b);
        }
        throw Exception('Unsupported primitive type: $type');
    }
  }

  // 解析 BigInt（支持十进制字符串、十六进制 0x 前缀、数字）
  BigInt _parseBigInt(dynamic value) {
    if (value is BigInt) return value;
    if (value is int) return BigInt.from(value);
    if (value is String) {
      final v = value.trim();
      if (v.startsWith('0x') || v.startsWith('0X')) {
        return BigInt.parse(v.substring(2), radix: 16);
      }
      return BigInt.parse(v);
    }
    throw Exception('Invalid numeric value: $value');
  }

  // 解析地址为 20 字节
  Uint8List _parseAddress(dynamic value) {
    final s = value.toString();
    if (!RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(s)) {
      throw Exception('Invalid address: $value');
    }
    return Uint8List.fromList(hex.HEX.decode(s.substring(2)));
  }

  // 解析 bytes（0x 前缀或 Uint8List）
  Uint8List _parseBytes(dynamic value) {
    if (value is Uint8List) return value;
    final s = value.toString();
    if (s.startsWith('0x') || s.startsWith('0X')) {
      return Uint8List.fromList(hex.HEX.decode(s.substring(2)));
    }
    // 允许原始字符串作为 bytes 输入
    return Uint8List.fromList(utf8.encode(s));
  }

  // 从 domain 提取 chainId
  int? _tryParseChainId(Map<String, dynamic> domain) {
    final v = domain['chainId'];
    if (v == null) return null;
    try {
      if (v is int) return v;
      if (v is String) {
        final s = v.trim();
        if (s.startsWith('0x') || s.startsWith('0X')) {
          return int.parse(s.substring(2), radix: 16);
        }
        return int.parse(s);
      }
    } catch (_) {}
    return null;
  }

  // 32 字节左填充（用于 address、uint、int、bool）
  Uint8List _padUint8ListTo32(Uint8List input) {
    if (input.length == 32) return input;
    if (input.length > 32) return input.sublist(input.length - 32);
    final out = Uint8List(32);
    out.setRange(32 - input.length, 32, input);
    return out;
  }

  // 32 字节右填充（用于 bytesN 固定长度）
  Uint8List _rightPadUint8ListTo32(Uint8List input) {
    if (input.length == 32) return input;
    if (input.length > 32) return input.sublist(0, 32);
    final out = Uint8List(32);
    out.setRange(0, input.length, input);
    return out;
  }

  // 构建注入的 Web3 Provider JS
  String _buildWeb3ProviderJS(String chainIdHex, String selectedAddress) {
    final networkVersion = int.parse(chainIdHex.substring(2), radix: 16);
    return '''
      (function() {
        // 如果已经有ethereum provider，不要覆盖
        if (window.ethereum && !window.ethereum.isFlutterWallet) { 
          console.log('[FlutterWeb3] Ethereum provider already exists, skipping injection');
          return; 
        }
        
        window.flutterWeb3Callbacks = window.flutterWeb3Callbacks || {};
        window.handleFlutterWeb3Response = function(response) {
          try {
            const data = typeof response === 'string' ? JSON.parse(response) : response;
            const id = data.id;
            const cb = window.flutterWeb3Callbacks[id];
            if (!cb) return;
            delete window.flutterWeb3Callbacks[id];
            if (data.error) { cb.reject(new Error(data.error)); } else { cb.resolve(data.result); }
          } catch (e) { console.error('[FlutterWeb3] response error', e); }
        };
        
        const provider = {
          // 钱包标识符
          isMetaMask: true,
          isFlutterWallet: true,
          isHarbor: true,
          isTrust: false,
          isCoinbaseWallet: false,
          isRabby: false,
          
          // 连接状态
          isConnected: () => true,
          
          // 网络信息
          chainId: '${chainIdHex}',
          networkVersion: '${networkVersion}',
          
          // 账户信息
          selectedAddress: '${selectedAddress}',
          
          // 核心方法
          request: async function(req) {
            if (!req || !req.method) throw new Error('Invalid request');
            const id = Date.now() + '_' + Math.random().toString(36).slice(2);
            return new Promise((resolve, reject) => {
              window.flutterWeb3Callbacks[id] = { resolve, reject };
              const msg = { id: id, method: req.method, params: req.params || [] };
              if (window.FlutterWeb3 && window.FlutterWeb3.postMessage) {
                window.FlutterWeb3.postMessage(JSON.stringify(msg));
              } else {
                delete window.flutterWeb3Callbacks[id];
                reject(new Error('FlutterWeb3 channel not available'));
              }
              setTimeout(() => {
                if (window.flutterWeb3Callbacks[id]) {
                  delete window.flutterWeb3Callbacks[id];
                  reject(new Error('Request timeout'));
                }
              }, 30000);
            });
          },
          
          // 兼容性方法
          enable: function() { return this.request({ method: 'eth_requestAccounts' }); },
          send: function(method, params) { return this.request(typeof method === 'string' ? { method, params } : method); },
          sendAsync: function(payload, cb) { this.request(payload).then(r => cb(null, { result: r })).catch(e => cb(e, null)); },
          
          // 事件监听器
          on: function(event, callback) {
            console.log('[FlutterWeb3] Event listener added:', event);
            // 简单的事件监听实现
            if (!this._events) this._events = {};
            if (!this._events[event]) this._events[event] = [];
            this._events[event].push(callback);
          },
          
          removeListener: function(event, callback) {
            if (!this._events || !this._events[event]) return;
            const index = this._events[event].indexOf(callback);
            if (index > -1) this._events[event].splice(index, 1);
          }
        };
        
        // 设置全局provider
        window.ethereum = provider;
        window.web3 = { currentProvider: provider };
        
        // EIP-6963: 钱包发现标准
        const walletInfo = {
          uuid: 'harbor-flutter-wallet',
          name: 'Harbor Wallet',
          icon: 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzIiIGhlaWdodD0iMzIiIHZpZXdCb3g9IjAgMCAzMiAzMiIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHJlY3Qgd2lkdGg9IjMyIiBoZWlnaHQ9IjMyIiByeD0iOCIgZmlsbD0iIzYzNjZGMSIvPgo8cGF0aCBkPSJNMTYgOEMxMi42ODYzIDggMTAgMTAuNjg2MyAxMCAxNEMxMCAxNy4zMTM3IDEyLjY4NjMgMjAgMTYgMjBDMTkuMzEzNyAyMCAyMiAxNy4zMTM3IDIyIDE0QzIyIDEwLjY4NjMgMTkuMzEzNyA4IDE2IDhaIiBmaWxsPSJ3aGl0ZSIvPgo8L3N2Zz4K',
          rdns: 'com.harbor.wallet'
        };
        
        // 发送EIP-6963钱包发现事件
        const announceEvent = new CustomEvent('eip6963:announceProvider', {
          detail: Object.freeze({ info: walletInfo, provider: provider })
        });
        
        // 立即发送事件
        window.dispatchEvent(announceEvent);
        
        // 监听请求事件
        window.addEventListener('eip6963:requestProvider', () => {
          window.dispatchEvent(announceEvent);
        });
        
        // 发送传统的初始化事件
        window.dispatchEvent(new Event('ethereum#initialized'));
        
        console.log('[FlutterWeb3] Provider injected successfully with EIP-6963 support');
      })();
    ''';
  }

  String _generateRequestId() {
    final random = Random();
    return 'req_${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(999999)}';
  }

  Future<void> _handleSwitchChain(Web3Request request) async {
    if (request.params.isEmpty) { throw Exception('Chain ID required'); }
    final chainIdParam = request.params.first as Map<String, dynamic>;
    final chainIdHex = chainIdParam['chainId'] as String?;
    if (chainIdHex == null) { throw Exception('Chain ID is required'); }
    final chainId = int.parse(chainIdHex.substring(2), radix: 16);
    final networks = _walletProvider.supportedNetworks;
    final targetNetwork = networks.firstWhere(
      (network) => network.chainId == chainId,
      orElse: () => throw Exception('Unsupported chain ID: $chainId'),
    );
    _walletProvider.setCurrentNetwork(targetNetwork);
    await injectProvider();
    debugPrint('Switched to network: ${targetNetwork.name}');
  }

  Future<void> _handleAddChain(Web3Request request) async {
    throw Exception('Add chain not implemented');
  }

  Future<bool> _handleWatchAsset(Web3Request request) async {
    debugPrint('Watch asset requested');
    return true;
  }

  Future<String> _handleSignTransaction(Web3Request request) async {
    if (request.params.isEmpty) { throw Exception('Transaction parameters required'); }
    final txParams = request.params.first as Map<String, dynamic>;
    final from = txParams['from'] as String?;
    final to = txParams['to'] as String?;
    final valueHex = txParams['value'] as String?;
    final dataHex = txParams['data'] as String?;
    final gasHex = (txParams['gas'] as String?) ?? (txParams['gasLimit'] as String?);
    final gasPriceHex = txParams['gasPrice'] as String?;
    final nonceHex = txParams['nonce'] as String?;
    final chainIdHex = txParams['chainId'] as String?;

    if (from == null || from.isEmpty) { throw Exception('From address is required'); }
    if (to == null || to.isEmpty) { throw Exception('To address is required'); }

    // 验证from地址权限 - 使用小写比较避免大小写问题
    final connection = _connectionService.getConnection(_currentOrigin!);
    final fromLower = from.toLowerCase();
    final connectedAddressesLower = connection?.connectedAddresses.map((addr) => addr.toLowerCase()).toList() ?? [];
    
    if (connection == null || !connectedAddressesLower.contains(fromLower)) { 
      debugPrint('Address authorization failed for transaction signing. From: $from, Connected: ${connection?.connectedAddresses}');
      throw Exception('Address not authorized'); 
    }
    if (!connection.hasPermission(DAppPermission.sendTransactions)) { throw Exception('Send transaction permission not granted'); }

    final currentWallet = _walletProvider.currentWallet;
    final currentNetwork = _walletProvider.currentNetwork;
    if (currentWallet == null || currentNetwork == null) { throw Exception('No active wallet or network selected'); }

    final addresses = currentWallet.addresses[currentNetwork.id];
    final addressesLower = addresses?.map((addr) => addr.toLowerCase()).toList();
    if (addresses == null || addressesLower == null || !addressesLower.contains(fromLower)) { 
      debugPrint('Address not found in wallet for transaction signing. From: $from, Wallet addresses: $addresses');
      throw Exception('Address not found in current wallet for network'); 
    }
    final addressIndex = addressesLower.indexOf(fromLower);

    BigInt _parseHexBigInt(String? hexStr) {
      if (hexStr == null || hexStr.isEmpty) return BigInt.zero;
      final s = hexStr.startsWith('0x') ? hexStr.substring(2) : hexStr;
      return s.isEmpty ? BigInt.zero : BigInt.parse(s, radix: 16);
    }
    int? _parseHexInt(String? hexStr) {
      if (hexStr == null || hexStr.isEmpty) return null;
      final s = hexStr.startsWith('0x') ? hexStr.substring(2) : hexStr;
      return s.isEmpty ? null : int.parse(s, radix: 16);
    }

    final valueWei = _parseHexBigInt(valueHex);
    final gasPriceWei = _parseHexBigInt(gasPriceHex);
    final gasLimitInt = _parseHexInt(gasHex);
    final nonceInt = _parseHexInt(nonceHex);
    final chainId = chainIdHex != null && chainIdHex.isNotEmpty ? int.parse(chainIdHex.substring(2), radix: 16) : currentNetwork.chainId;

    Uint8List? dataBytes;
    if (dataHex != null && dataHex.isNotEmpty) {
      final s = dataHex.startsWith('0x') ? dataHex.substring(2) : dataHex;
      dataBytes = Uint8List.fromList(hex.HEX.decode(s));
    }

    try {
      final mnemonic = currentWallet.mnemonic;
      if (mnemonic.isEmpty) { throw Exception('Unable to access signing key. Please implement password callback for private-key wallets.'); }
      final seed = bip39.mnemonicToSeed(mnemonic);
      final root = bip32.BIP32.fromSeed(seed);
      final derivationPath = DerivationPaths.ethereumWithIndex(addressIndex);
      final child = root.derivePath(derivationPath);
      final privateKeyBytes = child.privateKey;
      if (privateKeyBytes == null) { throw Exception('Failed to derive private key'); }
      final privateKeyHex = hex.HEX.encode(privateKeyBytes);
      final credentials = web3.EthPrivateKey.fromHex(privateKeyHex);

      final client = web3.Web3Client(currentNetwork.rpcUrl, http.Client());
      final fromAddress = web3.EthereumAddress.fromHex(from);
      final toAddress = web3.EthereumAddress.fromHex(to);

      final valueAmount = web3.EtherAmount.fromUnitAndValue(web3.EtherUnit.wei, valueWei);
      web3.EtherAmount? gasPriceAmount = gasPriceWei > BigInt.zero ? web3.EtherAmount.fromUnitAndValue(web3.EtherUnit.wei, gasPriceWei) : null;

      int? effectiveNonce = nonceInt;
      if (effectiveNonce == null) {
        effectiveNonce = await client.getTransactionCount(fromAddress, atBlock: const web3.BlockNum.pending());
      }
      if (gasPriceAmount == null) {
        gasPriceAmount = await client.getGasPrice();
      }
      int? effectiveGasLimit = gasLimitInt;
      if (effectiveGasLimit == null) {
        final estimated = await client.estimateGas(sender: fromAddress, to: toAddress, value: valueAmount, data: dataBytes);
        effectiveGasLimit = estimated.toInt();
      }

      final tx = web3.Transaction(to: toAddress, value: valueAmount, data: dataBytes, maxGas: effectiveGasLimit, gasPrice: gasPriceAmount, nonce: effectiveNonce);
      final signedBytes = await client.signTransaction(credentials, tx, chainId: chainId);
      client.dispose();

      final signedHex = '0x${hex.HEX.encode(signedBytes)}';
      debugPrint('Transaction signed (eth_signTransaction). From: $from, To: $to, ChainId: $chainId');
      return signedHex;
    } catch (e) {
      debugPrint('Failed to sign transaction: $e');
      throw Exception('eth_signTransaction failed: $e');
    }
  }

  /// 处理撤销权限请求
  Future<dynamic> _handleRevokePermissions(Web3Request request) async {
    try {
      debugPrint('Handling wallet_revokePermissions request from ${request.origin}');
      
      // 解析权限参数
      if (request.params.isEmpty) {
        throw Exception('Missing permissions parameter');
      }

      final permissionsParam = request.params.first;
      if (permissionsParam is! Map<String, dynamic>) {
        throw Exception('Invalid permissions parameter format');
      }

      // 调用连接服务撤销权限
      await _connectionService.revokePermissions(request.origin, permissionsParam);

      debugPrint('Permissions revoked successfully for ${request.origin}');
      return null; // wallet_revokePermissions 通常返回 null
    } catch (e) {
      debugPrint('Failed to revoke permissions: $e');
      throw Exception('wallet_revokePermissions failed: $e');
    }
  }

  /// 清理资源
  void dispose() {
    _pendingCallbacks.clear();
    _webViewController = null;
    _currentOrigin = null;
    debugPrint('Web3ProviderService disposed');
  }
}
