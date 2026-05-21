class CategoryMapper {
  // Map the platform's original category name → our app category name
  // Returns null if no match found (caller should fall back to '其他')
  static String? mapAlipay(String platformCategory) {
    final lower = platformCategory.trim();
    if (lower.contains('餐饮')) return '餐饮';
    if (lower.contains('交通') || lower.contains('出行')) return '交通';
    if (lower.contains('日用') || lower.contains('百货') || lower.contains('购物')) return '购物';
    if (lower.contains('文化') || lower.contains('休闲') || lower.contains('娱乐')) return '娱乐';
    if (lower.contains('医疗') || lower.contains('健康')) return '医疗';
    if (lower.contains('住房') || lower.contains('缴费') || lower.contains('充值')) return '住房';
    return null; // fallback to '其他'
  }

  static String? mapWechat(String platformCategory) {
    final lower = platformCategory.trim();
    if (lower.contains('餐饮')) return '餐饮';
    if (lower.contains('交通')) return '交通';
    if (lower.contains('购物') || lower.contains('消费')) return '购物';
    if (lower.contains('娱乐')) return '娱乐';
    if (lower.contains('医疗')) return '医疗';
    if (lower.contains('生活') || lower.contains('缴费') || lower.contains('住房')) return '住房';
    return null;
  }
}
