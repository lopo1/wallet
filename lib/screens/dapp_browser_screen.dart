import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/dapp_connection.dart';
import '../models/network.dart';
import '../providers/wallet_provider.dart';
import '../services/dapp_connection_service.dart';
import '../services/web3_provider_service.dart';
import '../widgets/bottom_nav_bar.dart';

/// DApp浏览器屏幕
///
/// 提供完整的DApp浏览体验，包括：
/// - WebView集成和导航
/// - Web3 Provider注入
/// - DApp连接管理
/// - 用户交互界面
class DAppBrowserScreen extends StatefulWidget {
  final String? initialUrl;
  final String? title;
  final Map<String, dynamic>? dappInfo;

  const DAppBrowserScreen({
    super.key,
    this.initialUrl,
    this.title,
    this.dappInfo,
  });

  @override
  State<DAppBrowserScreen> createState() => _DAppBrowserScreenState();
}

class _DAppBrowserScreenState extends State<DAppBrowserScreen> {
  late WebViewController _webViewController;
  late Web3ProviderService _web3ProviderService;
  late DAppConnectionService _connectionService;
  late WalletProvider _walletProvider;

  bool _isLoading = true;
  double _loadingProgress = 0.0;
  String _pageTitle = '';
  bool _isConnected = false;
  bool _isFavorite = false;
  String? _currentOrigin;
  bool _canGoBack = false;
  bool _canGoForward = false;
  bool _showWebView = false;
  String? _pendingUrl;

  final TextEditingController _urlController = TextEditingController();
  final FocusNode _urlFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeWebView();

