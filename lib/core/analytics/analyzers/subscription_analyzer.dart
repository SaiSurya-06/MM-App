import '../capability.dart';

class SubscriptionItem {
  final String title;
  final double amount;
  final DateTime lastBillingDate;
  final String frequency; // monthly, yearly
  final bool isUnused;

  const SubscriptionItem({
    required this.title,
    required this.amount,
    required this.lastBillingDate,
    required this.frequency,
    required this.isUnused,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'amount': amount,
        'lastBillingDate': lastBillingDate.toIso8601String(),
        'frequency': frequency,
        'isUnused': isUnused,
      };
}

class SubscriptionAnalysis {
  final double totalSubscriptionSpend;
  final List<SubscriptionItem> activeSubscriptions;
  final List<String> detectedLeaks;
  final String algorithmVersion;

  const SubscriptionAnalysis({
    required this.totalSubscriptionSpend,
    required this.activeSubscriptions,
    required this.detectedLeaks,
    this.algorithmVersion = '1.0.0',
  });

  Map<String, dynamic> toJson() => {
        'totalSubscriptionSpend': totalSubscriptionSpend,
        'activeSubscriptions': activeSubscriptions.map((e) => e.toJson()).toList(),
        'detectedLeaks': detectedLeaks,
        'algorithmVersion': algorithmVersion,
      };
}

class SubscriptionAnalyzer implements Capability<SubscriptionAnalysis> {
  @override
  String get id => 'subscription_analyzer';
  @override
  String get version => '1.1.0';
  @override
  String get name => 'Subscription Analyzer';
  @override
  List<Type> get dependencies => [];
  @override
  bool get isEnabled => true;

  @override
  Future<void> initialize() async {}

  @override
  bool supports(Intent intent) => false;


  @override
  Future<SubscriptionAnalysis> execute(OrchestratorContext context) async {
    final snapshot = context.snapshot;
    final currentMonth = snapshot.selectedMonth;
    final List<SubscriptionItem> activeSubs = [];
    final List<String> leaks = [];
    double totalSpend = 0.0;

    // Build category map for quick category name lookups
    final categoriesMap = {for (var cat in snapshot.categories) cat.id: cat};

    // Filter transactions for this month
    final thisMonthTxs = snapshot.transactions.where((tx) {
      final txMonth = tx.date.toIso8601String().substring(0, 7);
      return txMonth == currentMonth && tx.parentId == null;
    }).toList();

    // Scan for subscription keywords, tags, and categories
    for (var tx in thisMonthTxs) {
      if (tx.type != 'expense') continue;
      if (tx.recurrence == 'none') continue;

      final titleLower = tx.title.toLowerCase();
      final tagLower = tx.tags.toLowerCase();
      
      final category = categoriesMap[tx.categoryId];
      final categoryNameLower = category?.name.toLowerCase() ?? '';

      final excludedCategories = ['salary', 'income', 'rent', 'loan', 'emi', 'debt', 'transfer', 'investment'];
      if (excludedCategories.contains(categoryNameLower)) {
        continue;
      }

      final subscriptionKeywords = ['netflix', 'spotify', 'premium', 'subscription'];
      final isKeywordMatch = subscriptionKeywords.any((k) => titleLower.contains(k) || categoryNameLower.contains(k));
      final isTagMatch = tagLower.contains('subscription');
      
      final subscriptionCategories = ['entertainment', 'streaming', 'software', 'utilities'];
      final isCategoryMatch = subscriptionCategories.contains(categoryNameLower);

      if (isKeywordMatch || isTagMatch || isCategoryMatch) {
        final isUnused = titleLower.contains('gym') || tagLower.contains('unused') || tx.note?.toLowerCase().contains('unused') == true;
        
        activeSubs.add(SubscriptionItem(
          title: tx.title,
          amount: tx.amount,
          lastBillingDate: tx.date,
          frequency: tx.recurrence,
          isUnused: isUnused,
        ));
        
        totalSpend += tx.amount;

        if (isUnused) {
          leaks.add('Potential leak: Unused subscription "${tx.title}" of ₹${tx.amount.toStringAsFixed(0)} detected.');
        }
      }
    }

    // Add generic warning if total subscription spend is high (>10% of monthly average)
    if (totalSpend > 2000) {
      leaks.add('Subscription overhead is ₹${totalSpend.toStringAsFixed(0)}/month. Consider auditing active memberships.');
    }

    return SubscriptionAnalysis(
      totalSubscriptionSpend: totalSpend,
      activeSubscriptions: activeSubs,
      detectedLeaks: leaks,
    );
  }
}
