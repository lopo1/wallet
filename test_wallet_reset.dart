import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'lib/providers/wallet_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 创建钱包提供者
  final walletProvider = WalletProvider();

  print('=== 钱包重置功能测试 ===');

  try {
    // 检查是否有存储的钱包
    final hasWallets = await walletProvider.hasStoredWallets();
    print('是否有存储的钱包: $hasWallets');

    if (hasWallets) {
      print('当前钱包数量: ${walletProvider.wallets.length}');

      // 执行重置操作
      print('正在执行钱包重置...');
      await walletProvider.resetWallet();
      print('钱包重置完成');

      // 验证重置结果
      final hasWalletsAfterReset = await walletProvider.hasStoredWallets();
      print('重置后是否有存储的钱包: $hasWalletsAfterReset');
      print('重置后钱包数量: ${walletProvider.wallets.length}');
      print('当前钱包: ${walletProvider.currentWallet?.name ?? '无'}');
      print('选中地址: ${walletProvider.selectedAddress ?? '无'}');

      if (!hasWalletsAfterReset &&
          walletProvider.wallets.isEmpty &&
          walletProvider.currentWallet == null &&
          walletProvider.selectedAddress == null) {
        print('✅ 钱包重置功能测试通过');
      } else {
        print('❌ 钱包重置功能测试失败');
      }
    } else {
      print('没有钱包需要重置，创建一个测试钱包...');

      // 创建测试钱包
      await walletProvider.createWallet(
        name: '测试钱包',
        password: 'test123',
      );

      print('测试钱包创建完成');
      print('钱包数量: ${walletProvider.wallets.length}');
      print('当前钱包: ${walletProvider.currentWallet?.name}');

      // 现在执行重置
      print('正在执行钱包重置...');
      await walletProvider.resetWallet();
      print('钱包重置完成');

      // 验证重置结果
      final hasWalletsAfterReset = await walletProvider.hasStoredWallets();
      print('重置后是否有存储的钱包: $hasWalletsAfterReset');
      print('重置后钱包数量: ${walletProvider.wallets.length}');

      if (!hasWalletsAfterReset && walletProvider.wallets.isEmpty) {
        print('✅ 钱包重置功能测试通过');
      } else {
        print('❌ 钱包重置功能测试失败');
      }
    }
  } catch (e) {
    print('❌ 测试过程中发生错误: $e');
  }

  print('=== 测试完成 ===');
}
