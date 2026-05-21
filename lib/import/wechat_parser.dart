import 'dart:io';
import 'package:excel/excel.dart';

class WechatBillItem {
  final DateTime tradeTime;
  final String platformCategory;
  final String counterparty;
  final String productDescription;
  final double amount;
  final String externalId;

  WechatBillItem({
    required this.tradeTime, required this.platformCategory,
    required this.counterparty, required this.productDescription,
    required this.amount, required this.externalId,
  });
}

class WechatParser {
  static List<WechatBillItem> parse(String filePath) {
    final bytes = File(filePath).readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables.values.first;
    final items = <WechatBillItem>[];

    bool headerFound = false;
    int timeCol = -1, typeCol = -1, counterpartyCol = -1, productCol = -1, amountCol = -1, orderCol = -1;

    for (final row in sheet.rows) {
      if (row.isEmpty) continue;

      final cells = row.map((c) => c?.value?.toString() ?? '').toList();

      // Find header
      if (!headerFound) {
        final rowStr = cells.join(',');
        if (rowStr.contains('交易时间') && rowStr.contains('交易类型')) {
          headerFound = true;
          // Find column indices
          for (int i = 0; i < cells.length; i++) {
            final c = cells[i].trim();
            if (c.contains('交易时间')) timeCol = i;
            if (c.contains('交易类型')) typeCol = i;
            if (c.contains('交易对方')) counterpartyCol = i;
            if (c.contains('商品')) productCol = i;
            if (c.contains('金额')) amountCol = i;
            if (c.contains('交易单号') || c.contains('订单号')) orderCol = i;
          }
        }
        continue;
      }

      if (timeCol < 0 || amountCol < 0) continue;

      try {
        final timeStr = cells[timeCol].trim();
        if (timeStr.isEmpty) continue;

        final tradeTime = DateTime.parse(timeStr);
        final platformCategory = typeCol >= 0 ? cells[typeCol].trim() : '';
        final counterparty = counterpartyCol >= 0 ? cells[counterpartyCol].trim() : '';
        final productDesc = productCol >= 0 ? cells[productCol].trim() : '';

        var amountStr = cells[amountCol].trim();
        // Remove ¥ or ￥ prefix
        amountStr = amountStr.replaceAll('¥', '').replaceAll('￥', '').trim();

        final amount = double.tryParse(amountStr) ?? 0;
        if (amount <= 0) continue;

        final externalId = orderCol >= 0 && orderCol < cells.length ? cells[orderCol].trim() : '';

        items.add(WechatBillItem(
          tradeTime: tradeTime,
          platformCategory: platformCategory,
          counterparty: counterparty,
          productDescription: productDesc,
          amount: amount,
          externalId: externalId,
        ));
      } catch (_) {
        // Skip malformed rows
      }
    }

    return items;
  }
}
