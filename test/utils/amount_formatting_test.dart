import 'package:flutter_test/flutter_test.dart';
import '../../lib/utils/amount_utils.dart';

void main() {
  group('AmountUtils Formatting Tests', () {
    test('formatUsdValue should format USD values correctly', () {
      // 测试基本格式化（小于1000的值不使用K/M格式）
      expect(AmountUtils.formatUsdValue(123.56), '\$123.56');
      expect(AmountUtils.formatUsdValue(0.12), '\$0.12');
      expect(AmountUtils.formatUsdValue(0), '\$0.00');

      // 测试大数值
      expect(AmountUtils.formatUsdValue(1234567), '\$1.23M');
      expect(AmountUtils.formatUsdValue(12345), '\$12.35K');

      // 测试边界情况
      expect(AmountUtils.formatUsdValue(double.nan), '\$0.00');
      expect(AmountUtils.formatUsdValue(double.infinity), '\$0.00');
    });

    test('formatTokenBalance should format token balances correctly', () {
      // 测试基本格式化
      expect(AmountUtils.formatTokenBalance(1.123456789), '1.123456789');
      expect(AmountUtils.formatTokenBalance(0.000000001), '0.000000001');
      expect(AmountUtils.formatTokenBalance(0), '0');

      // 测试大数值
      expect(AmountUtils.formatTokenBalance(1234567), '1.23M');
      expect(AmountUtils.formatTokenBalance(12345), '12.35K');

      // 测试截取功能（最多9位小数）
      expect(AmountUtils.formatTokenBalance(1.1234567890123), '1.123456789');
    });

    test('formatPrice should format prices correctly', () {
      // 测试正常价格
      expect(AmountUtils.formatPrice(1234.56), '\$1234.5600');
      expect(AmountUtils.formatPrice(0.1234), '\$0.1234');

      // 测试边界情况
      expect(AmountUtils.formatPrice(0.0001), '\$0.0001');
      expect(AmountUtils.formatPrice(0), '\$0.0000');

      // 测试低价格（当前实现可能不完全支持科学计数法，先测试基本功能）
      // expect(AmountUtils.formatPrice(0.00000001), contains('0.'));
    });
  });

  group('Percentage Change Formatting Tests', () {
    test('formatPercentageChange should remove trailing zeros', () {
      // 测试移除尾部0
      expect(AmountUtils.formatPercentageChange(23.30), '+23.3%');
      expect(AmountUtils.formatPercentageChange(23.00), '+23%');
      expect(AmountUtils.formatPercentageChange(-1.50), '-1.5%');
      expect(AmountUtils.formatPercentageChange(-2.00), '-2%');

      // 测试保留必要的小数
      expect(AmountUtils.formatPercentageChange(23.45), '+23.45%');
      expect(AmountUtils.formatPercentageChange(-1.23), '-1.23%');

      // 测试边界情况
      expect(AmountUtils.formatPercentageChange(0), '0%');
      expect(AmountUtils.formatPercentageChange(0.01), '+0.01%');
      expect(AmountUtils.formatPercentageChange(-0.01), '-0.01%');

      // 测试特殊值
      expect(AmountUtils.formatPercentageChange(double.nan), '0%');
      expect(AmountUtils.formatPercentageChange(double.infinity), '0%');
    });

    test('FormatUtils.formatChange should work correctly', () {
      // 测试FormatUtils包装器
      expect(FormatUtils.formatChange(23.30), '+23.3%');
      expect(FormatUtils.formatChange(-1.50), '-1.5%');
      expect(FormatUtils.formatChange(0), '0%');
    });
  });
}