    // 设置初始URL
    if (widget.initialUrl != null) {
      _urlController.text = widget.initialUrl!;
      _pendingUrl = widget.initialUrl!;
      // 如果有初始URL，先显示连接对话框
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showConnectionDialogBeforeNavigate(_pendingUrl!);
      });
    } else {
      // 没有初始URL，显示搜索界面
      _showWebView = false;
    }

    // 监听URL输入变化
    _urlController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _urlFocusNode.dispose();
    _web3ProviderService.dispose();
    super.dispose();
  }

  /// 初始化服务
  void _initializeServices() {
    _connectionService =
        Provider.of<DAppConnectionService>(context, listen: false);
    _walletProvider = Provider.of<WalletProvider>(context, listen: false);

    _web3ProviderService = Web3ProviderService(
      walletProvider: _walletProvider,
      connectionService: _connectionService,
    );
  }

  /// 初始化WebView
  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _loadingProgress = 0.0;
              _urlController.text = url;
            });
            _handleUrlChange(url);
          },
          onPageFinished: (String url) async {
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
            } catch (e) {
              debugPrint('获取页面标题失败: $e');
            }

            // 更新导航状态
            await _updateNavigationState();

            // 注入Web3 Provider
            await _injectWeb3Provider();
          },
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress / 100;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView资源错误: ${error.description}');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('页面加载错误: ${error.description}'),
                  backgroundColor: Colors.red,
                  action: SnackBarAction(
                    label: '重试',
                    onPressed: _refreshPage,
                  ),
                ),
              );
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('导航请求: ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterWeb3',
        onMessageReceived: (JavaScriptMessage message) {
          _handleWeb3Message(message.message);
        },
      );

    // 如果有初始URL，立即加载
    if (widget.initialUrl != null) {
      _webViewController.loadRequest(Uri.parse(widget.initialUrl!));
    }
  }

  /// 处理URL变化
  void _handleUrlChange(String url) {
    try {
      final uri = Uri.parse(url);
      final origin = '${uri.scheme}://${uri.host}';

      setState(() {
        _currentOrigin = origin;
        _isConnected = _connectionService.isConnected(origin);
      });

      // 检查收藏状态
      _checkFavoriteStatus();

      // 添加到历史记录
      _connectionService.addToHistory(origin);

      // 更新最后使用时间
      if (_isConnected) {
        _connectionService.updateLastUsed(origin);
      }
    } catch (e) {
      debugPrint('处理URL变化失败: $e');
    }
  }

  /// 注入Web3 Provider
  Future<void> _injectWeb3Provider() async {
    if (_currentOrigin == null) return;

    try {
      _web3ProviderService.setWebViewController(
          _webViewController, _currentOrigin!);

      if (_isConnected) {
        await _web3ProviderService.injectProvider();
        debugPrint('Web3 Provider注入成功');
      }
    } catch (e) {
      debugPrint('Web3 Provider注入失败: $e');
    }
  }

  /// 处理Web3消息
  Future<void> _handleWeb3Message(String message) async {
    try {
      final data = jsonDecode(message);
      debugPrint('收到Web3消息: $data');

      final result = await _web3ProviderService.handleWeb3Request(data);

      // 发送响应
      final requestId = data['id']?.toString();
      if (requestId != null) {
        await _web3ProviderService.sendResponse(requestId, result);
      }
    } catch (e) {
      debugPrint('处理Web3消息失败: $e');

      // 发送错误响应
      final data = jsonDecode(message);
      final requestId = data['id']?.toString();
      if (requestId != null) {
        await _web3ProviderService.sendResponse(
          requestId,
          null,
          e.toString(),
          -32603,
        );
      }
    }
  }

  /// 检查收藏状态
  void _checkFavoriteStatus() {
    if (_currentOrigin != null) {
      setState(() {
        _isFavorite = _connectionService.isFavorite(_currentOrigin!);
      });
    }
  }


  /// 导航到URL
  void _navigateToUrl(String url) {
    if (url.trim().isEmpty) return;

    String finalUrl = url.trim();

    // 检查是否是搜索查询
    if (!_isValidUrl(finalUrl)) {
      // 如果不是有效URL，使用搜索引擎
      finalUrl =
          'https://www.google.com/search?q=${Uri.encodeComponent(finalUrl)}';
    } else if (!finalUrl.startsWith('http://') &&
        !finalUrl.startsWith('https://')) {
      // 如果是有效URL但没有协议，添加https
      finalUrl = 'https://$finalUrl';
    }

    // 保存待访问的URL
    _pendingUrl = finalUrl;

    // 先显示连接对话框
    _showConnectionDialogBeforeNavigate(finalUrl);
  }

  /// 在导航前显示连接对话框
  Future<void> _showConnectionDialogBeforeNavigate(String url) async {
    try {
      final uri = Uri.parse(url);
      final origin = '${uri.scheme}://${uri.host}';

      // 检查是否已经连接
      if (_connectionService.isConnected(origin)) {
        // 已连接，直接导航
        _actuallyNavigateToUrl(url);
        return;
      }

      // 显示连接对话框
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildConnectionDialog(url, origin),
      );

      if (result == true) {
        // 用户确认连接，执行连接并导航
        await _connectAndNavigate(url, origin);
      } else {
        // 用户取消，清除待访问URL
        _pendingUrl = null;
      }
    } catch (e) {
      debugPrint('显示连接对话框失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('无法解析URL: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 连接并导航到URL
  Future<void> _connectAndNavigate(String url, String origin) async {
    try {
      final currentNetwork = _walletProvider.currentNetwork;
      final currentAddress = _walletProvider.getCurrentNetworkAddress();

      if (currentNetwork == null || currentAddress == null) {
        throw Exception('请先选择网络和地址');
      }

      // 创建连接请求
      final request = DAppConnectionRequest(
        origin: origin,
        name: Uri.parse(url).host,
        iconUrl: '$origin/favicon.ico',
        requestedAddresses: [currentAddress],
        networkId: currentNetwork.id,
        requestedPermissions: [
          DAppPermission.readAccounts,
          DAppPermission.sendTransactions,
          DAppPermission.signMessages,
        ],
      );

      // 连接DApp
      final success = await _connectionService.connectDApp(request);

      if (success) {
        setState(() {
          _isConnected = true;
        });

        // 连接成功，导航到URL
        _actuallyNavigateToUrl(url);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已连接到 ${currentNetwork.name}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('连接失败');
      }
    } catch (e) {
      debugPrint('连接失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('连接失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 实际导航到URL
  void _actuallyNavigateToUrl(String url) {
    try {
      setState(() {
        _showWebView = true;
      });
      _webViewController.loadRequest(Uri.parse(url));
    } catch (e) {
      debugPrint('导航失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('无法加载页面: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 检查是否是有效的URL
  bool _isValidUrl(String url) {
    // 简单的URL验证
    final urlPattern = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
      caseSensitive: false,
    );

    return urlPattern.hasMatch(url) || url.contains('.') && !url.contains(' ');
  }

  /// 刷新页面
  void _refreshPage() {
    _webViewController.reload();
  }

  /// 更新导航状态
  Future<void> _updateNavigationState() async {
    try {
      final canGoBack = await _webViewController.canGoBack();
      final canGoForward = await _webViewController.canGoForward();

      setState(() {
        _canGoBack = canGoBack;
        _canGoForward = canGoForward;
      });
    } catch (e) {
      debugPrint('更新导航状态失败: $e');
    }
  }

  /// 后退
  Future<void> _goBack() async {
    if (_canGoBack) {
      await _webViewController.goBack();
      await _updateNavigationState();
    }
  }

  /// 前进
  Future<void> _goForward() async {
    if (_canGoForward) {
      await _webViewController.goForward();
      await _updateNavigationState();
    }
  }

  /// 分享当前页面
  Future<void> _sharePage() async {
    if (_currentOrigin != null && _pageTitle.isNotEmpty) {
      try {
        await Clipboard.setData(ClipboardData(
          text: '$_pageTitle\n$_currentOrigin',
        ));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('链接已复制到剪贴板'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        debugPrint('分享失败: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('分享失败: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// 显示页面信息
  Future<void> _showPageInfo() async {
    if (_currentOrigin == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2D3A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '页面信息',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('标题', _pageTitle),
            const SizedBox(height: 8),
            _buildInfoRow('网址', _currentOrigin!),
            const SizedBox(height: 8),
            _buildInfoRow('连接状态', _isConnected ? '已连接' : '未连接'),
            if (_isConnected) ...[
              const SizedBox(height: 8),
              Consumer<WalletProvider>(
                builder: (context, walletProvider, child) {
                  final network = walletProvider.currentNetwork;
                  final address = walletProvider.getCurrentNetworkAddress();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (network != null) _buildInfoRow('网络', network.name),
                      if (address != null) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow('地址',
                            '${address.substring(0, 6)}...${address.substring(address.length - 4)}'),
                      ],
                    ],
                  );
                },
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            '$label:',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  /// 显示连接对话框
  Future<void> _showConnectionDialog() async {
    if (_currentOrigin == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _buildConnectionDialog(),
    );

    if (result == true) {
      // 用户确认连接
      await _connectDApp();
    }
  }

  /// 连接DApp
  Future<void> _connectDApp() async {
    if (_currentOrigin == null) return;

    try {
      final currentNetwork = _walletProvider.currentNetwork;
      final currentAddress = _walletProvider.getCurrentNetworkAddress();

      if (currentNetwork == null || currentAddress == null) {
        throw Exception('请先选择网络和地址');
      }

      final request = DAppConnectionRequest(
        origin: _currentOrigin!,
        name: _pageTitle.isNotEmpty ? _pageTitle : _currentOrigin!,
        iconUrl: '$_currentOrigin/favicon.ico',
        requestedAddresses: [currentAddress],
        networkId: currentNetwork.id,
        requestedPermissions: [
          DAppPermission.readAccounts,
          DAppPermission.sendTransactions,
          DAppPermission.signMessages,
        ],
      );

      final success = await _connectionService.connectDApp(request);

      if (success) {
        setState(() {
          _isConnected = true;
        });

        // 重新注入Web3 Provider
        await _injectWeb3Provider();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已连接到 ${currentNetwork.name}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('连接失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 断开连接
  Future<void> _disconnectDApp() async {
    if (_currentOrigin == null) return;

    await _connectionService.disconnectDApp(_currentOrigin!);

    setState(() {
      _isConnected = false;
    });

    // 刷新页面
    _refreshPage();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已断开连接'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B23),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // URL输入栏
          _buildUrlBar(),

          // 加载进度条
          if (_isLoading && _showWebView)
            LinearProgressIndicator(
              value: _loadingProgress,
              backgroundColor: Colors.grey[800],
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
            ),

          // 主内容区域
          Expanded(
            child: _showWebView
                ? WebViewWidget(controller: _webViewController)
                : _buildSearchView(),
          ),

          // 底部导航栏
          if (_showWebView) _buildBottomBar(),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 2,
        onItemSelected: (index) {
          switch (index) {
            case 0:
              Navigator.of(context).pushReplacementNamed('/home');
              break;
            case 1:
              Navigator.of(context).pushReplacementNamed('/swap');
              break;
            case 2:
              // 当前页：发现
              break;
            case 3:
              Navigator.of(context).pushReplacementNamed('/settings');
              break;
          }
        },
      ),
    );
  }

  /// 构建搜索视图
  Widget _buildSearchView() {
    final searchQuery = _urlController.text.trim().toLowerCase();
    final hasInput = searchQuery.isNotEmpty;

    // 所有DApp列表
    final allDApps = [
      {
        'name': 'Uniswap',
        'description': '最大的链上市场,MMA交易开创者!',
        'url': 'https://app.uniswap.org',
        'icon': Icons.swap_horiz,
        'color': const Color(0xFFFF007A),
      },
      {
        'name': 'OpenSea',
        'description': 'NFT市场领导者',
        'url': 'https://opensea.io',
        'icon': Icons.image,
        'color': const Color(0xFF2081E2),
      },
      {
        'name': 'Aave',
        'description': '去中心化借贷协议',
        'url': 'https://app.aave.com',
        'icon': Icons.account_balance,
        'color': const Color(0xFFB6509E),
      },
      {
        'name': 'PancakeSwap',
        'description': 'BSC上的DEX',
        'url': 'https://pancakeswap.finance',
        'icon': Icons.cake,
        'color': const Color(0xFF1FC7D4),
      },
    ];

    // 根据搜索查询过滤DApp
    final filteredDApps = hasInput
        ? allDApps.where((dapp) {
            final name = (dapp['name'] as String).toLowerCase();
            final description = (dapp['description'] as String).toLowerCase();
            final url = (dapp['url'] as String).toLowerCase();
            return name.contains(searchQuery) ||
                description.contains(searchQuery) ||
                url.contains(searchQuery);
          }).toList()
        : allDApps;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            '探索DApp',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '输入网址或搜索DApp应用',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // 如果有输入且是有效URL，显示"前往网址"选项
          if (hasInput && _isValidUrl(searchQuery)) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2D3A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.language,
                    color: Color(0xFF6366F1),
                    size: 28,
                  ),
                ),
                title: const Text(
                  '前往网址：',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  searchQuery.startsWith('http')
                      ? searchQuery
                      : 'https://$searchQuery',
                  style: const TextStyle(
                    color: Color(0xFF6366F1),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(
                  Icons.arrow_forward,
                  color: Color(0xFF6366F1),
                  size: 24,
                ),
                onTap: () {
                  final url = searchQuery.startsWith('http')
                      ? searchQuery
                      : 'https://$searchQuery';
                  _navigateToUrl(url);
                },
              ),
            ),
          ],

          // 推荐DApp列表标题
          const Text(
            '推荐DApp',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // DApp列表
          Expanded(
            child: filteredDApps.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '没有找到匹配的DApp',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 16,
                          ),
                        ),
                        if (hasInput && _isValidUrl(searchQuery)) ...[
                          const SizedBox(height: 8),
                          const Text(
                            '您可以点击上方"前往网址"访问',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredDApps.length,
                    itemBuilder: (context, index) {
                      final dapp = filteredDApps[index];
                      return _buildDAppCard(
                        name: dapp['name'] as String,
                        description: dapp['description'] as String,
                        url: dapp['url'] as String,
                        icon: dapp['icon'] as IconData,
                        color: dapp['color'] as Color,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// 构建DApp卡片
  Widget _buildDAppCard({
    required String name,
    required String description,
    required String url,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D3A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white54,
          size: 16,
        ),
        onTap: () {
          _urlController.text = url;
          _navigateToUrl(url);
        },
      ),
    );
  }

  /// 构建应用栏
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF2A2D3A),
      elevation: 0,
      leading: IconButton(
        onPressed: () {
          // 检查是否可以返回，如果不能则导航到首页
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        },
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
      title: Text(
        _pageTitle.isNotEmpty ? _pageTitle : 'DApp浏览器',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      // 移除右上角的收藏按钮、连接状态和更多菜单
      actions: const [],
    );
  }

  /// 构建URL输入栏
  Widget _buildUrlBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFF2A2D3A),
        border: Border(
          bottom: BorderSide(
            color: Colors.white12,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // 安全指示器
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _currentOrigin?.startsWith('https://') == true
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              _currentOrigin?.startsWith('https://') == true
                  ? Icons.lock
                  : Icons.lock_open,
              size: 16,
              color: _currentOrigin?.startsWith('https://') == true
                  ? Colors.green
                  : Colors.orange,
            ),
          ),
          const SizedBox(width: 8),

          // URL输入框
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1B23),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _urlController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: '输入网址或搜索...',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: _navigateToUrl,
                      textInputAction: TextInputAction.go,
                    ),
                  ),
                  if (_urlController.text.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        _urlController.clear();
                        setState(() {});
                      },
                      icon: const Icon(
                        Icons.clear,
                        color: Colors.white54,
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 搜索/导航按钮
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: () => _navigateToUrl(_urlController.text),
              icon: Icon(
                _isValidUrl(_urlController.text)
                    ? Icons.arrow_forward
                    : Icons.search,
                color: Colors.white,
                size: 20,
              ),
              tooltip: _isValidUrl(_urlController.text) ? '访问' : '搜索',
            ),
          ),
        ],
      ),
    );
  }

  /// 构建底部导航栏
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF2A2D3A),
        border: Border(
          top: BorderSide(
            color: Colors.white12,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: _canGoBack ? _goBack : null,
            icon: Icon(
              Icons.arrow_back_ios,
              color: _canGoBack ? Colors.white : Colors.white30,
            ),
            tooltip: '后退',
          ),
          IconButton(
            onPressed: _canGoForward ? _goForward : null,
            icon: Icon(
              Icons.arrow_forward_ios,
              color: _canGoForward ? Colors.white : Colors.white30,
            ),
            tooltip: '前进',
          ),
          IconButton(
            onPressed: _refreshPage,
            icon: const Icon(Icons.refresh, color: Colors.white70),
            tooltip: '刷新',
          ),
          IconButton(
            onPressed: _showPageInfo,
            icon: const Icon(Icons.info_outline, color: Colors.white70),
            tooltip: '页面信息',
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.home, color: Colors.white70),
            tooltip: '返回首页',
          ),
        ],
      ),
    );
  }

  /// 构建连接对话框
  Widget _buildConnectionDialog([String? url, String? origin]) {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, child) {
        final currentNetwork = walletProvider.currentNetwork;
        final currentAddress = walletProvider.getCurrentNetworkAddress();
        final displayOrigin = origin ?? _currentOrigin ?? '';
        final displayUrl = url ?? _pendingUrl ?? '';

        return AlertDialog(
          backgroundColor: const Color(0xFF2A2D3A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '是否允许链接此DApp',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // DApp信息
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1B23),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.web,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Uri.parse(displayOrigin).host,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            displayOrigin,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 前往地址提示
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1B23),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF6366F1),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '前往地址：',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            displayUrl,
                            style: const TextStyle(
                              color: Color(0xFF6366F1),
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 网络选择
              const Text(
                '网络',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  // 显示网络选择器
                  final selectedNetwork =
                      await _showNetworkSelector(context, walletProvider);
                  if (selectedNetwork != null) {
                    walletProvider.setCurrentNetwork(selectedNetwork);
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1B23),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Color(currentNetwork?.color ?? 0xFF6366F1),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          currentNetwork?.name ?? '未选择网络',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white54,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 钱包地址
              const Text(
                '钱包',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  // 显示地址选择器
                  final selectedAddress =
                      await _showAddressSelector(context, walletProvider);
                  if (selectedAddress != null) {
                    walletProvider.setSelectedAddress(selectedAddress);
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1B23),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '主钱包',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (currentAddress != null)
                              Text(
                                '${currentAddress.substring(0, 6)}...${currentAddress.substring(currentAddress.length - 4)}',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white54,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                '取消',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '链接',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 处理菜单操作
  void _handleMenuAction(String action) {
    switch (action) {
      case 'connect':
        _showConnectionDialog();
        break;
      case 'disconnect':
        _disconnectDApp();
        break;
      case 'refresh':
        _refreshPage();
        break;
      case 'share':
        _sharePage();
        break;
      case 'info':
        _showPageInfo();
        break;
    }
  }

  /// 显示网络选择器
  Future<Network?> _showNetworkSelector(
      BuildContext context, WalletProvider walletProvider) async {
    return showDialog<Network>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2D3A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '选择网络',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: walletProvider.supportedNetworks.length,
            itemBuilder: (context, index) {
              final network = walletProvider.supportedNetworks[index];
              final isSelected =
                  network.id == walletProvider.currentNetwork?.id;

              return ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Color(network.color),
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(
                  network.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  network.symbol,
                  style: const TextStyle(color: Colors.white54),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Color(0xFF6366F1))
                    : null,
                onTap: () => Navigator.of(context).pop(network),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  /// 显示地址选择器
  Future<String?> _showAddressSelector(
      BuildContext context, WalletProvider walletProvider) async {
    final currentNetwork = walletProvider.currentNetwork;
    if (currentNetwork == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先选择网络'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }

    // 获取当前网络的所有地址
    final addresses =
        walletProvider.getCurrentWalletAddresses()[currentNetwork.id] ?? [];

    if (addresses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('当前网络没有可用地址'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }

    if (addresses.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('当前网络只有一个地址'),
          duration: Duration(seconds: 2),
        ),
      );
      return null;
    }

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2D3A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '选择地址',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final address = addresses[index];
              final isSelected =
                  address == walletProvider.getCurrentNetworkAddress();
              final addressName =
                  (walletProvider.currentWallet?.addressNames ?? {})[address] ??
                      '地址 ${index + 1}';

              return ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                title: Text(
                  addressName,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  '${address.substring(0, 6)}...${address.substring(address.length - 4)}',
                  style: const TextStyle(color: Colors.white54),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Color(0xFF6366F1))
                    : null,
                onTap: () => Navigator.of(context).pop(address),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }
}
