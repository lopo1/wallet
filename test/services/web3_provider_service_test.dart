import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/models/dapp_connection.dart';
import 'package:harbor/models/network.dart';
import 'package:harbor/models/web3_request.dart';
import 'package:harbor/providers/wallet_provider.dart';
import 'package:harbor/services/dapp_connection_service.dart';
import 'package:harbor/services/storage_service.dart';
import 'package:harbor/services/web3_provider_service.dart';

// Mock类用于测试
class MockWalletProvider extends WalletProvider {
  Network? _currentNetwork;

  @override
  Network? get currentNetwork => _currentNetwork;

  @override
  List<Network> get supportedNetworks => [
        Network(
          id: 'ethereum',
          name: 'Ethereum',
          symbol: 'ETH',
          rpcUrl: 'https://mainnet.infura.io/v3/test',
          chainId: 1,
          color: 0xFF627EEA,
          explorerUrl: 'https://etherscan.io',
        ),
        Network(
          id: 'polygon',
          name: 'Polygon',
          symbol: 'MATIC',
          rpcUrl: 'https://polygon-rpc.com',
          chainId: 137,
          color: 0xFF8247E5,
          explorerUrl: 'https://polygonscan.com',
        ),
      ];

  void setMockCurrentNetwork(Network network) {
    _currentNetwork = network;
  }

  @override
  void setCurrentNetwork(Network network) {
    _currentNetwork = network;
  }
}

class MockStorageService extends StorageService {
  final Map<String, dynamic> _data = {};

  @override
  Future<void> saveData(String key, dynamic data) async {
    _data[key] = data;
  }

  @override
  Future<dynamic> getData(String key) async {
    return _data[key];
  }

  @override
  Future<void> removeData(String key) async {
    _data.remove(key);
  }

  @override
  Future<bool> hasData(String key) async {
    return _data.containsKey(key);
  }
}

