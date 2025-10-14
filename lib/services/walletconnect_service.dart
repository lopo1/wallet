import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../models/wallet_model.dart';
import '../services/wallet_service.dart';
import '../providers/wallet_provider.dart';
import '../widgets/walletconnect_request_dialog.dart';
import '../config/walletconnect_config.dart';
import '../utils/debug_logger.dart';

// 导入SessionNamespace
import 'package:walletconnect_flutter_v2/apis/sign_api/models/session_models.dart';
import 'package:solana/solana.dart' as solana;
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import '../services/mnemonic_service.dart';
import '../constants/derivation_paths.dart';
import 'package:bs58/bs58.dart' as bs58;
import '../constants/password_constants.dart';
import 'package:flutter/services.dart';

class WalletConnectService extends ChangeNotifier {
  static const String _sessionKey = 'walletconnect_sessions';

  Web3Wallet? _web3App;
  final Logger _logger = Logger();
  final WalletService _walletService;
  final WalletProvider _walletProvider;
  BuildContext? _context;

  List<SessionData> _activeSessions = [];
  bool _isInitialized = false;
  String? _configError;

  WalletConnectService(this._walletService, this._walletProvider) {
    _initialize();
  }

  /// 设置上下文，用于显示对话框
  void setContext(BuildContext context) {
    _context = context;
  }

  List<SessionData> get activeSessions => _activeSessions;
  bool get isInitialized => _isInitialized;

  // 初始化WalletConnect
  Future<void> _initialize() async {
    try {
      // 检查配置
      _configError = WalletConnectConfig.getConfigError();
      if (_configError != null) {
        _logger.w('WalletConnect配置错误: $_configError');
        notifyListeners();
        return;
      }

      _web3App = await Web3Wallet.createInstance(
        projectId: WalletConnectConfig.projectId,
        metadata: PairingMetadata(
          name: WalletConnectConfig.appName,
          description: WalletConnectConfig.appDescription,
          url: WalletConnectConfig.appUrl,
          icons: [WalletConnectConfig.appIcon],
        ),
      );

      // 订阅事件
      _web3App!.onSessionProposal.subscribe(_onSessionProposal);
      _web3App!.onSessionRequest.subscribe(_onSessionRequest);
      _web3App!.onSessionDelete.subscribe(_onSessionDelete);
      _web3App!.onSessionExpire.subscribe(_onSessionExpire);

      // 恢复已保存的会话
      await _restoreSessions();

      // 获取当前活跃会话
      _activeSessions = _web3App!.sessions.getAll();

      _isInitialized = true;
      notifyListeners();

      DebugLogger.walletConnect('初始化成功',
          data: {'activeSessions': _activeSessions.length});
      _logger.i(
          'WalletConnect initialized successfully with ${_activeSessions.length} active sessions');
    } catch (e) {
      _logger.e('Failed to initialize WalletConnect: $e');
      throw Exception('Failed to initialize WalletConnect: $e');
    }
  }

  // 初始化WalletConnect
  Future<void> initialize() async {
    if (_isInitialized) return;
    await _initialize();
  }

  // 处理会话提案
  void _onSessionProposal(SessionProposalEvent? event) async {
    if (event == null) return;

    _logger
        .i('Received session proposal: ${event.params.proposer.metadata.name}');

    // 显示用户确认对话框
    if (_context != null) {
      final confirmed = await _showSessionProposalDialog(event);
      if (confirmed) {
        await _approveSession(event);
      } else {
        await _rejectSession(event);
      }
    } else {
      // 如果上下文不可用，自动批准（仅用于测试）
      await _approveSession(event);
    }
  }

