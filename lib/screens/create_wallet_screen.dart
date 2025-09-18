import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../services/mnemonic_service.dart';

class CreateWalletScreen extends StatefulWidget {
  const CreateWalletScreen({super.key});

  @override
  State<CreateWalletScreen> createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends State<CreateWalletScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _mnemonicController = TextEditingController();
  
  bool _isCreatingNew = true;
  bool _isLoading = false;
  bool _showMnemonic = false;
  bool _mnemonicConfirmed = false;
  int _selectedWordCount = 12;
  String _generatedMnemonic = '';
  
  @override
  void initState() {
    super.initState();
    _generateNewMnemonic();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if mode is passed as argument
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['mode'] != null) {
      final mode = args['mode'] as String;
      if (mode == 'import') {
        setState(() {
          _isCreatingNew = false;
        });
      } else if (mode == 'create') {
        setState(() {
          _isCreatingNew = true;
        });
      }
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _mnemonicController.dispose();
    super.dispose();
  }
  
  void _generateNewMnemonic() {
    setState(() {
      _generatedMnemonic = MnemonicService.generateMnemonic(wordCount: _selectedWordCount);
    });
  }
  
  Future<void> _createWallet() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_isCreatingNew && !_mnemonicConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先确认您已安全保存助记词，然后勾选确认复选框'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      // 滚动到确认复选框位置
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      
      if (_isCreatingNew) {
        await walletProvider.createWallet(
          name: _nameController.text,
          password: _passwordController.text,
          wordCount: _selectedWordCount,
        );
      } else {
        await walletProvider.importWallet(
          name: _nameController.text,
          mnemonic: _mnemonicController.text,
          password: _passwordController.text,
        );
      }
      
