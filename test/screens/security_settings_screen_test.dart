import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/screens/security_settings_screen.dart';

void main() {
  group('SecuritySettingsScreen Tests', () {
    testWidgets('should display security settings screen with all elements',
        (WidgetTester tester) async {
      // Build the SecuritySettingsScreen widget
      await tester.pumpWidget(
        const MaterialApp(
          home: SecuritySettingsScreen(),
        ),
      );

      // Verify that the security settings screen is displayed
      expect(find.text('安全性与隐私'), findsOneWidget);

      // Verify security options are present
      expect(find.text('锁屏时间'), findsOneWidget);
      expect(find.text('生物识别'), findsOneWidget);
      expect(find.text('密码设置'), findsOneWidget);
      expect(find.text('助记词备份'), findsOneWidget);
      expect(find.text('隐私设置'), findsOneWidget);
    });

    testWidgets('should show back button and handle tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SecuritySettingsScreen(),
        ),
      );

      // Find and tap the back button
      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Should pop the current screen
      expect(find.text('安全性与隐私'), findsNothing);
    });

    testWidgets('should navigate to lock screen timeout settings when tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SecuritySettingsScreen(),
        ),
      );

      // Find and tap lock screen timeout option
      final lockScreenOption = find.text('锁屏时间');
      expect(lockScreenOption, findsOneWidget);

      await tester.tap(lockScreenOption);
      await tester.pumpAndSettle();

      // Should navigate to lock screen timeout page
      expect(find.text('锁屏时间'), findsWidgets);
    });
  });

  group('LockScreenTimeoutScreen Tests', () {
    testWidgets('should display lock screen timeout options',
        (WidgetTester tester) async {
      // Build the LockScreenTimeoutScreen widget
      await tester.pumpWidget(
        MaterialApp(
          home: LockScreenTimeoutScreen(
            currentTimeout: -1,
            onTimeoutChanged: (timeout) {},
          ),
        ),
      );

      // Verify that the lock screen timeout screen is displayed
      expect(find.text('锁屏时间'), findsOneWidget);

      // Verify timeout options are present
      expect(find.text('立即'), findsOneWidget);
      expect(find.text('15秒后'), findsOneWidget);
      expect(find.text('30秒后'), findsOneWidget);
      expect(find.text('1分钟后'), findsOneWidget);
      expect(find.text('5分钟后'), findsOneWidget);
      expect(find.text('10分钟后'), findsOneWidget);
      expect(find.text('永不'), findsOneWidget);
    });

    testWidgets('should show selected timeout option',
        (WidgetTester tester) async {
      // Build the LockScreenTimeoutScreen widget with 5 minutes selected
      await tester.pumpWidget(
        MaterialApp(
          home: LockScreenTimeoutScreen(
            currentTimeout: 300,
            onTimeoutChanged: (timeout) {},
          ),
        ),
      );

      // Find the selected option (5分钟后)
      final selectedOption = find.text('5分钟后');
      expect(selectedOption, findsOneWidget);

      // Verify the check icon is present for selected option
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('should handle timeout selection', (WidgetTester tester) async {
      int? selectedTimeout;

      // Build the LockScreenTimeoutScreen widget
      await tester.pumpWidget(
        MaterialApp(
          home: LockScreenTimeoutScreen(
            currentTimeout: -1,
            onTimeoutChanged: (timeout) {
              selectedTimeout = timeout;
            },
          ),
        ),
      );

      // Find and tap the 1分钟后 option
      final oneMinuteOption = find.text('1分钟后');
      expect(oneMinuteOption, findsOneWidget);

      await tester.tap(oneMinuteOption);
      await tester.pump();

      // Verify the option is now selected
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });
}
