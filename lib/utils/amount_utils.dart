import 'package:decimal/decimal.dart';

/// 金额计算工具类
/// 使用 Decimal 类型避免浮点数精度问题
class AmountUtils {
  /// 将 double 转换为 Decimal
  static Decimal fromDouble(double value) {
    // 直接使用toString()保持原始精度，不进行任何四舍五入
    return Decimal.parse(value.toString());
  }

  /// 将 Decimal 转换为 double
  static double toDouble(Decimal value) {
    return value.toDouble();
  }

  /// 将字符串转换为 Decimal
  static Decimal fromString(String value) {
    try {
      return Decimal.parse(value);
    } catch (e) {
      return Decimal.zero;
    }
  }

  /// 加法运算
  static Decimal add(dynamic a, dynamic b) {
    final decimalA = _toDecimal(a);
    final decimalB = _toDecimal(b);
    return decimalA + decimalB;
  }

  /// 减法运算
  static Decimal subtract(dynamic a, dynamic b) {
    final decimalA = _toDecimal(a);
    final decimalB = _toDecimal(b);
    return decimalA - decimalB;
  }

  /// 乘法运算
  static Decimal multiply(dynamic a, dynamic b) {
    final decimalA = _toDecimal(a);
    final decimalB = _toDecimal(b);
    return decimalA * decimalB;
  }

  /// 除法运算
  static Decimal divide(dynamic a, dynamic b) {
    final decimalA = _toDecimal(a);
    final decimalB = _toDecimal(b);
    if (decimalB == Decimal.zero) {
      throw ArgumentError('Division by zero');
    }
    return (decimalA / decimalB).toDecimal();
  }

  /// 比较：a > b
  static bool greaterThan(dynamic a, dynamic b) {
    final decimalA = _toDecimal(a);
    final decimalB = _toDecimal(b);
    return decimalA > decimalB;
  }

  /// 比较：a >= b
  static bool greaterThanOrEqual(dynamic a, dynamic b) {
    final decimalA = _toDecimal(a);
    final decimalB = _toDecimal(b);
    return decimalA >= decimalB;
  }

  /// 比较：a < b
  static bool lessThan(dynamic a, dynamic b) {
    final decimalA = _toDecimal(a);
    final decimalB = _toDecimal(b);
    return decimalA < decimalB;
  }

  /// 比较：a <= b
  static bool lessThanOrEqual(dynamic a, dynamic b) {
    final decimalA = _toDecimal(a);
    final decimalB = _toDecimal(b);
    return decimalA <= decimalB;
  }

  /// 比较：a == b
  static bool equals(dynamic a, dynamic b) {
    final decimalA = _toDecimal(a);
    final decimalB = _toDecimal(b);
    return decimalA == decimalB;
  }

  /// 格式化为字符串（指定小数位数）
  // static String format(dynamic value, {int decimals = 8}) {
  //   final decimal = _toDecimal(value);
  //   return decimal.toStringAsFixed(decimals);
  // }
  static String format(dynamic value, {int decimals = 8}) {
    return value.toString();
  }

  /// 格式化为字符串（移除尾部的0）
  static String formatCompact(dynamic value, {int maxDecimals = 8}) {
    final decimal = _toDecimal(value);
    String str = decimal.toStringAsFixed(maxDecimals);

    // 移除尾部的0
    if (str.contains('.')) {
      str = str.replaceAll(RegExp(r'0+$'), '');
      str = str.replaceAll(RegExp(r'\.$'), '');
    }

    return str;
  }

  /// 格式化为字符串（截取指定小数位数，不进行四舍五入）
  static String formatTruncated(dynamic value, {int decimals = 9}) {
    final decimal = _toDecimal(value);
    String str = decimal.toString();

    // 如果没有小数点，直接返回
    if (!str.contains('.')) {
      return str;
    }

    // 分离整数部分和小数部分
    List<String> parts = str.split('.');
    String integerPart = parts[0];
    String decimalPart = parts[1];

    // 截取小数部分到指定位数
    if (decimalPart.length > decimals) {
      decimalPart = decimalPart.substring(0, decimals);
    }

    // 移除尾部的0
    decimalPart = decimalPart.replaceAll(RegExp(r'0+$'), '');

    // 如果小数部分为空，只返回整数部分
    if (decimalPart.isEmpty) {
      return integerPart;
    }

    return '$integerPart.$decimalPart';
  }

