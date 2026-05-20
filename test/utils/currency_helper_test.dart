import 'package:flutter_test/flutter_test.dart';
import 'package:aiaccounting/utils/currency_helper.dart';

void main() {
  group('CurrencyHelper', () {
    test('format CNY', () {
      expect(CurrencyHelper.format(1234.56), '¥1,234.56');
    });

    test('format USD', () {
      expect(CurrencyHelper.format(1234.56, code: 'USD'), '\$1,234.56');
    });

    test('symbol returns code for unknown', () {
      expect(CurrencyHelper.symbol('XYZ'), 'XYZ');
    });
  });
}
