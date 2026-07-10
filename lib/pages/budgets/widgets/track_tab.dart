import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/budgets_provider.dart';
import '../../../providers/categories_provider.dart';
import '../../../providers/money_map_view_model.dart';
import '../../../widgets/common/glassmorphism_card.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/category.dart';

class TrackTab extends ConsumerWidget {
  const TrackTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsState = ref.watch(budgetsProvider);
    final categoriesState = ref.watch(categoriesProvider);
    final moneyMapState = ref.watch(moneyMapViewModelProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    const currency = 'INR';

    if (budgetsState.isLoading || categoriesState.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
    }

    final budgets = budgetsState.budgets;
    final categories = categoriesState.categories;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Safe to Spend Card
          GlassmorphismCard(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Icon(Icons.bolt, color: Colors.amberAccent, size: 28),
                  const SizedBox(height: 8),
                  const Text(
                    'Safe to Spend Today',
                    style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${CurrencyFormatter.format(moneyMapState.safeToSpendToday, currency)}',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Inter'),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Estimated remaining days: ${moneyMapState.daysRemaining}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 2. Budget vs Actual Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Budget vs Actual', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              Text(
                '${budgets.length} Budgets Active',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (budgets.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: Text('No category budgets planned yet.', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: budgets.length,
              itemBuilder: (context, index) {
                final budget = budgets[index];
                final cat = categories.firstWhere(
                  (c) => c.id == budget.categoryId,
                  orElse: () => const Category(id: -99, name: 'Other', icon: 'payments', color: 'E53935', isDefault: true),
                );

                final actualSpent = budgetsState.categorySpendings[budget.categoryId] ?? 0.0;
                final plannedLimit = budget.limitAmount;
                final remaining = plannedLimit - actualSpent;
                final percent = plannedLimit > 0 ? (actualSpent / plannedLimit).clamp(0.0, 1.0) : 0.0;
                final isOver = remaining < 0;

                final categoryColor = Color(int.tryParse('FF${cat.color}', radix: 16) ?? 0xFF1E88E5);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: GlassmorphismCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: categoryColor.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.circle, color: categoryColor, size: 10),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    cat.name,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Text(
                                isOver
                                    ? 'Over by ₹${CurrencyFormatter.format(-remaining, currency)}'
                                    : 'Remaining: ₹${CurrencyFormatter.format(remaining, currency)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isOver ? Colors.redAccent : Colors.greenAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Linear progress indicator
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percent,
                              minHeight: 8,
                              backgroundColor: Colors.grey.withValues(alpha: 0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(isOver ? Colors.redAccent : Colors.greenAccent),
                            ),
                          ),
                          const SizedBox(height: 12),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Planned: ₹${CurrencyFormatter.format(plannedLimit, currency)}',
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              Text(
                                'Actual: ₹${CurrencyFormatter.format(actualSpent, currency)}',
                                style: TextStyle(
                                  color: isOver ? Colors.redAccent : textColor.withValues(alpha: 0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
