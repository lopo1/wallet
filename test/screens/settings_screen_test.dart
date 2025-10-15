import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/screens/settings_screen.dart';

void main() {
  group('SettingsScreen Tests', () {
    testWidgets('should display settings screen with all elements',
        (WidgetTester tester) async {
      // Build the SettingsScreen widget
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );

      // Verify that the settings screen is displayed
      expect(find.text('设置'), findsNWidgets(2)); // 标题栏和底部导航栏各一个

      // Verify search bar is present
      expect(find.text('搜索...'), findsOneWidget);

      // Verify user card is present
      expect(find.text('@SpryBunny634'), findsOneWidget);

      // Verify main setting options are present
      expect(find.text('管理账户'), findsOneWidget);
      expect(find.text('偏好设置'), findsOneWidget);
      expect(find.text('安全性与隐私'), findsOneWidget);
      expect(find.text('有效网络'), findsOneWidget);
      expect(find.text('地址簿'), findsOneWidget);
      expect(find.text('关联的应用'), findsOneWidget);
      expect(find.text('开发者设置'), findsOneWidget);
      expect(find.text('帮助与支持'), findsOneWidget);
      expect(find.text('邀请好友'), findsOneWidget);
    });

    testWidgets('should show close button and handle tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const SettingsScreen(),
          routes: {
            '/home': (context) => const Scaffold(body: Text('Home Screen')),
          },
        ),
      );

      // Find and tap the close button
      final closeButton = find.byIcon(Icons.close);
      expect(closeButton, findsOneWidget);

      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      // Should navigate to home screen
      expect(find.text('Home Screen'), findsOneWidget);
    });

    testWidgets('should handle search input', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );

      // Find the search field
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // Enter text in search field
      await tester.enterText(searchField, '安全');
      await tester.pump();

      // Verify text was entered
      expect(find.text('安全'), findsOneWidget);
    });

    testWidgets('should navigate to security settings when tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );

      // Find security settings option
      final securityOption = find.text('安全性与隐私');
      expect(securityOption, findsOneWidget);

      await tester.tap(securityOption);
      await tester.pumpAndSettle();

      // Should navigate to security settings page
      expect(find.text('安全性与隐私'), findsWidgets);
    });
  });
}
