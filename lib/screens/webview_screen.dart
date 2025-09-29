import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../providers/wallet_provider.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const WebViewScreen({
    super.key,
    required this.url,
    this.title = 'DApp',
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _currentTitle = '';
  bool _isWalletConnected = false;
  String? _connectedAddress;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterWallet',
        onMessageReceived: (JavaScriptMessage message) {
          _handleWalletMessage(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // 更新加载进度
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            // 获取页面标题
            _controller.getTitle().then((title) {
              if (title != null && title.isNotEmpty) {
                setState(() {
                  _currentTitle = title;
                });
              }
            });
            // 在页面加载完成后注入Web3 Provider
            _injectWeb3Provider();
            // 触发钱包ready事件
            _triggerWalletReadyEvent();
          },
          onWebResourceError: (WebResourceError error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('加载失败: ${error.description}'),
                backgroundColor: Colors.red,
              ),
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }


  
  String _getWeb3ProviderScript() {
    return '''
      try {
        console.log('Starting Web3 provider injection...');
        
        // Global state variables
        window._requestId = 0;
        window._pendingRequests = new Map();
        
        // Utility function to create event emitter
        window.createEventEmitter = function() {
          const listeners = new Map();
          return {
            on: function(event, callback) {
              if (!listeners.has(event)) {
                listeners.set(event, []);
              }
              listeners.get(event).push(callback);
            },
            emit: function(event, data) {
              if (listeners.has(event)) {
                listeners.get(event).forEach(callback => {
                  try {
                    callback(data);
                  } catch (e) {
                    console.error('Event callback error:', e);
                  }
                });
              }
            }
          };
        };
        
        // Create Ethereum provider
        const ethereumEvents = window.createEventEmitter();
        window.ethereum = {
          isMetaMask: true,
          chainId: '0x1',
          selectedAddress: null,
          
          request: function(args) {
            return new Promise((resolve, reject) => {
              const id = (++window._requestId).toString();
              window._pendingRequests.set(id, { resolve, reject });
              
              const message = {
                id: id,
                method: args.method,
                params: args.params || [],
                chain: 'eth'
              };
              
              try {
                window.webkit.messageHandlers.walletHandler.postMessage(JSON.stringify(message));
              } catch (e) {
                console.error('Failed to send message:', e);
                reject(new Error('Failed to communicate with wallet'));
              }
            });
          },
          
          on: ethereumEvents.on,
          emit: ethereumEvents.emit
        };
        
        console.log('Ethereum provider created successfully');
        
        // Create Solana provider
        const solanaEvents = window.createEventEmitter();
        window.solana = {
          isPhantom: true,
          publicKey: null,
          
          connect: function() {
            return new Promise((resolve, reject) => {
              const id = (++window._requestId).toString();
              window._pendingRequests.set(id, { resolve, reject });
              
              const message = {
                id: id,
                method: 'connect',
                params: [],
                chain: 'sol'
              };
              
              try {
                window.webkit.messageHandlers.walletHandler.postMessage(JSON.stringify(message));
              } catch (e) {
                console.error('Failed to send Solana message:', e);
                reject(new Error('Failed to communicate with wallet'));
              }
            });
          },
          
          signTransaction: function(transaction) {
            return new Promise((resolve, reject) => {
              const id = (++window._requestId).toString();
              window._pendingRequests.set(id, { resolve, reject });
              
              const message = {
                id: id,
                method: 'signTransaction',
                params: [transaction],
                chain: 'sol'
              };
              
              try {
                window.webkit.messageHandlers.walletHandler.postMessage(JSON.stringify(message));
              } catch (e) {
                console.error('Failed to send Solana sign message:', e);
                reject(new Error('Failed to communicate with wallet'));
              }
            });
          },
          
          on: solanaEvents.on,
          emit: solanaEvents.emit
        };
        
        console.log('Solana provider created successfully');
        
        // Create Keplr (Cosmos) provider
        window.keplr = {
          enable: function(chainId) {
            return new Promise((resolve, reject) => {
              const id = (++window._requestId).toString();
              window._pendingRequests.set(id, { resolve, reject });
              
              const message = {
                id: id,
                method: 'enable',
                params: [chainId],
                chain: 'cosmos'
              };
              
              try {
                window.webkit.messageHandlers.walletHandler.postMessage(JSON.stringify(message));
              } catch (e) {
                console.error('Failed to send Keplr message:', e);
                reject(new Error('Failed to communicate with wallet'));
              }
            });
          },
          
          getKey: function(chainId) {
            return new Promise((resolve, reject) => {
              const id = (++window._requestId).toString();
              window._pendingRequests.set(id, { resolve, reject });
              
              const message = {
                id: id,
                method: 'getKey',
                params: [chainId],
                chain: 'cosmos'
              };
              
              try {
                window.webkit.messageHandlers.walletHandler.postMessage(JSON.stringify(message));
              } catch (e) {
                console.error('Failed to send Keplr getKey message:', e);
                reject(new Error('Failed to communicate with wallet'));
              }
            });
          }
        };
        
        console.log('Keplr provider created successfully');
        console.log('All Web3 providers initialized successfully');
        
      } catch (error) {
        console.error('Web3 provider injection failed:', error);
      }
    ''';
  }
  
  // Ethereum Provider脚本


  // 注入Web3 Provider到网页中
  void _injectWeb3Provider() async {
    try {
      debugPrint('开始注入Web3 Provider...');
      await _controller.runJavaScript(_getWeb3ProviderScript());
      debugPrint('Web3 Provider注入成功');
    } catch (e) {
      debugPrint('Web3 Provider注入失败: $e');
      // 尝试延迟注入
      Future.delayed(Duration(milliseconds: 500), () async {
        try {
          debugPrint('尝试延迟注入Web3 Provider...');
          await _controller.runJavaScript(_getWeb3ProviderScript());
          debugPrint('延迟注入成功');
        } catch (e2) {
          debugPrint('延迟注入也失败: $e2');
        }
      });
    }
  }

  // 处理来自网页的钱包消息
  void _handleWalletMessage(String message) async {
    try {
      debugPrint('收到钱包消息: $message');
      final data = jsonDecode(message);
      final method = data['method'] as String;
      final params = data['params'] as List<dynamic>? ?? [];
      final id = data['id'] as String;
      final chain = data['chain'] as String? ?? 'eth';
      
      debugPrint('处理方法: $method, 参数: $params, ID: $id, 链: $chain');
      
      // 根据链类型分发请求
      switch (chain) {
        case 'eth':
          await _handleEthereumRequest(id, method, params);
          break;
        case 'solana':
          await _handleSolanaRequest(id, method, params);
          break;
        case 'cosmos':
          await _handleCosmosRequest(id, method, params);
          break;
        default:
          // 兼容旧版本，默认处理以太坊请求
          await _handleEthereumRequest(id, method, params);
      }
    } catch (e) {
       debugPrint('处理钱包消息错误: $e');
     }
   }
   
   // 处理以太坊请求
   Future<void> _handleEthereumRequest(String id, String method, List<dynamic> params) async {
     switch (method) {
       case 'eth_requestAccounts':
       case 'requestAccounts':
         await _handleConnectWallet(id);
         break;
       case 'eth_accounts':
         await _handleGetAccounts(id);
         break;
       case 'eth_chainId':
         await _handleGetChainId(id);
         break;
       case 'eth_sendTransaction':
         await _handleSendTransaction(id, params);
         break;
       case 'wallet_switchEthereumChain':
         await _handleSwitchChain(id, params);
         break;
       case 'personal_sign':
         await _handlePersonalSign(id, params);
         break;
       default:
         _sendResponse(id, null, 'Ethereum method not supported: $method');
     }
   }
   
   // 处理Solana请求
   Future<void> _handleSolanaRequest(String id, String method, List<dynamic> params) async {
     switch (method) {
       case 'connect':
         await _handleSolanaConnect(id, params);
         break;
       case 'disconnect':
         await _handleSolanaDisconnect(id);
         break;
       case 'signTransaction':
         await _handleSolanaSignTransaction(id, params);
         break;
       case 'signAllTransactions':
         await _handleSolanaSignAllTransactions(id, params);
         break;
       case 'signMessage':
         await _handleSolanaSignMessage(id, params);
         break;
       default:
         _sendResponse(id, null, 'Solana method not supported: $method');
     }
   }
   
   // 处理Cosmos请求
   Future<void> _handleCosmosRequest(String id, String method, List<dynamic> params) async {
     switch (method) {
       case 'enable':
         await _handleCosmosEnable(id, params);
         break;
       case 'getKey':
         await _handleCosmosGetKey(id, params);
         break;
       case 'signAmino':
         await _handleCosmosSignAmino(id, params);
         break;
       case 'signDirect':
         await _handleCosmosSignDirect(id, params);
         break;
       case 'sendTx':
         await _handleCosmosSendTx(id, params);
         break;
       case 'suggestChain':
         await _handleCosmosSuggestChain(id, params);
         break;
       case 'getAccounts':
         await _handleCosmosGetAccounts(id, params);
         break;
       default:
         _sendResponse(id, null, 'Cosmos method not supported: $method');
     }
   }

  // 处理连接钱包请求
  Future<void> _handleConnectWallet(String id) async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    
    // 如果没有钱包，自动创建一个测试钱包
    if (walletProvider.currentWallet == null) {
      try {
        print('没有钱包，正在创建测试钱包...');
        final wallet = await walletProvider.createWallet(
          name: '测试钱包',
          password: '12345678',
          wordCount: 12,
        );
        print('测试钱包创建成功: ${wallet.name}');
      } catch (e) {
        print('创建测试钱包失败: $e');
        _sendResponse(id, null, '创建钱包失败: $e');
        return;
      }
    }
    
    // 显示连接确认对话框
    final shouldConnect = await _showConnectDialog();
    
    if (shouldConnect) {
      final address = walletProvider.selectedAddress;
      if (address != null) {
        setState(() {
          _isWalletConnected = true;
          _connectedAddress = address;
        });
        
        // 更新网页中的地址
        _updateWebAddress(address);
        _sendResponse(id, [address]);
      } else {
        _sendResponse(id, null, '无法获取钱包地址');
      }
    } else {
      _sendResponse(id, null, '用户拒绝连接');
    }
  }

  // 处理获取账户请求
  Future<void> _handleGetAccounts(String id) async {
    if (_isWalletConnected && _connectedAddress != null) {
      _sendResponse(id, [_connectedAddress]);
    } else {
      _sendResponse(id, []);
    }
  }

  // 处理获取链ID请求
  Future<void> _handleGetChainId(String id) async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final network = walletProvider.currentNetwork;
    
    String chainId = '0x1'; // 默认以太坊主网
    if (network != null) {
      switch (network.id) {
        case 'ethereum':
          chainId = '0x1';
          break;
        case 'polygon':
          chainId = '0x89';
          break;
        case 'bsc':
          chainId = '0x38';
          break;
      }
    }
    
    _sendResponse(id, chainId);
  }

  // 处理发送交易请求
  Future<void> _handleSendTransaction(String id, List<dynamic> params) async {
    if (!_isWalletConnected) {
      _sendResponse(id, null, '钱包未连接');
      return;
    }
    
    if (params.isEmpty) {
      _sendResponse(id, null, '交易参数为空');
      return;
    }
    
    final txParams = params[0] as Map<String, dynamic>;
    final shouldSign = await _showTransactionDialog(txParams);
    
    if (shouldSign) {
      try {
        final walletProvider = Provider.of<WalletProvider>(context, listen: false);
        // 这里需要实现实际的交易发送逻辑
        // 暂时返回模拟的交易哈希
        final txHash = '0x' + DateTime.now().millisecondsSinceEpoch.toRadixString(16);
        _sendResponse(id, txHash);
      } catch (e) {
        _sendResponse(id, null, '交易发送失败: $e');
      }
    } else {
      _sendResponse(id, null, '用户拒绝交易');
    }
  }

  // 处理切换网络请求
  Future<void> _handleSwitchChain(String id, List<dynamic> params) async {
    if (params.isEmpty) {
      _sendResponse(id, null, '网络参数为空');
      return;
    }
    
    final chainParams = params[0] as Map<String, dynamic>;
    final chainId = chainParams['chainId'] as String;
    
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    
    // 根据链ID切换网络
    String? networkId;
    switch (chainId) {
      case '0x1':
        networkId = 'ethereum';
        break;
      case '0x89':
        networkId = 'polygon';
        break;
      case '0x38':
        networkId = 'bsc';
        break;
    }
    
    if (networkId != null) {
      final network = walletProvider.supportedNetworks
          .where((n) => n.id == networkId)
          .firstOrNull;
      
      if (network != null) {
        walletProvider.setCurrentNetwork(network);
        _sendResponse(id, null);
      } else {
        _sendResponse(id, null, '不支持的网络');
      }
    } else {
      _sendResponse(id, null, '无效的链ID');
    }
  }

  // 处理个人签名请求
  Future<void> _handlePersonalSign(String id, List<dynamic> params) async {
    if (!_isWalletConnected) {
      _sendResponse(id, null, '钱包未连接');
      return;
    }
    
    if (params.length < 2) {
      _sendResponse(id, null, '签名参数不足');
      return;
    }
    
    final message = params[0] as String;
    final shouldSign = await _showSignDialog(message);
    
    if (shouldSign) {
      try {
        // 这里需要实现实际的签名逻辑
        // 暂时返回模拟的签名
        final signature = '0x' + DateTime.now().millisecondsSinceEpoch.toRadixString(16) + '00';
        _sendResponse(id, signature);
      } catch (e) {
        _sendResponse(id, null, '签名失败: $e');
      }
    } else {
      _sendResponse(id, null, '用户拒绝签名');
    }
  }

  // Solana处理函数
  Future<void> _handleSolanaConnect(String id, List<dynamic> params) async {
    try {
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      
      // 检查是否已连接
      if (_isWalletConnected && _connectedAddress != null) {
        _sendResponse(id, {'publicKey': _connectedAddress});
        return;
      }
      
      // 显示连接确认对话框
      final confirmed = await _showConnectDialog();
      
      if (confirmed) {
        final address = walletProvider.selectedAddress;
        if (address != null) {
          setState(() {
            _isWalletConnected = true;
            _connectedAddress = address;
          });
          
          _sendResponse(id, {'publicKey': address});
          
          // 触发连接事件
          _controller.runJavaScript(
            'window._triggerSolanaEvent("connect", {publicKey: "$address"});'
          );
        } else {
          _sendResponse(id, null, '无法获取钱包地址');
        }
      } else {
        _sendResponse(id, null, '用户拒绝连接');
      }
    } catch (e) {
      _sendResponse(id, null, '连接失败: $e');
    }
  }
  
  Future<void> _handleSolanaDisconnect(String id) async {
    try {
      setState(() {
        _isWalletConnected = false;
        _connectedAddress = null;
      });
      
      _sendResponse(id, {});
      
      // 触发断开连接事件
      _controller.runJavaScript(
        'window._triggerSolanaEvent("disconnect", {});'
      );
    } catch (e) {
      _sendResponse(id, null, '断开连接失败: $e');
    }
  }
  
  Future<void> _handleSolanaSignTransaction(String id, List<dynamic> params) async {
    if (params.isEmpty) {
      _sendResponse(id, null, 'Solana交易参数为空');
      return;
    }
    
    try {
      final transaction = params[0];
      final confirmed = await _showTransactionDialog({
        'to': 'Solana Transaction',
        'value': '0.001 SOL'
      });
      
      if (confirmed) {
        // 这里应该调用实际的Solana签名逻辑
        final signedTx = '0x' + DateTime.now().millisecondsSinceEpoch.toRadixString(16);
        _sendResponse(id, {'signature': signedTx});
      } else {
        _sendResponse(id, null, '用户拒绝交易');
      }
    } catch (e) {
      _sendResponse(id, null, 'Solana交易签名失败: $e');
    }
  }
  
  Future<void> _handleSolanaSignAllTransactions(String id, List<dynamic> params) async {
    if (params.isEmpty) {
      _sendResponse(id, null, 'Solana批量交易参数为空');
      return;
    }
    
    try {
      final transactions = params[0] as List;
      final confirmed = await _showTransactionDialog({
        'to': 'Solana批量交易',
        'value': '${transactions.length * 0.001} SOL'
      });
      
      if (confirmed) {
        List<String> signatures = [];
        for (var tx in transactions) {
          final signedTx = '0x' + DateTime.now().millisecondsSinceEpoch.toRadixString(16);
          signatures.add(signedTx);
        }
        _sendResponse(id, signatures);
      } else {
        _sendResponse(id, null, '用户拒绝批量交易');
      }
    } catch (e) {
      _sendResponse(id, null, 'Solana批量交易签名失败: $e');
    }
  }
  
  Future<void> _handleSolanaSignMessage(String id, List<dynamic> params) async {
    if (params.isEmpty) {
      _sendResponse(id, null, 'Solana签名消息参数为空');
      return;
    }
    
    try {
      final message = params[0].toString();
      final confirmed = await _showSignDialog(message);
      
      if (confirmed) {
        final signature = '0x' + DateTime.now().millisecondsSinceEpoch.toRadixString(16);
        _sendResponse(id, {'signature': signature});
      } else {
        _sendResponse(id, null, '用户拒绝签名');
      }
    } catch (e) {
      _sendResponse(id, null, 'Solana消息签名失败: $e');
    }
  }

  // Cosmos处理函数
  Future<void> _handleCosmosEnable(String id, List<dynamic> params) async {
    try {
      final confirmed = await _showConnectDialog();
      if (confirmed) {
        _sendResponse(id, {});
      } else {
        _sendResponse(id, null, '用户拒绝启用Cosmos');
      }
    } catch (e) {
      _sendResponse(id, null, 'Cosmos启用失败: $e');
    }
  }
  
  Future<void> _handleCosmosGetKey(String id, List<dynamic> params) async {
    try {
      if (_isWalletConnected && _connectedAddress != null) {
        _sendResponse(id, {
          'name': 'Test Wallet',
          'algo': 'secp256k1',
          'pubKey': _connectedAddress,
          'address': _connectedAddress,
          'bech32Address': _connectedAddress
        });
      } else {
        _sendResponse(id, null, 'Cosmos钱包未连接');
      }
    } catch (e) {
      _sendResponse(id, null, 'Cosmos获取密钥失败: $e');
    }
  }
  
  Future<void> _handleCosmosSignAmino(String id, List<dynamic> params) async {
    if (params.length < 3) {
      _sendResponse(id, null, 'Cosmos Amino签名参数不足');
      return;
    }
    
    try {
      final confirmed = await _showSignDialog('Cosmos Amino签名请求');
      if (confirmed) {
        final signature = '0x' + DateTime.now().millisecondsSinceEpoch.toRadixString(16);
        _sendResponse(id, {'signature': signature});
      } else {
        _sendResponse(id, null, '用户拒绝Cosmos Amino签名');
      }
    } catch (e) {
      _sendResponse(id, null, 'Cosmos Amino签名失败: $e');
    }
  }
  
  Future<void> _handleCosmosSignDirect(String id, List<dynamic> params) async {
    if (params.length < 3) {
      _sendResponse(id, null, 'Cosmos Direct签名参数不足');
      return;
    }
    
    try {
      final confirmed = await _showSignDialog('Cosmos Direct签名请求');
      if (confirmed) {
        final signature = '0x' + DateTime.now().millisecondsSinceEpoch.toRadixString(16);
        _sendResponse(id, {'signature': signature});
      } else {
        _sendResponse(id, null, '用户拒绝Cosmos Direct签名');
      }
    } catch (e) {
      _sendResponse(id, null, 'Cosmos Direct签名失败: $e');
    }
  }
  
  Future<void> _handleCosmosSendTx(String id, List<dynamic> params) async {
    if (params.length < 3) {
      _sendResponse(id, null, 'Cosmos发送交易参数不足');
      return;
    }
    
    try {
      final confirmed = await _showTransactionDialog({
        'to': 'Cosmos交易',
        'value': '0.001 ATOM'
      });
      
      if (confirmed) {
        final txHash = '0x' + DateTime.now().millisecondsSinceEpoch.toRadixString(16);
        _sendResponse(id, {'transactionHash': txHash});
      } else {
        _sendResponse(id, null, '用户拒绝Cosmos交易');
      }
    } catch (e) {
      _sendResponse(id, null, 'Cosmos交易发送失败: $e');
    }
  }
  
  Future<void> _handleCosmosSuggestChain(String id, List<dynamic> params) async {
    try {
      final confirmed = await _showConnectDialog();
      if (confirmed) {
        _sendResponse(id, {});
      } else {
        _sendResponse(id, null, '用户拒绝添加Cosmos链');
      }
    } catch (e) {
      _sendResponse(id, null, 'Cosmos链添加失败: $e');
    }
  }
  
  Future<void> _handleCosmosGetAccounts(String id, List<dynamic> params) async {
    try {
      if (_isWalletConnected && _connectedAddress != null) {
        _sendResponse(id, [{
          'name': 'Test Wallet',
          'algo': 'secp256k1',
          'pubKey': _connectedAddress,
          'address': _connectedAddress,
          'bech32Address': _connectedAddress
        }]);
      } else {
        _sendResponse(id, []);
      }
    } catch (e) {
      _sendResponse(id, null, 'Cosmos获取账户失败: $e');
    }
  }

  // 发送响应到网页
  void _sendResponse(String id, dynamic result, [String? error]) {
    final response = {
      'id': id,
      'result': result,
      'error': error,
    };
    
    final jsCode = 'window._handleWalletResponse(${jsonEncode(jsonEncode(response))})';
    _controller.runJavaScript(jsCode);
  }

  // 更新网页中的地址
  void _updateWebAddress(String address) {
    final jsCode = '''
      if (window.ethereum) {
        window.ethereum.selectedAddress = '$address';
        if (window._triggerEthereumEvent) {
          window._triggerEthereumEvent('accountsChanged', ['$address']);
        }
        // 兼容旧版本事件
        window.dispatchEvent(new CustomEvent('ethereum_accountsChanged', {
          detail: ['$address']
        }));
      }
    ''';
    _controller.runJavaScript(jsCode);
  }
  
  // 触发钱包ready事件
  void _triggerWalletReadyEvent() {
    try {
      debugPrint('Triggering wallet ready events...');
      
      final script = '''
        try {
          if (window.ethereum && window.ethereum.emit) {
            window.ethereum.emit('connect', { chainId: '0x1' });
            window.ethereum.emit('accountsChanged', ['0x85c88b777318df7f1115f6541d014fdbe6c0bddb']);
            console.log('Ethereum wallet ready events triggered');
          }
          
          if (window.solana && window.solana.emit) {
            window.solana.publicKey = { toString: () => 'An8fjudvSfCzhkU1aZt1vrUH5QWYc73qgF2wUkYiu4hq' };
            window.solana.emit('connect', window.solana.publicKey);
            console.log('Solana wallet ready events triggered');
          }
          
          console.log('All wallet ready events completed');
        } catch (error) {
          console.error('Error triggering wallet events:', error);
        }
      ''';
      
      _controller.runJavaScript(script).catchError((error) {
        debugPrint('Error triggering wallet ready events: $error');
      });
    } catch (e) {
      debugPrint('Failed to trigger wallet ready events: $e');
    }
  }

  // 显示连接确认对话框
  Future<bool> _showConnectDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2B35),
        title: const Text(
          '连接钱包',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '${Uri.parse(widget.url).host} 请求连接您的钱包',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('拒绝', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            child: const Text('连接', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  // 显示交易确认对话框
  Future<bool> _showTransactionDialog(Map<String, dynamic> txParams) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2B35),
        title: const Text(
          '确认交易',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '接收地址: ${txParams['to'] ?? 'N/A'}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              '金额: ${txParams['value'] ?? '0'} ETH',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('拒绝', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            child: const Text('确认', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  // 显示签名确认对话框
  Future<bool> _showSignDialog(String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2B35),
        title: const Text(
          '签名请求',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '请求签名以下消息:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('拒绝', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            child: const Text('签名', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _currentTitle.isNotEmpty ? _currentTitle : widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _controller.reload(),
          ),
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.white),
            tooltip: 'Web3调试',
            onPressed: () {
              _controller.runJavaScript('''
                console.log('Web3 Debug Info:');
                console.log('Ethereum provider:', window.ethereum ? 'Available' : 'Not available');
                console.log('Solana provider:', window.solana ? 'Available' : 'Not available');
                console.log('Keplr provider:', window.keplr ? 'Available' : 'Not available');
                alert('Debug info logged to console. Check browser console for details.');
              ''');
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF2A2B35),
            onSelected: (value) {
              switch (value) {
                case 'copy_url':
                  _controller.currentUrl().then((url) {
                    if (url != null) {
                      // 复制URL到剪贴板
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('链接已复制到剪贴板'),
                          backgroundColor: Color(0xFF6366F1),
                        ),
                      );
                    }
                  });
                  break;
                case 'open_external':
                  // 在外部浏览器打开
                  Navigator.of(context).pop();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'copy_url',
                child: Row(
                  children: [
                    Icon(Icons.copy, color: Colors.white70, size: 20),
                    SizedBox(width: 12),
                    Text('复制链接', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'open_external',
                child: Row(
                  children: [
                    Icon(Icons.open_in_browser, color: Colors.white70, size: 20),
                    SizedBox(width: 12),
                    Text('在浏览器中打开', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: const Color(0xFF1A1B23),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '正在加载...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}