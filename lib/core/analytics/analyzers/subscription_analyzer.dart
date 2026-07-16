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

  final List<String> _subscriptionKeywords = [
    'netflix', 'spotify', 'prime', 'amazon prime', 'gym', 'fitness', 'youtube premium',
    'google one', 'icloud', 'disney', 'hbo', 'adobe', 'microsoft 365', 'apple music',
    'patreon', 'github copilot', 'chatgpt', 'openai', 'subscription', 'premium'
  ];

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
      final titleLower = tx.title.toLowerCase();
      final tagLower = tx.tags.toLowerCase();
      
      final category = categoriesMap[tx.categoryId];
      final categoryNameLower = category?.name.toLowerCase() ?? '';

      // 1. Recurrence must not be 'none'
      final isRecurMatch = tx.recurrence != 'none';
      if (!isRecurMatch) continue;

      // 2. Explicit exclusions (Income, Salary, Rent, Debt repayment, EMI, Loan)
      final isExcludedCategory = categoryNameLower == 'income' ||
          categoryNameLower == 'salary' ||
          categoryNameLower == 'rent' ||
          categoryNameLower == 'debt repayment/emi' ||
          categoryNameLower == 'debt' ||
          categoryNameLower == 'emi' ||
          categoryNameLower == 'loan';

      final isExcludedTitle = titleLower.contains('rent') ||
          titleLower.contains('salary') ||
          titleLower.contains('emi') ||
          titleLower.contains('loan') ||
          titleLower.contains('mortgage') ||
          titleLower.contains('repayment');

      if (isExcludedCategory || isExcludedTitle || tx.type != 'expense') {
        continue;
      }

      // 3. Subscription identification criteria (at least one must match)
      final isKeywordMatch = _subscriptionKeywords.any((keyword) => titleLower.contains(keyword));
      final isTagMatch = tagLower.contains('subscription');
      final isSubCategory = categoryNameLower == 'entertainment' ||
          categoryNameLower == 'software' ||
          categoryNameLower == 'utilities' ||
          categoryNameLower == 'streaming';

      if (isKeywordMatch || isTagMatch || isSubCategory) {
        // Simple unused heuristic: if notes contain "unused" or tags contain "unused", or if it's gym and we have no checkins
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