  Future<void> _approveSession(SessionProposalEvent event) async {
    try {
      final accounts = await _walletService.getAccounts();
      final chainId = 'eip155:1'; // Ethereum mainnet

      final namespaces = <String, Namespace>{};

      for (final entry in event.params.requiredNamespaces.entries) {
        final key = entry.key;
        final required = entry.value;

        namespaces[key] = Namespace(
          accounts: accounts.map((account) => '$chainId:$account').toList(),
          methods: required.methods,
          events: required.events,
        );
      }

      await _web3App!.approveSession(
        id: event.id,
        namespaces: namespaces,
      );

      await _saveSessions();
      _activeSessions = _web3App!.sessions.getAll();
      notifyListeners();

      debugPrint('Session approved successfully');
    } catch (e) {
      debugPrint('Failed to approve session: $e');
      rethrow;
    }
  }

  Future<void> _rejectSession(SessionProposalEvent event) async {
    try {
      await _web3App!.rejectSession(
        id: event.id,
        reason: Errors.getSdkError(Errors.USER_REJECTED),
      );
      debugPrint('Session rejected');
    } catch (e) {
      debugPrint('Failed to reject session: $e');
      rethrow;
    }
  }

  // 处理会话请求
  void _onSessionRequest(SessionRequestEvent? event) async {
    if (event == null) return;

    _logger.i('Received session request: ${event.params.request.method}');

    try {
      await _handleSessionRequest(event);
    } catch (e) {
      _logger.e('Failed to handle session request: $e');
      await _respondError(event, 'Request failed: $e');
    }
  }

  // 处理具体的会话请求
  Future<void> _handleSessionRequest(SessionRequestEvent event) async {
    final method = event.params.request.method;
    final params = event.params.request.params;

    switch (method) {
      case 'eth_sendTransaction':
      case 'eth_signTransaction':
        await _handleEthereumTransaction(event, params);
        break;
      case 'personal_sign':
      case 'eth_sign':
        await _handleEthereumSign(event, params);
        break;
      case 'eth_signTypedData':
      case 'eth_signTypedData_v4':
        await _handleEthereumTypedDataSign(event, params);
        break;
      case 'solana_signTransaction':
        await _handleSolanaTransaction(event, params);
        break;
      case 'solana_signMessage':
        await _handleSolanaSign(event, params);
        break;
      default:
        await _respondError(event, 'Unsupported method: $method');
    }
  }

  // 处理以太坊交易
  Future<void> _handleEthereumTransaction(
      SessionRequestEvent event, dynamic params) async {
    if (_context == null) {
      await _respondError(event, 'Context not available');
      return;
    }

    try {
      final confirmed = await _showRequestDialog(event);
      if (confirmed) {
        if (params is! List || params.isEmpty) {
          await _respondError(event, 'Invalid transaction parameters');
          return;
        }

        final txParams = params[0] as Map<String, dynamic>;
        final method = event.params.request.method;

        if (method == 'eth_sendTransaction') {
          // 发送交易
          final txHash = await _sendEthereumTransaction(txParams);
          await _respondSuccess(event, txHash);
        } else {
          // 仅签名交易
          final signedTx = await _signEthereumTransaction(txParams);
          await _respondSuccess(event, signedTx);
        }
      } else {
        await _respondError(event, 'User rejected transaction');
      }
    } catch (e) {
      _logger.e('Ethereum transaction failed: $e');
      await _respondError(event, 'Transaction failed: $e');
    }
  }

  // 处理以太坊签名
  Future<void> _handleEthereumSign(
      SessionRequestEvent event, dynamic params) async {
    if (_context == null) {
      await _respondError(event, 'Context not available');
      return;
    }

    try {
      final confirmed = await _showRequestDialog(event);
      if (confirmed) {
        if (params is! List || params.isEmpty) {
          await _respondError(event, 'Invalid sign parameters');
          return;
        }

        final message = params[0].toString();
        final signature = await _signEthereumMessage(message);
        await _respondSuccess(event, signature);
      } else {
        await _respondError(event, 'User rejected signing');
      }
    } catch (e) {
      _logger.e('Ethereum signing failed: $e');
      await _respondError(event, 'Signing failed: $e');
    }
  }

