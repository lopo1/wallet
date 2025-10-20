// 调试连接问题的测试代码
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../services/dapp_connection_service.dart';

class DebugConnectionScreen extends StatefulWidget {
  const DebugConnectionScreen({super.key});

  @override
  State<DebugConnectionScreen> createState() => _DebugConnectionScreenState();
}

class _DebugConnectionScreenState extends State<DebugConnectionScreen> {
  String _debugInfo = '';

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    final buffer = StringBuffer();

    try {
      buffer.writeln('=== 钱包连接诊断 ===');

      // 检查WalletProvider
      final walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      buffer.writeln('1. 钱包提供者状态:');
      buffer.writeln('   - 当前钱包: ${walletProvider.currentWallet?.id ?? "无"}');
      buffer
          .writeln('   - 当前网络: ${walletProvider.currentNetwork?.name ?? "无"}');
      buffer.writeln(
          '   - 当前地址: ${walletProvider.getCurrentNetworkAddress() ?? "无"}');
      buffer.writeln('   - 钱包数量: ${walletProvider.wallets.length}');
      buffer
          .writeln('   - 支持的网络数量: ${walletProvider.supportedNetworks.length}');

      // 检查DAppConnectionService
      final connectionService =
          Provider.of<DAppConnectionService>(context, listen: false);
      buffer.writeln('\n2. DApp连接服务状态:');
      buffer.writeln('   - 连接数量: ${connectionService.connections.length}');
      buffer.writeln('   - 待处理请求: ${connectionService.pendingRequests.length}');
      buffer.writeln('   - 收藏数量: ${connectionService.favoriteDApps.length}');

      // 测试连接功能
      buffer.writeln('\n3. 测试连接功能:');
      try {
        final testRequest = DAppConnectionRequest(
          origin: 'https://test.example.com',
          name: 'Test DApp',
          iconUrl: 'https://test.example.com/icon.png',
          requestedAddresses: [
            walletProvider.getCurrentNetworkAddress() ??
                '0x0000000000000000000000000000000000000000'
          ],
          networkId: walletProvider.currentNetwork?.id ?? 'ethereum',
          requestedPermissions: [DAppPermission.readAccounts],
        );

        final success = await connectionService.connectDApp(testRequest);
        buffer.writeln('   - 测试连接结果: ${success ? "成功" : "失败"}');

        if (success) {
          await connectionService.disconnectDApp('https://test.example.com');
          buffer.writeln('   - 测试断开连接: 成功');
        }
      } catch (e) {
        buffer.writeln('   - 测试连接异常: $e');
      }

      buffer.writeln('\n=== 诊断完成 ===');
    } catch (e) {
      buffer.writeln('诊断过程中发生错误: $e');
    }

    setState(() {
      _debugInfo = buffer.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('连接诊断'),
        backgroundColor: const Color(0xFF2A2D3A),
      ),
      backgroundColor: const Color(0xFF1A1B23),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _runDiagnostics,
              child: const Text('重新运行诊断'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2D3A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _debugInfo.isEmpty ? '正在运行诊断...' : _debugInfo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
