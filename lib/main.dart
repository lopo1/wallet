import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'screens/home_screen.dart';
import 'providers/wallet_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/create_wallet_screen.dart';
import 'screens/import_wallet_screen.dart';
import 'screens/import_private_key_screen.dart';
import 'screens/send_screen.dart';
import 'screens/send_detail_screen.dart';
import 'screens/receive_screen.dart';
import 'screens/swap_screen.dart';
import 'screens/account_detail_screen.dart';
import 'screens/solana_fee_estimator_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/security_settings_screen.dart';
import 'screens/add_token_screen.dart';
import 'screens/walletconnect_sessions_screen.dart';
import 'screens/dapp_browser_screen.dart';
import 'screens/dapp_discovery_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/set_new_password_screen.dart';
import 'screens/confirm_password_screen.dart';
import 'screens/import_mnemonic_screen.dart';
import 'screens/hot_tokens_screen.dart';
import 'screens/token_detail_screen.dart';
import 'screens/qr_scanner_screen.dart';

import 'services/walletconnect_service.dart';
import 'services/solana_wallet_service.dart';
import 'services/dapp_connection_service.dart';
import 'services/screen_lock_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final ScreenLockService _screenLockService = ScreenLockService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 设置锁屏回调
    _screenLockService.setLockScreenCallback(() {
      try {
        final walletProvider = Provider.of<WalletProvider>(context, listen: false);
        walletProvider.clearSensitiveMemory();
      } catch (e) {
        debugPrint('锁屏清空敏感数据失败: $e');
      }
      _navigateToLogin();
    });

    // 启动锁屏计时器
    _screenLockService.resetTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _screenLockService.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // 应用回到前台，恢复锁屏计时器
        _screenLockService.resume();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // 应用进入后台，暂停锁屏计时器
        _screenLockService.pause();
        break;
      case AppLifecycleState.detached:
        // 应用被销毁
        _screenLockService.stop();
        break;
      case AppLifecycleState.hidden:
        // 应用被隐藏
        _screenLockService.pause();
        break;
    }
  }

  void _navigateToLogin() {
    // 获取当前导航器并跳转到登录页面
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  // 全局导航器键
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider<SolanaWalletService>(
          create: (_) =>
              SolanaWalletService('https://api.mainnet-beta.solana.com'),
        ),
        ChangeNotifierProxyProvider2<WalletProvider, SolanaWalletService,
            WalletConnectService>(
          create: (context) => WalletConnectService(
            Provider.of<SolanaWalletService>(context, listen: false),
            Provider.of<WalletProvider>(context, listen: false),
          ),
          update: (context, walletProvider, walletService, previous) =>
              previous ?? WalletConnectService(walletService, walletProvider),
        ),
        ChangeNotifierProvider<DAppConnectionService>(
          create: (_) {
            final service = DAppConnectionService();
            // 异步初始化服务
            service.initialize();
            return service;
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'Harbor',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF6366F1),
                brightness: Brightness.light,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF6366F1),
                brightness: Brightness.dark,
              ),
            ),
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            initialRoute: '/',
            routes: {
              '/': (context) => const WalletInitScreen(),
              '/welcome': (context) => const WelcomeScreen(),
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const HomeScreen(),
              '/create-wallet': (context) => const CreateWalletScreen(),
              '/create_wallet': (context) => const CreateWalletScreen(),
              '/import-wallet': (context) => const ImportWalletScreen(),
              '/import_wallet': (context) => const ImportWalletScreen(),
              '/import-private-key': (context) =>
                  const ImportPrivateKeyScreen(),
              '/import_private_key': (context) =>
                  const ImportPrivateKeyScreen(),
              '/send': (context) => const SendScreen(),
              '/receive': (context) => const ReceiveScreen(),
              '/swap': (context) => const SwapScreen(),
              '/account_detail': (context) => const AccountDetailScreen(),
              '/solana-fee-estimator': (context) =>
                  const SolanaFeeEstimatorScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/wallet_settings': (context) => const SettingsScreen(),
              '/security-settings': (context) => const SecuritySettingsScreen(),
              '/add_token': (context) => const AddTokenScreen(),
              '/manage_tokens': (context) => const AddTokenScreen(),
              '/walletconnect-sessions': (context) =>
                  const WalletConnectSessionsScreen(),
              '/dapp-browser': (context) => const DAppBrowserScreen(),
              '/dapp-discovery': (context) => const DAppDiscoveryScreen(),
              '/reset-password': (context) => const ResetPasswordScreen(),
              '/set-new-password': (context) => const SetNewPasswordScreen(),
              '/confirm-password': (context) => const ConfirmPasswordScreen(),
              '/import-mnemonic': (context) => const ImportMnemonicScreen(),
              '/hot-tokens': (context) => const HotTokensScreen(),
              '/qr-scanner': (context) => const QRScannerScreen(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/send_detail') {
                return MaterialPageRoute(
                  builder: (context) => const SendDetailScreen(),
                  settings: settings,
                );
              }
              if (settings.name == '/token_detail') {
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => TokenDetailScreen(
                    asset: args?['asset'] ?? {},
                    balance: args?['balance'] ?? 0.0,
                    usdValue: args?['usdValue'] ?? 0.0,
                  ),
                  settings: settings,
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}

class WalletInitScreen extends StatefulWidget {
  const WalletInitScreen({super.key});

  @override
  State<WalletInitScreen> createState() => _WalletInitScreenState();
}

class _WalletInitScreenState extends State<WalletInitScreen> {
  bool _isInitializing = true;
  bool _hasStoredWallet = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);

      // Check if there are stored wallets
      _hasStoredWallet = await walletProvider.hasStoredWallets();

      setState(() {
        _isInitializing = false;
      });

      // Navigate based on wallet existence
      if (mounted) {
        if (_hasStoredWallet) {
          Navigator.of(context).pushReplacementNamed('/login');
        } else {
          Navigator.of(context).pushReplacementNamed('/welcome');
        }
      }
    } catch (e) {
      setState(() {
        _isInitializing = false;
      });

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/welcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B23),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                width: 120,
                height: 120,
                child: SvgPicture.asset(
                  'assets/images/harbor_logo.svg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
            ),
            const SizedBox(height: 16),

            // Loading text
            Text(
              _isInitializing ? '正在初始化 Harbor...' : '正在加载...',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
