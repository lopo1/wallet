import 'package:flutter_test/flutter_test.dart';
import 'package:decimal/decimal.dart';
import 'package:harbor/utils/amount_utils.dart';

void main() {
  group('AmountUtils', () {
    group('基本运算', () {
      test('加法运算', () {
        final result = AmountUtils.add(0.1, 0.2);
        expect(result, Decimal.parse('0.3'));
        expect(AmountUtils.toDouble(result), 0.3);
      });

      test('减法运算', () {
        final result = AmountUtils.subtract(0.3, 0.1);
        expect(result, Decimal.parse('0.2'));
      });

      test('乘法运算', () {
        final result = AmountUtils.multiply(0.1, 3);
        expect(result, Decimal.parse('0.3'));
      });

      test('除法运算', () {
        final result = AmountUtils.divide(0.3, 3);
        expect(result, Decimal.parse('0.1'));
      });

      test('除以零应该抛出异常', () {
        expect(() => AmountUtils.divide(1, 0), throwsArgumentError);
      });
    });

    group('比较运算', () {
      test('大于', () {
        expect(AmountUtils.greaterThan(0.2, 0.1), true);
        expect(AmountUtils.greaterThan(0.1, 0.2), false);
        expect(AmountUtils.greaterThan(0.1, 0.1), false);
      });

      test('大于等于', () {
        expect(AmountUtils.greaterThanOrEqual(0.2, 0.1), true);
        expect(AmountUtils.greaterThanOrEqual(0.1, 0.1), true);
        expect(AmountUtils.greaterThanOrEqual(0.1, 0.2), false);
      });

      test('小于', () {
        expect(AmountUtils.lessThan(0.1, 0.2), true);
        expect(AmountUtils.lessThan(0.2, 0.1), false);
        expect(AmountUtils.lessThan(0.1, 0.1), false);
      });

      test('小于等于', () {
        expect(AmountUtils.lessThanOrEqual(0.1, 0.2), true);
        expect(AmountUtils.lessThanOrEqual(0.1, 0.1), true);
        expect(AmountUtils.lessThanOrEqual(0.2, 0.1), false);
      });

      test('等于', () {
        expect(AmountUtils.equals(0.1, 0.1), true);
        expect(AmountUtils.equals(0.1, 0.2), false);
      });
    });

    group('格式化', () {
      test('格式化为固定小数位', () {
        expect(AmountUtils.format(0.123456789, decimals: 8), '0.12345679');
        expect(AmountUtils.format(0.1, decimals: 8), '0.10000000');
      });

      test('紧凑格式化（移除尾部0）', () {
        expect(AmountUtils.formatCompact(0.1), '0.1');
        expect(AmountUtils.formatCompact(0.10000000), '0.1');
        expect(AmountUtils.formatCompact(1.0), '1');
      });
    });

    group('状态检查', () {
      test('是否为零', () {
        expect(AmountUtils.isZero(0), true);
        expect(AmountUtils.isZero(0.0), true);
        expect(AmountUtils.isZero(0.1), false);
      });

      test('是否为正数', () {
        expect(AmountUtils.isPositive(0.1), true);
        expect(AmountUtils.isPositive(0), false);
        expect(AmountUtils.isPositive(-0.1), false);
      });

      test('是否为负数', () {
        expect(AmountUtils.isNegative(-0.1), true);
        expect(AmountUtils.isNegative(0), false);
        expect(AmountUtils.isNegative(0.1), false);
      });
    });

    group('最大/最小值', () {
      test('最小值', () {
        final result = AmountUtils.min(0.1, 0.2);
        expect(result, Decimal.parse('0.1'));
      });

      test('最大值', () {
        final result = AmountUtils.max(0.1, 0.2);
        expect(result, Decimal.parse('0.2'));
      });

      test('绝对值', () {
        expect(AmountUtils.abs(-0.1), Decimal.parse('0.1'));
        expect(AmountUtils.abs(0.1), Decimal.parse('0.1'));
      });
    });

    group('余额计算', () {
      test('计算最大发送金额', () {
        final balance = 0.12345678;
        final gasFee = 0.00000496;
        final maxAmount = AmountUtils.calculateMaxSendAmount(balance, gasFee);

        // 验证：maxAmount + gasFee = balance
        final total = AmountUtils.add(maxAmount, gasFee);
        expect(AmountUtils.equals(total, balance), true);
      });

      test('余额不足时返回0', () {
        final balance = 0.00000400;
        final gasFee = 0.00000496;
        final maxAmount = AmountUtils.calculateMaxSendAmount(balance, gasFee);

        expect(AmountUtils.isZero(maxAmount), true);
      });

      test('验证余额是否足够', () {
        final amount = 0.1;
        final gasFee = 0.00000496;
        final balance = 0.12345678;

        expect(
          AmountUtils.isSufficientBalance(amount, gasFee, balance),
          true,
        );
      });

      test('验证余额不足', () {
        final amount = 0.2;
        final gasFee = 0.00000496;
        final balance = 0.12345678;

        expect(
          AmountUtils.isSufficientBalance(amount, gasFee, balance),
          false,
        );
      });
    });

    group('浮点数精度问题测试', () {
      test('0.1 + 0.2 应该等于 0.3', () {
        // 使用 double 会有精度问题
        expect(0.1 + 0.2 == 0.3, false);

        // 使用 Decimal 没有精度问题
        final result = AmountUtils.add(0.1, 0.2);
        expect(AmountUtils.equals(result, 0.3), true);
      });

      test('余额减去手续费再加回来应该等于原余额', () {
        final balance = 0.12345678;
        final gasFee = 0.00000496;

        // 使用 double 可能有精度问题
        final doubleMaxAmount = balance - gasFee;
        final doubleTotal = doubleMaxAmount + gasFee;
        // 可能不相等

        // 使用 Decimal 没有精度问题
        final maxAmount = AmountUtils.calculateMaxSendAmount(balance, gasFee);
        final total = AmountUtils.add(maxAmount, gasFee);
        expect(AmountUtils.equals(total, balance), true);
      });

      test('全部按钮场景测试', () {
        final balance = 0.12345678;
        final gasFee = 0.00000496;

        // 计算最大金额
        final maxAmount = AmountUtils.calculateMaxSendAmount(balance, gasFee);

        // 验证余额是否足够
        expect(
          AmountUtils.isSufficientBalance(maxAmount, gasFee, balance),
          true,
        );
      });
    });

    group('单位转换', () {
      test('Lamports 转 SOL', () {
        final lamports = 1000000000; // 1 SOL
        final sol = AmountUtils.lamportsToSol(lamports);
        expect(sol, Decimal.one);
      });

      test('SOL 转 Lamports', () {
        final sol = 1.5;
        final lamports = AmountUtils.solToLamports(sol);
        expect(lamports, 1500000000);
      });

      test('Wei 转 ETH', () {
        final wei = BigInt.from(10).pow(18); // 1 ETH
        final eth = AmountUtils.weiToEth(wei);
        expect(eth, Decimal.one);
      });

      test('ETH 转 Wei', () {
        final eth = 1.5;
        final wei = AmountUtils.ethToWei(eth);
        expect(wei, BigInt.parse('1500000000000000000'));
      });

      test('Satoshi 转 BTC', () {
        final satoshi = 100000000; // 1 BTC
        final btc = AmountUtils.satoshiToBtc(satoshi);
        expect(btc, Decimal.one);
      });

      test('BTC 转 Satoshi', () {
        final btc = 1.5;
        final satoshi = AmountUtils.btcToSatoshi(btc);
        expect(satoshi, 150000000);
      });
    });

    group('边界情况', () {
      test('处理非常小的数字', () {
        final tiny = 0.00000001;
        final result = AmountUtils.add(tiny, tiny);
        expect(AmountUtils.format(result), '0.00000002');
      });

      test('处理非常大的数字', () {
        final large = 1000000000.0;
        final result = AmountUtils.add(large, 1);
        expect(AmountUtils.toDouble(result), 1000000001.0);
      });

      test('处理字符串输入', () {
        final result = AmountUtils.add('0.1', '0.2');
        expect(AmountUtils.equals(result, 0.3), true);
      });

      test('处理无效字符串', () {
        final result = AmountUtils.fromString('invalid');
        expect(AmountUtils.isZero(result), true);
      });
    });
  });
}
