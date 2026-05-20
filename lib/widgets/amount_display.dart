import 'package:flutter/material.dart';
import '../utils/currency_helper.dart';

class AmountDisplay extends StatelessWidget {
  final double amount;
  final double fontSize;
  final String currencyCode;
  final FontWeight fontWeight;
  final Color? color;

  const AmountDisplay({
    super.key, required this.amount, this.fontSize = 16,
    this.currencyCode = 'CNY', this.fontWeight = FontWeight.w600, this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      CurrencyHelper.format(amount, code: currencyCode),
      style: TextStyle(fontSize: fontSize, fontWeight: fontWeight,
          color: color ?? Theme.of(context).textTheme.bodyLarge?.color),
    );
  }
}
