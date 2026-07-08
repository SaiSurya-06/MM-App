import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/common/glassmorphism_card.dart';
import '../../../core/utils/currency_formatter.dart';

class TodaySummaryCard extends StatelessWidget {
  final double todayIncome;
  final double todayExpenses;
  final String majorExpenseCategory;
  final double majorExpenseAmount;
  final String majorIncomeCategory;
  final double majorIncomeAmount;
  final String currency;

  const TodaySummaryCard({
    super.key,
    required this.todayIncome,
    required this.todayExpenses,
    required this.majorExpenseCategory,
    required this.majorExpenseAmount,
    required this.majorIncomeCategory,
    required this.majorIncomeAmount,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasTransactions = todayIncome > 0 || todayExpenses > 0;

    return GlassmorphismCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => GoRouter.of(context).go('/transactions'),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "TODAY'S SUMMARY",
                        style: TextStyle(
                          color: isDark ? Colors.white70 : const Color(0xFF6C6C7D),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat.yMMMMd().format(DateTime.now()),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasTransactions
                          ? const Color(0xFFE53935).withValues(alpha: 0.12)
                          : Colors.grey.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: hasTransactions ? const Color(0xFFE53935) : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hasTransactions ? "Active Today" : "No Activity",
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: hasTransactions
                                ? const Color(0xFFE53935)
                                : (isDark ? Colors.grey : Colors.black45),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),

              if (!hasTransactions)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      "No transactions logged today.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                )
              else ...[
                // Income vs Expense Summary Row
                Row(
                  children: [
                    // Income Summary
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_downward, color: Colors.green, size: 14),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "INFLOW",
                                  style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    CurrencyFormatter.format(todayIncome, currency),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF1A1A26),
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    Container(
                      width: 1,
                      height: 30,
                      color: isDark ? Colors.white10 : Colors.black12,
                    ),
                    const SizedBox(width: 12),

                    // Expense Summary
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_upward, color: Color(0xFFE53935), size: 14),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "OUTFLOW",
                                  style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    CurrencyFormatter.format(todayExpenses, currency),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF1A1A26),
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 0.5),
                const SizedBox(height: 16),

                // Major Spending & Income Source Details
                Row(
                  children: [
                    // Major Spending
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "MAJOR SPENDING",
                            style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            majorExpenseCategory != "None" ? majorExpenseCategory : "N/A",
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                          ),
                          if (majorExpenseAmount > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  CurrencyFormatter.format(majorExpenseAmount, currency),
                                  style: const TextStyle(fontSize: 11, color: Color(0xFFE53935), fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Major Income Source
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "PRIMARY SOURCE",
                            style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            majorIncomeCategory != "None" ? majorIncomeCategory : "N/A",
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                          ),
                          if (majorIncomeAmount > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  CurrencyFormatter.format(majorIncomeAmount, currency),
                                  style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 16),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 12),
              
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Tap to view all transactions",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white54 : Colors.black45,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 14,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
