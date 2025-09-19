import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'lib/providers/wallet_provider.dart';
import 'lib/widgets/sidebar.dart';

void main() {
  runApp(const TestWalletSelectorApp());
}

class TestWalletSelectorApp extends StatelessWidget {
  const TestWalletSelectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => WalletProvider(),
      child: MaterialApp(
        title: '钱包选择器测试',
        theme: ThemeData.dark(),
        home: const TestWalletSelectorScreen(),
      ),
    );
  }
}

class TestWalletSelectorScreen extends StatelessWidget {
  const TestWalletSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B23),
      body: Row(
        children: [
          // 侧边栏
          SizedBox(
            width: 300,
            child: Sidebar(
              onCollapseChanged: (isCollapsed) {
                print('侧边栏折叠状态: $isCollapsed');
              },
            ),
          ),
          // 主内容区域
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '钱包选择器测试',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '点击左侧顶部的钱包选择器来测试功能',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Consumer<WalletProvider>(
                    builder: (context, walletProvider, child) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '当前钱包: ${walletProvider.currentWallet?.name ?? '无'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '钱包总数: ${walletProvider.wallets.length}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () async {
                              try {
                                await walletProvider.createWallet(
                                  name:
                                      '测试钱包 ${walletProvider.wallets.length + 1}',
                                  password: 'test123',
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('钱包创建成功')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('创建失败: $e')),
                                );
                              }
                            },
                            child: const Text('创建测试钱包'),
                          ),
                        ],
                      );
                    },
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
