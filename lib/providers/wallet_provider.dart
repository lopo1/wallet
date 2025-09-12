import 'package:flutter/foundation.dart';
import 'package:bip39/bip39.dart' as bip39;
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

class WalletProvider extends ChangeNotifier {
  List<Wallet> _wallets = [];
  Wallet? _currentWallet;
  List<Network> _supportedNetworks = [];
  Network? _currentNetwork;
  bool _isLoading = false;
  String? _selectedAddress;

  List<Wallet> get wallets => _wallets;
  Wallet? get currentWallet => _currentWallet;
  List<Network> get supportedNetworks => _supportedNetworks;
  Network? get currentNetwork => _currentNetwork;
  bool get isLoading => _isLoading;
  String? get selectedAddress => _selectedAddress;

  final StorageService _storageService = StorageService();
  SolanaWalletService? _solanaWalletService;
  TransactionMonitorService? _transactionMonitorService;

  WalletProvider() {
    _initializeSupportedNetworks();
    _loadWallets();
    _initializeSolanaService();
  }

  /// 初始化Solana服务
  void _initializeSolanaService() {
    final solanaNetwork = _supportedNetworks.firstWhere(
      (network) => network.id == 'solana',
      orElse: () => _supportedNetworks.first,
    );

    _solanaWalletService = SolanaWalletService(solanaNetwork.rpcUrl);
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
        rpcUrl: 'https://mainnet.infura.io/v3/YOUR_PROJECT_ID',
        rpcUrls: [
          'https://mainnet.infura.io/v3/YOUR_PROJECT_ID',
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
        rpcUrl: 'https://bsc-dataseed.binance.org',
        rpcUrls: [
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
        rpcUrl: 'https://api.devnet.solana.com',
        rpcUrls: [
          'https://api.devnet.solana.com',
          'https://api.mainnet-beta.solana.com',
          'https://rpc.ankr.com/solana',
          'https://solana-api.projectserum.com',
          'https://api.zan.top/node/v1/solana/mainnet/b49c38feccc54a49a318db163d336c60',
        ],
        explorerUrl: 'https://explorer.solana.com',
        color: 0xFF9945FF,
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

      // Create wallet
      final wallet = Wallet(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        mnemonic: mnemonic,
        addresses: {},
        createdAt: DateTime.now(),
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
    // 如果有选中的地址，返回选中的地址
    if (_selectedAddress != null) {
      return _selectedAddress;
    }
    // 否则返回第一个地址
    final addressList = _currentWallet!.addresses[_currentNetwork!.id];
    return addressList?.isNotEmpty == true ? addressList!.first : null;
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
  Future<void> updateWalletAddressesAndIndexes(
      String walletId,
      Map<String, List<String>> addresses,
      Map<String, int> addressIndexes) async {
    await _storageService.updateWalletAddressesAndIndexes(
        walletId, addresses, addressIndexes);

    // Update local wallet object
    final walletIndex = _wallets.indexWhere((w) => w.id == walletId);
    if (walletIndex != -1) {
      final updatedWallet = _wallets[walletIndex].copyWith(
        addresses: addresses,
        addressIndexes: addressIndexes,
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
          default:
            return 0.0;
        }
      });
    } catch (e) {
      debugPrint('获取余额失败: $e');
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

      // 获取当前钱包地址
      if (_selectedAddress == null) {
        return 0.0;
      }

      // 打印请求数据
      debugPrint('=== 以太坊余额查询请求 ===');
      debugPrint('RPC URL: $effectiveRpcUrl');
      debugPrint('钱包地址: $_selectedAddress');
      debugPrint('请求方法: eth_getBalance');

      final address = web3.EthereumAddress.fromHex(_selectedAddress!);
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

      // 获取当前钱包地址
      if (_selectedAddress == null) {
        return 0.0;
      }

      // 打印请求数据
      debugPrint('=== Polygon余额查询请求 ===');
      debugPrint('RPC URL: $effectiveRpcUrl');
      debugPrint('钱包地址: $_selectedAddress');
      debugPrint('请求方法: eth_getBalance');

      final address = web3.EthereumAddress.fromHex(_selectedAddress!);
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

      // 获取当前钱包地址
      if (_selectedAddress == null) {
        return 0.0;
      }

      // 打印请求数据
      debugPrint('=== BSC余额查询请求 ===');
      debugPrint('RPC URL: $effectiveRpcUrl');
      debugPrint('钱包地址: $_selectedAddress');
      debugPrint('请求方法: eth_getBalance');

      final address = web3.EthereumAddress.fromHex(_selectedAddress!);
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

  /// 获取比特币余额
  Future<double> _getBitcoinBalance(String networkId, {String? rpcUrl}) async {
    try {
      // 优先使用当前网络（如果匹配），否则查找指定网络
      final network = _currentNetwork?.id == networkId
          ? _currentNetwork!
          : _supportedNetworks.firstWhere((n) => n.id == networkId);

      // 获取当前钱包地址
      if (_selectedAddress == null) {
        return 0.0;
      }

      // 使用传入的rpcUrl或网络默认的rpcUrl
      final effectiveRpcUrl = rpcUrl ?? network.rpcUrl;
      final apiUrl = '$effectiveRpcUrl/address/${_selectedAddress!}';

      // 打印请求数据
      debugPrint('=== 比特币余额查询请求 ===');
      debugPrint('API URL: $apiUrl');
      debugPrint('钱包地址: $_selectedAddress');
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

  /// 获取Solana余额
  Future<double> _getSolanaBalance(String networkId, {String? rpcUrl}) async {
    try {
      // 优先使用当前网络（如果匹配），否则查找指定网络
      final network = _currentNetwork?.id == networkId
          ? _currentNetwork!
          : _supportedNetworks.firstWhere((n) => n.id == networkId);

      // 使用传入的rpcUrl或网络默认的rpcUrl
      final effectiveRpcUrl = rpcUrl ?? network.rpcUrl;

      // 获取当前钱包地址
      if (_selectedAddress == null) {
        return 0.0;
      }

      final requestBody = {
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'getBalance',
        'params': [_selectedAddress!]
      };

      // 打印请求数据
      debugPrint('=== Solana余额查询请求 ===');
      debugPrint('RPC URL: $effectiveRpcUrl');
      debugPrint('钱包地址: $_selectedAddress');
      debugPrint('请求方法: POST');
      debugPrint('请求头: Content-Type: application/json');
      debugPrint('请求体: ${jsonEncode(requestBody)}');

      // Solana RPC请求
      final response = await http.post(
        Uri.parse(effectiveRpcUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('响应状态码: ${response.statusCode}');
      debugPrint('响应数据: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['result'] != null && data['result']['value'] != null) {
          // Solana余额以lamports为单位，1 SOL = 1,000,000,000 lamports
          final lamports = data['result']['value'] as int;
          final solBalance = lamports / 1000000000.0;

          debugPrint('响应余额: $solBalance SOL');
          debugPrint('=======================');

          return solBalance;
        }
      }

      debugPrint('=======================');
      return 0.0;
    } catch (e) {
      debugPrint('获取Solana余额失败: $e');
      return 0.0;
    }
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

      // 打印调试信息
      debugPrint('=== 钱包信息调试 ===');
      debugPrint('钱包ID: ${_currentWallet!.id}');
      debugPrint('当前网络: ${_currentNetwork?.id}');
      debugPrint('获取到的助记词: $mnemonic');
      debugPrint('从钱包获取的地址: $fromAddress');
      debugPrint('==================');

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
      // 获取助记词
      final mnemonic = await getWalletMnemonic(_currentWallet!.id, password);
      if (mnemonic == null) {
        throw Exception('无法获取钱包助记词');
      }

      // 创建Web3客户端
      final client = web3.Web3Client(rpcUrl, http.Client());

      // 从助记词生成私钥
      final seed = bip39.mnemonicToSeed(mnemonic);
      final privateKey = HEX.encode(seed.sublist(0, 32));
      final credentials = web3.EthPrivateKey.fromHex(privateKey);

      // 获取网络信息
      final network = _supportedNetworks.firstWhere((n) => n.id == networkId);
      final chainId = network.chainId;

      // 将金额转换为Wei
      final weiAmount = web3.EtherAmount.fromUnitAndValue(
        web3.EtherUnit.ether,
        amount,
      );

      // 发送交易
      final txHash = await client.sendTransaction(
        credentials,
        web3.Transaction(
          to: web3.EthereumAddress.fromHex(toAddress),
          value: weiAmount,
        ),
        chainId: chainId,
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

  /// 停止监控Solana交易
  void stopMonitoringSolanaTransaction(String signature) {
    // 暂时注释掉，因为TransactionMonitorService接口不匹配
    // if (_transactionMonitorService == null) {
    //   debugPrint('交易监控服务未初始化');
    //   return;
    // }

    try {
      // _transactionMonitorService!.stopMonitoring(signature);
      debugPrint('停止监控交易: $signature');
    } catch (e) {
      debugPrint('停止监控交易失败: $e');
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

  /// 发送Solana交易并自动开始监控
  Future<String> sendSolanaTransactionWithMonitoring({
    required String toAddress,
    required double amount,
    required String password,
    String? memo,
    double priorityFeeMultiplier = 1.0,
  }) async {
    try {
      // 发送交易
      final signature = await _sendSolanaTransaction(
        toAddress: toAddress,
        amount: amount,
        rpcUrl: _currentNetwork?.rpcUrl ?? '',
        password: password,
        memo: memo,
        priorityFeeMultiplier: priorityFeeMultiplier,
      );

      // 获取交易对象并开始监控
      final pendingTransactions = getPendingSolanaTransactions();
      final transaction = pendingTransactions.firstWhere(
        (tx) => tx.signature == signature,
        orElse: () => SolanaTransaction(
          id: 'unknown_$signature',
          type: SolanaTransactionType.transfer,
          status: SolanaTransactionStatus.processing,
          fromAddress: getCurrentNetworkAddress() ?? '',
          toAddress: toAddress,
          amount: (amount * 1000000000).toInt(),
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
        ),
      );

      // 开始监控交易
      await startMonitoringSolanaTransaction(transaction);

      return signature;
    } catch (e) {
      debugPrint('发送Solana交易并监控失败: $e');
      rethrow;
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

  /// 释放资源
  @override
  void dispose() {
    _transactionMonitorService?.dispose();
    _solanaWalletService?.dispose();
    super.dispose();
  }
}