  // 处理以太坊类型化数据签名
  Future<void> _handleEthereumTypedDataSign(
      SessionRequestEvent event, dynamic params) async {
    if (_context == null) {
      await _respondError(event, 'Context not available');
      return;
    }

    try {
      final confirmed = await _showRequestDialog(event);
      if (confirmed) {
        // 暂时返回模拟签名，实际实现需要根据EIP-712标准
        final signature = '0x' +
            DateTime.now()
                .millisecondsSinceEpoch
                .toRadixString(16)
                .padLeft(128, '0');
        await _respondSuccess(event, signature);
      } else {
        await _respondError(event, 'User rejected typed data signing');
      }
    } catch (e) {
      _logger.e('Ethereum typed data signing failed: $e');
      await _respondError(event, 'Typed data signing failed: $e');
    }
  }

  // 处理Solana交易
  Future<void> _handleSolanaTransaction(
      SessionRequestEvent event, dynamic params) async {
    if (_context == null) {
      await _respondError(event, 'Context not available');
      return;
    }

    try {
      final confirmed = await _showRequestDialog(event);
      if (confirmed) {
        // 解析参数
        final List<dynamic> paramList =
            params is List ? params as List<dynamic> : [params];
        final dynamic txParam = paramList.isNotEmpty ? paramList[0] : null;
        if (txParam == null) {
          await _respondError(event, 'Missing transaction to sign');
          return;
        }

        // 检查钱包
        final currentWallet = _walletProvider.currentWallet;
        if (currentWallet == null) {
          await _respondError(event, 'No wallet available');
          return;
        }

        // 地址索引：使用Solana地址列表，默认索引0
        final solAddresses = currentWallet.addresses['solana'] ?? [];
        final addressIndex = solAddresses.isNotEmpty ? 0 : 0;

        // 获取密码与助记词
        final password = await _getPasswordFromUser();
        if (password == null) {
          await _respondError(event, 'User rejected');
          return;
        }
        final mnemonic =
            await _walletProvider.getWalletMnemonic(currentWallet.id, password);
        if (mnemonic == null) {
          await _respondError(event, '无法获取助记词，请检查密码');
          return;
        }

        // 派生 Ed25519 密钥
        final seed = MnemonicService.mnemonicToSeed(mnemonic);
        final path = DerivationPaths.solanaWithIndex(addressIndex);
        final derivedKey = await ED25519_HD_KEY.derivePath(path, seed);
        final keypair = await solana.Ed25519HDKeyPair.fromPrivateKeyBytes(
            privateKey: derivedKey.key);

        // 解析交易字节并签名
        final Uint8List txBytes = _parseBytes(txParam);
        final signature = await keypair.sign(txBytes);
        final Uint8List sigBytes = Uint8List.fromList(signature.bytes);

        final result = {
          'signature': bs58.base58.encode(sigBytes),
          'publicKey': keypair.publicKey.toBase58(),
        };
        await _respondSuccess(event, result);
      } else {
        await _respondError(event, 'User rejected Solana transaction');
      }
    } catch (e) {
      _logger.e('Solana transaction failed: $e');
      await _respondError(event, 'Solana transaction failed: $e');
    }
  }

