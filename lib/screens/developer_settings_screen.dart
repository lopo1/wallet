import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';

class DeveloperSettingsScreen extends StatefulWidget {
  const DeveloperSettingsScreen({super.key});

  @override
  State<DeveloperSettingsScreen> createState() => _DeveloperSettingsScreenState();
}

class _DeveloperSettingsScreenState extends State<DeveloperSettingsScreen> {
  String? _selectedNetworkId;
  final TextEditingController _rpcController = TextEditingController();

  @override
  void dispose() {
    _rpcController.dispose();
    super.dispose();
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '开发者设置',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Consumer<WalletProvider>(
          builder: (context, provider, _) {
            final isTestnet = provider.isTestnetMode;
            _selectedNetworkId ??= provider.currentNetwork?.id ?? (provider.supportedNetworks.isNotEmpty ? provider.supportedNetworks.first.id : null);

            final networks = provider.supportedNetworks;
            final selectedNetwork = networks.firstWhere(
              (n) => n.id == _selectedNetworkId,
              orElse: () => networks.isNotEmpty ? networks.first : provider.currentNetwork!,
            );

            final envs = provider.getAvailableEnvironments(selectedNetwork.id);
            final currentEnv = provider.getSelectedEnvironment(selectedNetwork.id);
            final rpcUrls = provider.getNetworkRpcUrls(selectedNetwork.id);
            final selectedRpc = provider.getSelectedRpcForNetwork(selectedNetwork.id) ?? (rpcUrls.isNotEmpty ? rpcUrls.first : selectedNetwork.rpcUrl);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 测试网模式开关
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B7280).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.developer_mode, color: Color(0xFF6B7280), size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '测试网模式',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Switch(
                        value: isTestnet,
                        activeColor: const Color(0xFF10B981),
                        onChanged: (v) => provider.setTestnetMode(v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // 当前模式提示
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isTestnet ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isTestnet ? '当前网络：测试网' : '当前网络：主网',
                          style: TextStyle(
                            color: isTestnet ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '启用后将自动切换所有网络的RPC至对应测试网，确保转账、Swap、DApp交互等均在测试环境执行。',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // 网络选择
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('选择网络', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedNetworkId,
                          dropdownColor: const Color(0xFF2A2B36),
                          iconEnabledColor: Colors.white,
                          items: networks.map((n) => DropdownMenuItem(
                                value: n.id,
                                child: Text(n.name, style: const TextStyle(color: Colors.white)),
                              )).toList(),
                          onChanged: (v) {
                            setState(() {
                              _selectedNetworkId = v;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // 测试网环境选择（仅测试网模式）
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('测试网环境', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      if (isTestnet) DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: currentEnv,
                          dropdownColor: const Color(0xFF2A2B36),
                          iconEnabledColor: Colors.white,
                          items: envs
                              .where((e) => e != 'mainnet')
                              .map((e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e, style: const TextStyle(color: Colors.white)),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              provider.setNetworkEnvironment(selectedNetwork.id, v);
                            }
                          },
                        ),
                      )
                      else
                        Text('主网模式下不可选择测试网环境', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // RPC管理
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('RPC节点管理', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      ...rpcUrls.map((url) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: Row(
                              children: [
                                Radio<String>(
                                  value: url,
                                  groupValue: selectedRpc,
                                  activeColor: const Color(0xFF10B981),
                                  onChanged: (v) {
                                    if (v != null) {
                                      provider.updateNetworkRpcUrl(selectedNetwork.id, v);
                                    }
                                  },
                                ),
                                Expanded(
                                  child: Text(url, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.wifi_tethering, color: Color(0xFF10B981)),
                                  tooltip: '测试连接',
                                  onPressed: () async {
                                    final ok = await provider.testRpcConnection(url);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(ok ? '连接正常' : '连接失败'),
                                        backgroundColor: ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                                  tooltip: '移除',
                                  onPressed: () {
                                    provider.removeCustomRpcUrl(selectedNetwork.id, url);
                                  },
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _rpcController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: '输入自定义RPC URL',
                                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.03),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: const Color(0xFF10B981)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              final url = _rpcController.text.trim();
                              if (url.isNotEmpty && _selectedNetworkId != null) {
                                provider.addCustomRpcUrl(selectedNetwork.id, url);
                                _rpcController.clear();
                              }
                            },
                            child: const Text('添加', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}