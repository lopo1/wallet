/// 网络常量定义
/// 统一管理各个区块链网络的公共变量
class NetworkConstants {
  // 小数精度
  static const int solanaDecimals = 9;
  static const int ethereumDecimals = 18;
  static const int bitcoinDecimals = 8;
  
  // 小数精度转换因子
  static const double solanaDecimalFactor = 1000000000.0; // 10^9
  static const double ethereumDecimalFactor = 1000000000000000000.0; // 10^18
  static const double bitcoinDecimalFactor = 100000000.0; // 10^8
  
  // 默认Gas限制
  static const int evmStandardTransferGasLimit = 21000;
  static const int evmContractCallGasLimit = 100000;
  
  // 默认基础费用 (单位: 原生代币)
  static const double solanaBaseFee = 0.000005;
  static const double ethereumBaseFee = 0.001;
  static const double bscBaseFee = 0.001;
  static const double polygonBaseFee = 0.001;
  static const double bitcoinBaseFee = 0.0001;
  
  // 费用波动范围
  static const double feeVariationRange = 0.01;
  static const int feeVariationModulo = 1000;
  static const double feeVariationDivisor = 100000.0;
  
  // 比特币费用波动
  static const int bitcoinFeeVariationModulo = 500;
  static const double bitcoinFeeVariationDivisor = 50000.0;
  
  // 优先费倍数选项
  static const double standardPriorityMultiplier = 1.0;
  static const double fastPriorityMultiplier = 2.0;
  static const double veryFastPriorityMultiplier = 4.0;
  
  // 费用更新阈值 (避免微小变化导致频繁更新)
  static const double feeUpdateThreshold = 0.000001;
  
  // 网络ID常量
  static const String ethereumNetworkId = 'ethereum';
  static const String bscNetworkId = 'bsc';
  static const String polygonNetworkId = 'polygon';
  static const String solanaNetworkId = 'solana';
  static const String bitcoinNetworkId = 'bitcoin';
  
  // 单位转换辅助方法
  static double lamportsToSol(int lamports) {
    return lamports / solanaDecimalFactor;
  }
  
  static int solToLamports(double sol) {
    return (sol * solanaDecimalFactor).round();
  }
  
  static double weiToEth(BigInt wei) {
    return wei.toDouble() / ethereumDecimalFactor;
  }
  
  static BigInt ethToWei(double eth) {
    return BigInt.from(eth * ethereumDecimalFactor);
  }
  
  static double satoshisToBtc(int satoshis) {
    return satoshis / bitcoinDecimalFactor;
  }
  
  static int btcToSatoshis(double btc) {
    return (btc * bitcoinDecimalFactor).round();
  }
}