  // 处理Solana签名
  Future<void> _handleSolanaSign(
      SessionRequestEvent event, dynamic params) async {
    if (_context == null) {
      await _respondError(event, 'Context not available');
      return;
    }

    try {
      final confirmed = await _showRequestDialog(event);
      if (confirmed) {
        // 解析参数
        final List<dynamic> paramList =
            params is List ? params as List<dynamic> : [params];
        final dynamic msgParam = paramList.isNotEmpty ? paramList[0] : null;
        if (msgParam == null) {
          await _respondError(event, 'Missing message to sign');
          return;
        }

        // 检查钱包
        final currentWallet = _walletProvider.currentWallet;
        if (currentWallet == null) {
          await _respondError(event, 'No wallet available');
          return;
        }

        // 地址索引：使用Solana地址列表，默认索引0
        final solAddresses = currentWallet.addresses['solana'] ?? [];
        final addressIndex = solAddresses.isNotEmpty ? 0 : 0;

        // 获取密码与助记词
        final password = await _getPasswordFromUser();
        if (password == null) {
          await _respondError(event, 'User rejected');
          return;
        }
        final mnemonic =
            await _walletProvider.getWalletMnemonic(currentWallet.id, password);
        if (mnemonic == null) {
          await _respondError(event, '无法获取助记词，请检查密码');
          return;
        }

        // 派生 Ed25519 密钥
        final seed = MnemonicService.mnemonicToSeed(mnemonic);
        final path = DerivationPaths.solanaWithIndex(addressIndex);
        final derivedKey = await ED25519_HD_KEY.derivePath(path, seed);
        final keypair = await solana.Ed25519HDKeyPair.fromPrivateKeyBytes(
            privateKey: derivedKey.key);

        // 解析消息字节并签名
        final Uint8List msgBytes = _parseBytes(msgParam);
        final signature = await keypair.sign(msgBytes);
        final Uint8List sigBytes = Uint8List.fromList(signature.bytes);

        final result = {
          'signature': bs58.base58.encode(sigBytes),
          'publicKey': keypair.publicKey.toBase58(),
        };
        await _respondSuccess(event, result);
      } else {
        await _respondError(event, 'User rejected Solana signing');
      }
    } catch (e) {
      _logger.e('Solana signing failed: $e');
      await _respondError(event, 'Solana signing failed: $e');
    }
  }

  // 发送以太坊交易
  Future<String> _sendEthereumTransaction(Map<String, dynamic> txParams) async {
    try {
      // 解析交易参数
      final from = txParams['from'] as String?;
      final to = txParams['to'] as String?;
      final value = txParams['value'] as String?;

      if (from == null || to == null) {
        throw Exception('缺少必要的交易参数');
      }

      // 将十六进制值转换为 double（以太币单位）
      double amount = 0.0;
      if (value != null && value.isNotEmpty) {
        // 移除 '0x' 前缀并转换为 BigInt
        final hexValue = value.startsWith('0x') ? value.substring(2) : value;
        final weiAmount = BigInt.parse(hexValue, radix: 16);
        // 转换为以太币（1 ETH = 10^18 Wei）
        amount = weiAmount / BigInt.from(10).pow(18);
      }

      // 获取当前网络ID
      final networkId = _walletProvider.currentNetwork?.id ?? 'ethereum';

      // 需要密码来发送交易 - 这里应该弹出密码输入对话框
      // 暂时抛出异常，提示需要用户确认
      throw Exception('需要用户确认交易');

      // 实际实现应该是：
      // 1. 显示交易确认对话框
      // 2. 用户输入密码
      // 3. 调用 WalletProvider 的 sendTransaction 方法
      // final txHash = await _walletProvider.sendTransaction(
      //   networkId: networkId,
      //   toAddress: to,
      //   amount: amount,
      //   password: password, // 从用户输入获取
      // );
      // return txHash;
    } catch (e) {
      debugPrint('发送以太坊交易失败: $e');
      rethrow;
    }
  }

  // 签名以太坊交易
  Future<String> _signEthereumTransaction(Map<String, dynamic> txParams) async {
    // 暂时返回模拟签名，实际实现需要调用以太坊钱包服务
    return '0x' +
        DateTime.now()
            .millisecondsSinceEpoch
            .toRadixString(16)
            .padLeft(128, '0');
  }

  // 签名以太坊消息
  Future<String> _signEthereumMessage(String message) async {
    // 暂时返回模拟签名，实际实现需要调用以太坊钱包服务
    return '0x' +
        DateTime.now()
            .millisecondsSinceEpoch
            .toRadixString(16)
            .padLeft(128, '0');
  }

  // 响应成功
  Future<void> _respondSuccess(
      SessionRequestEvent event, dynamic result) async {
    await _web3App!.respondSessionRequest(
      topic: event.topic,
      response: JsonRpcResponse<dynamic>(
        id: event.params.request.id,
        result: result,
      ),
    );
  }

