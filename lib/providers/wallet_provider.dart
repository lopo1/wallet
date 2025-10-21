import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;
import 'package:hex/hex.dart';
import 'package:crypto/crypto.dart';
import 'package:web3dart/web3dart.dart' as web3;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:solana/solana.dart' as solana;
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import '../models/wallet.dart';
import '../models/network.dart';
import '../models/solana_transaction.dart';
import '../services/storage_service.dart';
import '../services/mnemonic_service.dart';
import '../services/address_service.dart';
import '../services/solana_wallet_service.dart';
import '../services/transaction_monitor_service.dart';
import '../services/solana_transaction_monitor.dart';
import '../constants/derivation_paths.dart';
import '../constants/network_constants.dart';
import '../models/token_model.dart';
import '../services/tron_service.dart';
import '../services/trc20_service.dart';
import '../services/tron_fee_service.dart';

class WalletProvider extends ChangeNotifier {
  List<Wallet> _wallets = [];
  Wallet? _currentWallet;
  List<Network> _supportedNetworks = [];
  Network? _currentNetwork;
  bool _isLoading = false;
  String? _selectedAddress;
  List<Token> _customTokens = [];
  bool _isBalanceHidden = false;

  List<Wallet> get wallets => _wallets;
  Wallet? get currentWallet => _currentWallet;
  List<Network> get supportedNetworks => _supportedNetworks;
  Network? get currentNetwork => _currentNetwork;
  bool get isLoading => _isLoading;
  String? get selectedAddress => _selectedAddress;
  List<Token> get customTokens => _customTokens;
  bool get isBalanceHidden => _isBalanceHidden;

  final StorageService _storageService = StorageService();
  SolanaWalletService? _solanaWalletService;
  TransactionMonitorService? _transactionMonitorService;
  SolanaTransactionMonitor? _solanaTransactionMonitor;

  WalletProvider() {
    _initializeSupportedNetworks();
    _loadWallets();
    _loadCustomTokens();
    _initializeSolanaService();
  }

  /// 初始化Solana服务
  void _initializeSolanaService() {
    final solanaNetwork = _supportedNetworks.firstWhere(
      (network) => network.id == 'solana',
      orElse: () => _supportedNetworks.first,
    );

    _solanaWalletService = SolanaWalletService(solanaNetwork.rpcUrl);
    _solanaTransactionMonitor = SolanaTransactionMonitor(solanaNetwork.rpcUrl);
  }

  /// 获取Solana服务
  SolanaWalletService? get solanaWalletService => _solanaWalletService;

  void _initializeSupportedNetworks() {
    _supportedNetworks = [
      Network(
        id: 'ethereum',
        name: 'Ethereum',
        symbol: 'ETH',
        chainId: 1,
        rpcUrl:
            'https://ethereum.blockpi.network/v1/rpc/bb98a6bd2a003a01b46b479224a24db69caed026',
        rpcUrls: [
          'https://ethereum.blockpi.network/v1/rpc/bb98a6bd2a003a01b46b479224a24db69caed026',
          'https://eth-mainnet.alchemyapi.io/v2/YOUR_API_KEY',
          'https://rpc.ankr.com/eth',
          'https://ethereum.publicnode.com',
        ],
        explorerUrl: 'https://etherscan.io',
        color: 0xFF627EEA,
      ),
      Network(
        id: 'polygon',
        name: 'Polygon',
        symbol: 'MATIC',
        chainId: 137,
        rpcUrl: 'https://polygon-rpc.com',
        rpcUrls: [
          'https://polygon-rpc.com',
          'https://rpc.ankr.com/polygon',
          'https://polygon-mainnet.infura.io/v3/YOUR_PROJECT_ID',
          'https://polygon.publicnode.com',
        ],
        explorerUrl: 'https://polygonscan.com',
        color: 0xFF8247E5,
      ),
      Network(
        id: 'bsc',
        name: 'BSC',
        symbol: 'BNB',
        chainId: 56,
        rpcUrl:
            'https://bsc.blockpi.network/v1/rpc/77e2b602c1012feb83cfc51b592656b3dcfa231f',
        rpcUrls: [
          'https://bsc.blockpi.network/v1/rpc/77e2b602c1012feb83cfc51b592656b3dcfa231f',
          'https://data-seed-prebsc-1-s3.bnbchain.org:8545',
          'https://bsc-dataseed.binance.org',
          'https://bsc-dataseed1.defibit.io',
          'https://bsc-dataseed1.ninicoin.io',
          'https://rpc.ankr.com/bsc',
        ],
        explorerUrl: 'https://bscscan.com',
        color: 0xFFF3BA2F,
      ),
      Network(
        id: 'bitcoin',
        name: 'Bitcoin',
        symbol: 'BTC',
        chainId: 0, // Bitcoin doesn't use chainId
        rpcUrl: 'https://blockstream.info/api',
        rpcUrls: [
          'https://blockstream.info/api',
          'https://mempool.space/api',
        ],
        explorerUrl: 'https://blockstream.info',
        color: 0xFFF7931A,
      ),
      Network(
        id: 'solana',
        name: 'Solana',
        symbol: 'SOL',
        chainId: 101, // Solana mainnet
        rpcUrl:
            'https://api.zan.top/node/v1/solana/devnet/b49c38feccc54a49a318db163d336c60',
        rpcUrls: [
          'https://api.zan.top/node/v1/solana/devnet/b49c38feccc54a49a318db163d336c60',
          'https://api.devnet.solana.com',
          'https://api.mainnet-beta.solana.com',
          'https://rpc.ankr.com/solana',
          'https://solana-api.projectserum.com',
          'https://api.zan.top/node/v1/solana/mainnet/b49c38feccc54a49a318db163d336c60',
        ],
        explorerUrl: 'https://explorer.solana.com',
        color: 0xFF9945FF,
      ),
      // TRON (Nile 测试网)
      Network(
        id: 'tron',
        name: 'Tron',
        symbol: 'TRX',
        chainId: 728,
        rpcUrl: 'https://nile.trongrid.io',
        rpcUrls: [
          'https://nile.trongrid.io',
          'https://api.nileex.io',
        ],
        explorerUrl: 'https://nile.tronscan.org',
        color: 0xFFC6312D,
      ),
    ];
    // 设置默认网络为以太坊
    _currentNetwork = _supportedNetworks.first;
  }

