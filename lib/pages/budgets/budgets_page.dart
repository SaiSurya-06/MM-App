import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/budgets_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../models/budget.dart';
import 'budget_form.dart';
import '../../../widgets/common/glassmorphism_card.dart';
import '../../core/database/database.dart';
import '../../core/utils/currency_formatter.dart';
import 'package:intl/intl.dart';

class BudgetsPage extends ConsumerStatefulWidget {
  const BudgetsPage({super.key});

  @override
  ConsumerState<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends ConsumerState<BudgetsPage> {
  List<Map<String, dynamic>> _categories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final db = await AppDatabase.instance.database;
      final list = await db.query('category');
      setState(() {
        _categories = list;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
    }
  }

  void _openBudgetForm(BuildContext context, [int? categoryId, double? currentLimit]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BudgetForm(
        categoryId: categoryId,
        currentLimit: currentLimit,
      ),
    ).then((_) {
      // Reload budget spendings for currently selected month
      final month = ref.read(budgetsProvider).selectedMonth;
      ref.read(budgetsProvider.notifier).loadBudgetsForMonth(month);
    });
  }

  Widget _buildMonthAndLimitsBentoCard(BuildContext context, BudgetsState state, int activeBudgetsCount) {
    final DateTime monthDateTime = DateTime.parse('${state.selectedMonth}-01');
    final monthLabel = DateFormat('MMM yyyy').format(monthDateTime);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassmorphismCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'PERIOD',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.0,
              fontFamily: 'Inter',
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  final prev = DateTime(monthDateTime.year, monthDateTime.month - 1);
                  ref.read(budgetsProvider.notifier).selectMonth(prev.toIso8601String().substring(0, 7));
                },
                icon: const Icon(Icons.chevron_left, size: 18),
                color: isDark ? Colors.white70 : Colors.black87,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              Text(
                monthLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
              IconButton(
                onPressed: () {
                  final next = DateTime(monthDateTime.year, monthDateTime.month + 1);
                  ref.read(budgetsProvider.notifier).selectMonth(next.toIso8601String().substring(0, 7));
                },
                icon: const Icon(Icons.chevron_right, size: 18),
                color: isDark ? Colors.white70 : Colors.black87,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          Text(
            '$activeBudgetsCount Active Limits',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallLimitBentoCard(BuildContext context, double spent, double limit, String currency, int totalBudgetCatId) {
    final percent = limit > 0 ? (spent / limit) : 0.0;
    final percentClamped = percent.clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color progressColor = Colors.greenAccent;
    if (percent >= 1.0) {
      progressColor = const Color(0xFFE53935);
    } else if (percent >= 0.8) {
      progressColor = Colors.orangeAccent;
    }

    return GlassmorphismCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'OVERALL CAP',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.0,
                  fontFamily: 'Inter',
                ),
              ),
              IconButton(
                onPressed: () => _openBudgetForm(context, totalBudgetCatId, limit),
                icon: const Icon(Icons.edit, size: 14, color: Colors.grey),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${CurrencyFormatter.format(spent, currency)} / ${CurrencyFormatter.format(limit, currency)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: percentClamped,
              minHeight: 5,
              backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          Text(
            '${(percent * 100).toStringAsFixed(0)}% Used',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: progressColor,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetOverallCapPlaceholder(BuildContext context, int totalBudgetCatId) {
    return GlassmorphismCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'OVERALL CAP',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.0,
              fontFamily: 'Inter',
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'No cap set for this month',
                style: TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'Inter'),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 28,
            child: ElevatedButton(
              onPressed: () => _openBudgetForm(context, totalBudgetCatId),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935).withValues(alpha: 0.15),
                foregroundColor: const Color(0xFFE53935),
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Set Cap', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _openAccountForm(BuildContext context, int catId, double limit) {
    _openBudgetForm(context, catId, limit);
  }

  Widget _buildTotalItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.0,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final budgetsState = ref.watch(budgetsProvider);
    final authState = ref.watch(authProvider);
    final analyticsState = ref.watch(analyticsProvider);

    final currency = authState.profile?.preferredCurrency ?? 'USD';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Create a map of category ID -> Budget
    final Map<int, Budget> budgetMap = {};
    for (var b in budgetsState.budgets) {
      budgetMap[b.categoryId] = b;
    }

    // Separate Total Budget category from other categories
    Map<String, dynamic>? totalBudgetCategory;
    final List<Map<String, dynamic>> regularCategories = [];
    for (var cat in _categories) {
      if (cat['name'] == 'Total Budget') {
        totalBudgetCategory = cat;
      } else if (cat['type'] != 'income' && cat['type'] != 'person') {
        regularCategories.add(cat);
      }
    }

    final totalBudgetCatId = totalBudgetCategory != null ? totalBudgetCategory['id'] as int : -1;
    final totalBudget = budgetMap[totalBudgetCatId];
    final overallLimit = totalBudget?.limitAmount;
    final overallSpent = budgetsState.categorySpendings[totalBudgetCatId] ?? 0.0;

    final budgetedCategories = <Map<String, dynamic>>[];
    final unbudgetedCategories = <Map<String, dynamic>>[];
    for (var cat in regularCategories) {
      final catId = cat['id'] as int;
      if (budgetMap.containsKey(catId)) {
        budgetedCategories.add(cat);
      } else {
        unbudgetedCategories.add(cat);
      }
    }

    // Calculate totals for banner
    double totalBudgeted = 0.0;
    double totalSpent = 0.0;
    for (var cat in regularCategories) {
      final catId = cat['id'] as int;
      final budget = budgetMap[catId];
      if (budget != null) {
        totalBudgeted += budget.limitAmount;
        totalSpent += budgetsState.categorySpendings[catId] ?? 0.0;
      }
    }
    final totalRemaining = totalBudgeted - totalSpent;

    // Group budgeted categories by groupName
    final Map<String, List<Map<String, dynamic>>> groupedBudgeted = {};
    for (var cat in budgetedCategories) {
      final catId = cat['id'] as int;
      final budget = budgetMap[catId]!;
      final gName = (budget.groupName == null || budget.groupName!.trim().isEmpty)
          ? 'General'
          : budget.groupName!;
      groupedBudgeted.putIfAbsent(gName, () => []).add(cat);
    }

    // Build the list of slivers dynamically
    final List<Widget> slivers = [];
    
    // Spacing at start
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 12)));
    
    // Bento Header
    slivers.add(
      SliverToBoxAdapter(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 130,
                child: _buildMonthAndLimitsBentoCard(
                  context, 
                  budgetsState, 
                  budgetedCategories.length,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 130,
                child: totalBudgetCatId != -1 && overallLimit != null
                    ? _buildOverallLimitBentoCard(context, overallSpent, overallLimit, currency, totalBudgetCatId)
                    : _buildSetOverallCapPlaceholder(context, totalBudgetCatId),
              ),
            ),
          ],
        ),
      ),
    );
    
    // Totals Banner
    slivers.add(
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: GlassmorphismCard(
            padding: const EdgeInsets.all(16),
            color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTotalItem('Budgeted', CurrencyFormatter.format(totalBudgeted, currency), isDark ? Colors.white70 : Colors.black87),
                _buildTotalItem('Spent', CurrencyFormatter.format(totalSpent, currency), const Color(0xFFE53935)),
                _buildTotalItem(
                  'Remaining', 
                  CurrencyFormatter.format(totalRemaining, currency), 
                  totalRemaining >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFE53935)
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 20)));
    
    // Budgeted Categories (Grouped)
    if (groupedBudgeted.isNotEmpty) {
      for (var entry in groupedBudgeted.entries) {
        final groupTitle = entry.key;
        final list = entry.value;
        
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    groupTitle.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        
        slivers.add(
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.92,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final cat = list[index];
                final catId = cat['id'] as int;
                final catName = cat['name'] as String;
                final catIcon = cat['icon'] as String;
                final catColor = cat['color'] as String;

                final budget = budgetMap[catId]!;
                final limit = budget.limitAmount;
                final spent = budgetsState.categorySpendings[catId] ?? 0.0;

                final trend = analyticsState.categoryTrends.firstWhere(
                  (t) => t.categoryId == catId,
                  orElse: () => CategoryTrend(
                    categoryId: catId,
                    categoryName: catName,
                    monthlyAverage: 0.0,
                    threeMonthRollingAverage: 0.0,
                    projectedMonthEnd: 0.0,
                    currentMonthSpend: spent,
                  ),
                );

                return CompactBudgetBentoCard(
                  categoryName: catName,
                  categoryIcon: catIcon,
                  categoryColorHex: catColor,
                  spent: spent,
                  limit: limit,
                  currency: currency,
                  recurrence: budget.recurrence,
                  groupName: budget.groupName,
                  rollover: budgetsState.categoryRollovers[catId] ?? 0.0,
                  threeMonthRollingAverage: trend.threeMonthRollingAverage,
                  projectedMonthEnd: trend.projectedMonthEnd,
                  onTap: () => _openAccountForm(context, catId, limit),
                );
              },
              childCount: list.length,
            ),
          ),
        );
        
        slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 16)));
      }
    }
    
    // Unbudgeted Categories
    if (unbudgetedCategories.isNotEmpty) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
            child: Text(
              'UNBUDGETED CATEGORIES',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.black45,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
      );
      
      slivers.add(
        SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.2,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final cat = unbudgetedCategories[index];
              final catId = cat['id'] as int;
              final catName = cat['name'] as String;
              final catIcon = cat['icon'] as String;
              final catColor = cat['color'] as String;

              return UnbudgetedBentoCard(
                categoryName: catName,
                categoryIcon: catIcon,
                categoryColorHex: catColor,
                onTap: () => _openBudgetForm(context, catId),
              );
            },
            childCount: unbudgetedCategories.length,
          ),
        ),
      );
      
      slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 20)));
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 26, width: 26),
            const SizedBox(width: 8),
            const Text('Budgets'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _openBudgetForm(context),
            icon: const Icon(Icons.add_chart),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          final DateTime monthDateTime = DateTime.parse('${budgetsState.selectedMonth}-01');
          if (details.primaryVelocity! > 0) {
            // Swipe right: previous month
            final prev = DateTime(monthDateTime.year, monthDateTime.month - 1);
            ref.read(budgetsProvider.notifier).selectMonth(prev.toIso8601String().substring(0, 7));
          } else if (details.primaryVelocity! < 0) {
            // Swipe left: next month
            final next = DateTime(monthDateTime.year, monthDateTime.month + 1);
            ref.read(budgetsProvider.notifier).selectMonth(next.toIso8601String().substring(0, 7));
          }
        },
        child: budgetsState.isLoading || _isLoadingCategories
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)))
            : TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 750),
                curve: Curves.easeOutQuart,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: CustomScrollView(
                    slivers: slivers,
                  ),
                ),
              ),
      ),
    );
  }
}