void main() {
  group('Web3ProviderService Tests', () {
    late Web3ProviderService service;
    late MockWalletProvider mockWalletProvider;
    late DAppConnectionService mockConnectionService;
    late MockStorageService mockStorage;

    const testOrigin = 'https://example.com';
    const testAddress = '0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6';

    setUp(() {
      mockStorage = MockStorageService();
      mockWalletProvider = MockWalletProvider();
      mockConnectionService =
          DAppConnectionService(storageService: mockStorage);

      service = Web3ProviderService(
        walletProvider: mockWalletProvider,
        connectionService: mockConnectionService,
      );

      // 设置测试网络
      mockWalletProvider.setMockCurrentNetwork(
        Network(
          id: 'ethereum',
          name: 'Ethereum',
          symbol: 'ETH',
          rpcUrl: 'https://mainnet.infura.io/v3/test',
          chainId: 1,
          color: 0xFF627EEA,
          explorerUrl: 'https://etherscan.io',
        ),
      );
    });

    tearDown(() {
      service.dispose();
      mockConnectionService.dispose();
    });

    group('Request Handling', () {
      setUp(() async {
        // 创建测试连接
        final request = DAppConnectionRequest(
          origin: testOrigin,
          name: 'Test DApp',
          iconUrl: 'https://example.com/icon.png',
          requestedAddresses: [testAddress],
          networkId: 'ethereum',
          requestedPermissions: [
            DAppPermission.readAccounts,
            DAppPermission.sendTransactions,
            DAppPermission.signMessages,
          ],
        );

        await mockConnectionService.connectDApp(request);

        // 设置模拟的WebView控制器
        service.setWebViewController(null, testOrigin);
      });

      test('should handle eth_requestAccounts', () async {
        final requestData = {
          'id': 'test-1',
          'method': 'eth_requestAccounts',
          'params': [],
        };

        final result = await service.handleWeb3Request(requestData);

        expect(result, isA<List<String>>());
        expect(result, contains(testAddress));
      });

      test('should handle eth_accounts', () async {
        final requestData = {
          'id': 'test-2',
          'method': 'eth_accounts',
          'params': [],
        };

        final result = await service.handleWeb3Request(requestData);

        expect(result, isA<List<String>>());
        expect(result, contains(testAddress));
      });

      test('should handle eth_chainId', () async {
        final requestData = {
          'id': 'test-3',
          'method': 'eth_chainId',
          'params': [],
        };

        final result = await service.handleWeb3Request(requestData);

        expect(result, equals('0x1')); // Ethereum mainnet
      });

      test('should handle net_version', () async {
        final requestData = {
          'id': 'test-4',
          'method': 'net_version',
          'params': [],
        };

        final result = await service.handleWeb3Request(requestData);

        expect(result, equals('1')); // Ethereum mainnet
      });

      test('should handle eth_sendTransaction', () async {
        final requestData = {
          'id': 'test-5',
          'method': 'eth_sendTransaction',
          'params': [
            {
              'from': testAddress,
              'to': '0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b7',
              'value': '0x16345785D8A0000', // 0.1 ETH
            }
          ],
        };

        final result = await service.handleWeb3Request(requestData);

        expect(result, isA<String>());
        expect(result.toString().startsWith('0x'), true);
        expect(result.toString().length,
            equals(66)); // 32 bytes = 64 hex chars + 0x
      });

      test('should handle personal_sign', () async {
        final requestData = {
          'id': 'test-6',
          'method': 'personal_sign',
          'params': ['Hello World', testAddress],
        };

        final result = await service.handleWeb3Request(requestData);

        expect(result, isA<String>());
        expect(result.toString().startsWith('0x'), true);
      });

      test('should handle wallet_switchEthereumChain', () async {
        final requestData = {
          'id': 'test-7',
          'method': 'wallet_switchEthereumChain',
          'params': [
            {'chainId': '0x89'} // Polygon
          ],
        };

        await service.handleWeb3Request(requestData);

        // 验证网络已切换
        expect(mockWalletProvider.currentNetwork?.chainId, equals(137));
      });

      test('should handle wallet_watchAsset', () async {
        final requestData = {
          'id': 'test-8',
          'method': 'wallet_watchAsset',
          'params': [
            {
              'type': 'ERC20',
              'options': {
                'address': '0xA0b86a33E6441c8C06DD2b7c94b7E0e8c07e8e8e',
                'symbol': 'TEST',
                'decimals': 18,
              }
            }
          ],
        };

        final result = await service.handleWeb3Request(requestData);

        expect(result, equals(true));
      });
    });

    group('Error Handling', () {
      test('should throw error for unsupported method', () async {
        final requestData = {
          'id': 'test-error-1',
          'method': 'unsupported_method',
          'params': [],
        };

        service.setWebViewController(null, testOrigin);

        expect(
          () => service.handleWeb3Request(requestData),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw error when not connected', () async {
        final requestData = {
          'id': 'test-error-2',
          'method': 'eth_accounts',
          'params': [],
        };

        service.setWebViewController(null, 'https://notconnected.com');

        expect(
          () => service.handleWeb3Request(requestData),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw error for unauthorized address', () async {
        // 创建连接但不包含测试地址
        final request = DAppConnectionRequest(
          origin: 'https://unauthorized.com',
          name: 'Unauthorized DApp',
          iconUrl: 'https://unauthorized.com/icon.png',
          requestedAddresses: ['0x1234567890123456789012345678901234567890'],
          networkId: 'ethereum',
          requestedPermissions: [DAppPermission.readAccounts],
        );

        await mockConnectionService.connectDApp(request);

        final requestData = {
          'id': 'test-error-3',
          'method': 'eth_sendTransaction',
          'params': [
            {
              'from': testAddress, // 使用未授权的地址
              'to': '0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b7',
              'value': '0x16345785D8A0000',
            }
          ],
        };

        service.setWebViewController(null, 'https://unauthorized.com');

        expect(
          () => service.handleWeb3Request(requestData),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw error for missing permissions', () async {
        // 创建只有读取权限的连接
        final request = DAppConnectionRequest(
          origin: 'https://readonly.com',
          name: 'ReadOnly DApp',
          iconUrl: 'https://readonly.com/icon.png',
          requestedAddresses: [testAddress],
          networkId: 'ethereum',
          requestedPermissions: [DAppPermission.readAccounts], // 只有读取权限
        );

        await mockConnectionService.connectDApp(request);

        final requestData = {
          'id': 'test-error-4',
          'method': 'eth_sendTransaction',
          'params': [
            {
              'from': testAddress,
              'to': '0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b7',
              'value': '0x16345785D8A0000',
            }
          ],
        };

        service.setWebViewController(null, 'https://readonly.com');

        expect(
          () => service.handleWeb3Request(requestData),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Network Switching', () {
      test('should switch to supported network', () async {
        // 创建测试连接
        final request = DAppConnectionRequest(
          origin: testOrigin,
          name: 'Test DApp',
          iconUrl: 'https://example.com/icon.png',
          requestedAddresses: [testAddress],
          networkId: 'ethereum',
          requestedPermissions: [DAppPermission.readAccounts],
        );

        await mockConnectionService.connectDApp(request);

        final requestData = {
          'id': 'test-switch',
          'method': 'wallet_switchEthereumChain',
          'params': [
            {'chainId': '0x89'} // Polygon
          ],
        };

        service.setWebViewController(null, testOrigin);
        await service.handleWeb3Request(requestData);

        expect(mockWalletProvider.currentNetwork?.chainId, equals(137));
        expect(mockWalletProvider.currentNetwork?.name, equals('Polygon'));
      });

      test('should throw error for unsupported chain', () async {
        // 创建测试连接
        final request = DAppConnectionRequest(
          origin: testOrigin,
          name: 'Test DApp',
          iconUrl: 'https://example.com/icon.png',
          requestedAddresses: [testAddress],
          networkId: 'ethereum',
          requestedPermissions: [DAppPermission.readAccounts],
        );

        await mockConnectionService.connectDApp(request);

        final requestData = {
          'id': 'test-switch-error',
          'method': 'wallet_switchEthereumChain',
          'params': [
            {'chainId': '0x999'} // 不支持的链
          ],
        };

        service.setWebViewController(null, testOrigin);

        expect(
          () => service.handleWeb3Request(requestData),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Provider JavaScript Generation', () {
      test('should generate provider without errors', () {
        service.setWebViewController(null, testOrigin);

        // 测试注入方法不会抛出异常
        expect(() => service.injectProvider(), returnsNormally);
      });
    });
  });
}