  /// 检查是否为零
  static bool isZero(dynamic value) {
    final decimal = _toDecimal(value);
    return decimal == Decimal.zero;
  }

  /// 检查是否为正数
  static bool isPositive(dynamic value) {
    final decimal = _toDecimal(value);
    return decimal > Decimal.zero;
  }

  /// 检查是否为负数
  static bool isNegative(dynamic value) {
    final decimal = _toDecimal(value);
    return decimal < Decimal.zero;
  }

  /// 获取最小值
  static Decimal min(dynamic a, dynamic b) {
    final decimalA = _toDecimal(a);
    final decimalB = _toDecimal(b);
    return decimalA < decimalB ? decimalA : decimalB;
  }

  /// 获取最大值
  static Decimal max(dynamic a, dynamic b) {
    final decimalA = _toDecimal(a);
    final decimalB = _toDecimal(b);
    return decimalA > decimalB ? decimalA : decimalB;
  }

  /// 获取绝对值
  static Decimal abs(dynamic value) {
    final decimal = _toDecimal(value);
    return decimal.abs();
  }

  /// 转换为 Decimal（内部辅助方法）
  static Decimal _toDecimal(dynamic value) {
    if (value is Decimal) {
      return value;
    } else if (value is double) {
      return fromDouble(value);
    } else if (value is int) {
      return Decimal.fromInt(value);
    } else if (value is String) {
      return fromString(value);
    } else {
      throw ArgumentError('Unsupported type: ${value.runtimeType}');
    }
  }

  /// 计算可用于发送的最大金额（余额 - 手续费）
  /// 返回 Decimal 类型
  static Decimal calculateMaxSendAmount(dynamic balance, dynamic gasFee) {
    final balanceDecimal = _toDecimal(balance);
    final gasFeeDecimal = _toDecimal(gasFee);

    final maxAmount = balanceDecimal - gasFeeDecimal;

    // 如果结果为负数，返回0
    return maxAmount > Decimal.zero ? maxAmount : Decimal.zero;
  }

  /// 验证余额是否足够（金额 + 手续费 <= 余额）
  static bool isSufficientBalance(
    dynamic amount,
    dynamic gasFee,
    dynamic balance,
  ) {
    final amountDecimal = _toDecimal(amount);
    final gasFeeDecimal = _toDecimal(gasFee);
    final balanceDecimal = _toDecimal(balance);

    final totalRequired = amountDecimal + gasFeeDecimal;
    return totalRequired <= balanceDecimal;
  }

  /// 将 Lamports (Solana) 转换为 SOL
  static Decimal lamportsToSol(int lamports) {
    return (Decimal.fromInt(lamports) / Decimal.fromInt(1000000000))
        .toDecimal();
  }

  /// 将 SOL 转换为 Lamports (Solana)
  static int solToLamports(dynamic sol) {
    final solDecimal = _toDecimal(sol);
    final lamportsDecimal = solDecimal * Decimal.fromInt(1000000000);
    return lamportsDecimal.toBigInt().toInt();
  }

  /// 将 Wei (Ethereum) 转换为 ETH
  static Decimal weiToEth(BigInt wei) {
    return (Decimal.fromBigInt(wei) /
            Decimal.fromBigInt(BigInt.from(10).pow(18)))
        .toDecimal();
  }

  /// 将 ETH 转换为 Wei (Ethereum)
  static BigInt ethToWei(dynamic eth) {
    final ethDecimal = _toDecimal(eth);
    final weiDecimal = ethDecimal * Decimal.fromBigInt(BigInt.from(10).pow(18));
    return weiDecimal.toBigInt();
  }

  /// 将 Satoshi (Bitcoin) 转换为 BTC
  static Decimal satoshiToBtc(int satoshi) {
    return (Decimal.fromInt(satoshi) / Decimal.fromInt(100000000)).toDecimal();
  }

  /// 将 BTC 转换为 Satoshi (Bitcoin)
  static int btcToSatoshi(dynamic btc) {
    final btcDecimal = _toDecimal(btc);
    final satoshiDecimal = btcDecimal * Decimal.fromInt(100000000);
    return satoshiDecimal.toBigInt().toInt();
  }