class CompactBudgetBentoCard extends StatelessWidget {
  final String categoryName;
  final String categoryIcon;
  final String categoryColorHex;
  final double spent;
  final double limit;
  final String currency;
  final String recurrence;
  final String? groupName;
  final double rollover;
  final double? threeMonthRollingAverage;
  final double? projectedMonthEnd;
  final VoidCallback onTap;

  const CompactBudgetBentoCard({
    super.key,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColorHex,
    required this.spent,
    required this.limit,
    required this.currency,
    required this.recurrence,
    this.groupName,
    required this.rollover,
    this.threeMonthRollingAverage,
    this.projectedMonthEnd,
    required this.onTap,
  });

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'fastfood':
        return Icons.fastfood;
      case 'home':
        return Icons.home;
      case 'payments':
        return Icons.payments;
      case 'directions_bus':
        return Icons.directions_bus;
      case 'movie':
        return Icons.movie;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'power':
        return Icons.power;
      case 'category':
        return Icons.category;
      default:
        return Icons.monetization_on;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hex = '0xFF${categoryColorHex.replaceAll("#", "")}';
    final catColor = Color(int.tryParse(hex) ?? 0xFF757575);
    final totalLimit = limit + rollover;
    final percent = totalLimit > 0 ? (spent / totalLimit) : 0.0;
    final percentClamped = percent.clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color progressBarColor = Colors.greenAccent;
    String statusText = '';
    Color statusColor = Colors.greenAccent;

