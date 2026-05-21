import 'alipay_parser.dart';
import 'wechat_parser.dart';
import 'category_mapper.dart';

enum BillType { wechat, alipay, unsupported }

class UnifiedBillItem {
  final DateTime tradeTime;
  final String platformCategory;
  final String counterparty;
  final String productDescription;
  final double amount;
  final String externalId;
  final BillType billType;
  final String mappedCategory; // our app category

  UnifiedBillItem({
    required this.tradeTime, required this.platformCategory,
    required this.counterparty, required this.productDescription,
    required this.amount, required this.externalId, required this.billType,
    required this.mappedCategory,
  });
}

class BillParseResult {
  final BillType billType;
  final List<UnifiedBillItem> items;
  final String? error;

  BillParseResult(this.billType, this.items, {this.error});

  bool get isSuccess => error == null && items.isNotEmpty;
}

class BillParser {
  static BillParseResult parse(String filePath, String fileName) {
    final lower = fileName.toLowerCase();

    try {
      if (lower.endsWith('.csv')) {
        final items = AlipayParser.parse(filePath);
        if (items.isEmpty) return BillParseResult(BillType.alipay, [], error: '文件中未找到支出记录');
        return BillParseResult(
          BillType.alipay,
          items.map((i) => UnifiedBillItem(
            tradeTime: i.tradeTime, platformCategory: i.platformCategory,
            counterparty: i.counterparty, productDescription: i.productDescription,
            amount: i.amount, externalId: i.externalId, billType: BillType.alipay,
            mappedCategory: CategoryMapper.mapAlipay(i.platformCategory) ?? '其他',
          )).toList(),
        );
      }

      if (lower.endsWith('.xlsx')) {
        final items = WechatParser.parse(filePath);
        if (items.isEmpty) return BillParseResult(BillType.wechat, [], error: '文件中未找到支出记录');
        return BillParseResult(
          BillType.wechat,
          items.map((i) => UnifiedBillItem(
            tradeTime: i.tradeTime, platformCategory: i.platformCategory,
            counterparty: i.counterparty, productDescription: i.productDescription,
            amount: i.amount, externalId: i.externalId, billType: BillType.wechat,
            mappedCategory: CategoryMapper.mapWechat(i.platformCategory) ?? '其他',
          )).toList(),
        );
      }

      return BillParseResult(BillType.unsupported, [], error: '文件类型不支持，请导入微信(.xlsx)或支付宝(.csv)账单文件');
    } catch (e) {
      return BillParseResult(BillType.unsupported, [], error: '文件解析失败: $e');
    }
  }
}
