import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/token.dart';

class TokenService {
  static const String _etherscanApiKey = 'YourEtherscanApiKey'; // 替换为实际的API密钥
  static const String _polygonscanApiKey =
      'YourPolygonscanApiKey'; // 替换为实际的API密钥
  static const String _bscscanApiKey = 'YourBscscanApiKey'; // 替换为实际的API密钥

  /// 根据合约地址获取代币信息
  static Future<Token?> getTokenInfo(
      String contractAddress, String networkId) async {
    try {
      switch (networkId) {
        case 'ethereum':
          return await _getEthereumTokenInfo(contractAddress);
        case 'polygon':
          return await _getPolygonTokenInfo(contractAddress);
        case 'bsc':
          return await _getBscTokenInfo(contractAddress);
        default:
          throw Exception('不支持的网络: $networkId');
      }
    } catch (e) {
      debugPrint('获取代币信息失败: $e');
      return null;
    }
  }

  /// 获取以太坊代币信息
  static Future<Token?> _getEthereumTokenInfo(String contractAddress) async {
    try {
      // 使用Etherscan API获取代币信息
      final url = 'https://api.etherscan.io/api'
          '?module=token'
          '&action=tokeninfo'
          '&contractaddress=$contractAddress'
          '&apikey=$_etherscanApiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == '1' &&
            data['result'] != null &&
            data['result'].isNotEmpty) {
          final tokenData = data['result'][0];
          return Token(
            address: contractAddress.toLowerCase(),
            name: tokenData['tokenName'] ?? '',
            symbol: tokenData['symbol'] ?? '',
            decimals: int.tryParse(tokenData['divisor'] ?? '18') ?? 18,
            networkId: 'ethereum',
            logoUrl: _getTokenLogoUrl(contractAddress),
          );
        }
      }