  // 响应错误
  Future<void> _respondError(SessionRequestEvent event, String error) async {
    await _web3App!.respondSessionRequest(
      topic: event.topic,
      response: JsonRpcResponse<dynamic>(
        id: event.params.request.id,
        error: JsonRpcError(
          code: 5000,
          message: error,
        ),
      ),
    );
  }

  // 处理会话删除
  void _onSessionDelete(SessionDelete? event) {
    if (event == null) return;

    _activeSessions.removeWhere((session) => session.topic == event.topic);
    _saveSessions();
    notifyListeners();

    _logger.i('Session deleted: ${event.topic}');
  }

  // 处理会话过期
  void _onSessionExpire(SessionExpire? event) {
    if (event == null) return;

    _activeSessions.removeWhere((session) => session.topic == event.topic);
    _saveSessions();
    notifyListeners();

    _logger.i('Session expired: ${event.topic}');
  }

  // 通过URI连接
  Future<void> connectWithUri(String uri) async {
    if (_web3App == null) {
      throw Exception('WalletConnect not initialized');
    }

    try {
      await _web3App!.pair(uri: Uri.parse(uri));
      // The pairing will trigger onSessionProposal event
      debugPrint('Pairing initiated with URI: $uri');
    } catch (e) {
      debugPrint('Failed to connect with URI: $e');
      rethrow;
    }
  }

  // 断开会话
  Future<void> disconnectSession(String topic) async {
    if (_web3App == null) return;

    try {
      await _web3App!.disconnectSession(
        topic: topic,
        reason: const WalletConnectError(
          code: 6000,
          message: 'User disconnected',
        ),
      );

      _activeSessions.removeWhere((session) => session.topic == topic);
      await _saveSessions();
      notifyListeners();

      _logger.i('Session disconnected: $topic');
    } catch (e) {
      _logger.e('Failed to disconnect session: $e');
    }
  }

  // 断开所有会话
  Future<void> disconnectAllSessions() async {
    final topics = _activeSessions.map((s) => s.topic).toList();
    for (final topic in topics) {
      await disconnectSession(topic);
    }
  }

  // 保存会话到本地存储
  Future<void> _saveSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = _activeSessions
          .map((s) => {
                'topic': s.topic,
                'pairingTopic': s.pairingTopic,
                'relay': {
                  'protocol': s.relay.protocol,
                  'data': s.relay.data,
                },
                'expiry': s.expiry,
                'acknowledged': s.acknowledged,
                'controller': s.controller,
                'namespaces': s.namespaces.map((key, value) => MapEntry(key, {
                      'accounts': value.accounts,
                      'methods': value.methods,
                      'events': value.events,
                    })),
                'requiredNamespaces':
                    s.requiredNamespaces?.map((key, value) => MapEntry(key, {
                          'chains': value.chains,
                          'methods': value.methods,
                          'events': value.events,
                        })),
                'optionalNamespaces':
                    s.optionalNamespaces?.map((key, value) => MapEntry(key, {
                          'chains': value.chains,
                          'methods': value.methods,
                          'events': value.events,
                        })),
                'sessionProperties': s.sessionProperties,
                'self': {
                  'publicKey': s.self.publicKey,
                  'metadata': {
                    'name': s.self.metadata.name,
                    'description': s.self.metadata.description,
                    'url': s.self.metadata.url,
                    'icons': s.self.metadata.icons,
                  },
                },
                'peer': {
                  'publicKey': s.peer.publicKey,
                  'metadata': {
                    'name': s.peer.metadata.name,
                    'description': s.peer.metadata.description,
                    'url': s.peer.metadata.url,
                    'icons': s.peer.metadata.icons,
                  },
                },
              })
          .toList();

