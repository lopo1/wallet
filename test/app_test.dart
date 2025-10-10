import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/main.dart';

void main() {
  testWidgets('应用能够正常启动', (WidgetTester tester) async {
    // 构建应用
    await tester.pumpWidget(const MyApp());

    // 等待初始化完成
    await tester.pumpAndSettle();

    // 验证应用正常启动（不会抛出Provider错误）
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
