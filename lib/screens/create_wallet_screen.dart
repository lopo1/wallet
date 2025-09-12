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
          content: Text('Please confirm you have saved your mnemonic phrase'),
          backgroundColor: Colors.red,
        ),
      );
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
              
              const SizedBox(height: 32),
              
              // Create/Import button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createWallet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isCreatingNew ? 'Create Wallet' : 'Import Wallet',
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
      const Text(
        'Your Mnemonic Phrase',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
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
                Icon(Icons.warning, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Save this phrase securely. You\'ll need it to recover your wallet.',
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _showMnemonic ? const Color(0xFF1A1B23) : Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _showMnemonic
                  ? SelectableText(
                      _generatedMnemonic,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    )
                  : GestureDetector(
                      onTap: () => setState(() => _showMnemonic = true),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.visibility, color: Colors.white70),
                          SizedBox(width: 8),
                          Text(
                            'Tap to reveal mnemonic',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
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
                            content: Text('Mnemonic copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _generateNewMnemonic,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Generate New'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A2D3A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
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
      
      // Confirmation checkbox
      Row(
        children: [
          Checkbox(
            value: _mnemonicConfirmed,
            onChanged: (value) => setState(() => _mnemonicConfirmed = value ?? false),
            activeColor: const Color(0xFF6366F1),
          ),
          const Expanded(
            child: Text(
              'I have saved my mnemonic phrase in a secure location',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
        ],
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