    if (percent >= 1.0) {
      progressBarColor = const Color(0xFFE53935);
      statusText = 'Over';
      statusColor = const Color(0xFFE53935);
    } else if (percent >= 0.8) {
      progressBarColor = Colors.orangeAccent;
      statusText = '80%';
      statusColor = Colors.orangeAccent;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: GlassmorphismCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIconData(categoryIcon),
                    color: catColor,
                    size: 14,
                  ),
                ),
                if (statusText.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    fontFamily: 'Inter',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Limit: ${CurrencyFormatter.format(totalLimit, currency)}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontFamily: 'Inter',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: percentClamped,
                minHeight: 5,
                backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                valueColor: AlwaysStoppedAnimation<Color>(progressBarColor),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Spent: ${CurrencyFormatter.format(spent, currency)}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontFamily: 'Inter',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${(percent * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
            if (projectedMonthEnd != null && projectedMonthEnd! > 0)
              Text(
                'Proj: ${CurrencyFormatter.format(projectedMonthEnd!, currency)}',
                style: TextStyle(
                  fontSize: 9,
                  color: projectedMonthEnd! > limit ? const Color(0xFFE53935) : Colors.grey,
                  fontWeight: projectedMonthEnd! > limit ? FontWeight.bold : FontWeight.normal,
                  fontFamily: 'Inter',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}

class UnbudgetedBentoCard extends StatelessWidget {
  final String categoryName;
  final String categoryIcon;
  final String categoryColorHex;
  final VoidCallback onTap;

  const UnbudgetedBentoCard({
    super.key,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColorHex,
    required this.onTap,
  });

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'fastfood':
        return Icons.fastfood;
      case 'home':
        return Icons.home;
      case 'payments':
        return Icons.payments;
      case 'directions_bus':
        return Icons.directions_bus;
      case 'movie':
        return Icons.movie;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'power':
        return Icons.power;
      case 'category':
        return Icons.category;
      default:
        return Icons.monetization_on;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hex = '0xFF${categoryColorHex.replaceAll("#", "")}';
    final catColor = Color(int.tryParse(hex) ?? 0xFF757575);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: GlassmorphismCard(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconData(categoryIcon),
                color: catColor,
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                categoryName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  fontFamily: 'Inter',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.add,
              size: 14,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
