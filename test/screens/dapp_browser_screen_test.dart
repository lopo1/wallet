import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../lib/screens/dapp_browser_screen.dart';
import '../../lib/providers/wallet_provider.dart';
import '../../lib/services/dapp_connection_service.dart';
import '../../lib/models/network.dart';

// 简单的测试用Mock类
class TestWalletProvider extends WalletProvider {
  @override
  Network? get currentNetwork => Network(
        id: 'ethereum',
        name: 'Ethereum',
        chainId: 1,
        rpcUrl: 'https://mainnet.infura.io/v3/test',
        symbol: 'ETH',
        explorerUrl: 'https://etherscan.io',
        color: 0xFF2196F3,
      );

  @override
  String? getCurrentNetworkAddress() =>
      '0x1234567890123456789012345678901234567890';

  @override
  List<Network> get supportedNetworks => [];
}

class TestDAppConnectionService extends DAppConnectionService {
  @override
  bool isConnected(String origin) => false;

  @override
  bool isFavorite(String origin) => false;

  @override
  Future<void> addToHistory(String origin) async {}
}

void main() {
  group('DAppBrowserScreen Tests', () {
    late TestWalletProvider testWalletProvider;
    late TestDAppConnectionService testConnectionService;

    setUp(() {
      testWalletProvider = TestWalletProvider();
      testConnectionService = TestDAppConnectionService();
    });

    Widget createTestWidget({String? initialUrl}) {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<WalletProvider>.value(
              value: testWalletProvider,
            ),
            ChangeNotifierProvider<DAppConnectionService>.value(
              value: testConnectionService,
            ),
          ],
          child: DAppBrowserScreen(
            initialUrl: initialUrl,
            title: 'Test DApp',
          ),
        ),
      );
    }

    testWidgets('应该正确显示DApp浏览器界面', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 验证基本UI元素
      expect(find.text('DApp浏览器'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('应该正确显示初始URL', (WidgetTester tester) async {
      const testUrl = 'https://example.com';
      await tester.pumpWidget(createTestWidget(initialUrl: testUrl));
      await tester.pumpAndSettle();

      // 验证URL输入框显示初始URL
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, equals(testUrl));
    });

    testWidgets('应该正确显示连接状态', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 验证未连接状态
      expect(find.text('未连接'), findsOneWidget);
      expect(find.byIcon(Icons.link_off), findsOneWidget);
    });

    testWidgets('应该能够输入URL', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 输入URL
      const testUrl = 'https://test.com';
      await tester.enterText(find.byType(TextField), testUrl);
      await tester.pumpAndSettle();

      // 验证输入
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, equals(testUrl));
    });

    testWidgets('应该显示正确的底部导航按钮', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 验证底部导航按钮
      expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.byIcon(Icons.home), findsOneWidget);
    });

    testWidgets('应该能够打开更多选项菜单', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 点击更多选项按钮
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // 验证菜单项
      expect(find.text('连接钱包'), findsOneWidget);
      expect(find.text('刷新'), findsOneWidget);
      expect(find.text('分享'), findsOneWidget);
      expect(find.text('页面信息'), findsOneWidget);
    });

    testWidgets('应该能够清除URL输入', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 输入文本
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pumpAndSettle();

      // 验证清除按钮出现
      expect(find.byIcon(Icons.clear), findsOneWidget);

      // 点击清除按钮
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // 验证文本被清除
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });
  });
}
