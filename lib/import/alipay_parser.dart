import 'dart:io';
import 'package:csv/csv.dart';

class AlipayBillItem {
  final DateTime tradeTime;
  final String platformCategory;
  final String counterparty;
  final String productDescription;
  final double amount;
  final String externalId;

  AlipayBillItem({
    required this.tradeTime, required this.platformCategory,
    required this.counterparty, required this.productDescription,
    required this.amount, required this.externalId,
  });
}

class AlipayParser {
  static List<AlipayBillItem> parse(String filePath) {
    final content = File(filePath).readAsStringSync();
    final lines = const CsvToListConverter().convert(content);
    final items = <AlipayBillItem>[];

    bool headerFound = false;
    for (final row in lines) {
      if (row.isEmpty) continue;
      final firstCell = row[0].toString().trim();

      // Find header
      if (!headerFound && firstCell.contains('交易时间')) {
        headerFound = true;
        continue;
      }
      if (!headerFound) continue;

      // Skip non-data rows
      if (firstCell.isEmpty || firstCell.startsWith('---') || firstCell.startsWith('备注')) continue;
      if (row.length < 7) continue;

      try {
        final tradeTime = DateTime.parse(firstCell);
        final platformCategory = row[1]?.toString().trim() ?? '';
        final counterparty = row[2]?.toString().trim() ?? '';
        final productDesc = row[4]?.toString().trim() ?? '';
        final direction = row[5]?.toString().trim() ?? '';
        final amountStr = row[6]?.toString().trim() ?? '0';
        final externalId = row.length > 9 ? row[9].toString().trim() : '';

        // Only import expenses
        if (!direction.contains('支出')) continue;
        if (amountStr.isEmpty || amountStr == '0' || amountStr == '0.00') continue;

        final amount = double.tryParse(amountStr) ?? 0;
        if (amount <= 0) continue;

        items.add(AlipayBillItem(
          tradeTime: tradeTime,
          platformCategory: platformCategory,
          counterparty: counterparty,
          productDescription: productDesc,
          amount: amount,
          externalId: externalId,
        ));
      } catch (_) {
        // Skip malformed lines
      }
    }

    return items;
  }
}