  Future<void> _loadWallets() async {
    _isLoading = true;
    notifyListeners();

    try {
      _wallets = await _storageService.getWallets();
      if (_wallets.isNotEmpty) {
        _currentWallet = _wallets.first;
        _setDefaultSelectedAddress();
        // Note: Mnemonic will be empty from storage for security
        // It needs to be retrieved separately when needed
      }
    } catch (e) {
      debugPrint('Error loading wallets: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Get wallet mnemonic with password
  Future<String?> getWalletMnemonic(String walletId, String password) async {
    return await _storageService.getWalletMnemonic(walletId, password);
  }

  Future<String?> getWalletPrivateKey(String walletId, String password) async {
    return await _storageService.getPrivateKey(walletId, password);
  }

  Future<bool> verifyPasswordForWallet(String walletId, String password) async {
    return await _storageService.verifyPasswordHash(walletId, password);
  }

  /// Login with password for existing wallet
  Future<bool> loginWithPassword(String password) async {
    if (_wallets.isEmpty) {
      return false;
    }

    try {
      // Try to verify password with the first wallet using password hash
      final firstWallet = _wallets.first;
      final isValid =
          await _storageService.verifyPasswordHash(firstWallet.id, password);

      if (isValid) {
        // Load the wallet with mnemonic
        final mnemonic =
            await _storageService.getWalletMnemonic(firstWallet.id, password);
        if (mnemonic != null && mnemonic.isNotEmpty) {
          _currentWallet = firstWallet.copyWith(mnemonic: mnemonic);
          _setDefaultSelectedAddress();
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  /// Reset wallet (clear all data)
  Future<void> resetWallet() async {
    try {
      await _storageService.clearAll();
      _wallets.clear();
      _currentWallet = null;
      _selectedAddress = null;
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to reset wallet: $e');
    }
  }

  /// Check if there are stored wallets
  Future<bool> hasStoredWallets() async {
    try {
      final wallets = await _storageService.getWallets();
      return wallets.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<Wallet> createWallet({
    required String name,
    required String password,
    int wordCount = 12,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Generate mnemonic
      final mnemonic = MnemonicService.generateMnemonic(wordCount: wordCount);

      // Create wallet
      final wallet = Wallet(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        mnemonic: mnemonic,
        addresses: {},
        addressIndexes: {},
        createdAt: DateTime.now(),
      );

      // Generate addresses for all supported networks
      for (final network in _supportedNetworks) {
        final address = await _generateAddressForNetwork(mnemonic, network);
        wallet.addresses[network.id] = [address]; // 初始化为包含一个地址的列表
        wallet.addressIndexes[network.id] = 1; // 下一个索引从1开始
      }

      // Save password hash for future verification
      await _storageService.savePasswordHash(wallet.id, password);

      // Save wallet
      await _storageService.saveWallet(wallet, password);

      _wallets.add(wallet);
      _currentWallet = wallet;

      _isLoading = false;
      notifyListeners();

      return wallet;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Failed to create wallet: $e');
    }
  }

  Future<Wallet> importWallet({
    required String name,
    required String mnemonic,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Clean and validate mnemonic
      final cleanedMnemonic = _cleanMnemonic(mnemonic);
      if (!bip39.validateMnemonic(cleanedMnemonic)) {
        throw Exception('Invalid mnemonic phrase');
      }

      // Check if mnemonic is already imported
      final isAlreadyImported =
          await isMnemonicAlreadyImported(cleanedMnemonic);
      if (isAlreadyImported) {
        final existingWalletName =
            await getWalletNameByMnemonic(cleanedMnemonic);
        throw Exception('此助记词已经导入过了，钱包名称：$existingWalletName');
      }

      // Create wallet
      final wallet = Wallet(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        mnemonic: mnemonic,
        addresses: {},
        createdAt: DateTime.now(),
        importType: 'mnemonic',
      );

      // Generate addresses for all supported networks
      for (final network in _supportedNetworks) {
        final address = await _generateAddressForNetwork(mnemonic, network);
        wallet.addresses[network.id] = [address]; // 初始化为包含一个地址的列表
      }

      // Save password hash for future verification
      await _storageService.savePasswordHash(wallet.id, password);

      // Save wallet
      await _storageService.saveWallet(wallet, password);

      _wallets.add(wallet);
      _currentWallet = wallet;

      _isLoading = false;
      notifyListeners();

      return wallet;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Failed to import wallet: $e');
    }
  }

  Future<Wallet> importWalletFromPrivateKey({
    required String name,
    required String privateKey,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 检查支持的网络是否已初始化
      if (_supportedNetworks.isEmpty) {
        throw Exception('支持的网络列表未初始化');
      }

      // 使用一个占位符助记词，因为从私钥导入不需要真实的助记词
      // 在实际应用中，应该修改钱包模型来支持私钥导入
      const placeholderMnemonic =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

      // Create wallet
      final wallet = Wallet(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        mnemonic: placeholderMnemonic, // 占位符助记词
        addresses: {},
        addressIndexes: {},
        createdAt: DateTime.now(),
        importType: 'private_key',
      );

      // 从私钥生成地址（简化实现）
      // 在实际应用中，需要使用正确的加密库来从私钥生成各网络的地址
      for (final network in _supportedNetworks) {
        // 这里简化处理，实际应该从私钥正确生成对应网络的地址
        final address =
            await _generateAddressFromPrivateKey(privateKey, network);
        wallet.addresses[network.id] = [address]; // 初始化为包含一个地址的列表
        wallet.addressIndexes[network.id] = 1; // 下一个索引从1开始
      }

      // Save wallet
      await _storageService.saveWallet(wallet, password);

      // 保存加密的私钥以便后续导出
      await _storageService.savePrivateKey(wallet.id, privateKey, password);

      _wallets.add(wallet);
      _currentWallet = wallet;

      _isLoading = false;
      notifyListeners();

      return wallet;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Failed to import wallet from private key: $e');
    }
  }

  // 新方法：将私钥地址添加到当前钱包
  Future<void> addPrivateKeyToCurrentWallet(
      String privateKey, String addressName) async {
    if (_currentWallet == null) {
      throw Exception('没有当前钱包，请先创建或选择一个钱包');
    }

    if (_currentNetwork == null) {
      throw Exception('没有选择网络');
    }

    _isLoading = true;
    notifyListeners();

    try {
      // 从私钥生成当前网络的地址
      final address =
          await _generateAddressFromPrivateKey(privateKey, _currentNetwork!);

      // 添加地址到当前钱包的当前网络
      if (_currentWallet!.addresses[_currentNetwork!.id] == null) {
        _currentWallet!.addresses[_currentNetwork!.id] = [];
      }

      _currentWallet!.addresses[_currentNetwork!.id]!.add(address);

      // 更新地址索引
      _currentWallet!.addressIndexes[_currentNetwork!.id] =
          (_currentWallet!.addressIndexes[_currentNetwork!.id] ?? 0) + 1;

      // 如果提供了地址名字，保存它
      if (addressName.isNotEmpty) {
        _currentWallet!.addressNames[address] = addressName;
      }

      // 保存更新后的钱包（包括地址名字）
      await _storageService.updateWalletAddressesAndIndexes(
        _currentWallet!.id,
        _currentWallet!.addresses,
        _currentWallet!.addressIndexes,
        _currentWallet!.addressNames,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('添加私钥地址失败: $e');
    }
  }

  Future<String> _generateAddressFromPrivateKey(
      String privateKey, Network network) async {
    // 这是一个简化的实现
    // 在实际应用中，需要使用正确的加密库来从私钥生成地址
    // 这里返回一个模拟地址
    final cleanKey = privateKey.toLowerCase().replaceFirst('0x', '');

    // 安全检查：确保私钥长度足够
    if (cleanKey.length < 8) {
      throw Exception('私钥长度不足，无法生成地址');
    }

    final addressSuffix = cleanKey.substring(cleanKey.length - 8);

    switch (network.id) {
      case 'ethereum':
        return '0x${addressSuffix}1234567890123456789012345678';
      case 'bitcoin':
        return '1${addressSuffix}ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      case 'polygon':
        return '0x${addressSuffix}9876543210987654321098765432';
      case 'bsc':
        return '0x${addressSuffix}ABCDEF1234567890ABCDEF123456';
      default:
        return '0x${addressSuffix}0000000000000000000000000000';
    }
  }

  String _generateAddressFromPublicKey(List<int> publicKey) {
    // This is a simplified implementation
    // In a real app, you'd use proper cryptographic functions
    final hash = sha256.convert(publicKey).bytes;
    return '0x${HEX.encode(hash.sublist(12))}';
  }

  Future<String> _generateAddressForNetwork(
      String mnemonic, Network network) async {
    // Use AddressService to generate address
    return await AddressService.generateAddress(
      mnemonic: mnemonic,
      network: network.id,
      index: 0,
    );
  }

  /// Public method to generate address for a specific network
  Future<String> generateAddressForNetwork(
      String mnemonic, String networkId) async {
    final network = _supportedNetworks.firstWhere(
      (n) => n.id == networkId,
      orElse: () => throw Exception('Unsupported network: $networkId'),
    );
    return await _generateAddressForNetwork(mnemonic, network);
  }

  /// Public method to generate address for a specific network with index
  Future<String> generateAddressForNetworkWithIndex(
      String mnemonic, String networkId, int index) async {
    return await AddressService.generateAddress(
      mnemonic: mnemonic,
      network: networkId,
      index: index,
    );
  }

  void setCurrentWallet(Wallet wallet) {
    _currentWallet = wallet;
    _setDefaultSelectedAddress();
    notifyListeners();
  }

  void setCurrentNetwork(Network network) {
    _currentNetwork = network;
    _setDefaultSelectedAddress();
    notifyListeners();
  }

  /// Set the selected address
  void setSelectedAddress(String address) {
    _selectedAddress = address;
    notifyListeners();
  }

  /// Set the first address as default selected address for current network
  void _setDefaultSelectedAddress() {
    if (_currentWallet == null || _currentNetwork == null) {
      _selectedAddress = null;
      return;
    }
    final addressList = _currentWallet!.addresses[_currentNetwork!.id];
    if (addressList?.isNotEmpty == true) {
      _selectedAddress = addressList!.first;
    } else {
      _selectedAddress = null;
    }
  }

  /// Get current network address for the current wallet
  String? getCurrentNetworkAddress() {
    if (_currentWallet == null || _currentNetwork == null) {
      return null;
    }

    // 获取当前网络的地址列表
    final addressList = _currentWallet!.addresses[_currentNetwork!.id];
    if (addressList == null || addressList.isEmpty) {
      return null;
    }

    // 如果有选中的地址，检查它是否属于当前网络
    if (_selectedAddress != null && addressList.contains(_selectedAddress)) {
      return _selectedAddress;
    }

    // 否则返回第一个地址
    return addressList.first;
  }

  /// Get address for a specific network and wallet
  String? getAddressForNetwork(String walletId, String networkId) {
    final wallet = _wallets.firstWhere(
      (w) => w.id == walletId,
      orElse: () => throw Exception('Wallet not found'),
    );
    final addressList = wallet.addresses[networkId];
    return addressList?.isNotEmpty == true ? addressList!.first : null;
  }

  /// Get all addresses for current wallet
  Map<String, List<String>> getCurrentWalletAddresses() {
    return _currentWallet?.addresses ?? {};
  }

  Future<void> deleteWallet(String walletId) async {
    await _storageService.deleteWallet(walletId);
    _wallets.removeWhere((wallet) => wallet.id == walletId);

    if (_currentWallet?.id == walletId) {
      _currentWallet = _wallets.isNotEmpty ? _wallets.first : null;
    }

    notifyListeners();
  }

  /// Update wallet addresses in storage
  Future<void> updateWalletAddresses(
      String walletId, Map<String, List<String>> addresses) async {
    await _storageService.updateWalletAddresses(walletId, addresses);

    // Update local wallet object
    final walletIndex = _wallets.indexWhere((w) => w.id == walletId);
    if (walletIndex != -1) {
      final updatedWallet =
          _wallets[walletIndex].copyWith(addresses: addresses);
      _wallets[walletIndex] = updatedWallet;

      if (_currentWallet?.id == walletId) {
        _currentWallet = updatedWallet;
      }

      notifyListeners();
    }
  }

  /// Update wallet addresses and indexes in storage
  Future<void> updateWalletAddressesAndIndexes(String walletId,
      Map<String, List<String>> addresses, Map<String, int> addressIndexes,
      [Map<String, String>? addressNames]) async {
    await _storageService.updateWalletAddressesAndIndexes(
        walletId, addresses, addressIndexes, addressNames);

    // Update local wallet object
    final walletIndex = _wallets.indexWhere((w) => w.id == walletId);
    if (walletIndex != -1) {
      final updatedWallet = _wallets[walletIndex].copyWith(
        addresses: addresses,
        addressIndexes: addressIndexes,
        addressNames: addressNames ?? _wallets[walletIndex].addressNames,
      );
      _wallets[walletIndex] = updatedWallet;

      if (_currentWallet?.id == walletId) {
        _currentWallet = updatedWallet;
      }

      notifyListeners();
    }
  }

  /// Update wallet name in storage
  Future<void> updateWalletName(String walletId, String newName) async {
    await _storageService.updateWalletName(walletId, newName);

    // Update local wallet object
    final walletIndex = _wallets.indexWhere((w) => w.id == walletId);
    if (walletIndex != -1) {
      final updatedWallet = _wallets[walletIndex].copyWith(name: newName);
      _wallets[walletIndex] = updatedWallet;

      if (_currentWallet?.id == walletId) {
        _currentWallet = updatedWallet;
      }

      notifyListeners();
    }
  }

  // 更新地址名字
  Future<void> updateAddressName(String address, String newName) async {
    if (_currentWallet == null) {
      throw Exception('没有当前钱包');
    }

    _isLoading = true;
    notifyListeners();

    try {
      // 更新地址名字
      if (newName.isEmpty) {
        _currentWallet!.addressNames.remove(address);
      } else {
        _currentWallet!.addressNames[address] = newName;
      }

      // 保存到存储
      await _storageService.updateWalletAddressesAndIndexes(
        _currentWallet!.id,
        _currentWallet!.addresses,
        _currentWallet!.addressIndexes,
        _currentWallet!.addressNames,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('更新地址名字失败: $e');
    }
  }

  /// Clean mnemonic phrase by removing extra spaces and normalizing format
  String _cleanMnemonic(String mnemonic) {
    return mnemonic.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Check if a mnemonic has already been imported
  Future<bool> isMnemonicAlreadyImported(String mnemonic) async {
    try {
      final cleanedMnemonic = _cleanMnemonic(mnemonic);

      // Generate the first address for Ethereum network (as a unique identifier)
      final ethereumNetwork = _supportedNetworks.firstWhere(
        (network) => network.id == 'ethereum',
        orElse: () => _supportedNetworks.first,
      );

      final testAddress =
          await _generateAddressForNetwork(cleanedMnemonic, ethereumNetwork);

      // Check if any existing wallet has this address
      for (final wallet in _wallets) {
        final walletAddresses = wallet.addresses[ethereumNetwork.id];
        if (walletAddresses != null && walletAddresses.contains(testAddress)) {
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('Error checking mnemonic duplication: $e');
      return false;
    }
  }

  /// Get wallet name by mnemonic (if exists)
  Future<String?> getWalletNameByMnemonic(String mnemonic) async {
    try {
      final cleanedMnemonic = _cleanMnemonic(mnemonic);

      // Generate the first address for Ethereum network (as a unique identifier)
      final ethereumNetwork = _supportedNetworks.firstWhere(
        (network) => network.id == 'ethereum',
        orElse: () => _supportedNetworks.first,
      );

      final testAddress =
          await _generateAddressForNetwork(cleanedMnemonic, ethereumNetwork);

      // Find wallet with this address
      for (final wallet in _wallets) {
        final walletAddresses = wallet.addresses[ethereumNetwork.id];
        if (walletAddresses != null && walletAddresses.contains(testAddress)) {
          return wallet.name;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error getting wallet name by mnemonic: $e');
      return null;
    }
  }

  // RPC管理方法

  /// 获取网络的RPC URL列表
  List<String> getNetworkRpcUrls(String networkId) {
    final network = _supportedNetworks.firstWhere(
      (n) => n.id == networkId,
      orElse: () => throw Exception('Network not found: $networkId'),
    );
    return network.rpcUrls ?? [network.rpcUrl];
  }

  /// 更新网络的当前RPC URL
  void updateNetworkRpcUrl(String networkId, String newRpcUrl) {
    final networkIndex =
        _supportedNetworks.indexWhere((n) => n.id == networkId);
    if (networkIndex != -1) {
      _supportedNetworks[networkIndex] =
          _supportedNetworks[networkIndex].copyWith(
        rpcUrl: newRpcUrl,
      );

      // 如果是当前网络，更新当前网络
      if (_currentNetwork?.id == networkId) {
        _currentNetwork = _supportedNetworks[networkIndex];
      }

      notifyListeners();
    }
  }

  /// 添加自定义RPC URL到网络
  void addCustomRpcUrl(String networkId, String rpcUrl) {
    final networkIndex =
        _supportedNetworks.indexWhere((n) => n.id == networkId);
    if (networkIndex != -1) {
      final network = _supportedNetworks[networkIndex];
      final updatedRpcUrls =
          List<String>.from(network.rpcUrls ?? [network.rpcUrl]);

      if (!updatedRpcUrls.contains(rpcUrl)) {
        updatedRpcUrls.add(rpcUrl);

        _supportedNetworks[networkIndex] = network.copyWith(
          rpcUrls: updatedRpcUrls,
        );

        // 如果是当前网络，更新当前网络
        if (_currentNetwork?.id == networkId) {
          _currentNetwork = _supportedNetworks[networkIndex];
        }

        notifyListeners();
      }
    }
  }

  /// 移除自定义RPC URL
  void removeCustomRpcUrl(String networkId, String rpcUrl) {
    final networkIndex =
        _supportedNetworks.indexWhere((n) => n.id == networkId);
    if (networkIndex != -1) {
      final network = _supportedNetworks[networkIndex];
      final updatedRpcUrls =
          List<String>.from(network.rpcUrls ?? [network.rpcUrl]);

      // 不能删除默认的RPC URL
      if (rpcUrl != network.rpcUrl && updatedRpcUrls.contains(rpcUrl)) {
        updatedRpcUrls.remove(rpcUrl);

        _supportedNetworks[networkIndex] = network.copyWith(
          rpcUrls: updatedRpcUrls,
        );

        // 如果是当前网络，更新当前网络
        if (_currentNetwork?.id == networkId) {
          _currentNetwork = _supportedNetworks[networkIndex];
        }

        notifyListeners();
      }
    }
  }

  /// 测试RPC URL连接
  Future<bool> testRpcConnection(String rpcUrl) async {
    try {
      // 这里应该实现实际的RPC连接测试
      // 暂时返回true作为占位符
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      debugPrint('RPC connection test failed: $e');
      return false;
    }
  }

  /// 重试机制包装器
  Future<T> _retryOperation<T>(Future<T> Function() operation,
      {int maxRetries = 3}) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          rethrow;
        }
        // 指数退避：等待时间随重试次数增加
        await Future.delayed(Duration(milliseconds: 1000 * attempts));
        debugPrint('重试第 $attempts 次，错误: $e');
      }
    }
    throw Exception('重试次数已达上限');
  }

  /// 获取指定网络的余额
  Future<double> getNetworkBalance(String networkId, {String? rpcUrl}) async {
    try {
      // 使用重试机制调用相应的链上查询方法
      return await _retryOperation(() async {
        switch (networkId) {
          case 'ethereum':
            return await _getEthereumBalance(networkId, rpcUrl: rpcUrl);
          case 'polygon':
            return await _getPolygonBalance(networkId, rpcUrl: rpcUrl);
          case 'bsc':
            return await _getBscBalance(networkId, rpcUrl: rpcUrl);
          case 'bitcoin':
            return await _getBitcoinBalance(networkId, rpcUrl: rpcUrl);
          case 'solana':
            return await _getSolanaBalance(networkId, rpcUrl: rpcUrl);
          case 'tron':
            return await _getTronBalance(networkId, rpcUrl: rpcUrl);
          default:
            return 0.0;
        }
      });
    } catch (e) {
      debugPrint('获取余额失败: $e');
      return 0.0;
    }
  }

  /// 获取指定地址在指定网络的余额（不改变所选地址，不触发通知）
  Future<double> getNetworkBalanceForAddress(
    String networkId,
    String address, {
    String? rpcUrl,
  }) async {
    try {
      return await _retryOperation(() async {
        switch (networkId) {
          case 'ethereum':
            return await _getEthereumBalanceForAddress(networkId, address,
                rpcUrl: rpcUrl);
          case 'polygon':
            return await _getPolygonBalanceForAddress(networkId, address,
                rpcUrl: rpcUrl);
          case 'bsc':
            return await _getBscBalanceForAddress(networkId, address,
                rpcUrl: rpcUrl);
          case 'bitcoin':
            return await _getBitcoinBalanceForAddress(networkId, address,
                rpcUrl: rpcUrl);
          case 'solana':
            return await _getSolanaBalanceForAddress(networkId, address,
                rpcUrl: rpcUrl);
          case 'tron':
            return await _getTronBalanceForAddress(networkId, address,
                rpcUrl: rpcUrl);
          default:
            return 0.0;
        }
      });
    } catch (e) {
      debugPrint('获取按地址余额失败: $e');
      return 0.0;
    }
  }

  /// 获取以太坊余额
  Future<double> _getEthereumBalance(String networkId, {String? rpcUrl}) async {
    try {
      // 优先使用当前网络（如果匹配），否则查找指定网络
      final network = _currentNetwork?.id == networkId
          ? _currentNetwork!
          : _supportedNetworks.firstWhere((n) => n.id == networkId);

      // 使用传入的rpcUrl或网络默认的rpcUrl
      final effectiveRpcUrl = rpcUrl ?? network.rpcUrl;
      final client = web3.Web3Client(effectiveRpcUrl, http.Client());

      // 获取以太坊网络的地址
      final ethereumAddress =
          _currentWallet?.addresses[networkId]?.isNotEmpty == true
              ? _currentWallet!.addresses[networkId]!.first
              : null;

      if (ethereumAddress == null) {
        debugPrint('以太坊地址不存在');
        return 0.0;
      }

      // 打印请求数据
      debugPrint('=== 以太坊余额查询请求 ===');
      debugPrint('RPC URL: $effectiveRpcUrl');
      debugPrint('钱包地址: $ethereumAddress');
      debugPrint('请求方法: eth_getBalance');

      final address = web3.EthereumAddress.fromHex(ethereumAddress);
      final balance = await client.getBalance(address);

      // 将Wei转换为ETH
      final ethBalance = balance.getValueInUnit(web3.EtherUnit.ether);

      debugPrint('响应余额: $ethBalance ETH');
      debugPrint('========================');

      client.dispose();
      return ethBalance;
    } catch (e) {
      debugPrint('获取以太坊余额失败: $e');
      return 0.0;
    }
  }

  Future<double> _getEthereumBalanceForAddress(
      String networkId, String addressHex,
      {String? rpcUrl}) async {
    try {
      final network = _currentNetwork?.id == networkId
          ? _currentNetwork!
          : _supportedNetworks.firstWhere((n) => n.id == networkId);
      final effectiveRpcUrl = rpcUrl ?? network.rpcUrl;
      final client = web3.Web3Client(effectiveRpcUrl, http.Client());

      debugPrint('=== 以太坊余额查询(按地址) ===');
      debugPrint('RPC URL: $effectiveRpcUrl');
      debugPrint('钱包地址: $addressHex');
      final address = web3.EthereumAddress.fromHex(addressHex);
      final balance = await client.getBalance(address);
      final ethBalance = balance.getValueInUnit(web3.EtherUnit.ether);
      client.dispose();
      return ethBalance;
    } catch (e) {
      debugPrint('获取以太坊余额(按地址)失败: $e');
      return 0.0;
    }
  }

  /// 获取Polygon余额
  Future<double> _getPolygonBalance(String networkId, {String? rpcUrl}) async {
    try {
      // 优先使用当前网络（如果匹配），否则查找指定网络
      final network = _currentNetwork?.id == networkId
          ? _currentNetwork!
          : _supportedNetworks.firstWhere((n) => n.id == networkId);

      // 使用传入的rpcUrl或网络默认的rpcUrl
      final effectiveRpcUrl = rpcUrl ?? network.rpcUrl;
      final client = web3.Web3Client(effectiveRpcUrl, http.Client());

      // 获取Polygon网络的地址
      final polygonAddress =
          _currentWallet?.addresses[networkId]?.isNotEmpty == true
              ? _currentWallet!.addresses[networkId]!.first
              : null;

      if (polygonAddress == null) {
        debugPrint('Polygon地址不存在');
        return 0.0;
      }

      // 打印请求数据
      debugPrint('=== Polygon余额查询请求 ===');
      debugPrint('RPC URL: $effectiveRpcUrl');
      debugPrint('钱包地址: $polygonAddress');
      debugPrint('请求方法: eth_getBalance');

      final address = web3.EthereumAddress.fromHex(polygonAddress);
      final balance = await client.getBalance(address);

      // 将Wei转换为MATIC
      final maticBalance = balance.getValueInUnit(web3.EtherUnit.ether);

      debugPrint('响应余额: $maticBalance MATIC');
      debugPrint('=========================');

      client.dispose();
      return maticBalance;
    } catch (e) {
      debugPrint('获取Polygon余额失败: $e');
      return 0.0;
    }
  }

  Future<double> _getPolygonBalanceForAddress(
      String networkId, String addressHex,
      {String? rpcUrl}) async {
    try {
      final network = _currentNetwork?.id == networkId
          ? _currentNetwork!
          : _supportedNetworks.firstWhere((n) => n.id == networkId);
      final effectiveRpcUrl = rpcUrl ?? network.rpcUrl;
      final client = web3.Web3Client(effectiveRpcUrl, http.Client());

      debugPrint('=== Polygon余额查询(按地址) ===');
      debugPrint('RPC URL: $effectiveRpcUrl');
      debugPrint('钱包地址: $addressHex');
      final address = web3.EthereumAddress.fromHex(addressHex);
      final balance = await client.getBalance(address);
      final maticBalance = balance.getValueInUnit(web3.EtherUnit.ether);
      client.dispose();
      return maticBalance;
    } catch (e) {
      debugPrint('获取Polygon余额(按地址)失败: $e');
      return 0.0;
    }
  }

  /// 获取BSC余额
  Future<double> _getBscBalance(String networkId, {String? rpcUrl}) async {
    try {
      // 优先使用当前网络（如果匹配），否则查找指定网络
      final network = _currentNetwork?.id == networkId
          ? _currentNetwork!
          : _supportedNetworks.firstWhere((n) => n.id == networkId);

      // 使用传入的rpcUrl或网络默认的rpcUrl
      final effectiveRpcUrl = rpcUrl ?? network.rpcUrl;
      final client = web3.Web3Client(effectiveRpcUrl, http.Client());

      // 获取BSC网络的地址
      final bscAddress =
          _currentWallet?.addresses[networkId]?.isNotEmpty == true
              ? _currentWallet!.addresses[networkId]!.first
              : null;

      if (bscAddress == null) {
        debugPrint('BSC地址不存在');
        return 0.0;
      }

      // 打印请求数据
      debugPrint('=== BSC余额查询请求 ===');
      debugPrint('RPC URL: $effectiveRpcUrl');
      debugPrint('钱包地址: $bscAddress');
      debugPrint('请求方法: eth_getBalance');

      final address = web3.EthereumAddress.fromHex(bscAddress);
      final balance = await client.getBalance(address);

      // 将Wei转换为BNB
      final bnbBalance = balance.getValueInUnit(web3.EtherUnit.ether);

      debugPrint('响应余额: $bnbBalance BNB');
      debugPrint('====================');

      client.dispose();
      return bnbBalance;
    } catch (e) {
      debugPrint('获取BSC余额失败: $e');
      return 0.0;
    }
  }

  Future<double> _getBscBalanceForAddress(String networkId, String addressHex,
      {String? rpcUrl}) async {
    try {
      final network = _currentNetwork?.id == networkId
          ? _currentNetwork!
          : _supportedNetworks.firstWhere((n) => n.id == networkId);
      final effectiveRpcUrl = rpcUrl ?? network.rpcUrl;
      final client = web3.Web3Client(effectiveRpcUrl, http.Client());

      debugPrint('=== BSC余额查询(按地址) ===');
      debugPrint('RPC URL: $effectiveRpcUrl');
      debugPrint('钱包地址: $addressHex');
      final address = web3.EthereumAddress.fromHex(addressHex);
      final balance = await client.getBalance(address);
      final bnbBalance = balance.getValueInUnit(web3.EtherUnit.ether);
      client.dispose();
      return bnbBalance;
    } catch (e) {
      debugPrint('获取BSC余额(按地址)失败: $e');
      return 0.0;
    }
  }

  /// 获取比特币余额
  Future<double> _getBitcoinBalance(String networkId, {String? rpcUrl}) async {
    try {
      // 优先使用当前网络（如果匹配），否则查找指定网络
      final network = _currentNetwork?.id == networkId
          ? _currentNetwork!
          : _supportedNetworks.firstWhere((n) => n.id == networkId);

      // 获取比特币网络的地址
      final bitcoinAddress =
          _currentWallet?.addresses[networkId]?.isNotEmpty == true
              ? _currentWallet!.addresses[networkId]!.first
              : null;

      if (bitcoinAddress == null) {
        debugPrint('比特币地址不存在');
        return 0.0;
      }

      // 使用传入的rpcUrl或网络默认的rpcUrl
      final effectiveRpcUrl = rpcUrl ?? network.rpcUrl;
      final apiUrl = '$effectiveRpcUrl/address/$bitcoinAddress';

      // 打印请求数据
      debugPrint('=== 比特币余额查询请求 ===');
      debugPrint('API URL: $apiUrl');
      debugPrint('钱包地址: $bitcoinAddress');
      debugPrint('请求方法: GET');
      debugPrint('请求头: Content-Type: application/json');

      // 使用Blockstream API查询比特币余额
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      debugPrint('响应状态码: ${response.statusCode}');
      debugPrint('响应数据: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['chain_stats'] != null &&
            data['chain_stats']['funded_txo_sum'] != null) {
          // 比特币余额以satoshi为单位，1 BTC = 100,000,000 satoshi
          final satoshi = data['chain_stats']['funded_txo_sum'] as int;
          final spent = data['chain_stats']['spent_txo_sum'] as int? ?? 0;
          final balance = satoshi - spent;
          final btcBalance = balance / 100000000.0;

          debugPrint('响应余额: $btcBalance BTC');
          debugPrint('======================');

          return btcBalance;
        }
      }

      debugPrint('======================');
      return 0.0;
    } catch (e) {
      debugPrint('获取比特币余额失败: $e');
      return 0.0;
    }
  }

  Future<double> _getBitcoinBalanceForAddress(String networkId, String address,
      {String? rpcUrl}) async {
    try {
      final network = _currentNetwork?.id == networkId
          ? _currentNetwork!
          : _supportedNetworks.firstWhere((n) => n.id == networkId);
      final effectiveRpcUrl = rpcUrl ?? network.rpcUrl;
      final apiUrl = '$effectiveRpcUrl/address/$address';

      debugPrint('=== 比特币余额查询(按地址) ===');
      debugPrint('API URL: $apiUrl');
      debugPrint('钱包地址: $address');

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['chain_stats'] != null &&
            data['chain_stats']['funded_txo_sum'] != null) {
          final satoshi = data['chain_stats']['funded_txo_sum'] as int;
          final spent = data['chain_stats']['spent_txo_sum'] as int? ?? 0;
          final btcBalance = (satoshi - spent) / 100000000.0;
          return btcBalance;
        }
      }
      return 0.0;
    } catch (e) {
      debugPrint('获取比特币余额(按地址)失败: $e');
      return 0.0;
    }
  }

  /// 获取Solana余额
  Future<double> _getSolanaBalance(String networkId, {String? rpcUrl}) async {
    try {
      // 优先使用当前网络（如果匹配），否则查找指定网络
      final network = _currentNetwork?.id == networkId
          ? _currentNetwork!
          : _supportedNetworks.firstWhere((n) => n.id == networkId);

      // 使用传入的rpcUrl或网络默认的rpcUrl
      final effectiveRpcUrl = rpcUrl ?? network.rpcUrl;

      // 获取Solana网络的地址
      final solanaAddress =
          _currentWallet?.addresses[networkId]?.isNotEmpty == true
              ? _currentWallet!.addresses[networkId]!.first
              : null;

      if (solanaAddress == null) {
        debugPrint('Solana地址不存在');
        return 0.0;
      }

      // 使用SolanaWalletService获取余额
      _solanaWalletService ??= SolanaWalletService(effectiveRpcUrl);

      debugPrint('=== Solana余额查询请求 ===');
      debugPrint('RPC URL: $effectiveRpcUrl');
      debugPrint('钱包地址: $solanaAddress');

      final balance = await _solanaWalletService!.getBalance(solanaAddress);

      debugPrint('响应余额: $balance SOL');
      debugPrint('========================');

      return balance;
    } catch (e) {
      debugPrint('获取Solana余额失败: $e');
      return 0.0;
    }
  }

  Future<double> _getSolanaBalanceForAddress(String networkId, String address,
      {String? rpcUrl}) async {
    try {
      final network = _currentNetwork?.id == networkId
          ? _currentNetwork!
          : _supportedNetworks.firstWhere((n) => n.id == networkId);
      final effectiveRpcUrl = rpcUrl ?? network.rpcUrl;
      _solanaWalletService ??= SolanaWalletService(effectiveRpcUrl);
      final balance = await _solanaWalletService!.getBalance(address);
      return balance;
    } catch (e) {
      debugPrint('获取Solana余额(按地址)失败: $e');
      return 0.0;
    }
  }

  /// 获取TRON余额
  Future<double> _getTronBalance(String networkId, {String? rpcUrl}) async {
    try {
      final network = _currentNetwork?.id == networkId
          ? _currentNetwork!
          : _supportedNetworks.firstWhere((n) => n.id == networkId);

      final effectiveRpcUrl = rpcUrl ?? network.rpcUrl;
      final tronAddress =
          _currentWallet?.addresses[networkId]?.isNotEmpty == true
              ? _currentWallet!.addresses[networkId]!.first
              : null;

      if (tronAddress == null) {
        debugPrint('TRON地址不存在');
        return 0.0;
      }

      debugPrint('=== TRON余额查询请求 ===');
      debugPrint('RPC URL: $effectiveRpcUrl');
      debugPrint('钱包地址: $tronAddress');
      debugPrint('请求方法: GET /v1/accounts/{address}');

      final uri = Uri.parse('$effectiveRpcUrl/v1/accounts/$tronAddress');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final accounts = data['data'];
        if (accounts is List && accounts.isNotEmpty) {
          final account = accounts[0] as Map<String, dynamic>;
          final balanceSun = (account['balance'] ?? 0) as int;
          final balanceTrx = balanceSun / NetworkConstants.tronDecimalFactor;
          debugPrint('响应余额: $balanceTrx TRX');
          debugPrint('========================');
          return balanceTrx;
        }
      }

      debugPrint('TRON余额查询失败: ${response.statusCode} ${response.body}');
      return 0.0;
    } catch (e) {
      debugPrint('获取TRON余额失败: $e');
      return 0.0;
    }
  }

  /// 获取TRON余额（按地址）
  Future<double> _getTronBalanceForAddress(String networkId, String address,
      {String? rpcUrl}) async {
    try {
      final network = _currentNetwork?.id == networkId
          ? _currentNetwork!
          : _supportedNetworks.firstWhere((n) => n.id == networkId);
      final effectiveRpcUrl = rpcUrl ?? network.rpcUrl;

      debugPrint('=== TRON余额查询(按地址) ===');
      debugPrint('RPC URL: $effectiveRpcUrl');
      debugPrint('钱包地址: $address');

      final uri = Uri.parse('$effectiveRpcUrl/v1/accounts/$address');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final accounts = data['data'];
        if (accounts is List && accounts.isNotEmpty) {
          final account = accounts[0] as Map<String, dynamic>;
          final balanceSun = (account['balance'] ?? 0) as int;
          final balanceTrx = balanceSun / NetworkConstants.tronDecimalFactor;
          return balanceTrx;
        }
      }
      return 0.0;
    } catch (e) {
      debugPrint('获取TRON余额(按地址)失败: $e');
      return 0.0;
    }
  }

  /// 获取 TRC20 代币余额
  Future<double> getTRC20Balance({
    required String contractAddress,
    required int decimals,
    String? rpcUrl,
  }) async {
    try {
      if (_currentWallet == null) return 0.0;

      final network = _supportedNetworks.firstWhere((n) => n.id == 'tron');
      final effectiveRpcUrl = rpcUrl ?? network.rpcUrl;

      // 直接从 TRON 网络获取地址，而不是使用当前选中的网络地址
      final tronAddresses = _currentWallet!.addresses['tron'];
      if (tronAddresses == null || tronAddresses.isEmpty) {
        debugPrint('当前钱包没有 TRON 地址');
        return 0.0;
      }

      final ownerAddress = tronAddresses.first;
      debugPrint('查询 TRC20 余额 - 地址: $ownerAddress, 合约: $contractAddress');

      final balance = await TRC20Service.getBalance(
        contractAddress: contractAddress,
        ownerAddress: ownerAddress,
        tronRpcBaseUrl: effectiveRpcUrl,
        decimals: decimals,
      );

      debugPrint('TRC20 余额查询结果: $balance');
      return balance;
    } catch (e) {
      debugPrint('获取 TRC20 余额失败: $e');
      return 0.0;
    }
  }

  /// 发送 TRC20 代币
  Future<String> sendTRC20Token({
    required String contractAddress,
    required String toAddress,
    required double amount,
    required int decimals,
    required String password,
    String? rpcUrl,
  }) async {
    if (_currentWallet == null) {
      throw Exception('没有当前钱包');
    }

    try {
      final network = _supportedNetworks.firstWhere((n) => n.id == 'tron');
      final effectiveRpcUrl = rpcUrl ?? network.rpcUrl;

      // 获取助记词
      final mnemonic = await getWalletMnemonic(_currentWallet!.id, password);
      if (mnemonic == null) {
        throw Exception('无法获取钱包助记词');
      }

      // 获取 TRON 网络的地址列表
      final addresses = _currentWallet!.addresses['tron'];
      if (addresses == null || addresses.isEmpty) {
        throw Exception('当前钱包没有TRON地址');
      }

      // 确定使用哪个地址和索引
      int addressIndex = 0;
      String fromAddress = addresses.first;

      // 如果选中的地址在 TRON 地址列表中，使用选中的地址
      if (_selectedAddress != null && addresses.contains(_selectedAddress)) {
        fromAddress = _selectedAddress!;
        addressIndex = addresses.indexOf(_selectedAddress!);
      }

      debugPrint('=== TRC20 代币转账 ===');
      debugPrint('合约地址: $contractAddress');
      debugPrint('发送地址: $fromAddress');
      debugPrint('接收地址: $toAddress');
      debugPrint('金额: $amount');

      // 清理地址
      final cleanToAddress = toAddress.trim();
      final cleanFromAddress = fromAddress.trim();

      // 预校验：根据助记词与索引推导地址并与选中地址比对
      try {
        final preDerived = await generateAddressForNetworkWithIndex(
          mnemonic,
          'tron',
          addressIndex,
        );
        debugPrint('签名地址预校验(TRC20): 推导地址 ' + preDerived + ', 选中地址 ' + cleanFromAddress);
        if (preDerived != cleanFromAddress) {
          debugPrint('错误(TRC20): 选中地址与推导地址不一致，可能索引错位或网络切换未同步');
        }
      } catch (e) {
        debugPrint('签名地址预校验(TRC20)失败: $e');
      }

      // 地址校验
      if (!AddressService.validateAddress(cleanToAddress, 'tron')) {
        throw Exception('收款地址格式无效: $cleanToAddress');
      }

      if (!AddressService.validateAddress(cleanFromAddress, 'tron')) {
        throw Exception('当前钱包TRON地址格式无效: $cleanFromAddress');
      }

      // 发送 TRC20 转账
      final txId = await TRC20Service.transfer(
        mnemonic: mnemonic,
        addressIndex: addressIndex,
        contractAddress: contractAddress,
        fromAddress: cleanFromAddress,
        toAddress: cleanToAddress,
        amount: amount,
        decimals: decimals,
        tronRpcBaseUrl: effectiveRpcUrl,
      );

      return txId;
    } catch (e) {
      debugPrint('TRC20 转账失败: $e');
      rethrow;
    }
  }

  /// 获取Solana网络状态
  Future<Map<String, dynamic>> getSolanaNetworkStatus() async {
    if (_solanaWalletService == null) {
      return {'error': 'Solana服务未初始化'};
    }
    return await _solanaWalletService!.getNetworkStatus();
  }

  /// 获取Solana交易费用预估
  Future<Map<SolanaTransactionPriority, SolanaTransactionFee>>
      getSolanaFeeEstimates({
    required String toAddress,
    required double amount,
  }) async {
    if (_currentWallet?.mnemonic == null || _solanaWalletService == null) {
      throw Exception('钱包或Solana服务未初始化');
    }

    return await _solanaWalletService!.getAllPriorityFees(
      mnemonic: _currentWallet!.mnemonic,
      toAddress: toAddress,
      amount: amount,
    );
  }

  /// 发送Solana交易
  Future<SolanaTransaction> sendSolanaTransaction({
    required String toAddress,
    required double amount,
    required SolanaTransactionPriority priority,
    String? memo,
    int? customComputeUnits,
    int? customComputeUnitPrice,
  }) async {
    if (_currentWallet?.mnemonic == null || _solanaWalletService == null) {
      throw Exception('钱包或Solana服务未初始化');
    }

    final fromAddress = getCurrentNetworkAddress();
    if (fromAddress == null) {
      throw Exception('无法获取发送地址');
    }

    return await _solanaWalletService!.sendSolTransfer(
      mnemonic: _currentWallet!.mnemonic,
      fromAddress: fromAddress,
      toAddress: toAddress,
      amount: amount,
      priority: priority,
      memo: memo,
      customComputeUnits: customComputeUnits,
      customComputeUnitPrice: customComputeUnitPrice,
    );
  }

  /// 优化Solana交易费用
  Future<SolanaTransactionFee> optimizeSolanaFee({
    required String toAddress,
    required double amount,
    required double maxFeeInSol,
  }) async {
    if (_currentWallet?.mnemonic == null || _solanaWalletService == null) {
      throw Exception('钱包或Solana服务未初始化');
    }

    return await _solanaWalletService!.optimizeTransactionFee(
      mnemonic: _currentWallet!.mnemonic,
      toAddress: toAddress,
      amount: amount,
      maxFeeInSol: maxFeeInSol,
    );
  }

  /// 预测Solana交易确认时间
  Future<Map<SolanaTransactionPriority, Duration>>
      predictSolanaConfirmationTimes() async {
    if (_solanaWalletService == null) {
      throw Exception('Solana服务未初始化');
    }

    return await _solanaWalletService!.predictConfirmationTimes();
  }

  /// 发送Solana交易并实时监控费用
  Future<Stream<SolanaTransaction>> sendSolanaTransactionWithMonitoring({
    required String toAddress,
    required double amount,
    required SolanaTransactionPriority priority,
    String? memo,
    int? customComputeUnits,
    int? customComputeUnitPrice,
  }) async {
    if (_currentWallet?.mnemonic == null ||
        _solanaWalletService == null ||
        _solanaTransactionMonitor == null) {
      throw Exception('钱包或Solana服务未初始化');
    }

    final fromAddress = getCurrentNetworkAddress();
    if (fromAddress == null) {
      throw Exception('无法获取发送地址');
    }

    // 发送交易
    final transaction = await _solanaWalletService!.sendSolTransfer(
      mnemonic: _currentWallet!.mnemonic,
      fromAddress: fromAddress,
      toAddress: toAddress,
      amount: amount,
      priority: priority,
      memo: memo,
      customComputeUnits: customComputeUnits,
      customComputeUnitPrice: customComputeUnitPrice,
    );

    // 开始监控交易，返回实时更新流
    return _solanaTransactionMonitor!.monitorTransaction(transaction);
  }

  /// 监控现有的Solana交易
  Stream<SolanaTransaction> monitorSolanaTransaction(
      SolanaTransaction transaction) {
    if (_solanaTransactionMonitor == null) {
      throw Exception('Solana交易监控服务未初始化');
    }
    return _solanaTransactionMonitor!.monitorTransaction(transaction);
  }

  /// 停止监控Solana交易
  void stopMonitoringSolanaTransaction(String signature) {
    _solanaTransactionMonitor?.stopMonitoring(signature);
  }

  /// 发送交易
  Future<String> sendTransaction({
    required String toAddress,
    required double amount,
    required String networkId,
    String? memo,
    String? rpcUrl,
    required String password,
    double? priorityFeeMultiplier,
  }) async {
    if (_currentWallet == null) {
      throw Exception('没有当前钱包');
    }

    // 检查余额
    final balance = await getNetworkBalance(networkId, rpcUrl: rpcUrl);
    const estimatedFee = 0.001; // 模拟手续费

    if (balance < amount + estimatedFee) {
      throw Exception('余额不足（当前余额: ${balance.toStringAsFixed(6)}）');
    }

    // 使用指定的RPC URL或默认URL
    final network = _supportedNetworks.firstWhere((n) => n.id == networkId);
    final effectiveRpcUrl = rpcUrl ?? network.rpcUrl;

    // 根据网络类型发送交易
    switch (networkId) {
      case 'solana':
        return await _sendSolanaTransaction(
          toAddress: toAddress,
          amount: amount,
          rpcUrl: effectiveRpcUrl,
          password: password,
          memo: memo,
          priorityFeeMultiplier: priorityFeeMultiplier ?? 1.0,
        );
      case 'ethereum':
      case 'polygon':
      case 'bsc':
        return await _sendEVMTransaction(
          toAddress: toAddress,
          amount: amount,
          networkId: networkId,
          rpcUrl: effectiveRpcUrl,
          password: password,
        );
      case 'bitcoin':
        return await _sendBitcoinTransaction(
          toAddress: toAddress,
          amount: amount,
          rpcUrl: effectiveRpcUrl,
          password: password,
        );
      case 'tron':
        // 使用TRON测试网RPC发送交易（带地址校验与备用RPC重试）
        final mnemonic = await getWalletMnemonic(_currentWallet!.id, password);
        if (mnemonic == null) {
          throw Exception('无法获取钱包助记词');
        }

        // 获取 TRON 网络的地址列表
        final addresses = _currentWallet!.addresses[networkId];
        if (addresses == null || addresses.isEmpty) {
          throw Exception('当前钱包没有TRON地址');
        }

        // 确定使用哪个地址和索引
        int addressIndex = 0;
        String fromAddress = addresses.first;

        // 如果选中的地址在 TRON 地址列表中，使用选中的地址
        if (_selectedAddress != null && addresses.contains(_selectedAddress)) {
          fromAddress = _selectedAddress!;
          addressIndex = addresses.indexOf(_selectedAddress!);
        }

        debugPrint('=== TRON 交易发送 ===');
        debugPrint('网络ID: $networkId');
        debugPrint('发送地址: $fromAddress');
        debugPrint('地址索引: $addressIndex');
        debugPrint('TRON地址列表: $addresses');

        // 清理地址（去除空格和换行符）
        final cleanToAddress = toAddress.trim();
        final cleanFromAddress = fromAddress.trim();

        // 预校验：根据助记词与索引推导地址并与选中地址比对
        try {
          final preDerived = await generateAddressForNetworkWithIndex(
            mnemonic,
            'tron',
            addressIndex,
          );
          debugPrint('签名地址预校验: 推导地址 $preDerived, 选中地址 $cleanFromAddress');
          if (preDerived != cleanFromAddress) {
            debugPrint('错误: 选中地址与推导地址不一致，可能索引错位或网络切换未同步');
          }
        } catch (e) {
          debugPrint('签名地址预校验失败: $e');
        }

        // 基本地址校验
        debugPrint('验证收款地址: $cleanToAddress (长度: ${cleanToAddress.length})');
        if (!AddressService.validateAddress(cleanToAddress, 'tron')) {
          throw Exception('收款地址格式无效: $cleanToAddress');
        }

        debugPrint(
            '验证发送地址: $cleanFromAddress (长度: ${cleanFromAddress.length})');
        if (!AddressService.validateAddress(cleanFromAddress, 'tron')) {
          throw Exception('当前钱包TRON地址格式无效: $cleanFromAddress');
        }

        // 组合候选RPC列表
        final List<String> rpcCandidates = [
          effectiveRpcUrl,
          ...network.rpcUrls.where((u) => u != effectiveRpcUrl),
        ];

        Exception? lastError;
        for (final baseUrl in rpcCandidates) {
          try {
            debugPrint('尝试使用TRON RPC: $baseUrl');
            final txId = await TronService.sendTrxTransfer(
              mnemonic: mnemonic,
              addressIndex: addressIndex,
              fromAddress: cleanFromAddress,
              toAddress: cleanToAddress,
              amountTRX: amount,
              tronRpcBaseUrl: baseUrl,
            );
            return txId;
          } catch (e) {
            debugPrint('TRON发送失败，切换备用RPC: $e');
            lastError = e is Exception ? e : Exception(e.toString());
          }
        }
        throw lastError ?? Exception('TRON交易发送失败（所有RPC均不可用）');
      default:
        throw Exception('不支持的网络: $networkId');
    }
  }

  /// 发送Solana交易
  Future<String> _sendSolanaTransaction({
    required String toAddress,
    required double amount,
    required String rpcUrl,
    required String password,
    String? memo,
    double priorityFeeMultiplier = 1.0,
  }) async {
    if (_currentWallet == null) {
      throw Exception('当前钱包为空');
    }

    if (_solanaWalletService == null) {
      throw Exception('Solana服务未初始化');
    }

    debugPrint('=== 开始发送Solana交易 ===');
    debugPrint('目标地址: $toAddress');
    debugPrint('转账金额: $amount SOL');
    debugPrint('RPC地址: $rpcUrl');
    debugPrint('备注信息: $memo');
    debugPrint('优先费倍数: ${priorityFeeMultiplier}x');

    if (_currentNetwork?.id != 'solana') {
      throw Exception('当前网络不是Solana网络');
    }

    try {
      debugPrint('开始验证和准备Solana交易...');

      if (toAddress.isEmpty) {
        throw Exception('接收地址不能为空');
      }

      if (amount <= 0) {
        throw Exception('转账金额必须大于0');
      }

      debugPrint('交易参数验证通过');

      // 获取助记词
      final mnemonic = await getWalletMnemonic(_currentWallet!.id, password);
      if (mnemonic == null) {
        throw Exception('无法获取钱包助记词');
      }

      // 获取发送方地址
      final fromAddress = getCurrentNetworkAddress();
      if (fromAddress == null) {
        throw Exception('无法获取发送地址');
      }

      // 确定交易优先级
      SolanaTransactionPriority priority;
      if (priorityFeeMultiplier <= 1.0) {
        priority = SolanaTransactionPriority.low;
      } else if (priorityFeeMultiplier <= 1.5) {
        priority = SolanaTransactionPriority.medium;
      } else if (priorityFeeMultiplier <= 2.0) {
        priority = SolanaTransactionPriority.high;
      } else {
        priority = SolanaTransactionPriority.veryHigh;
      }

      debugPrint('使用Solana钱包服务发送交易...');

      // 使用SolanaWalletService发送SOL转账
      final transaction = await _solanaWalletService!.sendSolTransfer(
        mnemonic: mnemonic,
        fromAddress: fromAddress,
        toAddress: toAddress,
        amount: amount,
        priority: priority,
        memo: memo,
      );

      debugPrint('=== Solana交易发送成功 ===');
      debugPrint('交易ID: ${transaction.id}');
      debugPrint('交易签名: ${transaction.signature}');
      debugPrint('交易状态: ${transaction.statusDescription}');

      // 返回交易签名
      final signature = transaction.signature ?? transaction.id;

      debugPrint('=== 交易发送完成 ===');
      debugPrint('交易签名: $signature');
      debugPrint(
          '可在Solana Explorer查看: https://explorer.solana.com/tx/$signature?cluster=devnet');

      return signature;
    } catch (e) {
      debugPrint('=== Solana交易发送失败 ===');
      debugPrint('错误类型: ${e.runtimeType}');
      debugPrint('错误详情: $e');
      throw Exception('发送Solana交易失败: $e');
    }
  }

  /// 发送EVM交易（以太坊、Polygon、BSC）
  Future<String> _sendEVMTransaction({
    required String toAddress,
    required double amount,
    required String networkId,
    required String rpcUrl,
    required String password,
  }) async {
    try {
      debugPrint('=== EVM交易发送开始 ===');
      debugPrint('网络: $networkId');
      debugPrint('RPC URL: $rpcUrl');
      debugPrint('接收地址: $toAddress');
      debugPrint('发送金额: $amount');

      // 获取助记词
      final mnemonic = await getWalletMnemonic(_currentWallet!.id, password);
      if (mnemonic == null) {
        throw Exception('无法获取钱包助记词');
      }

      // 创建Web3客户端
      final client = web3.Web3Client(rpcUrl, http.Client());

      // 从助记词生成私钥 - 使用正确的BIP44派生路径
      final seed = bip39.mnemonicToSeed(mnemonic);
      final root = bip32.BIP32.fromSeed(seed);

      // 获取当前选中地址的索引
      int addressIndex = 0;
      if (_selectedAddress != null &&
          _currentWallet != null &&
          _currentNetwork != null) {
        final addressList = _currentWallet!.addresses[_currentNetwork!.id];
        if (addressList != null) {
          final index = addressList.indexOf(_selectedAddress!);
          if (index >= 0) {
            addressIndex = index;
          }
        }
      }

      // 使用公共的派生路径和对应的地址索引
      final derivationPath = DerivationPaths.ethereumWithIndex(addressIndex);
      final child = root.derivePath(derivationPath);
      final privateKeyBytes = child.privateKey;
      if (privateKeyBytes == null) {
        throw Exception('无法派生私钥');
      }
      final privateKey = HEX.encode(privateKeyBytes);
      final credentials = web3.EthPrivateKey.fromHex(privateKey);

      debugPrint('使用派生路径: $derivationPath');
      debugPrint('地址索引: $addressIndex');
      debugPrint('发送地址: ${credentials.address.hex}');

      // 获取网络信息
      final network = _supportedNetworks.firstWhere((n) => n.id == networkId);

      // 从RPC获取链ID而不是使用预设值
      final chainId = await client.getChainId();
      debugPrint('从RPC获取的链ID: $chainId');

      // 获取当前余额
      final balance = await client.getBalance(credentials.address);
      debugPrint('当前余额: ${balance.getValueInUnit(web3.EtherUnit.ether)} ETH');

      // 将金额转换为Wei
      final weiAmount = web3.EtherAmount.fromBigInt(
        web3.EtherUnit.wei,
        BigInt.from((amount * 1e18).toInt()),
      );
      debugPrint('转换后的Wei金额: ${weiAmount.getInWei}');

      // 获取gas价格和估算gas限制
      final gasPrice = await client.getGasPrice();
      debugPrint('Gas价格: ${gasPrice.getInWei} wei');

      // 先进行gas预估 - 创建交易对象进行更准确的估算
      final transaction = web3.Transaction(
        to: web3.EthereumAddress.fromHex(toAddress),
        value: weiAmount,
        gasPrice: gasPrice,
      );

      // 估算gas限制 - 使用完整的交易参数
      BigInt gasLimit;
      try {
        gasLimit = await client.estimateGas(
          sender: credentials.address,
          to: web3.EthereumAddress.fromHex(toAddress),
          value: weiAmount,
          gasPrice: gasPrice,
        );
        debugPrint('估算Gas限制: $gasLimit');

        // 为安全起见，增加10%的gas缓冲
        gasLimit = (gasLimit * BigInt.from(110)) ~/ BigInt.from(100);
        debugPrint('添加缓冲后的Gas限制: $gasLimit');
      } catch (e) {
        debugPrint('Gas估算失败，使用默认值: $e');
        // 如果估算失败，使用默认的gas限制
        gasLimit = BigInt.from(21000); // 标准转账的gas限制
      }

      // 计算总费用
      final totalFee = gasPrice.getInWei * BigInt.from(gasLimit.toInt());
      final totalCost = weiAmount.getInWei + totalFee;
      debugPrint(
          'Gas费用: ${web3.EtherAmount.fromBigInt(web3.EtherUnit.wei, totalFee).getValueInUnit(web3.EtherUnit.ether)} ETH');
      debugPrint(
          '总成本: ${web3.EtherAmount.fromBigInt(web3.EtherUnit.wei, totalCost).getValueInUnit(web3.EtherUnit.ether)} ETH');

      // 检查余额是否足够
      if (balance.getInWei < totalCost) {
        final shortfall = totalCost - balance.getInWei;
        debugPrint(
            '余额不足！缺少: ${web3.EtherAmount.fromBigInt(web3.EtherUnit.wei, shortfall).getValueInUnit(web3.EtherUnit.ether)} ETH');
        throw Exception(
            '余额不足，需要额外 ${web3.EtherAmount.fromBigInt(web3.EtherUnit.wei, shortfall).getValueInUnit(web3.EtherUnit.ether)} ETH');
      }

      // 发送交易
      final txHash = await client.sendTransaction(
        credentials,
        web3.Transaction(
          to: web3.EthereumAddress.fromHex(toAddress),
          value: weiAmount,
          gasPrice: gasPrice,
          maxGas: gasLimit.toInt(),
        ),
        chainId: chainId.toInt(),
      );

      client.dispose();
      debugPrint('EVM交易发送成功: $txHash');
      return txHash;
    } catch (e) {
      debugPrint('发送EVM交易失败: $e');
      throw Exception('发送EVM交易失败: $e');
    }
  }

  /// 发送比特币交易（简化实现）
  Future<String> _sendBitcoinTransaction({
    required String toAddress,
    required double amount,
    required String rpcUrl,
    required String password,
  }) async {
    // 比特币交易实现较为复杂，这里提供简化版本
    // 实际应用中需要使用专门的比特币库
    try {
      // 模拟比特币交易发送
      await Future.delayed(const Duration(seconds: 2));
      final txHash =
          'btc_${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}';

      debugPrint('比特币交易发送成功（模拟）: $txHash');
      return txHash;
    } catch (e) {
      debugPrint('发送比特币交易失败: $e');
      throw Exception('发送比特币交易失败: $e');
    }
  }

  /// 获取Solana交易状态
  Future<SolanaTransaction?> getSolanaTransactionStatus(
      String signature) async {
    if (_solanaWalletService == null) {
      return null;
    }

    try {
      final status =
          await _solanaWalletService!.getTransactionStatus(signature);
      // 这里需要根据TransactionStatus创建SolanaTransaction对象
      // 暂时返回null，实际应用中需要实现完整的转换逻辑
      return null;
    } catch (e) {
      debugPrint('获取Solana交易状态失败: $e');
      return null;
    }
  }

  /// 等待Solana交易确认
  Future<SolanaTransaction> waitForSolanaTransactionConfirmation(
    String signature, {
    String commitment = 'confirmed',
    Duration timeout = const Duration(minutes: 2),
  }) async {
    if (_solanaWalletService == null) {
      throw Exception('Solana服务未初始化');
    }

    try {
      await _solanaWalletService!.waitForTransactionConfirmation(signature);
      // 暂时返回一个占位符SolanaTransaction，实际应用中需要实现完整的逻辑
      return SolanaTransaction.transfer(
        id: signature,
        fromAddress: '',
        toAddress: '',
        amount: 0,
        fee: const SolanaTransactionFee(
            baseFee: 5000,
            priorityFee: 1000,
            totalFee: 6000,
            priorityMultiplier: 1.0),
        recentBlockhash: '',
      );
    } catch (e) {
      debugPrint('等待Solana交易确认失败: $e');
      rethrow;
    }
  }

  /// 获取所有待处理的Solana交易
  List<SolanaTransaction> getPendingSolanaTransactions() {
    if (_solanaWalletService == null) {
      return [];
    }

    return _solanaWalletService!.getPendingTransactions();
  }

  /// 清理已完成的Solana交易
  void cleanupCompletedSolanaTransactions() {
    _solanaWalletService?.cleanupCompletedTransactions();
  }

  /// 开始监控Solana交易
  Future<void> startMonitoringSolanaTransaction(
      SolanaTransaction transaction) async {
    // 暂时注释掉，因为TransactionMonitorService接口不匹配
    // if (_transactionMonitorService == null) {
    //   debugPrint('交易监控服务未初始化');
    //   return;
    // }

    try {
      // await _transactionMonitorService!.startMonitoring(transaction);
      debugPrint('开始监控交易: ${transaction.signature}');
    } catch (e) {
      debugPrint('开始监控交易失败: $e');
    }
  }

  /// 获取交易监控状态
  Map<String, dynamic> getSolanaTransactionMonitorStatus(String signature) {
    // 暂时返回默认状态，因为TransactionMonitorService接口不匹配
    return {'status': 'service_not_available'};
  }

  /// 获取监控统计信息
  Map<String, int> getTransactionMonitorStatistics() {
    // 暂时返回空统计，因为TransactionMonitorService接口不匹配
    return {};
  }

  /// 获取当前监控的交易列表
  List<SolanaTransaction> getMonitoredSolanaTransactions() {
    // 暂时返回空列表，因为TransactionMonitorService接口不匹配
    return [];
  }

  /// 停止所有交易监控
  void stopAllTransactionMonitoring() {
    if (_transactionMonitorService == null) {
      debugPrint('交易监控服务未初始化');
      return;
    }

    try {
      _transactionMonitorService!.stopAllMonitoring();
      debugPrint('已停止所有交易监控');
    } catch (e) {
      debugPrint('停止所有交易监控失败: $e');
    }
  }

  /// 重置监控统计信息
  void resetTransactionMonitorStatistics() {
    if (_transactionMonitorService == null) {
      debugPrint('交易监控服务未初始化');
      return;
    }

    try {
      _transactionMonitorService!.resetStatistics();
      debugPrint('监控统计信息已重置');
    } catch (e) {
      debugPrint('重置监控统计信息失败: $e');
    }
  }

  /// 存储数据到Solana链上
  Future<String> storeDataOnSolanaChain({
    required Map<String, dynamic> data,
    required String password,
    String? memo,
    SolanaTransactionPriority priority = SolanaTransactionPriority.medium,
  }) async {
    if (_solanaWalletService == null) {
      throw Exception('Solana服务未初始化');
    }

    if (_currentWallet == null) {
      throw Exception('没有当前钱包');
    }

    try {
      // 获取钱包助记词
      final mnemonic = await getWalletMnemonic(_currentWallet!.id, password);
      if (mnemonic == null) {
        throw Exception('无法获取钱包助记词');
      }

      // 调用Solana服务存储数据
      await _solanaWalletService!.storeDataOnChain(mnemonic, data);

      // 返回一个模拟的交易签名，实际应用中应该返回真实的签名
      return 'mock_signature_${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      debugPrint('存储数据到Solana链失败: $e');
      rethrow;
    }
  }

  /// 存储数据到Solana链上并自动开始监控
  Future<String> storeDataOnSolanaChainWithMonitoring({
    required Map<String, dynamic> data,
    required String password,
    String? memo,
    SolanaTransactionPriority priority = SolanaTransactionPriority.medium,
  }) async {
    try {
      // 存储数据
      final signature = await storeDataOnSolanaChain(
        data: data,
        password: password,
        memo: memo,
        priority: priority,
      );

      // 获取交易对象并开始监控
      final pendingTransactions = getPendingSolanaTransactions();
      final transaction = pendingTransactions.firstWhere(
        (tx) => tx.signature == signature,
        orElse: () => SolanaTransaction(
          id: 'data_storage_$signature',
          type: SolanaTransactionType.dataStorage,
          status: SolanaTransactionStatus.processing,
          fromAddress: getCurrentNetworkAddress() ?? '',
          instructions: [],
          fee: const SolanaTransactionFee(
            baseFee: 5000,
            priorityFee: 1000,
            totalFee: 6000,
            priorityMultiplier: 1.0,
          ),
          recentBlockhash: '',
          createdAt: DateTime.now(),
          signature: signature,
          customData: data,
        ),
      );

      // 开始监控交易
      await startMonitoringSolanaTransaction(transaction);

      return signature;
    } catch (e) {
      debugPrint('存储数据到链上并监控失败: $e');
      rethrow;
    }
  }

  /// 获取网络的实时费用估算
  Future<double> getNetworkFeeEstimate(String networkId,
      {String? rpcUrl, double? amount, String? toAddress}) async {
    try {
      switch (networkId) {
        case NetworkConstants.ethereumNetworkId:
        case NetworkConstants.bscNetworkId:
        case NetworkConstants.polygonNetworkId:
          return await _getEVMFeeEstimate(networkId,
              rpcUrl: rpcUrl, amount: amount);
        case NetworkConstants.solanaNetworkId:
          return await _getSolanaFeeEstimate(amount: amount);
        case NetworkConstants.bitcoinNetworkId:
          return await _getBitcoinFeeEstimate(amount: amount);
        case 'tron':
          return await _getTronFeeEstimate(
            rpcUrl: rpcUrl,
            amount: amount,
            toAddress: toAddress,
          );
        default:
          return NetworkConstants.ethereumBaseFee; // 默认费用
      }
    } catch (e) {
      debugPrint('获取网络费用估算失败: $e');
      // 返回默认费用
      switch (networkId) {
        case NetworkConstants.ethereumNetworkId:
        case NetworkConstants.bscNetworkId:
        case NetworkConstants.polygonNetworkId:
          return NetworkConstants.ethereumBaseFee;
        case NetworkConstants.solanaNetworkId:
          return NetworkConstants.solanaBaseFee;
        case NetworkConstants.bitcoinNetworkId:
          return NetworkConstants.bitcoinBaseFee;
        case 'tron':
          return 0.1; // TRON 默认费用
        default:
          return NetworkConstants.ethereumBaseFee;
      }
    }
  }

  /// 获取EVM网络的费用估算（以太坊、BSC、Polygon）
  Future<double> _getEVMFeeEstimate(String networkId,
      {String? rpcUrl, double? amount}) async {
    try {
      // 获取网络信息
      final network = _supportedNetworks.firstWhere((n) => n.id == networkId);
      final effectiveRpcUrl = rpcUrl ?? network.rpcUrl;
      final client = web3.Web3Client(effectiveRpcUrl, http.Client());

      // 获取当前gas价格
      final gasPrice = await client.getGasPrice();

      // 使用标准转账的gas限制
      const standardGasLimit = NetworkConstants.evmStandardTransferGasLimit;

      // 如果提供了金额，可以进行更精确的gas估算
      BigInt gasLimit = BigInt.from(standardGasLimit);

      if (amount != null && _selectedAddress != null) {
        try {
          final weiAmount = web3.EtherAmount.fromBigInt(
            web3.EtherUnit.wei,
            BigInt.from((amount * 1e18).toInt()),
          );

          // 尝试估算实际的gas限制
          gasLimit = await client.estimateGas(
            sender: web3.EthereumAddress.fromHex(_selectedAddress!),
            to: web3.EthereumAddress.fromHex(
                '0x0000000000000000000000000000000000000000'), // 占位地址
            value: weiAmount,
            gasPrice: gasPrice,
          );

          // 添加10%缓冲
          gasLimit = (gasLimit * BigInt.from(110)) ~/ BigInt.from(100);
        } catch (e) {
          debugPrint('Gas估算失败，使用默认值: $e');
          gasLimit = BigInt.from(standardGasLimit);
        }
      }

      // 计算总费用：gasPrice * gasLimit
      final totalFee = gasPrice.getInWei * gasLimit;
      final feeInEther =
          web3.EtherAmount.fromBigInt(web3.EtherUnit.wei, totalFee)
              .getValueInUnit(web3.EtherUnit.ether);

      client.dispose();
      debugPrint(
          '$networkId 网络费用估算: $feeInEther ETH (gasPrice: ${gasPrice.getInWei} wei, gasLimit: $gasLimit)');

      return feeInEther;
    } catch (e) {
      debugPrint('获取 $networkId 费用估算失败: $e');
      rethrow;
    }
  }

  /// 获取Solana网络的费用估算
  Future<double> _getSolanaFeeEstimate({double? amount}) async {
    try {
      if (_solanaWalletService == null) {
        return NetworkConstants.solanaBaseFee; // 默认Solana基础费用
      }

      // 获取当前网络状态和费用信息
      final networkStatus = await _solanaWalletService!.getNetworkStatus();
      final baseFee = networkStatus['baseFee'] ?? 5000; // 微lamports

      // 转换为SOL（使用网络常量）
      final feeInSol = NetworkConstants.lamportsToSol(
          baseFee ~/ 1000); // 微lamports转lamports再转SOL

      debugPrint('Solana 网络费用估算: $feeInSol SOL (基础费用: $baseFee 微lamports)');
      return feeInSol;
    } catch (e) {
      debugPrint('获取Solana费用估算失败: $e');
      return 0.000005; // 返回默认值
    }
  }

  /// 获取比特币网络的费用估算
  Future<double> _getBitcoinFeeEstimate({double? amount}) async {
    try {
      // 比特币费用估算需要调用比特币RPC API
      // 这里提供简化实现，实际应用中需要调用真实的比特币节点

      // 模拟获取当前网络费率（satoshi/byte）
      const feeRate = 10; // 假设当前费率为10 sat/byte
      const txSize = 250; // 假设交易大小为250字节

      // 计算费用（satoshi）
      const feeInSatoshi = feeRate * txSize;

      // 转换为BTC（使用网络常量）
      final feeInBtc = NetworkConstants.satoshisToBtc(feeInSatoshi);

      debugPrint('比特币网络费用估算: $feeInBtc BTC ($feeInSatoshi satoshi)');
      return feeInBtc;
    } catch (e) {
      debugPrint('获取比特币费用估算失败: $e');
      return 0.0001; // 返回默认值
    }
  }

  /// 获取 TRON 网络的费用估算
  Future<double> _getTronFeeEstimate({
    String? rpcUrl,
    double? amount,
    String? toAddress,
  }) async {
    try {
      final network = _supportedNetworks.firstWhere((n) => n.id == 'tron');
      final effectiveRpcUrl = rpcUrl ?? network.rpcUrl;

      // 获取发送方地址
      final fromAddress = getCurrentNetworkAddress();
      if (fromAddress == null) {
        debugPrint('无法获取 TRON 发送地址');
        return 0.1; // 返回默认值
      }

      // 如果没有提供目标地址，返回基础费用估算
      if (toAddress == null || toAddress.isEmpty) {
        debugPrint('未提供目标地址，返回基础费用估算');
        return 0.1; // 基础带宽费用
      }

      // 调用费用估算服务
      final feeEstimate = await TronFeeService.estimateTrxTransferFee(
        fromAddress: fromAddress,
        toAddress: toAddress,
        amountTRX: amount ?? 0.001,
        tronRpcBaseUrl: effectiveRpcUrl,
      );

      debugPrint('TRON 费用估算: ${feeEstimate.totalFeeTrx} TRX');
      return feeEstimate.totalFeeTrx;
    } catch (e) {
      debugPrint('获取 TRON 费用估算失败: $e');
      return 0.1; // 返回默认值
    }
  }

  /// 获取 TRC20 代币的费用估算
  Future<TronFeeEstimate> getTrc20FeeEstimate({
    required String contractAddress,
    required String toAddress,
    required double amount,
    required int decimals,
    String? rpcUrl,
  }) async {
    try {
      final network = _supportedNetworks.firstWhere((n) => n.id == 'tron');
      final effectiveRpcUrl = rpcUrl ?? network.rpcUrl;

      // 获取发送方地址
      final fromAddress = getCurrentNetworkAddress();
      if (fromAddress == null) {
        throw Exception('无法获取 TRON 发送地址');
      }

      // 调用费用估算服务
      return await TronFeeService.estimateTrc20TransferFee(
        fromAddress: fromAddress,
        toAddress: toAddress,
        contractAddress: contractAddress,
        amount: amount,
        decimals: decimals,
        tronRpcBaseUrl: effectiveRpcUrl,
      );
    } catch (e) {
      debugPrint('获取 TRC20 费用估算失败: $e');
      rethrow;
    }
  }

  /// 加载自定义代币
  Future<void> _loadCustomTokens() async {
    try {
      final tokensData = await _storageService.getCustomTokens();
      _customTokens = tokensData.map((data) => Token.fromJson(data)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('加载自定义代币失败: $e');
    }
  }

  /// 添加自定义代币
  Future<bool> addCustomToken(Token token) async {
    try {
      // 检查代币是否已存在
      final exists = _customTokens.any((t) =>
          t.contractAddress.toLowerCase() ==
              token.contractAddress.toLowerCase() &&
          t.networkId == token.networkId);

      if (exists) {
        debugPrint('代币已存在: ${token.symbol}');
        return false;
      }

      // 添加到列表
      _customTokens.add(token);

      // 保存到存储
      await _saveCustomTokens();

      notifyListeners();
      debugPrint('成功添加代币: ${token.symbol}');
      return true;
    } catch (e) {
      debugPrint('添加代币失败: $e');
      return false;
    }
  }

  /// 移除自定义代币
  Future<bool> removeCustomToken(Token token) async {
    try {
      _customTokens.removeWhere((t) =>
          t.contractAddress.toLowerCase() ==
              token.contractAddress.toLowerCase() &&
          t.networkId == token.networkId);

      await _saveCustomTokens();
      notifyListeners();
      debugPrint('成功移除代币: ${token.symbol}');
      return true;
    } catch (e) {
      debugPrint('移除代币失败: $e');
      return false;
    }
  }

  /// 获取指定网络的自定义代币
  List<Token> getCustomTokensForNetwork(String networkId) {
    return _customTokens
        .where((token) => token.networkId == networkId)
        .toList();
  }

  /// 获取所有资产（原生代币 + 自定义代币）
  List<Map<String, dynamic>> getAllAssets() {
    // 原生代币
    final nativeAssets = [
      {
        'id': 'ethereum',
        'name': 'Ethereum',
        'symbol': 'ETH',
        'icon': Icons.currency_bitcoin,
        'color': const Color(0xFF627EEA),
        'price': 2000.0,
        'isNative': true,
      },
      {
        'id': 'polygon',
        'name': 'Polygon',
        'symbol': 'MATIC',
        'icon': Icons.hexagon,
        'color': const Color(0xFF8247E5),
        'price': 0.8,
        'isNative': true,
      },
      {
        'id': 'bsc',
        'name': 'BNB',
        'symbol': 'BNB',
        'icon': Icons.currency_exchange,
        'color': const Color(0xFFF3BA2F),
        'price': 300.0,
        'isNative': true,
      },
      {
        'id': 'bitcoin',
        'name': 'Bitcoin',
        'symbol': 'BTC',
        'icon': Icons.currency_bitcoin,
        'color': const Color(0xFFF7931A),
        'price': 45000.0,
        'isNative': true,
      },
      {
        'id': 'solana',
        'name': 'Solana',
        'symbol': 'SOL',
        'icon': Icons.wb_sunny,
        'color': const Color(0xFF9945FF),
        'price': 100.0,
        'isNative': true,
      },
    ];

    // 自定义代币
    final customAssets = _customTokens
        .map((token) => {
              'id': token.contractAddress,
              'name': token.name,
              'symbol': token.symbol,
              'icon': Icons.token,
              'color': const Color(0xFF6366F1),
              'price': token.priceUsd ?? 0.0,
              'isNative': false,
              'networkId': token.networkId,
              'decimals': token.decimals,
              'logoUrl': token.iconUrl,
              'token': token,
            })
        .toList();

    return [...nativeAssets, ...customAssets];
  }

  /// 保存自定义代币到存储
  Future<void> _saveCustomTokens() async {
    try {
      final tokensData = _customTokens.map((token) => token.toJson()).toList();
      await _storageService.saveCustomTokens(tokensData);
    } catch (e) {
      debugPrint('保存自定义代币失败: $e');
    }
  }

  /// 刷新代币余额
  Future<void> refreshTokenBalances() async {
    if (_currentWallet == null || _currentNetwork == null) return;

    try {
      final walletAddress = getCurrentNetworkAddress();
      if (walletAddress == null) return;

      // 刷新自定义代币余额
      for (final token in _customTokens) {
        if (token.networkId == _currentNetwork!.id) {
          // 这里可以调用TokenService来获取代币余额
          // final balance = await TokenService.getTokenBalance(
          //   token.contractAddress,
          //   walletAddress,
          //   token.networkId
          // );
          // token = token.copyWith(balance: balance);
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('刷新代币余额失败: $e');
    }
  }

  /// 释放资源
  @override
  void dispose() {
    _transactionMonitorService?.dispose();
    _solanaWalletService?.dispose();
    super.dispose();
  }

  /// 切换余额显示/隐藏
  void toggleBalanceVisibility() {
    _isBalanceHidden = !_isBalanceHidden;
    notifyListeners();
  }
}
