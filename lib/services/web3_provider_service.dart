import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/web3_request.dart';
import '../models/dapp_connection.dart';
import '../providers/wallet_provider.dart';
import 'dapp_connection_service.dart';

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
    // Note: These parameters will be used in future transaction implementation
    // final to = txParams['to'] as String?;
    // final value = txParams['value'] as String?;
    // final data = txParams['data'] as String?;
    // final gas = txParams['gas'] as String?;
    // final gasPrice = txParams['gasPrice'] as String?;

    if (from == null) {
      throw Exception('From address is required');
    }

    // 检查地址权限
    final connection = _connectionService.getConnection(_currentOrigin!);
    if (connection == null || !connection.connectedAddresses.contains(from)) {
      throw Exception('Address not authorized');
    }

    // 检查发送交易权限
    if (!connection.hasPermission(DAppPermission.sendTransactions)) {
      throw Exception('Send transaction permission not granted');
    }

    // 这里应该显示交易确认对话框
    // 暂时返回模拟的交易哈希
    final txHash = _generateTransactionHash();

    debugPrint('Transaction sent: $txHash');
    return txHash;
  }

  /// 处理个人签名
  Future<String> _handlePersonalSign(Web3Request request) async {
    if (request.params.length < 2) {
      throw Exception('Personal sign requires message and address');
    }

    final message = request.params[0] as String;
    final address = request.params[1] as String;

    // 检查地址权限
    final connection = _connectionService.getConnection(_currentOrigin!);
    if (connection == null ||
        !connection.connectedAddresses.contains(address)) {
      throw Exception('Address not authorized');
    }

    // 检查签名权限
    if (!connection.hasPermission(DAppPermission.signMessages)) {
      throw Exception('Sign message permission not granted');
    }

    // 这里应该显示签名确认对话框
    // 暂时返回模拟的签名
    final signature = _generateSignature();

    debugPrint('Message signed: $message');
    return signature;
  }

  /// 处理类型化数据签名
  Future<String> _handleSignTypedData(Web3Request request) async {
    if (request.params.length < 2) {
      throw Exception('Sign typed data requires address and data');
    }

    final address = request.params[0] as String;
    // Note: typedData will be used in future implementation
    // final typedData = request.params[1];

    // 检查地址权限
    final connection = _connectionService.getConnection(_currentOrigin!);
    if (connection == null ||
        !connection.connectedAddresses.contains(address)) {
      throw Exception('Address not authorized');
    }

    // 检查签名权限
    if (!connection.hasPermission(DAppPermission.signMessages)) {
      throw Exception('Sign message permission not granted');
    }

    // 这里应该显示类型化数据签名确认对话框
    // 暂时返回模拟的签名
    final signature = _generateSignature();

    debugPrint('Typed data signed');
    return signature;
  }

  /// 处理切换链
  Future<void> _handleSwitchChain(Web3Request request) async {
    if (request.params.isEmpty) {
      throw Exception('Chain ID required');
    }

    final chainIdParam = request.params.first as Map<String, dynamic>;
    final chainIdHex = chainIdParam['chainId'] as String?;

    if (chainIdHex == null) {
      throw Exception('Chain ID is required');
    }

    final chainId = int.parse(chainIdHex.substring(2), radix: 16);

    // 查找对应的网络
    final networks = _walletProvider.supportedNetworks;
    final targetNetwork = networks.firstWhere(
      (network) => network.chainId == chainId,
      orElse: () => throw Exception('Unsupported chain ID: $chainId'),
    );

    // 切换网络
    _walletProvider.setCurrentNetwork(targetNetwork);

    // 重新注入Provider以更新链ID
    await injectProvider();

    debugPrint('Switched to network: ${targetNetwork.name}');
  }

  /// 处理添加链
  Future<void> _handleAddChain(Web3Request request) async {
    // 这里应该显示添加网络确认对话框
    // 暂时抛出未实现异常
    throw Exception('Add chain not implemented');
  }

  /// 处理监视资产
  Future<bool> _handleWatchAsset(Web3Request request) async {
    // 这里应该显示添加代币确认对话框
    // 暂时返回true
    debugPrint('Watch asset requested');
    return true;
  }

  /// 构建EVM Web3 Provider JavaScript代码
  static String buildEvmProviderJS({
    required String chainIdHex,
    String? selectedAddress,
    bool debug = false,
  }) {
    return '''
      (function() {
        ${debug ? 'console.log("[FlutterWeb3] Starting EVM provider injection...");' : ''}
        
        if (window.ethereum) {
          ${debug ? 'console.log("[FlutterWeb3] EVM provider already exists");' : ''}
          return;
        }
        
        // 全局回调映射
        window.flutterWeb3Callbacks = window.flutterWeb3Callbacks || {};
        
        // 处理Flutter响应的函数
        window.handleFlutterWeb3Response = function(response) {
          try {
            ${debug ? 'console.log("[FlutterWeb3] Received response:", response);' : ''}
            const data = typeof response === 'string' ? JSON.parse(response) : response;
            const id = data.id;
            
            if (window.flutterWeb3Callbacks[id]) {
              const callback = window.flutterWeb3Callbacks[id];
              delete window.flutterWeb3Callbacks[id];
              
              if (data.error) {
                const error = new Error(data.error);
                error.code = data.code || -32603;
                callback.reject(error);
              } else {
                callback.resolve(data.result);
              }
            }
          } catch (error) {
            ${debug ? 'console.error("[FlutterWeb3] Error handling response:", error);' : ''}
          }
        };
        
        const provider = {
          isMetaMask: true,
          isFlutterWallet: true,
          isConnected: () => true,
          chainId: '$chainIdHex',
          networkVersion: '${int.parse(chainIdHex.substring(2), radix: 16)}',
          selectedAddress: '${selectedAddress ?? ''}',
          _metamask: {
            isUnlocked: () => Promise.resolve(true),
          },
          
          request: async function(request) {
            ${debug ? 'console.log("[FlutterWeb3] Request:", request);' : ''}
            
            if (!request || !request.method) {
              throw new Error('Invalid request');
            }
            
            const id = Date.now() + '_' + Math.random().toString(36).substr(2, 9);
            
            return new Promise((resolve, reject) => {
              // 存储回调
              window.flutterWeb3Callbacks[id] = { resolve, reject };
              
              // 发送消息到Flutter
              const message = {
                id: id,
                method: request.method,
                params: request.params || []
              };
              
              ${debug ? 'console.log("[FlutterWeb3] Sending message to Flutter:", message);' : ''}
              
              if (window.FlutterWeb3 && window.FlutterWeb3.postMessage) {
                window.FlutterWeb3.postMessage(JSON.stringify(message));
              } else {
                ${debug ? 'console.error("[FlutterWeb3] FlutterWeb3 channel not available");' : ''}
                delete window.flutterWeb3Callbacks[id];
                reject(new Error('FlutterWeb3 channel not available'));
                return;
              }
              
              // 设置超时
              setTimeout(() => {
                if (window.flutterWeb3Callbacks[id]) {
                  delete window.flutterWeb3Callbacks[id];
                  reject(new Error('Request timeout'));
                }
              }, 30000);
            });
          },
          
          on: function(event, handler) {
            ${debug ? 'console.log("[FlutterWeb3] Event listener added:", event);' : ''}
          },
          
          removeListener: function(event, handler) {
            ${debug ? 'console.log("[FlutterWeb3] Event listener removed:", event);' : ''}
          },
          
          // 兼容性方法
          enable: function() {
            ${debug ? 'console.log("[FlutterWeb3] Enable called");' : ''}
            return this.request({ method: 'eth_requestAccounts' });
          },
          
          send: function(method, params) {
            ${debug ? 'console.log("[FlutterWeb3] Send called:", method, params);' : ''}
            if (typeof method === 'string') {
              return this.request({ method: method, params: params });
            } else {
              return this.request(method);
            }
          },
          
          sendAsync: function(payload, callback) {
            ${debug ? 'console.log("[FlutterWeb3] SendAsync called:", payload);' : ''}
            this.request(payload).then(result => {
              callback(null, { result: result });
            }).catch(error => {
              callback(error, null);
            });
          }
        };
        
        window.ethereum = provider;
        window.web3 = { currentProvider: provider };
        
        ${debug ? 'console.log("[FlutterWeb3] EVM provider injected successfully");' : ''}
        ${debug ? 'console.log("[FlutterWeb3] Selected address:", "${selectedAddress ?? ''}");' : ''}
        ${debug ? 'console.log("[FlutterWeb3] Chain ID:", "$chainIdHex");' : ''}
        
        // 触发各种Provider就绪事件
        window.dispatchEvent(new Event('ethereum#initialized'));
        window.dispatchEvent(new CustomEvent('eip6963:announceProvider', {
          detail: {
            info: {
              uuid: 'flutter-wallet-uuid',
              name: 'Flutter Wallet',
              icon: 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzIiIGhlaWdodD0iMzIiIHZpZXdCb3g9IjAgMCAzMiAzMiIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHJlY3Qgd2lkdGg9IjMyIiBoZWlnaHQ9IjMyIiByeD0iOCIgZmlsbD0iIzYzNjZGMSIvPgo8L3N2Zz4K',
              rdns: 'com.flutter.wallet'
            },
            provider: provider
          }
        }));
        
        // 模拟连接事件
        setTimeout(() => {
          window.dispatchEvent(new CustomEvent('connect', {
            detail: { chainId: '$chainIdHex' }
          }));
        }, 100);
        
      })();
    ''';
  }

  /// 构建Solana Provider JavaScript代码
  static String buildSolanaProviderJS({
    String? publicKey,
    String network = 'mainnet-beta',
    bool debug = false,
  }) {
    return '''
      (function() {
        ${debug ? 'console.log("[FlutterWeb3] Starting Solana provider injection...");' : ''}
        
        if (window.solana || window.phantom) {
          ${debug ? 'console.log("[FlutterWeb3] Solana provider already exists");' : ''}
          return;
        }
        
        const solanaProvider = {
          isPhantom: true,
          isSolana: true,
          isFlutterWallet: true,
          publicKey: ${publicKey != null ? "'$publicKey'" : 'null'},
          isConnected: ${publicKey != null ? 'true' : 'false'},
          
          connect: async function() {
            ${debug ? 'console.log("[FlutterWeb3] Solana connect called");' : ''}
            
            const id = Date.now() + '_' + Math.random().toString(36).substr(2, 9);
            
            return new Promise((resolve, reject) => {
              window.flutterWeb3Callbacks = window.flutterWeb3Callbacks || {};
              window.flutterWeb3Callbacks[id] = { resolve, reject };
              
              const message = {
                id: id,
                method: 'solana_connect',
                params: []
              };
              
              if (window.FlutterWeb3 && window.FlutterWeb3.postMessage) {
                window.FlutterWeb3.postMessage(JSON.stringify(message));
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
          
          disconnect: async function() {
            ${debug ? 'console.log("[FlutterWeb3] Solana disconnect called");' : ''}
            this.publicKey = null;
            this.isConnected = false;
          },
          
          signTransaction: async function(transaction) {
            ${debug ? 'console.log("[FlutterWeb3] Solana signTransaction called");' : ''}
            
            const id = Date.now() + '_' + Math.random().toString(36).substr(2, 9);
            
            return new Promise((resolve, reject) => {
              window.flutterWeb3Callbacks = window.flutterWeb3Callbacks || {};
              window.flutterWeb3Callbacks[id] = { resolve, reject };
              
              const message = {
                id: id,
                method: 'solana_signTransaction',
                params: [transaction]
              };
              
              if (window.FlutterWeb3 && window.FlutterWeb3.postMessage) {
                window.FlutterWeb3.postMessage(JSON.stringify(message));
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
          
          signMessage: async function(message) {
            ${debug ? 'console.log("[FlutterWeb3] Solana signMessage called");' : ''}
            
            const id = Date.now() + '_' + Math.random().toString(36).substr(2, 9);
            
            return new Promise((resolve, reject) => {
              window.flutterWeb3Callbacks = window.flutterWeb3Callbacks || {};
              window.flutterWeb3Callbacks[id] = { resolve, reject };
              
              const requestMessage = {
                id: id,
                method: 'solana_signMessage',
                params: [message]
              };
              
              if (window.FlutterWeb3 && window.FlutterWeb3.postMessage) {
                window.FlutterWeb3.postMessage(JSON.stringify(requestMessage));
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
          }
        };
        
        window.solana = solanaProvider;
        window.phantom = { solana: solanaProvider };
        
        ${debug ? 'console.log("[FlutterWeb3] Solana provider injected successfully");' : ''}
        
        // 触发Solana Provider就绪事件
        window.dispatchEvent(new Event('solana#initialized'));
        
      })();
    ''';
  }

  /// 构建Web3 Provider JavaScript代码
  String _buildWeb3ProviderJS(String chainIdHex, String selectedAddress) {
    return '''
      (function() {
        console.log('[FlutterWeb3] Starting provider injection...');
        
        if (window.ethereum) {
          console.log('[FlutterWeb3] Provider already exists');
          return;
        }
        
        // 全局回调映射
        window.flutterWeb3Callbacks = window.flutterWeb3Callbacks || {};
        
        // 处理Flutter响应的函数
        window.handleFlutterWeb3Response = function(response) {
          try {
            console.log('[FlutterWeb3] Received response:', response);
            const data = typeof response === 'string' ? JSON.parse(response) : response;
            const id = data.id;
            
            if (window.flutterWeb3Callbacks[id]) {
              const callback = window.flutterWeb3Callbacks[id];
              delete window.flutterWeb3Callbacks[id];
              
              if (data.error) {
                const error = new Error(data.error);
                error.code = data.code || -32603;
                callback.reject(error);
              } else {
                callback.resolve(data.result);
              }
            }
          } catch (error) {
            console.error('[FlutterWeb3] Error handling response:', error);
          }
        };
        
        const provider = {
          isMetaMask: true,
          isFlutterWallet: true,
          isConnected: () => true,
          chainId: '$chainIdHex',
          networkVersion: '${int.parse(chainIdHex.substring(2), radix: 16)}',
          selectedAddress: '$selectedAddress',
          _metamask: {
            isUnlocked: () => Promise.resolve(true),
          },
          
          request: async function(request) {
            console.log('[FlutterWeb3] Request:', request);
            
            if (!request || !request.method) {
              throw new Error('Invalid request');
            }
            
            const id = Date.now() + '_' + Math.random().toString(36).substr(2, 9);
            
            return new Promise((resolve, reject) => {
              // 存储回调
              window.flutterWeb3Callbacks[id] = { resolve, reject };
              
              // 发送消息到Flutter
              const message = {
                id: id,
                method: request.method,
                params: request.params || []
              };
              
              console.log('[FlutterWeb3] Sending message to Flutter:', message);
              
              if (window.FlutterWeb3 && window.FlutterWeb3.postMessage) {
                window.FlutterWeb3.postMessage(JSON.stringify(message));
              } else {
                console.error('[FlutterWeb3] FlutterWeb3 channel not available');
                delete window.flutterWeb3Callbacks[id];
                reject(new Error('FlutterWeb3 channel not available'));
                return;
              }
              
              // 设置超时
              setTimeout(() => {
                if (window.flutterWeb3Callbacks[id]) {
                  delete window.flutterWeb3Callbacks[id];
                  reject(new Error('Request timeout'));
                }
              }, 30000);
            });
          },
          
          on: function(event, handler) {
            console.log('[FlutterWeb3] Event listener added:', event);
          },
          
          removeListener: function(event, handler) {
            console.log('[FlutterWeb3] Event listener removed:', event);
          },
          
          // 兼容性方法
          enable: function() {
            console.log('[FlutterWeb3] Enable called');
            return this.request({ method: 'eth_requestAccounts' });
          },
          
          send: function(method, params) {
            console.log('[FlutterWeb3] Send called:', method, params);
            if (typeof method === 'string') {
              return this.request({ method: method, params: params });
            } else {
              return this.request(method);
            }
          },
          
          sendAsync: function(payload, callback) {
            console.log('[FlutterWeb3] SendAsync called:', payload);
            this.request(payload).then(result => {
              callback(null, { result: result });
            }).catch(error => {
              callback(error, null);
            });
          }
        };
        
        window.ethereum = provider;
        window.web3 = { currentProvider: provider };
        
        console.log('[FlutterWeb3] Provider injected successfully');
        console.log('[FlutterWeb3] Selected address:', '$selectedAddress');
        console.log('[FlutterWeb3] Chain ID:', '$chainIdHex');
        
        // 触发各种Provider就绪事件
        window.dispatchEvent(new Event('ethereum#initialized'));
        window.dispatchEvent(new CustomEvent('eip6963:announceProvider', {
          detail: {
            info: {
              uuid: 'flutter-wallet-uuid',
              name: 'Flutter Wallet',
              icon: 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzIiIGhlaWdodD0iMzIiIHZpZXdCb3g9IjAgMCAzMiAzMiIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHJlY3Qgd2lkdGg9IjMyIiBoZWlnaHQ9IjMyIiByeD0iOCIgZmlsbD0iIzYzNjZGMSIvPgo8L3N2Zz4K',
              rdns: 'com.flutter.wallet'
            },
            provider: provider
          }
        }));
        
        // 模拟连接事件
        setTimeout(() => {
          window.dispatchEvent(new CustomEvent('connect', {
            detail: { chainId: '$chainIdHex' }
          }));
        }, 100);
        
      })();
    ''';
  }

  /// 生成请求ID
  String _generateRequestId() {
    final random = Random();
    return 'req_${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(999999)}';
  }

  /// 生成模拟交易哈希
  String _generateTransactionHash() {
    final random = Random();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return '0x${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
  }

  /// 生成模拟签名
  String _generateSignature() {
    final random = Random();
    final bytes = List<int>.generate(65, (i) => random.nextInt(256));
    return '0x${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
  }

  /// 清理资源
  void dispose() {
    _pendingCallbacks.clear();
    _webViewController = null;
    _currentOrigin = null;
  }
}
