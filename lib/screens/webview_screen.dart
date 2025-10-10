import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;
import 'package:web3dart/web3dart.dart' as web3;
import 'package:web3dart/crypto.dart' as web3_crypto;
import 'package:hex/hex.dart';
// import '../services/wallet_provider.dart';
import '../services/walletconnect_service.dart';

// import '../utils/web3_provider.dart';
import '../services/wallet_service.dart';
import '../providers/wallet_provider.dart';
import '../models/network.dart';
import '../utils/debug_logger.dart';

import '../constants/derivation_paths.dart';
import 'package:solana/solana.dart' as solana;
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:bs58/bs58.dart' as bs58;
import '../services/mnemonic_service.dart';

/// WebView屏幕 - 支持Web3 Provider注入
class WebViewScreen extends StatefulWidget {
  final String url;
  final String? title;
  final bool enableWeb3;
  final bool enableDebug;

  const WebViewScreen({
    super.key,
    required this.url,
    this.title,
    this.enableWeb3 = true,
    this.enableDebug = true,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  double _loadingProgress = 0.0;
  String _currentUrl = '';
  String _pageTitle = '';
  bool _web3Injected = false;
  bool _debugMode = false;
  List<String> _debugLogs = [];

  // Web3相关
  bool _web3Enabled = false;
  bool _walletConnected = false;
  String? _connectedAddress;

  // JavaScript通道
  // late final Web3Provider _web3Provider;
  late final WalletProvider _walletProvider;
  WalletConnectService? _walletConnectService;

  @override
  void initState() {
    super.initState();
    _debugMode = widget.enableDebug;
    _initializeWeb3();
    _initializeWebView();
    _setupWalletConnectListener();
  }

  /// 初始化Web3
  void _initializeWeb3() {
    _walletProvider = Provider.of<WalletProvider>(context, listen: false);
    _walletConnectService =
        Provider.of<WalletConnectService?>(context, listen: false);
    // _web3Provider = Web3Provider();
    _web3Enabled = widget.enableWeb3;

    _addDebugLog('Web3初始化完成');
  }

  /// 设置WalletConnect监听器
  void _setupWalletConnectListener() {
    final walletConnectService =
        Provider.of<WalletConnectService>(context, listen: false);

    // 监听WalletConnect会话变化
    walletConnectService?.addListener(_onWalletConnectSessionChanged);

    // 设置WalletConnect上下文
    WidgetsBinding.instance.addPostFrameCallback((_) {
      walletConnectService?.setContext(context);
    });
  }

  /// WalletConnect会话变化处理
  void _onWalletConnectSessionChanged() {
    final walletConnectService =
        Provider.of<WalletConnectService>(context, listen: false);

    if (walletConnectService?.activeSessions.isNotEmpty == true) {
      // 如果有活跃的WalletConnect会话，更新Web3 Provider状态
      _updateWeb3ProviderWithWalletConnect();
    }
  }

  /// 使用WalletConnect数据更新Web3 Provider
  void _updateWeb3ProviderWithWalletConnect() {
    // 这里可以实现WalletConnect数据与Web3 Provider的同步
    // 例如更新账户信息、网络状态等
    if (mounted) {
      _addDebugLog('WalletConnect会话活跃');
    }
  }

  /// 初始化WebView
  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            _addDebugLog('页面开始加载: $url');
            setState(() {
              _isLoading = true;
              _loadingProgress = 0.0;
              _currentUrl = url;
            });
          },
          onPageFinished: (String url) async {
            _addDebugLog('页面加载完成: $url');
            setState(() {
              _isLoading = false;
              _loadingProgress = 1.0;
            });

            // 获取页面标题
            try {
              final title = await _webViewController.getTitle();
              setState(() {
                _pageTitle = title ?? widget.title ?? '';
              });
              _addDebugLog('页面标题: $_pageTitle');
            } catch (e) {
              _addDebugLog('获取页面标题失败: $e');
            }

            // 注入Web3 Provider
            if (_web3Enabled && !_web3Injected) {
              await _injectWeb3Provider();
            }
          },
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress / 100;
            });
          },
          onWebResourceError: (WebResourceError error) {
            _addDebugLog('资源加载错误: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            _addDebugLog('导航请求: ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterWeb3',
        onMessageReceived: (JavaScriptMessage message) {
          _handleJavaScriptMessage(message.message);
        },
      )
      ..addJavaScriptChannel(
        'FlutterDebug',
        onMessageReceived: (JavaScriptMessage message) {
          _addDebugLog('JS调试: ${message.message}');
        },
      )
      ..enableZoom(true)
      ..loadRequest(Uri.parse(widget.url));

    _addDebugLog('WebView初始化完成');
  }

  /// 注入Web3 Provider
  Future<void> _injectWeb3Provider() async {
    try {
      _addDebugLog('开始注入Web3 Provider...');

      // 构建Web3 Provider JavaScript代码（使用服务生成）
      final web3Js = _buildWeb3ProviderJSFromService();

      await _webViewController.runJavaScript(web3Js);
      _web3Injected = true;

      _addDebugLog('Web3 Provider注入成功');

      // 测试注入结果
      await _testWeb3Injection();
    } catch (e) {
      _addDebugLog('Web3 Provider注入失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Web3 Provider注入失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 使用服务生成 Web3 Provider 注入脚本
  String _buildWeb3ProviderJSFromService() {
    final int? chainIdInt = _walletProvider.currentNetwork?.chainId;
    final String chainIdHex =
        chainIdInt != null ? '0x${chainIdInt.toRadixString(16)}' : '0x1';
    final String? currentAddress = _walletProvider.getCurrentNetworkAddress();

    final evmJs = Web3ProviderService.buildEvmProviderJS(
      chainIdHex: chainIdHex,
      selectedAddress: currentAddress,
      debug: widget.enableDebug,
    );

    final isSolana = _walletProvider.currentNetwork?.id == 'solana';
    final solJs = Web3ProviderService.buildSolanaProviderJS(
      publicKey: isSolana ? currentAddress : null,
      network: 'mainnet-beta',
      debug: widget.enableDebug,
    );

    return evmJs + '\n' + solJs;
  }

  /// 构建Web3 Provider JavaScript代码
  String _buildWeb3ProviderJS() {
    return r'''
      // Web3 Provider注入 - 增强版本
      (function() {
        'use strict';
        
        // 防止重复注入
        if (window.ethereum || window.solana || window.phantom || window.flutterWallet) {
          console.log('[FlutterWeb3] Provider already exists, skipping injection');
          return;
        }
        
        console.log('[FlutterWeb3] Starting Web3 Provider injection...');
        
        // 错误处理工具
        function createProviderError(message, code = -32603) {
          const error = new Error(message);
          error.code = code;
          return error;
        }
        
        // Flutter钱包Provider - 兼容MetaMask API
        const flutterWallet = {
          isMetaMask: true,
          isFlutterWallet: true,
          chainId: '0x1',
          networkVersion: '1',
          selectedAddress: null,
          _events: {},
          _initialized: false,
          
          // 初始化Provider
          _initialize: function() {
            if (this._initialized) return;
            this._initialized = true;
            console.log('[FlutterWeb3] FlutterWallet initialized');
            
            // 监听网络变化
            this._setupNetworkListener();
          },
          
          // 设置网络监听器
          _setupNetworkListener: function() {
            // 这里可以添加网络变化监听逻辑
            console.log('[FlutterWeb3] Network listener setup');
          },
          
          // 请求方法 - 符合EIP-1193标准
          request: async function(request) {
            console.log('[FlutterWeb3] Request:', JSON.stringify(request, null, 2));
            
            if (!request || typeof request !== 'object') {
              throw createProviderError('Invalid request object', -32600);
            }
            
            const { method, params = [] } = request;
            
            if (!method || typeof method !== 'string') {
              throw createProviderError('Invalid method', -32600);
            }
            
            try {
              switch (method) {
                case 'eth_requestAccounts':
                case 'eth_accounts':
                  return await this._requestAccounts();
                  
                case 'eth_chainId':
                  return this.chainId;
                  
                case 'net_version':
                  return this.networkVersion;
                  
                case 'eth_sendTransaction':
                  if (!params[0]) throw createProviderError('Missing transaction parameters', -32602);
                  return await this._sendTransaction(params[0]);
                  
                case 'eth_sign':
                  if (!params[1] || !params[0]) throw createProviderError('Missing sign parameters', -32602);
                  return await this._signMessage(params[1], params[0]);
                  
                case 'personal_sign':
                  if (!params[0] || !params[1]) throw createProviderError('Missing personal sign parameters', -32602);
                  return await this._personalSign(params[0], params[1]);
                  
                case 'eth_signTypedData_v4':
                case 'eth_signTypedData':
                  if (!params[1] || !params[0]) throw createProviderError('Missing typed data parameters', -32602);
                  return await this._signTypedData(params[1], params[0]);
                  
                case 'wallet_switchEthereumChain':
                  if (!params[0]) throw createProviderError('Missing chain parameters', -32602);
                  return await this._switchChain(params[0]);
                  
                case 'wallet_addEthereumChain':
                  if (!params[0]) throw createProviderError('Missing chain parameters', -32602);
                  return await this._addChain(params[0]);
                  
                case 'wallet_watchAsset':
                  if (!params[0]) throw createProviderError('Missing asset parameters', -32602);
                  return await this._watchAsset(params[0]);
                  
                default:
                  throw createProviderError('Method not supported: ' + method, -32601);
              }
            } catch (error) {
              console.error('[FlutterWeb3] Request error:', error);
              throw error;
            }
          },
          
          // 事件监听 - 符合EIP-1193标准
          on: function(event, handler) {
            if (!event || typeof event !== 'string') {
              console.error('[FlutterWeb3] Invalid event name:', event);
              return;
            }
            
            if (typeof handler !== 'function') {
              console.error('[FlutterWeb3] Invalid event handler:', handler);
              return;
            }
            
            if (!this._events[event]) {
              this._events[event] = [];
            }
            this._events[event].push(handler);
            console.log('[FlutterWeb3] Event listener added:', event);
          },
          
          // 移除事件监听
          removeListener: function(event, handler) {
            if (!this._events[event]) return;
            
            const index = this._events[event].indexOf(handler);
            if (index > -1) {
              this._events[event].splice(index, 1);
            }
            
            console.log('[FlutterWeb3] Event listener removed:', event);
          },
          
          // 触发事件
          _emit: function(event, ...args) {
            if (!this._events[event]) return;
            
            console.log('[FlutterWeb3] Emitting event:', event, args);
            
            this._events[event].forEach(handler => {
              try {
                setTimeout(() => handler(...args), 0);
              } catch (error) {
                console.error('[FlutterWeb3] Event handler error:', error);
              }
            });
          },
          
          // 请求账户
          _requestAccounts: async function() {
            try {
              console.log('[FlutterWeb3] Requesting accounts...');
              
              const result = await window.FlutterWeb3.postMessage(JSON.stringify({
                type: 'requestAccounts',
                method: 'eth_requestAccounts',
                id: Date.now()
              }));
              
              const response = JSON.parse(result);
              
              if (response.error) {
                throw createProviderError(response.error, response.code || -32603);
              }
              
              const accounts = response.result || [];
              
              if (accounts.length > 0) {
                this.selectedAddress = accounts[0];
                console.log('[FlutterWeb3] Accounts received:', accounts);
                this._emit('accountsChanged', accounts);
              }
              
              return accounts;
            } catch (error) {
              console.error('[FlutterWeb3] Account request failed:', error);
              throw createProviderError('User rejected account access', 4001);
            }
          },
          
          // 发送交易
          _sendTransaction: async function(tx) {
            try {
              console.log('[FlutterWeb3] Sending transaction:', tx);
              
              // 验证交易参数
              if (!tx.to) throw createProviderError('Missing transaction recipient', -32602);
              if (!tx.value && !tx.data) throw createProviderError('Missing transaction value or data', -32602);
              
              const result = await window.FlutterWeb3.postMessage(JSON.stringify({
                type: 'sendTransaction',
                method: 'eth_sendTransaction',
                params: [tx],
                id: Date.now()
              }));
              
              const response = JSON.parse(result);
              
              if (response.error) {
                throw createProviderError(response.error, response.code || -32603);
              }
              
              console.log('[FlutterWeb3] Transaction sent:', response.result);
              return response.result;
              
            } catch (error) {
              console.error('[FlutterWeb3] Transaction failed:', error);
              throw error;
            }
          },
          
          // 签名消息
          _signMessage: async function(message, address) {
            try {
              console.log('[FlutterWeb3] Signing message:', { message, address });
              
              if (!message) throw createProviderError('Missing message to sign', -32602);
              if (!address) throw createProviderError('Missing signer address', -32602);
              
              const result = await window.FlutterWeb3.postMessage(JSON.stringify({
                type: 'signMessage',
                method: 'eth_sign',
                params: [address, message],
                id: Date.now()
              }));
              
              const response = JSON.parse(result);
              
              if (response.error) {
                throw createProviderError(response.error, response.code || -32603);
              }
              
              console.log('[FlutterWeb3] Message signed:', response.result);
              return response.result;
              
            } catch (error) {
              console.error('[FlutterWeb3] Message signing failed:', error);
              throw error;
            }
          },
          
          // 个人消息签名
          _personalSign: async function(message, address) {
            try {
              console.log('[FlutterWeb3] Personal signing:', { message, address });
              
              if (!message) throw createProviderError('Missing message to sign', -32602);
              if (!address) throw createProviderError('Missing signer address', -32602);
              
              const result = await window.FlutterWeb3.postMessage(JSON.stringify({
                type: 'personalSign',
                method: 'personal_sign',
                params: [message, address],
                id: Date.now()
              }));
              
              const response = JSON.parse(result);
              
              if (response.error) {
                throw createProviderError(response.error, response.code || -32603);
              }
              
              console.log('[FlutterWeb3] Personal message signed:', response.result);
              return response.result;
              
            } catch (error) {
              console.error('[FlutterWeb3] Personal message signing failed:', error);
              throw error;
            }
          },
          
          // 签名类型化数据
          _signTypedData: async function(address, typedData) {
            try {
              console.log('[FlutterWeb3] Signing typed data:', { address, typedData });
              
              const result = await window.FlutterWeb3.postMessage(JSON.stringify({
                type: 'signTypedData',
                method: 'eth_signTypedData_v4',
                params: [address, typedData],
                id: Date.now()
              }));
              
              const response = JSON.parse(result);
              
              if (response.error) {
                throw createProviderError(response.error, response.code || -32603);
              }
              
              console.log('[FlutterWeb3] Typed data signed:', response.result);
              return response.result;
              
            } catch (error) {
              console.error('[FlutterWeb3] Typed data signing failed:', error);
              throw error;
            }
          },
          
          // 切换链
          _switchChain: async function(chainParams) {
            try {
              console.log('[FlutterWeb3] Switching chain:', chainParams);
              
              if (!chainParams.chainId) throw createProviderError('Missing chain ID', -32602);
              
              const result = await window.FlutterWeb3.postMessage(JSON.stringify({
                type: 'switchChain',
                method: 'wallet_switchEthereumChain',
                params: [chainParams],
                id: Date.now()
              }));
              
              const response = JSON.parse(result);
              
              if (response.error) {
                throw createProviderError(response.error, response.code || -32603);
              }
              
              // 更新链信息
              this.chainId = chainParams.chainId;
              this.networkVersion = parseInt(chainParams.chainId, 16).toString();
              
              console.log('[FlutterWeb3] Chain switched to:', chainParams.chainId);
              this._emit('chainChanged', chainParams.chainId);
              
              return response.result;
              
            } catch (error) {
              console.error('[FlutterWeb3] Chain switching failed:', error);
              throw error;
            }
          },
          
          // 添加链
          _addChain: async function(chainParams) {
            try {
              console.log('[FlutterWeb3] Adding chain:', chainParams);
              
              const result = await window.FlutterWeb3.postMessage(JSON.stringify({
                type: 'addChain',
                method: 'wallet_addEthereumChain',
                params: [chainParams],
                id: Date.now()
              }));
              
              const response = JSON.parse(result);
              
              if (response.error) {
                throw createProviderError(response.error, response.code || -32603);
              }
              
              console.log('[FlutterWeb3] Chain added:', response.result);
              return response.result;
              
            } catch (error) {
              console.error('[FlutterWeb3] Chain adding failed:', error);
              throw error;
            }
          },
          
          // 观察资产
          _watchAsset: async function(assetParams) {
            try {
              console.log('[FlutterWeb3] Watching asset:', assetParams);
              
              const result = await window.FlutterWeb3.postMessage(JSON.stringify({
                type: 'watchAsset',
                method: 'wallet_watchAsset',
                params: [assetParams],
                id: Date.now()
              }));
              
              const response = JSON.parse(result);
              
              if (response.error) {
                throw createProviderError(response.error, response.code || -32603);
              }
              
              console.log('[FlutterWeb3] Asset watched:', response.result);
              return response.result;
              
            } catch (error) {
              console.error('[FlutterWeb3] Asset watching failed:', error);
              throw error;
            }
          },
          
          // 启用Provider
          enable: async function() {
            console.log('[FlutterWeb3] Enabling provider...');
            return await this.request({ method: 'eth_requestAccounts' });
          },
          
          // 检查是否已连接
          isConnected: function() {
            return this.selectedAddress !== null;
          }
        };
        
        // Solana Provider - 兼容Phantom API
        const solanaProvider = {
          isPhantom: true,
          isSolana: true,
          isFlutterWallet: true,
          publicKey: null,
          _events: {},
          _initialized: false,
          
          // 初始化
          _initialize: function() {
            if (this._initialized) return;
            this._initialized = true;
            console.log('[FlutterWeb3] Solana provider initialized');
          },
          
          // 连接
          connect: async function() {
            try {
              console.log('[FlutterWeb3] Connecting to Solana...');
              
              const result = await window.FlutterWeb3.postMessage(JSON.stringify({
                type: 'solanaConnect',
                method: 'solana_connect',
                id: Date.now()
              }));
              
              const response = JSON.parse(result);
              
              if (response.error) {
                throw createProviderError(response.error, response.code || -32603);
              }
              
              this.publicKey = response.result.publicKey;
              console.log('[FlutterWeb3] Solana connected:', this.publicKey);
              
              return response.result;
              
            } catch (error) {
              console.error('[FlutterWeb3] Solana connection failed:', error);
              throw error;
            }
          },
          
          // 断开连接
          disconnect: async function() {
            try {
              console.log('[FlutterWeb3] Disconnecting Solana...');
              
              const result = await window.FlutterWeb3.postMessage(JSON.stringify({
                type: 'solanaDisconnect',
                method: 'solana_disconnect',
                id: Date.now()
              }));
              
              const response = JSON.parse(result);
              
              this.publicKey = null;
              console.log('[FlutterWeb3] Solana disconnected');
              
              return response.result;
              
            } catch (error) {
              console.error('[FlutterWeb3] Solana disconnection failed:', error);
              throw error;
            }
          },
          
          // 签名交易
          signTransaction: async function(transaction) {
            try {
              console.log('[FlutterWeb3] Signing Solana transaction...');
              
              const result = await window.FlutterWeb3.postMessage(JSON.stringify({
                type: 'solanaSignTransaction',
                method: 'solana_signTransaction',
                params: [transaction],
                id: Date.now()
              }));
              
              const response = JSON.parse(result);
              
              if (response.error) {
                throw createProviderError(response.error, response.code || -32603);
              }
              
              console.log('[FlutterWeb3] Solana transaction signed');
              return response.result;
              
            } catch (error) {
              console.error('[FlutterWeb3] Solana transaction signing failed:', error);
              throw error;
            }
          },
          
          // 签名消息
          signMessage: async function(message) {
            try {
              console.log('[FlutterWeb3] Signing Solana message...');
              
              const result = await window.FlutterWeb3.postMessage(JSON.stringify({
                type: 'solanaSignMessage',
                method: 'solana_signMessage',
                params: [message],
                id: Date.now()
              }));
              
              const response = JSON.parse(result);
              
              if (response.error) {
                throw createProviderError(response.error, response.code || -32603);
              }
              
              console.log('[FlutterWeb3] Solana message signed');
              return response.result;
              
            } catch (error) {
              console.error('[FlutterWeb3] Solana message signing failed:', error);
              throw error;
            }
          }
        };
        
        // 初始化Provider
        flutterWallet._initialize();
        solanaProvider._initialize();
        
        // 注入到全局对象
        Object.defineProperty(window, 'ethereum', {
          value: flutterWallet,
          writable: false,
          configurable: false
        });
        
        Object.defineProperty(window, 'solana', {
          value: solanaProvider,
          writable: false,
          configurable: false
        });
        
        Object.defineProperty(window, 'phantom', {
          value: { solana: solanaProvider },
          writable: false,
          configurable: false
        });
        
        Object.defineProperty(window, 'flutterWallet', {
          value: flutterWallet,
          writable: false,
          configurable: false
        });
        
        // 添加回调处理机制
        window.flutterWalletCallbacks = {};
        
        // 处理来自Flutter的响应
        window.handleFlutterResponse = function(response) {
          try {
            const data = typeof response === 'string' ? JSON.parse(response) : response;
            const id = data.id;
            
            if (window.flutterWalletCallbacks[id]) {
              const callback = window.flutterWalletCallbacks[id];
              delete window.flutterWalletCallbacks[id];
              
              if (data.error) {
                const error = new Error(data.error.message);
                error.code = data.error.code;
                callback.reject(error);
              } else {
                callback.resolve(data);
              }
            }
          } catch (error) {
            console.error('[FlutterWeb3] Error handling Flutter response:', error);
          }
        };
        
        console.log('[FlutterWeb3] Web3 Providers injected successfully!');
        console.log('[FlutterWeb3] Available providers:', {
          ethereum: !!window.ethereum,
          solana: !!window.solana,
          phantom: !!window.phantom,
          flutterWallet: !!window.flutterWallet
        });
        
        // 触发Provider就绪事件
        window.dispatchEvent(new Event('ethereum#initialized'));
        window.dispatchEvent(new Event('solana#initialized'));
        
      })();
    ''';
  }

  Future<String?> _getPasswordFromUser() async {
    final TextEditingController passwordController = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('输入钱包密码'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
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
                final password = passwordController.text;
                if (password.isNotEmpty) {
                  Navigator.of(context).pop(password);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('密码不能为空'),
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

  /// 测试Web3注入
  Future<void> _testWeb3Injection() async {
    try {
      final result = await _webViewController.runJavaScriptReturningResult(r'''
        (function() {
          const result = {
            hasEthereum: !!window.ethereum,
            hasSolana: !!window.solana,
            hasFlutterWallet: !!window.flutterWallet,
            hasFlutterWalletCallbacks: !!window.flutterWalletCallbacks,
            ethereumInfo: window.ethereum ? {
              isMetaMask: window.ethereum.isMetaMask,
              isFlutterWallet: window.ethereum.isFlutterWallet
            } : null,
            solanaInfo: window.solana ? {
              isPhantom: window.solana.isPhantom,
              isSolana: window.solana.isSolana
            } : null,
            callbackCount: window.flutterWalletCallbacks ? Object.keys(window.flutterWalletCallbacks).length : 0
          };
          return JSON.stringify(result);
        })();
      ''');

      final testResult =
          json.decode(result.toString().replaceAll(RegExp(r'^"|"$'), ''));
      _addDebugLog('Web3注入测试结果: $testResult');

      if (testResult['hasEthereum'] || testResult['hasSolana']) {
        _addDebugLog('Web3 Provider注入成功');
      } else {
        _addDebugLog('Web3 Provider注入失败');
      }

      // 测试回调机制
      await _webViewController.runJavaScript(r'''
        (function() {
          console.log('[FlutterWeb3] Testing callback mechanism...');
          console.log('[FlutterWeb3] flutterWalletCallbacks:', window.flutterWalletCallbacks);
          console.log('[FlutterWeb3] handleFlutterResponse:', typeof window.handleFlutterResponse);
        })();
      ''');
    } catch (e) {
      _addDebugLog('Web3注入测试失败: $e');
    }
  }

  /// 处理JavaScript消息 - 增强版本
  void _handleJavaScriptMessage(String message) async {
    try {
      final data = jsonDecode(message);
      final type = data['type'] as String;
      final id = data['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString();

      debugPrint('WebView JavaScript message: $type (ID: $id)');

      try {
        switch (type) {
          case 'requestAccounts':
            await _handleRequestAccounts(id);
            break;

          case 'sendTransaction':
            await _handleSendTransaction(
                ((data['params'] as List?)?.elementAt(0) ?? <String, dynamic>{})
                    as Map<String, dynamic>,
                id);
            break;

          case 'signMessage':
            await _handleSignMessage((data['params'] as List<dynamic>), id);
            break;

          case 'personalSign':
            await _handlePersonalSign((data['params'] as List<dynamic>), id);
            break;

          case 'switchChain':
            await _handleSwitchChain(
                data['params'] as Map<String, dynamic>, id);
            break;

          case 'addChain':
            await _handleAddChain(data['params'] as Map<String, dynamic>, id);
            break;

          case 'watchAsset':
            await _handleWatchAsset(data['params'] as Map<String, dynamic>, id);
            break;

          case 'signTypedData':
            await _handleSignTypedData((data['params'] as List<dynamic>), id);
            break;

          case 'solanaConnect':
            await _handleSolanaConnect(id);
            break;

          case 'solanaDisconnect':
            await _handleSolanaDisconnect(id);
            break;

          case 'solanaSignTransaction':
            await _handleSolanaSignTransaction(
                (data['params'] as List<dynamic>), id);
            break;

          case 'solanaSignMessage':
            await _handleSolanaSignMessage(
                (data['params'] as List<dynamic>), id);
            break;

          case 'web3Ready':
            debugPrint('Web3 Provider is ready');
            _sendJavaScriptResponse(id, {'success': true, 'result': 'ready'});
            break;

          default:
            debugPrint('Unknown JavaScript message type: $type');
            _sendJavaScriptError(id, 'Unknown message type: $type', -32601);
        }
      } catch (error) {
        debugPrint('Error processing $type message: $error');
        _sendJavaScriptError(id, error.toString(), -32603);
      }
    } catch (e) {
      debugPrint('Error handling JavaScript message: $e');
      _sendJavaScriptError(DateTime.now().millisecondsSinceEpoch.toString(),
          'Invalid message format', -32700);
    }
  }

  /// 发送JavaScript响应
  void _sendJavaScriptResponse(String id, Map<String, dynamic> response) {
    final payload = jsonEncode(response);
    final jsCode = "(function(){"
            "if (window.flutterWalletCallbacks && window.flutterWalletCallbacks['$id']) {"
            "window.flutterWalletCallbacks['$id'](" +
        payload +
        ");"
            "delete window.flutterWalletCallbacks['$id'];"
            "}"
            "})();";
    _webViewController?.runJavaScript(jsCode);
  }

  /// 处理ETH账户
  Future<void> _handleEthAccounts(String id) async {
    await _handleRequestAccounts(id);
  }

  /// 处理ETH链ID
  Future<void> _handleEthChainId(String id) async {
    try {
      final chainId = _walletProvider.currentNetwork?.chainId ?? '0x1';
      _sendJavaScriptResponse(id, {'result': chainId});
    } catch (e) {
      _sendJavaScriptError(id, e.toString(), -32603);
    }
  }

  /// 处理账户请求
  Future<void> _handleRequestAccounts(String id) async {
    try {
      final currentWallet = _walletProvider.currentWallet;
      if (currentWallet == null) {
        _showWeb3Dialog(
          title: '连接钱包',
          message: '请先创建或导入钱包',
          onConfirm: () {
            Navigator.pop(context);
            _sendJavaScriptError(id, 'No wallet available', -32603);
          },
          onCancel: () {
            Navigator.pop(context);
            _sendJavaScriptError(id, 'User cancelled', 4001);
          },
        );
        return;
      }

      // 显示网络选择对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return DAppConnectionDialog(
            dAppName: _pageTitle,
            dAppUrl: _currentUrl,
            onConfirm: (Network selectedNetwork, String selectedAddress) async {
              Navigator.pop(context);
              // 切换到选择的网络
              _walletProvider.setCurrentNetwork(selectedNetwork);
              setState(() {
                _walletConnected = true;
                _connectedAddress = selectedAddress;
              });
              _sendJavaScriptResponse(id, {
                'result': [selectedAddress]
              });
            },
            onCancel: () {
              Navigator.pop(context);
              _sendJavaScriptError(id, 'User rejected', 4001);
            },
          );
        },
      );
    } catch (e) {
      _sendJavaScriptError(id, e.toString(), -32603);
    }
  }

  /// 处理发送交易
  Future<void> _handleSendTransaction(
      Map<String, dynamic> tx, String id) async {
    try {
      if (!_walletConnected) {
        _sendJavaScriptError(id, 'Wallet not connected', -32603);
        return;
      }

      final from = tx['from'] as String?;
      final to = tx['to'] as String?;
      final value = tx['value'] as String?;
      final data = tx['data'] as String?;

      _showWeb3Dialog(
        title: '确认交易',
        message: '发送交易详情：',
        dappName: _pageTitle,
        dappUrl: _currentUrl,
        walletAddress: _connectedAddress,
        transaction: tx,
        onConfirm: () async {
          Navigator.pop(context);
          try {
            final txHash = await _walletProvider.sendTransaction(
              toAddress: tx['to'] as String,
              amount: double.tryParse(tx['value']?.toString() ?? '0') ?? 0.0,
              networkId: _walletProvider.currentNetwork?.id ?? 'ethereum',
              password: 'default_password', // TODO: 获取用户密码
            );
            _sendJavaScriptResponse(id, {'result': txHash});
          } catch (e) {
            _sendJavaScriptError(id, e.toString(), -32603);
          }
        },
        onCancel: () {
          Navigator.pop(context);
          _sendJavaScriptError(id, 'User rejected', 4001);
        },
      );
    } catch (e) {
      _sendJavaScriptError(id, e.toString(), -32603);
    }
  }

  /// 处理消息签名
  Future<void> _handleSignMessage(List<dynamic> params, String id) async {
    try {
      if (!_walletConnected) {
        _sendJavaScriptError(id, 'Wallet not connected', -32603);
        return;
      }

      final message = params[1] as String;
      final address = params[0] as String;

      _showWeb3Dialog(
        title: '签名消息',
        message: '是否签名以下消息？',
        dappName: _pageTitle,
        dappUrl: _currentUrl,
        walletAddress: address,
        messageText: message,
        onConfirm: () async {
          Navigator.pop(context);
          try {
            // TODO: 实现消息签名
            throw Exception('Message signing not implemented');
            // _sendJavaScriptResponse(id, {'result': signature});
          } catch (e) {
            _sendJavaScriptError(id, e.toString(), -32603);
          }
        },
        onCancel: () {
          Navigator.pop(context);
          _sendJavaScriptError(id, 'User rejected', 4001);
        },
      );
    } catch (e) {
      _sendJavaScriptError(id, e.toString(), -32603);
    }
  }

  /// 处理个人消息签名
  Future<void> _handlePersonalSign(List<dynamic> params, String id) async {
    try {
      if (!_walletConnected) {
        _sendJavaScriptError(id, 'Wallet not connected', -32603);
        return;
      }

      final message = params[0] as String;
      final address = params[1] as String;

      _showWeb3Dialog(
        title: '个人消息签名',
        message: '是否签名以下个人消息？',
        dappName: _pageTitle,
        dappUrl: _currentUrl,
        walletAddress: address,
        messageText: message,
        onConfirm: () async {
          Navigator.pop(context);
          try {
            // 获取当前钱包与网络
            final currentWallet = _walletProvider.currentWallet;
            final currentNetwork = _walletProvider.currentNetwork;
            if (currentWallet == null || currentNetwork == null) {
              throw Exception('当前钱包或网络不可用');
            }

            // 计算地址索引，确保与所选地址对应
            final addressList =
                currentWallet.addresses[currentNetwork.id] ?? [];
            final addrIndex = addressList.indexOf(address);
            final addressIndex = addrIndex >= 0 ? addrIndex : 0;

            // 让用户输入解锁密码
            final password = await _getPasswordFromUser();
            if (password == null) {
              _sendJavaScriptError(id, 'User rejected', 4001);
              return;
            }

            // 通过助记词派生对应索引的私钥
            final mnemonic = await _walletProvider.getWalletMnemonic(
                currentWallet.id, password);
            if (mnemonic == null) {
              throw Exception('无法获取助记词，请检查密码');
            }

            // 使用 BIP32 从助记词与索引派生以太坊私钥
            final seed = bip39.mnemonicToSeed(mnemonic);
            final root = bip32.BIP32.fromSeed(seed);
            final derivationPath =
                DerivationPaths.ethereumWithIndex(addressIndex);
            final child = root.derivePath(derivationPath);
            final privateKeyBytes = child.privateKey;
            if (privateKeyBytes == null) {
              throw Exception('无法派生私钥');
            }
            final privateKeyHex = HEX.encode(privateKeyBytes);
            final credentials = web3.EthPrivateKey.fromHex(privateKeyHex);

            // 将消息转成字节并进行个人消息签名（EIP-191 前缀）
            Uint8List payload;
            if (message.startsWith('0x') || message.startsWith('0X')) {
              // 兼容部分 DApp 传入十六进制字符串
              var s = message.substring(2);
              final bytes = Uint8List(s.length ~/ 2);
              for (int i = 0; i < s.length; i += 2) {
                bytes[i ~/ 2] = int.parse(s.substring(i, i + 2), radix: 16);
              }
              payload = bytes;
            } else {
              payload = Uint8List.fromList(utf8.encode(message));
            }
            final signatureBytes =
                await credentials.signPersonalMessageToUint8List(payload);

            // 转为 0x 格式的签名字符串
            final signatureHex = '0x' +
                signatureBytes
                    .map((b) => b.toRadixString(16).padLeft(2, '0'))
                    .join('');
            _sendJavaScriptResponse(id, {'result': signatureHex});
          } catch (e) {
            _sendJavaScriptError(id, e.toString(), -32603);
          }
        },
        onCancel: () {
          Navigator.pop(context);
          _sendJavaScriptError(id, 'User rejected', 4001);
        },
      );
    } catch (e) {
      _sendJavaScriptError(id, e.toString(), -32603);
    }
  }

  /// 处理链切换
  Future<void> _handleSwitchChain(
      Map<String, dynamic> params, String id) async {
    try {
      final chainId = params['chainId'] as String;

      _showWeb3Dialog(
        title: '切换网络',
        message: '是否切换到链ID: $chainId？',
        dappName: _pageTitle,
        dappUrl: _currentUrl,
        walletAddress: _connectedAddress,
        onConfirm: () async {
          Navigator.pop(context);
          try {
            final network = _walletProvider.supportedNetworks.firstWhere(
              (n) => n.chainId == chainId,
              orElse: () => _walletProvider.currentNetwork!,
            );
            _walletProvider.setCurrentNetwork(network);
            _sendJavaScriptResponse(id, {'result': null});
          } catch (e) {
            _sendJavaScriptError(id, e.toString(), -32603);
          }
        },
        onCancel: () {
          Navigator.pop(context);
          _sendJavaScriptError(id, 'User rejected', 4001);
        },
      );
    } catch (e) {
      _sendJavaScriptError(id, e.toString(), -32603);
    }
  }

  /// 处理Solana连接
  Future<void> _handleSolanaConnect(String id) async {
    try {
      final currentWallet = _walletProvider.currentWallet;
      if (currentWallet == null) {
        _sendJavaScriptError(id, 'No wallet available', -32603);
        return;
      }

      // 显示网络选择对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return DAppConnectionDialog(
            dAppName: _pageTitle,
            dAppUrl: _currentUrl,
            onConfirm: (Network selectedNetwork, String selectedAddress) async {
              Navigator.pop(context);
              // 切换到选择的网络
              _walletProvider.setCurrentNetwork(selectedNetwork);
              setState(() {
                _walletConnected = true;
                _connectedAddress = selectedAddress;
              });
              _sendJavaScriptResponse(id, {
                'result': {'publicKey': selectedAddress}
              });
            },
            onCancel: () {
              Navigator.pop(context);
              _sendJavaScriptError(id, 'User rejected', 4001);
            },
          );
        },
      );
    } catch (e) {
      _sendJavaScriptError(id, e.toString(), -32603);
    }
  }

  /// 显示Web3对话框
  void _showWeb3Dialog({
    required String title,
    required String message,
    String? dappName,
    String? dappUrl,
    String? walletAddress,
    Map<String, dynamic>? transaction,
    String? messageText,
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
  }) {
    showDialog<bool>(
      context: context,
      builder: (context) => Web3ProviderDialog(
        title: title,
        message: message,
        address: walletAddress ?? '',
        dAppName: dappName ?? '',
        dAppUrl: dappUrl ?? '',
        additionalInfo: _getAdditionalInfo(transaction, messageText),
      ),
    ).then((result) {
      if (result == true) {
        onConfirm();
      } else {
        onCancel();
      }
    });
  }

  /// 获取额外信息
  Map<String, dynamic>? _getAdditionalInfo(
      Map<String, dynamic>? transaction, String? messageText) {
    if (transaction != null) return transaction;
    if (messageText != null) return {'message': messageText};
    return null;
  }

  /// 发送JavaScript错误
  void _sendJavaScriptError(String id, String message, int code) {
    try {
      final errorResponse = {
        'id': id,
        'error': {
          'code': code,
          'message': message,
        },
      };

      _sendJavaScriptResponse(id, errorResponse);
      _addDebugLog('Sent JavaScript error: $errorResponse');
    } catch (e) {
      _addDebugLog('Error sending JavaScript error: $e');
    }
  }

  /// 处理添加链
  Future<void> _handleAddChain(Map<String, dynamic> params, String id) async {
    try {
      final chainId = params['chainId'] as String;
      final chainName = params['chainName'] as String;

      _showWeb3Dialog(
        title: '添加网络',
        message: '是否添加网络: $chainName (链ID: $chainId)？',
        dappName: _pageTitle,
        dappUrl: _currentUrl,
        walletAddress: _connectedAddress,
        onConfirm: () async {
          Navigator.pop(context);
          // TODO: 实现添加自定义网络功能
          _sendJavaScriptError(id, 'Add chain not implemented', -32603);
        },
        onCancel: () {
          Navigator.pop(context);
          _sendJavaScriptError(id, 'User rejected', 4001);
        },
      );
    } catch (e) {
      _sendJavaScriptError(id, e.toString(), -32603);
    }
  }

  /// 处理观察资产
  Future<void> _handleWatchAsset(Map<String, dynamic> params, String id) async {
    try {
      final type = params['type'] as String;
      final options = params['options'] as Map<String, dynamic>;
      final address = options['address'] as String;
      final symbol = options['symbol'] as String;
      final decimals = options['decimals'] as int;

      _showWeb3Dialog(
        title: '添加代币',
        message: '是否添加代币: $symbol ($address)？',
        dappName: _pageTitle,
        dappUrl: _currentUrl,
        walletAddress: _connectedAddress,
        onConfirm: () async {
          Navigator.pop(context);
          // TODO: 实现添加代币功能
          _sendJavaScriptError(id, 'Watch asset not implemented', -32603);
        },
        onCancel: () {
          Navigator.pop(context);
          _sendJavaScriptError(id, 'User rejected', 4001);
        },
      );
    } catch (e) {
      _sendJavaScriptError(id, e.toString(), -32603);
    }
  }

  /// 处理签名类型数据
  Future<void> _handleSignTypedData(List<dynamic> params, String id) async {
    try {
      if (!_walletConnected) {
        _sendJavaScriptError(id, 'Wallet not connected', -32603);
        return;
      }

      final address = params[0] as String;
      final dynamic typedParam = params[1];
      final String typedDataDisplay =
          typedParam is String ? typedParam : json.encode(typedParam);
      final Map<String, dynamic> typedData = typedParam is String
          ? json.decode(typedParam)
          : Map<String, dynamic>.from(typedParam as Map);

      _showWeb3Dialog(
        title: '签名类型化数据',
        message: '是否签名以下类型化数据？',
        dappName: _pageTitle,
        dappUrl: _currentUrl,
        walletAddress: address,
        messageText: typedDataDisplay,
        onConfirm: () async {
          Navigator.pop(context);
          try {
            final currentWallet = _walletProvider.currentWallet;
            final currentNetwork = _walletProvider.currentNetwork;
            if (currentWallet == null || currentNetwork == null) {
              throw Exception('当前钱包或网络不可用');
            }

            // 地址索引
            final addressList =
                currentWallet.addresses[currentNetwork.id] ?? [];
            final idx = addressList.indexOf(address);
            final addressIndex = idx >= 0 ? idx : 0;

            // 密码
            final password = await _getPasswordFromUser();
            if (password == null) {
              _sendJavaScriptError(id, 'User rejected', 4001);
              return;
            }

            // 助记词 -> 私钥
            final mnemonic = await _walletProvider.getWalletMnemonic(
                currentWallet.id, password);
            if (mnemonic == null) throw Exception('无法获取助记词，请检查密码');
            final seed = bip39.mnemonicToSeed(mnemonic);
            final root = bip32.BIP32.fromSeed(seed);
            final derivationPath =
                DerivationPaths.ethereumWithIndex(addressIndex);
            final child = root.derivePath(derivationPath);
            final pkBytes = child.privateKey;
            if (pkBytes == null) throw Exception('无法派生私钥');
            final pkHex = HEX.encode(pkBytes);
            final credentials = web3.EthPrivateKey.fromHex(pkHex);

            // 计算 EIP-712 哈希
            final digest = Eip712Encoder.hashTypedData(typedData);

            // 使用 secp256k1 对 digest 进行签名
            final ecSig = web3_crypto.sign(digest, Uint8List.fromList(pkBytes));
            // 拼接标准 65 字节：r(32) + s(32) + v(1)
            final rHex = ecSig.r.toRadixString(16).padLeft(64, '0');
            final sHex = ecSig.s.toRadixString(16).padLeft(64, '0');
            final vHex = ecSig.v.toRadixString(16).padLeft(2, '0');
            final sigHex = '0x$rHex$sHex$vHex';

            _sendJavaScriptResponse(id, {'result': sigHex});
          } catch (e) {
            _sendJavaScriptError(id, e.toString(), -32603);
          }
        },
        onCancel: () {
          Navigator.pop(context);
          _sendJavaScriptError(id, 'User rejected', 4001);
        },
      );
    } catch (e) {
      _sendJavaScriptError(id, e.toString(), -32603);
    }
  }

  /// 处理Solana断开连接
  Future<void> _handleSolanaDisconnect(String id) async {
    try {
      setState(() {
        _walletConnected = false;
        _connectedAddress = '';
      });
      _sendJavaScriptResponse(id, {'result': null});
    } catch (e) {
      _sendJavaScriptError(id, e.toString(), -32603);
    }
  }

  /// 处理Solana交易签名
  Future<void> _handleSolanaSignTransaction(
      List<dynamic> params, String id) async {
    try {
      final dynamic txParam = params.isNotEmpty ? params[0] : null;
      if (txParam == null) {
        throw Exception('Missing transaction to sign');
      }

      final String previewText =
          txParam is String ? txParam : '[Binary Transaction]';
      _showWeb3Dialog(
        title: '签名Solana交易',
        message: '是否签名此Solana交易？',
        dappName: _pageTitle,
        dappUrl: _currentUrl,
        walletAddress: _connectedAddress,
        transaction: {'data': previewText},
        onConfirm: () async {
          Navigator.pop(context);
          try {
            final currentWallet = _walletProvider.currentWallet;
            final currentNetwork = _walletProvider.currentNetwork;
            if (currentWallet == null || currentNetwork == null) {
              throw Exception('当前钱包或网络不可用');
            }

            // 解析交易/消息为字节
            Uint8List _parseBytes(dynamic data) {
              if (data == null) throw Exception('空数据');
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
                // base64 尝试
                try {
                  return Uint8List.fromList(base64.decode(s));
                } catch (_) {
                  // 退化为 UTF-8 文本（某些 DApp 可能错误传入）
                  return Uint8List.fromList(utf8.encode(s));
                }
              } else if (data is List) {
                return Uint8List.fromList(List<int>.from(data));
              } else if (data is Map) {
                // 形如 {"0":byte,...}
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

            final txBytes = _parseBytes(txParam);

            // 地址索引解析
            final solAddresses = currentWallet.addresses['solana'] ?? [];
            final addr = _connectedAddress ?? '';
            final idx = solAddresses.indexOf(addr);
            final addressIndex = idx >= 0 ? idx : 0;

            // 获取密码与助记词
            final password = await _getPasswordFromUser();
            if (password == null) {
              _sendJavaScriptError(id, 'User rejected', 4001);
              return;
            }
            final mnemonic = await _walletProvider.getWalletMnemonic(
                currentWallet.id, password);
            if (mnemonic == null) {
              throw Exception('无法获取助记词，请检查密码');
            }

            // 派生 Ed25519 密钥
            final seed = MnemonicService.mnemonicToSeed(mnemonic);
            final path = DerivationPaths.solanaWithIndex(addressIndex);
            final derivedKey = await ED25519_HD_KEY.derivePath(path, seed);
            final keypair = await solana.Ed25519HDKeyPair.fromPrivateKeyBytes(
                privateKey: derivedKey.key);

            // Solana 交易签名通常对 message bytes 进行签名
            // 为通用性，这里直接对传入字节进行 Ed25519 签名
            final signature = await keypair.sign(txBytes);
            final Uint8List sigBytes = Uint8List.fromList(signature.bytes);

            final result = {
              'signature': bs58.base58.encode(sigBytes),
              'publicKey': keypair.publicKey.toBase58(),
            };
            _sendJavaScriptResponse(id, {'result': result});
          } catch (e) {
            _sendJavaScriptError(id, e.toString(), -32603);
          }
        },
        onCancel: () {
          Navigator.pop(context);
          _sendJavaScriptError(id, 'User rejected', 4001);
        },
      );
    } catch (e) {
      _sendJavaScriptError(id, e.toString(), -32603);
    }
  }

  /// 处理Solana消息签名
  Future<void> _handleSolanaSignMessage(List<dynamic> params, String id) async {
    try {
      final dynamic msgParam = params.isNotEmpty ? params[0] : null;
      if (msgParam == null) {
        throw Exception('Missing message to sign');
      }

      // 展示确认对话框
      final String previewText =
          msgParam is String ? msgParam : '[Binary Message]';
      _showWeb3Dialog(
        title: '签名Solana消息',
        message: '是否签名此Solana消息？',
        dappName: _pageTitle,
        dappUrl: _currentUrl,
        walletAddress: _connectedAddress,
        messageText: previewText,
        onConfirm: () async {
          Navigator.pop(context);
          try {
            // 检查钱包与网络
            final currentWallet = _walletProvider.currentWallet;
            final currentNetwork = _walletProvider.currentNetwork;
            if (currentWallet == null || currentNetwork == null) {
              throw Exception('当前钱包或网络不可用');
            }

            // 解析消息为字节
            Uint8List _parseMessage(dynamic data) {
              if (data == null) throw Exception('空消息');
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
                // 尝试按 base64 解码
                try {
                  return Uint8List.fromList(base64.decode(s));
                } catch (_) {
                  // 退化为 UTF-8 文本
                  return Uint8List.fromList(utf8.encode(s));
                }
              } else if (data is List) {
                return Uint8List.fromList(List<int>.from(data));
              } else if (data is Map) {
                // 将形如 {"0":72,"1":101,...} 的对象转为字节序列
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
              throw Exception('不支持的消息格式');
            }

            final messageBytes = _parseMessage(msgParam);

            // 计算地址索引（优先使用 Solana 地址列表）
            final solAddresses = currentWallet.addresses['solana'] ?? [];
            final addr = _connectedAddress ?? '';
            final idx = solAddresses.indexOf(addr);
            final addressIndex = idx >= 0 ? idx : 0;

            // 获取密码与助记词
            final password = await _getPasswordFromUser();
            if (password == null) {
              _sendJavaScriptError(id, 'User rejected', 4001);
              return;
            }
            final mnemonic = await _walletProvider.getWalletMnemonic(
                currentWallet.id, password);
            if (mnemonic == null) {
              throw Exception('无法获取助记词，请检查密码');
            }

            // 派生 Ed25519 私钥
            final seed = MnemonicService.mnemonicToSeed(mnemonic);
            final path = DerivationPaths.solanaWithIndex(addressIndex);
            final derivedKey = await ED25519_HD_KEY.derivePath(path, seed);
            final keypair = await solana.Ed25519HDKeyPair.fromPrivateKeyBytes(
                privateKey: derivedKey.key);

            // 生成签名（Ed25519 原始字节签名）
            final signature = await keypair.sign(messageBytes);
            final Uint8List sigBytes = Uint8List.fromList(signature.bytes);

            // 返回 base58 签名与公钥
            final result = {
              'signature': bs58.base58.encode(sigBytes),
              'publicKey': keypair.publicKey.toBase58(),
            };
            _sendJavaScriptResponse(id, {'result': result});
          } catch (e) {
            _sendJavaScriptError(id, e.toString(), -32603);
          }
        },
        onCancel: () {
          Navigator.pop(context);
          _sendJavaScriptError(id, 'User rejected', 4001);
        },
      );
    } catch (e) {
      _sendJavaScriptError(id, e.toString(), -32603);
    }
  }

  /// 添加调试日志
  void _addDebugLog(String message) {
    DebugLogger.info(message, tag: 'WebViewScreen');
    if (!_debugMode) return;

    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] $message';

    developer.log(logMessage, name: 'WebViewScreen');

    setState(() {
      _debugLogs.add(logMessage);
      if (_debugLogs.length > 100) {
        _debugLogs.removeAt(0);
      }
    });
  }

  /// 重新加载页面
  void _reloadPage() {
    _webViewController.reload();
    _addDebugLog('页面重新加载');
  }

  /// 返回上一页
  void _goBack() async {
    if (await _webViewController.canGoBack()) {
      _webViewController.goBack();
      _addDebugLog('返回上一页');
    }
  }

  /// 前进到下一页
  void _goForward() async {
    if (await _webViewController.canGoForward()) {
      _webViewController.goForward();
      _addDebugLog('前进');
    }
  }

  /// 切换调试模式
  void _toggleDebugMode() {
    setState(() {
      _debugMode = !_debugMode;
    });
    _addDebugLog('调试模式: $_debugMode');
  }

  /// 清除调试日志
  void _clearDebugLogs() {
    setState(() {
      _debugLogs.clear();
    });
    _addDebugLog('调试日志已清除');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1B23),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _pageTitle.isNotEmpty ? _pageTitle : widget.title ?? 'DApp浏览器',
              style: const TextStyle(color: Colors.white, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_currentUrl.isNotEmpty)
              Text(
                _currentUrl,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _debugMode ? Icons.bug_report : Icons.bug_report_outlined,
              color: _debugMode ? Colors.green : Colors.white,
            ),
            onPressed: _toggleDebugMode,
            tooltip: '切换调试模式',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _reloadPage,
            tooltip: '刷新页面',
          ),
        ],
      ),
      body: Column(
        children: [
          // 进度条
          if (_isLoading)
            LinearProgressIndicator(
              value: _loadingProgress,
              backgroundColor: Colors.grey.shade800,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),

          // WebView
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _webViewController),

                // Web3状态指示器
                if (_web3Enabled)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _web3Injected ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _web3Injected ? Icons.check_circle : Icons.info,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _web3Injected ? 'Web3已连接' : 'Web3注入中...',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 钱包连接状态
                if (_walletConnected && _connectedAddress != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_connectedAddress!.substring(0, 6)}...${_connectedAddress!.substring(_connectedAddress!.length - 4)}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 调试面板
          if (_debugMode)
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                border: Border(top: BorderSide(color: Colors.grey.shade700)),
              ),
              child: Column(
                children: [
                  // 调试工具栏
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(color: Colors.grey.shade700)),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          '调试日志',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.clear,
                              size: 16, color: Colors.white),
                          onPressed: _clearDebugLogs,
                          tooltip: '清除日志',
                        ),
                      ],
                    ),
                  ),

                  // 日志列表
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _debugLogs.length,
                      itemBuilder: (context, index) {
                        final log = _debugLogs[_debugLogs.length - 1 - index];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(bottom: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            log,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),

      // 底部导航栏
      bottomNavigationBar: Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1B23),
          border: Border(top: BorderSide(color: Colors.grey.shade800)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: _goBack,
              tooltip: '后退',
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
              onPressed: _goForward,
              tooltip: '前进',
            ),
            IconButton(
              icon: const Icon(Icons.home, color: Colors.white),
              onPressed: () {
                Navigator.pop(context, true);
              },
              tooltip: '主页',
            ),
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: () {
                // 分享功能
                _shareUrl();
              },
              tooltip: '分享',
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {
                _showMoreMenu();
              },
              tooltip: '更多',
            ),
          ],
        ),
      ),
    );
  }

  /// 分享URL
  void _shareUrl() {
    if (_currentUrl.isNotEmpty) {
      // 这里可以实现分享功能
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('分享链接: $_currentUrl'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// 显示更多菜单
  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1B23),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.content_copy, color: Colors.white),
              title: const Text('复制链接', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                if (_currentUrl.isNotEmpty) {
                  // 复制到剪贴板
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('链接已复制')),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(
                _debugMode ? Icons.bug_report : Icons.bug_report_outlined,
                color: Colors.white,
              ),
              title: Text(
                _debugMode ? '关闭调试模式' : '开启调试模式',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _toggleDebugMode();
              },
            ),
            if (_debugMode)
              ListTile(
                leading: const Icon(Icons.clear_all, color: Colors.white),
                title:
                    const Text('清除调试日志', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _clearDebugLogs();
                },
              ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.white),
              title: const Text('关于', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 显示关于对话框
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1B23),
        title: const Text('关于DApp浏览器', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('当前页面: $_pageTitle',
                style: const TextStyle(color: Colors.white)),
            Text('URL: $_currentUrl',
                style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            Text('Web3状态: ${_web3Injected ? "已注入" : "未注入"}',
                style: const TextStyle(color: Colors.white)),
            Text('钱包连接: ${_walletConnected ? "已连接" : "未连接"}',
                style: const TextStyle(color: Colors.white)),
            if (_connectedAddress != null)
              Text(
                  '地址: ${_connectedAddress!.substring(0, 6)}...${_connectedAddress!.substring(_connectedAddress!.length - 4)}',
                  style: const TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