      if (mounted) {
        // Navigate to home screen after successful wallet creation/import
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isCreatingNew ? 'Wallet created successfully!' : 'Wallet imported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1B23),
        title: Text(
          _isCreatingNew ? 'Create Wallet' : 'Import Wallet',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  physics: const BouncingScrollPhysics(),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
              // Toggle between create and import
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2D3A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _isCreatingNew = true;
                          _generateNewMnemonic();
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isCreatingNew ? const Color(0xFF6366F1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Create New',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _isCreatingNew ? Colors.white : Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _isCreatingNew = false;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isCreatingNew ? const Color(0xFF6366F1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Import Existing',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: !_isCreatingNew ? Colors.white : Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Wallet name
              _buildTextField(
                controller: _nameController,
                label: 'Wallet Name',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a wallet name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Password
              _buildTextField(
                controller: _passwordController,
                label: 'Password',
                obscureText: true,
                validator: (value) {
                  if (value == null || value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Confirm password
              _buildTextField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                obscureText: true,
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              if (_isCreatingNew) ..._buildCreateWalletSection(),
              if (!_isCreatingNew) ..._buildImportWalletSection(),
              
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Fixed bottom button with scroll hint
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1B23),
                border: const Border(
                  top: BorderSide(color: Color(0xFF2A2D3A), width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isCreatingNew && !_mnemonicConfirmed)
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                       margin: const EdgeInsets.only(bottom: 16),
                       decoration: BoxDecoration(
                         color: Colors.orange.withOpacity(0.1),
                         borderRadius: BorderRadius.circular(8),
                         border: Border.all(color: Colors.orange, width: 1),
                       ),
                       child: const Row(
                         children: [
                           Icon(Icons.info_outline, color: Colors.orange, size: 16),
                           SizedBox(width: 6),
                           Expanded(
                             child: Text(
                               '请向上滚动查看并确认保存助记词',
                               style: TextStyle(
                                 color: Colors.orange,
                                 fontSize: 11,
                               ),
                               maxLines: 2,
                               overflow: TextOverflow.ellipsis,
                             ),
                           ),
                         ],
                       ),
                     ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createWallet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (_isCreatingNew && !_mnemonicConfirmed) 
                            ? Colors.grey 
                            : const Color(0xFF6366F1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _isCreatingNew ? '创建钱包' : '导入钱包',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  List<Widget> _buildCreateWalletSection() {
    return [
      // Word count selection
      const Text(
        'Mnemonic Length',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedWordCount = 12;
                  _generateNewMnemonic();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedWordCount == 12 ? const Color(0xFF6366F1) : const Color(0xFF2A2D3A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _selectedWordCount == 12 ? const Color(0xFF6366F1) : Colors.transparent,
                  ),
                ),
                child: Text(
                  '12 Words',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _selectedWordCount == 12 ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedWordCount = 24;
                  _generateNewMnemonic();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedWordCount == 24 ? const Color(0xFF6366F1) : const Color(0xFF2A2D3A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _selectedWordCount == 24 ? const Color(0xFF6366F1) : Colors.transparent,
                  ),
                ),
                child: Text(
                  '24 Words',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _selectedWordCount == 24 ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      
      // Mnemonic display
      Row(
         children: [
           const Expanded(
             child: Text(
               '您的助记词',
               style: TextStyle(
                 color: Colors.white,
                 fontSize: 16,
                 fontWeight: FontWeight.w600,
               ),
             ),
           ),
           Container(
             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
             decoration: BoxDecoration(
               color: Colors.orange.withOpacity(0.2),
               borderRadius: BorderRadius.circular(8),
             ),
             child: const Text(
               '重要',
               style: TextStyle(
                 color: Colors.orange,
                 fontSize: 10,
                 fontWeight: FontWeight.w600,
               ),
             ),
           ),
         ],
       ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2D3A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange, width: 2),
        ),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.security, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '请安全保存此助记词！这是恢复钱包的唯一方式。',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              constraints: const BoxConstraints(
                minHeight: 120,
                maxHeight: 200,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _showMnemonic ? const Color(0xFF1A1B23) : Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _showMnemonic
                  ? SingleChildScrollView(
                      child: SelectableText(
                        _generatedMnemonic,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'monospace',
                          height: 1.5,
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: () => setState(() => _showMnemonic = true),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.visibility, color: Colors.white70),
                            SizedBox(width: 8),
                            Text(
                              '点击显示助记词',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            if (_showMnemonic) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _generatedMnemonic));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('助记词已复制'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 14),
                      label: const Text(
                        '复制',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _generateNewMnemonic,
                      icon: const Icon(Icons.refresh, size: 14),
                      label: const Text(
                        '重新生成',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A2D3A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 24),
      
      // Confirmation checkbox with enhanced visibility
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _mnemonicConfirmed ? const Color(0xFF6366F1).withOpacity(0.1) : const Color(0xFF2A2D3A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _mnemonicConfirmed ? const Color(0xFF6366F1) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Checkbox(
               value: _mnemonicConfirmed,
               onChanged: (value) => setState(() => _mnemonicConfirmed = value ?? false),
               activeColor: const Color(0xFF6366F1),
               materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
             ),
             const SizedBox(width: 8),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const Text(
                     '我已安全保存助记词',
                     style: TextStyle(
                       color: Colors.white,
                       fontSize: 14,
                       fontWeight: FontWeight.w600,
                     ),
                   ),
                   const SizedBox(height: 4),
                   Text(
                      '请确保您已将助记词保存在安全的地方',
                      style: TextStyle(
                        color: _mnemonicConfirmed ? Colors.white70 : Colors.orange,
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                 ],
               ),
             ),
           ],
         ),
      ),
    ];
  }
  
  List<Widget> _buildImportWalletSection() {
    return [
      const Text(
        'Enter Mnemonic Phrase',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _mnemonicController,
        maxLines: 4,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Enter your 12 or 24 word mnemonic phrase...',
          hintStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: const Color(0xFF2A2D3A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your mnemonic phrase';
          }
          if (!MnemonicService.validateMnemonic(value)) {
            return 'Invalid mnemonic phrase';
          }
          if (!MnemonicService.hasValidWordCount(value)) {
            return 'Mnemonic must be 12 or 24 words';
          }
          return null;
        },
      ),
    ];
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF2A2D3A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}