  /// 格式化美元价值显示（固定2位小数）
  static String formatUsdValue(dynamic value) {
    // 先检查特殊值
    if (value is double && (value.isNaN || value.isInfinite)) {
      return '\$0.00';
    }

    final decimal = _toDecimal(value);

    final doubleValue = decimal.toDouble();
    if (doubleValue >= 1000000) {
      return '\$${(doubleValue / 1000000).toStringAsFixed(2)}M';
    } else if (doubleValue >= 1000) {
      return '\$${(doubleValue / 1000).toStringAsFixed(2)}K';
    } else {
      return '\$${doubleValue.toStringAsFixed(2)}';
    }
  }

  /// 格式化代币余额显示（最多9位小数，截取不四舍五入）
  static String formatTokenBalance(dynamic balance) {
    // 先检查特殊值
    if (balance is double && (balance.isNaN || balance.isInfinite)) {
      return '0';
    }

    final decimal = _toDecimal(balance);

    final doubleValue = decimal.toDouble();
    if (doubleValue >= 1000000) {
      return '${(doubleValue / 1000000).toStringAsFixed(2)}M';
    } else if (doubleValue >= 1000) {
      return '${(doubleValue / 1000).toStringAsFixed(2)}K';
    } else {
      return formatTruncated(balance, decimals: 9);
    }
  }

  /// 格式化币价显示（4位小数，支持科学计数法表示）
  static String formatPrice(dynamic price) {
    // 先检查特殊值
    if (price is double && (price.isNaN || price.isInfinite)) {
      return '\$0.0000';
    }

    final decimal = _toDecimal(price);

    final doubleValue = decimal.toDouble();

    // 如果价格大于等于1，显示4位小数
    if (doubleValue >= 1) {
      return '\$${doubleValue.toStringAsFixed(4)}';
    }

    // 如果价格小于1但大于等于0.0001，显示4位小数
    if (doubleValue >= 0.0001) {
      return '\$${doubleValue.toStringAsFixed(4)}';
    }

    // 如果价格非常小，使用科学计数法表示
    if (doubleValue > 0) {
      // 计算前导零的个数
      String str = doubleValue.toStringAsExponential();

      // 转换为 0.{n}x 格式
      if (str.contains('e-')) {
        List<String> parts = str.split('e-');
        double coefficient = double.parse(parts[0]);
        int exponent = int.parse(parts[1]);

        // 如果指数大于6，使用 0.{n}x 格式
        if (exponent > 6) {
          int zeros = exponent - 1;
          String coefficientStr = coefficient.toStringAsFixed(1);
          // 移除小数点
          coefficientStr = coefficientStr.replaceAll('.', '');
          return '\$0.{$zeros}$coefficientStr';
        }
      }
    }

    return '\$${doubleValue.toStringAsFixed(4)}';
  }

  /// 格式化百分比变化（移除尾部的0）
  static String formatPercentageChange(double change) {
    // 先检查特殊值
    if (change.isNaN || change.isInfinite) {
      return '0%';
    }

    // 格式化为2位小数
    String formatted = change.toStringAsFixed(2);

    // 移除尾部的0和小数点
    if (formatted.contains('.')) {
      formatted = formatted.replaceAll(RegExp(r'0+$'), '');
      formatted = formatted.replaceAll(RegExp(r'\.$'), '');
    }

    // 特殊处理0的情况
    if (change == 0.0 || formatted == '0') {
      return '0%';
    }

    return '${change > 0 ? '+' : ''}$formatted%';
  }
}

/// 格式化工具类 - 提供便捷的静态方法
class FormatUtils {
  /// 格式化美元价值显示（固定2位小数）
  static String formatValue(double value) {
    return AmountUtils.formatUsdValue(value);
  }

  /// 格式化代币余额显示（最多9位小数）
  static String formatBalance(double balance) {
    return AmountUtils.formatTokenBalance(balance);
  }

  /// 格式化币价显示（4位小数或科学计数法）
  static String formatPrice(double price) {
    return AmountUtils.formatPrice(price);
  }

  /// 格式化百分比变化
  static String formatChange(double change) {
    return AmountUtils.formatPercentageChange(change);
  }
}
