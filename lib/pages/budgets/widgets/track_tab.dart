import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/budgets_provider.dart';
import '../../../providers/categories_provider.dart';
import '../../../providers/money_map_view_model.dart';
import '../../../widgets/common/glassmorphism_card.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/pdf_report_helper.dart';
import '../../../models/category.dart';
import '../../../models/budget.dart';

class TrackTab extends ConsumerStatefulWidget {
  const TrackTab({super.key});

  @override
  ConsumerState<TrackTab> createState() => _TrackTabState();
}

class _TrackTabState extends ConsumerState<TrackTab> {
  String _sortBy = 'remaining_asc'; // Default: Critical first (Remaining Low to High)

  void _showExportMenu(
    BuildContext context,
    List<Budget> budgets,
    Map<int, double> spendings,
    List<Category> categories,
    String monthStr,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Export Monthly Budget Report',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                title: const Text('Export as PDF Document'),
                subtitle: const Text('A polished A4 table with health status and highlights.'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await PdfReportHelper.generateAndShareBudgetReport(
                      budgets: budgets,
                      spendings: spendings,
                      categories: categories,
                      monthStr: monthStr,
                      currency: 'INR',
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to export PDF: $e'), backgroundColor: Colors.redAccent),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.grid_on, color: Colors.green),
                title: const Text('Export as CSV Spreadsheet'),
                subtitle: const Text('A plain CSV file compatible with Excel or Google Sheets.'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await PdfReportHelper.generateAndShareBudgetCsv(
                      budgets: budgets,
                      spendings: spendings,
                      categories: categories,
                      monthStr: monthStr,
                      currency: 'INR',
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to export CSV: $e'), backgroundColor: Colors.redAccent),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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

    // Apply sorting
    final sortedBudgets = List.of(budgets);
    if (_sortBy == 'name') {
      sortedBudgets.sort((a, b) {
        final catA = categories.firstWhere((c) => c.id == a.categoryId, orElse: () => const Category(id: -99, name: '', icon: '', color: '', isDefault: false));
        final catB = categories.firstWhere((c) => c.id == b.categoryId, orElse: () => const Category(id: -99, name: '', icon: '', color: '', isDefault: false));
        return catA.name.toLowerCase().compareTo(catB.name.toLowerCase());
      });
    } else if (_sortBy == 'planned_desc') {
      sortedBudgets.sort((a, b) => b.limitAmount.compareTo(a.limitAmount));
    } else if (_sortBy == 'planned_asc') {
      sortedBudgets.sort((a, b) => a.limitAmount.compareTo(b.limitAmount));
    } else if (_sortBy == 'remaining_desc') {
      sortedBudgets.sort((a, b) {
        final spentA = budgetsState.categorySpendings[a.categoryId] ?? 0.0;
        final remainingA = a.limitAmount - spentA;
        final spentB = budgetsState.categorySpendings[b.categoryId] ?? 0.0;
        final remainingB = b.limitAmount - spentB;
        return remainingB.compareTo(remainingA);
      });
    } else if (_sortBy == 'remaining_asc') {
      sortedBudgets.sort((a, b) {
        final spentA = budgetsState.categorySpendings[a.categoryId] ?? 0.0;
        final remainingA = a.limitAmount - spentA;
        final spentB = budgetsState.categorySpendings[b.categoryId] ?? 0.0;
        final remainingB = b.limitAmount - spentB;
        return remainingA.compareTo(remainingB);
      });
    }

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
                    CurrencyFormatter.format(moneyMapState.safeToSpendToday, currency),
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
              Row(
                children: [
                  Text(
                    '${sortedBudgets.length} Budgets Active',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.grey, size: 20),
                    tooltip: 'Export Report',
                    onPressed: () => _showExportMenu(context, sortedBudgets, budgetsState.categorySpendings, categories, budgetsState.selectedMonth),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.sort, color: Colors.grey, size: 20),
                    tooltip: 'Sort Budgets',
                    onSelected: (val) {
                      setState(() {
                        _sortBy = val;
                      });
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'remaining_asc', child: Text('Critical First (Remaining Low-High)')),
                      const PopupMenuItem(value: 'remaining_desc', child: Text('Remaining (High-Low)')),
                      const PopupMenuItem(value: 'planned_desc', child: Text('Planned (High-Low)')),
                      const PopupMenuItem(value: 'planned_asc', child: Text('Planned (Low-High)')),
                      const PopupMenuItem(value: 'name', child: Text('Alphabetical (A-Z)')),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (sortedBudgets.isEmpty)
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
              itemCount: sortedBudgets.length,
              itemBuilder: (context, index) {
                final budget = sortedBudgets[index];
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
                                    ? 'Over by ${CurrencyFormatter.format(-remaining, currency)}'
                                    : 'Remaining: ${CurrencyFormatter.format(remaining, currency)}',
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
                                'Planned: ${CurrencyFormatter.format(plannedLimit, currency)}',
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              Text(
                                'Actual: ${CurrencyFormatter.format(actualSpent, currency)}',
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
