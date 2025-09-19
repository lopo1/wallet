import 'package:flutter/material.dart';

void main() {
  runApp(const SimpleWalletSelectorApp());
}

class SimpleWalletSelectorApp extends StatelessWidget {
  const SimpleWalletSelectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '钱包选择器UI测试',
      theme: ThemeData.dark(),
      home: const SimpleWalletSelectorScreen(),
    );
  }
}

class SimpleWalletSelectorScreen extends StatefulWidget {
  const SimpleWalletSelectorScreen({super.key});

  @override
  State<SimpleWalletSelectorScreen> createState() =>
      _SimpleWalletSelectorScreenState();
}

class _SimpleWalletSelectorScreenState
    extends State<SimpleWalletSelectorScreen> {
  bool _isCollapsed = false;
  String _selectedWallet = '主钱包';

  final List<Map<String, String>> _wallets = [
    {'name': '主钱包', 'date': '2024/01/15'},
    {'name': '交易钱包', 'date': '2024/02/20'},
    {'name': 'DeFi钱包', 'date': '2024/03/10'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B23),
      body: Row(
        children: [
          // 侧边栏
          Container(
            width: _isCollapsed ? 80 : 300,
            color: const Color(0xFF2A2D3A),
            child: Column(
              children: [
                // Header with wallet selector and collapse button
                Container(
                  padding: EdgeInsets.all(_isCollapsed ? 12 : 24),
                  child: Row(
                    mainAxisAlignment: _isCollapsed
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.spaceBetween,
                    children: [
                      if (!_isCollapsed)
                        Expanded(
                          child: _buildWalletSelector(),
                        ),
                      if (!_isCollapsed)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isCollapsed = !_isCollapsed;
                            });
                          },
                          child: const Icon(
                            Icons.chevron_left,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                      if (_isCollapsed)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isCollapsed = !_isCollapsed;
                            });
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Color(0xFF627EEA),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Portfolio section
                if (!_isCollapsed)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Portfolio',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Total Retolls',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                // Network list placeholder
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildNetworkItem('Ethereum', const Color(0xFF627EEA),
                          Icons.currency_bitcoin),
                      _buildNetworkItem(
                          'Polygon', const Color(0xFF8247E5), Icons.hexagon),
                      _buildNetworkItem('BSC', const Color(0xFFF3BA2F),
                          Icons.account_balance),
                      _buildNetworkItem('Bitcoin', const Color(0xFFF7931A),
                          Icons.currency_bitcoin),
                      _buildNetworkItem(
                          'Solana', const Color(0xFF9945FF), Icons.wb_sunny),
                    ],
                  ),
                ),
              ],
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
                    '钱包选择器UI测试',
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
                  Text(
                    '当前选择的钱包: $_selectedWallet',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '钱包总数: ${_wallets.length}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletSelector() {
    return GestureDetector(
      onTap: () => _showWalletDropdown(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF3A3D4A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF6366F1), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFF627EEA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedWallet,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${_wallets.length} 个钱包',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white70,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showWalletDropdown() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF2A2D3A),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      '选择钱包',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Wallet list
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _wallets.length,
                  itemBuilder: (context, index) {
                    final wallet = _wallets[index];
                    final isSelected = _selectedWallet == wallet['name'];

                    return _buildWalletItem(
                      name: wallet['name']!,
                      date: wallet['date']!,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedWallet = wallet['name']!;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              // Add wallet button
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showAddWalletOptions();
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('添加钱包'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWalletItem({
    required String name,
    required String date,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3A3D4A) : const Color(0xFF1A1B23),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF627EEA).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: Color(0xFF627EEA),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '创建于 $date',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF6366F1),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _showAddWalletOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF2A2D3A),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                '添加钱包',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.add_circle, color: Colors.white70),
                title:
                    const Text('创建新钱包', style: TextStyle(color: Colors.white)),
                subtitle: const Text('生成新的助记词',
                    style: TextStyle(color: Colors.white70)),
                onTap: () {
                  Navigator.pop(context);
                  // 这里可以导航到创建钱包页面
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_download, color: Colors.white70),
                title:
                    const Text('导入钱包', style: TextStyle(color: Colors.white)),
                subtitle: const Text('使用助记词导入',
                    style: TextStyle(color: Colors.white70)),
                onTap: () {
                  Navigator.pop(context);
                  // 这里可以导航到导入钱包页面
                },
              ),
              ListTile(
                leading: const Icon(Icons.vpn_key, color: Colors.white70),
                title:
                    const Text('导入私钥', style: TextStyle(color: Colors.white)),
                subtitle: const Text('使用私钥导入',
                    style: TextStyle(color: Colors.white70)),
                onTap: () {
                  Navigator.pop(context);
                  // 这里可以导航到导入私钥页面
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNetworkItem(String name, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: _isCollapsed
          ? Center(
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            )
          : Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white70,
                  size: 16,
                ),
              ],
            ),
    );
  }
}
