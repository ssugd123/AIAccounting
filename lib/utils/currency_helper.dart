import 'package:intl/intl.dart';
import 'constants.dart';

class CurrencyHelper {
  static String format(double amount, {String code = 'CNY'}) {
    final symbol = currencySymbols[code] ?? code;
    final formatter = NumberFormat('#,##0.00');
    return '$symbol${formatter.format(amount)}';
  }

  static String symbol(String code) => currencySymbols[code] ?? code;
}