      await prefs.setString(_sessionKey, jsonEncode(sessionsJson));
    } catch (e) {
      _logger.e('Failed to save sessions: $e');
    }
  }

  // 从本地存储恢复会话
  Future<void> _restoreSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsString = prefs.getString(_sessionKey);

      if (sessionsString != null) {
        final sessionsJson = jsonDecode(sessionsString) as List;
        // 注意：这里需要根据实际的SessionData构造函数来恢复会话
        // 由于SessionData的构造比较复杂，这里暂时跳过恢复逻辑
        // 在实际使用中，应该使用WalletConnect SDK提供的会话恢复方法
        _logger.i('Found ${sessionsJson.length} saved sessions');
      }
    } catch (e) {
      _logger.e('Failed to restore sessions: $e');
    }
  }

  // 清理资源
  @override
  void dispose() {
    _web3App?.onSessionProposal.unsubscribe(_onSessionProposal);
    _web3App?.onSessionRequest.unsubscribe(_onSessionRequest);
    _web3App?.onSessionDelete.unsubscribe(_onSessionDelete);
    _web3App?.onSessionExpire.unsubscribe(_onSessionExpire);
    super.dispose();
  }

  // 显示会话提案确认对话框（类内定义）
  Future<bool> _showSessionProposalDialog(SessionProposalEvent event) async {
    if (_context == null) return false;
    return await showDialog<bool>(
          context: _context!,
          builder: (context) => AlertDialog(
            title: const Text('连接请求'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          const Icon(Icons.web, color: Colors.white, size: 20),
                    ),
                    title: Text(event.params.proposer.metadata.name),
                    subtitle:
                        Text(event.params.proposer.metadata.description ?? ''),
                  ),
                  const SizedBox(height: 16),
                  const Text('请求权限:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...event.params.requiredNamespaces.entries
                      .map((entry) => Padding(
                            padding: const EdgeInsets.only(left: 16, bottom: 4),
                            child: Text(
                                '• ${entry.key}: ${entry.value.methods.join(", ")}'),
                          ))
                      .toList(),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('拒绝'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('连接'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // 显示请求确认对话框（类内定义）
  Future<bool> _showRequestDialog(SessionRequestEvent event) async {
    if (_context == null) return false;
    return await showDialog<bool>(
          context: _context!,
          builder: (context) => WalletConnectRequestDialog(
            event: event,
            onApprove: () => Navigator.of(context).pop(true),
            onReject: () => Navigator.of(context).pop(false),
          ),
        ) ??
        false;
  }

  // 获取用户密码对话框（类内定义）
  Future<String?> _getPasswordFromUser() async {
    if (_context == null) return null;
    final TextEditingController passwordController = TextEditingController();
    return showDialog<String>(
      context: _context!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('输入钱包密码'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(
                  PasswordConstants.passwordLength),
            ],
            decoration: const InputDecoration(
              hintText: '请输入钱包密码',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final password = passwordController.text.trim();
                final error = PasswordConstants.validatePassword(password);
                if (error == null) {
                  Navigator.of(context).pop(password);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
  }

  // 通用字节解析工具：支持hex/base64/UTF-8/数组/对象（类内定义）
  Uint8List _parseBytes(dynamic data) {
    if (data == null) {
      throw Exception('空数据');
    }
    if (data is String) {
      final s = data.trim();
      if (s.startsWith('0x') || s.startsWith('0X')) {
        final hex = s.substring(2);
        final out = Uint8List(hex.length ~/ 2);
        for (int i = 0; i < hex.length; i += 2) {
          out[i >> 1] = int.parse(hex.substring(i, i + 2), radix: 16);
        }
        return out;
      }
      try {
        return Uint8List.fromList(base64.decode(s));
      } catch (_) {
        return Uint8List.fromList(utf8.encode(s));
      }
    } else if (data is List) {
      return Uint8List.fromList(List<int>.from(data));
    } else if (data is Map) {
      final keys = data.keys
          .where((k) => int.tryParse(k.toString()) != null)
          .map((k) => int.parse(k.toString()))
          .toList()
        ..sort();
      final out = Uint8List(keys.length);
      for (int i = 0; i < keys.length; i++) {
        final v = data[keys[i].toString()] ?? data[keys[i]];
        out[i] = (v is num) ? v.toInt() : int.parse(v.toString());
      }
      return out;
    }
    throw Exception('不支持的数据格式');
  }
}