      // 如果Etherscan API失败，尝试使用合约调用
      return await _getTokenInfoFromContract(contractAddress, 'ethereum');
    } catch (e) {
      debugPrint('获取以太坊代币信息失败: $e');
      return null;
    }
  }

  /// 获取Polygon代币信息
  static Future<Token?> _getPolygonTokenInfo(String contractAddress) async {
    try {
      // 使用Polygonscan API获取代币信息
      final url = 'https://api.polygonscan.com/api'
          '?module=token'
          '&action=tokeninfo'
          '&contractaddress=$contractAddress'
          '&apikey=$_polygonscanApiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == '1' &&
            data['result'] != null &&
            data['result'].isNotEmpty) {
          final tokenData = data['result'][0];
          return Token(
            address: contractAddress.toLowerCase(),
            name: tokenData['tokenName'] ?? '',
            symbol: tokenData['symbol'] ?? '',
            decimals: int.tryParse(tokenData['divisor'] ?? '18') ?? 18,
            networkId: 'polygon',
            logoUrl: _getTokenLogoUrl(contractAddress),
          );
        }
      }

      return await _getTokenInfoFromContract(contractAddress, 'polygon');
    } catch (e) {
      debugPrint('获取Polygon代币信息失败: $e');
      return null;
    }
  }

  /// 获取BSC代币信息
  static Future<Token?> _getBscTokenInfo(String contractAddress) async {
    try {
      // 使用BSCscan API获取代币信息
      final url = 'https://api.bscscan.com/api'
          '?module=token'
          '&action=tokeninfo'
          '&contractaddress=$contractAddress'
          '&apikey=$_bscscanApiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == '1' &&
            data['result'] != null &&
            data['result'].isNotEmpty) {
          final tokenData = data['result'][0];
          return Token(
            address: contractAddress.toLowerCase(),
            name: tokenData['tokenName'] ?? '',
            symbol: tokenData['symbol'] ?? '',
            decimals: int.tryParse(tokenData['divisor'] ?? '18') ?? 18,
            networkId: 'bsc',
            logoUrl: _getTokenLogoUrl(contractAddress),
          );
        }
      }

      return await _getTokenInfoFromContract(contractAddress, 'bsc');
    } catch (e) {
      debugPrint('获取BSC代币信息失败: $e');
      return null;
    }
  }

  /// 通过合约调用获取代币信息（备用方法）
  static Future<Token?> _getTokenInfoFromContract(
      String contractAddress, String networkId) async {
    try {
      // 这里可以实现直接调用合约的方法
      // 由于需要web3库，这里先返回一个基本的Token对象
      return Token(
        address: contractAddress.toLowerCase(),
        name: 'Unknown Token',
        symbol: 'UNKNOWN',
        decimals: 18,
        networkId: networkId,
      );
    } catch (e) {
      debugPrint('通过合约获取代币信息失败: $e');
      return null;
    }
  }

  /// 获取代币Logo URL
  static String? _getTokenLogoUrl(String contractAddress) {
    // 使用Trust Wallet的代币Logo服务
    return 'https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/ethereum/assets/${contractAddress.toLowerCase()}/logo.png';
  }

  /// 验证合约地址格式
  static bool isValidContractAddress(String address, String networkId) {
    if (address.isEmpty) return false;

    switch (networkId) {
      case 'ethereum':
      case 'polygon':
      case 'bsc':
        // EVM地址格式验证
        final ethAddressRegex = RegExp(r'^0x[a-fA-F0-9]{40}$');
        return ethAddressRegex.hasMatch(address);
      case 'solana':
        // Solana地址格式验证
        return address.length >= 32 && address.length <= 44;
      default:
        return false;
    }
  }

  /// 获取代币余额
  static Future<double> getTokenBalance(
      String contractAddress, String walletAddress, String networkId) async {
    try {
      switch (networkId) {
        case 'ethereum':
          return await _getEthereumTokenBalance(contractAddress, walletAddress);
        case 'polygon':
          return await _getPolygonTokenBalance(contractAddress, walletAddress);
        case 'bsc':
          return await _getBscTokenBalance(contractAddress, walletAddress);
        default:
          return 0.0;
      }
    } catch (e) {
      debugPrint('获取代币余额失败: $e');
      return 0.0;
    }
  }

  static Future<double> _getEthereumTokenBalance(
      String contractAddress, String walletAddress) async {
    // 实现以太坊代币余额查询
    // 这里需要使用web3库或API调用
    return 0.0;
  }

  static Future<double> _getPolygonTokenBalance(
      String contractAddress, String walletAddress) async {
    // 实现Polygon代币余额查询
    return 0.0;
  }

  static Future<double> _getBscTokenBalance(
      String contractAddress, String walletAddress) async {
    // 实现BSC代币余额查询
    return 0.0;
  }

  /// 获取热门代币列表
  static List<Token> getPopularTokens(String networkId) {
    switch (networkId) {
      case 'ethereum':
        return [
          Token(
            address: '0xA0b86a33E6441b8C4505E2E8b8F8b8B8B8B8B8B8',
            name: 'USD Coin',
            symbol: 'USDC',
            decimals: 6,
            networkId: 'ethereum',
            logoUrl: 'https://cryptologos.cc/logos/usd-coin-usdc-logo.png',
          ),
          Token(
            address: '0xdAC17F958D2ee523a2206206994597C13D831ec7',
            name: 'Tether USD',
            symbol: 'USDT',
            decimals: 6,
            networkId: 'ethereum',
            logoUrl: 'https://cryptologos.cc/logos/tether-usdt-logo.png',
          ),
          Token(
            address: '0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984',
            name: 'Uniswap',
            symbol: 'UNI',
            decimals: 18,
            networkId: 'ethereum',
            logoUrl: 'https://cryptologos.cc/logos/uniswap-uni-logo.png',
          ),
        ];
      case 'polygon':
        return [
          Token(
            address: '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174',
            name: 'USD Coin',
            symbol: 'USDC',
            decimals: 6,
            networkId: 'polygon',
            logoUrl: 'https://cryptologos.cc/logos/usd-coin-usdc-logo.png',
          ),
          Token(
            address: '0xc2132D05D31c914a87C6611C10748AEb04B58e8F',
            name: 'Tether USD',
            symbol: 'USDT',
            decimals: 6,
            networkId: 'polygon',
            logoUrl: 'https://cryptologos.cc/logos/tether-usdt-logo.png',
          ),
        ];
      case 'bsc':
        return [
          Token(
            address: '0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d',
            name: 'USD Coin',
            symbol: 'USDC',
            decimals: 18,
            networkId: 'bsc',
            logoUrl: 'https://cryptologos.cc/logos/usd-coin-usdc-logo.png',
          ),
          Token(
            address: '0x55d398326f99059fF775485246999027B3197955',
            name: 'Tether USD',
            symbol: 'USDT',
            decimals: 18,
            networkId: 'bsc',
            logoUrl: 'https://cryptologos.cc/logos/tether-usdt-logo.png',
          ),
        ];
      default:
        return [];
    }
  }
}
