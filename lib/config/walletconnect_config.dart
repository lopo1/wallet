/// WalletConnect配置文件
/// 包含WalletConnect相关的配置信息
class WalletConnectConfig {
  /// WalletConnect项目ID
  /// 需要从 https://cloud.walletconnect.com 获取
  /// 1. 访问 https://cloud.walletconnect.com
  /// 2. 创建账户并登录
  /// 3. 创建新项目
  /// 4. 复制项目ID并替换下面的值
  static const String projectId = '38d62272a06b73b1f9aab563e46185ae';
  
  /// 应用元数据
  static const String appName = 'Flutter Wallet';
  static const String appDescription = 'A decentralized multi-chain wallet';
  static const String appUrl = 'https://flutter-wallet.com';
  static const String appIcon = 'https://flutter-wallet.com/icon.png';
  
  /// 支持的链ID
  static const Map<String, String> supportedChains = {
    'ethereum': 'eip155:1',
    'polygon': 'eip155:137',
    'bsc': 'eip155:56',
    'solana': 'solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp',
  };
  
  /// 支持的方法
  static const List<String> supportedMethods = [
    'eth_sendTransaction',
    'eth_signTransaction',
    'eth_sign',
    'personal_sign',
    'eth_signTypedData',
    'eth_signTypedData_v4',
    'solana_signTransaction',
    'solana_signMessage',
  ];
  
  /// 支持的事件
  static const List<String> supportedEvents = [
    'chainChanged',
    'accountsChanged',
  ];
  
  /// 检查项目ID是否已配置
  static bool get isProjectIdConfigured {
    return projectId != '38d62272a06b73b1f9aab563e46185ae' && projectId.isNotEmpty;
  }
  
  /// 获取配置错误信息
  static String? getConfigError() {
    if (!isProjectIdConfigured) {
      return '请配置WalletConnect项目ID。访问 https://cloud.walletconnect.com 获取项目ID。';
    }
    return null;
  }
}