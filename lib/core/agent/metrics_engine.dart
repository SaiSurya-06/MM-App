import 'financial_brain.dart';

class MetricsEngine implements FinancialEngine {
  static String _getBaseMerchant(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('swiggy')) return 'Swiggy';
    if (lower.contains('zomato')) return 'Zomato';
    if (lower.contains('amazon')) return 'Amazon';
    if (lower.contains('netflix')) return 'Netflix';
    if (lower.contains('uber')) return 'Uber';
    if (lower.contains('ola')) return 'Ola';
    if (lower.contains('flipkart')) return 'Flipkart';
    if (lower.contains('starbucks')) return 'Starbucks';
    return title;
  }

  @override
  Future<FinancialContext> execute(FinancialContext context) async {
    final rows = context.rawData.transactions;

    double totalAmount = 0.0;
    double totalIncome = 0.0;
    double totalExpense = 0.0;
    
    for (var r in rows) {
      final amt = (r['amount'] as num).toDouble();
      totalAmount += amt;
      if (r['type'] == 'income') {
        totalIncome += amt;
      } else {
        totalExpense += amt;
      }
    }
    
    final averageAmount = rows.isNotEmpty ? totalAmount / rows.length : 0.0;

    Map<String, dynamic>? largestTransaction;
    if (rows.isNotEmpty) {
      largestTransaction = rows.reduce((a, b) =>
          (a['amount'] as num).toDouble() > (b['amount'] as num).toDouble() ? a : b);
    }

    final categoryShares = <String, double>{};
    for (var r in rows) {
      final cat = r['category']?.toString() ?? 'Other';
      categoryShares[cat] = (categoryShares[cat] ?? 0.0) + (r['amount'] as num).toDouble();
    }
    final topCategory = categoryShares.entries.isNotEmpty
        ? categoryShares.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : "N/A";

    final merchantShares = <String, double>{};
    for (var r in rows) {
      final title = r['title']?.toString() ?? 'Other';
      final merch = _getBaseMerchant(title);
      merchantShares[merch] = (merchantShares[merch] ?? 0.0) + (r['amount'] as num).toDouble();
    }
    final topMerchant = merchantShares.entries.isNotEmpty
        ? merchantShares.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : "N/A";

    final metrics = {
      'totalAmount': totalAmount,
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'averageAmount': averageAmount,
      'transactionCount': rows.length,
      'largestTransaction': largestTransaction,
      'categoryShares': categoryShares,
      'merchantShares': merchantShares,
      'topCategory': topCategory,
      'topMerchant': topMerchant,
    };

    return context.copyWith(metrics: metrics);
  }
}
