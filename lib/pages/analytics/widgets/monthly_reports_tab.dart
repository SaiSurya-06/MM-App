import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/transaction.dart';
import '../../../models/category.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../widgets/common/glassmorphism_card.dart';
import '../../../core/analytics/monthly_report_generator.dart';
import '../../../core/utils/pdf_report_helper.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../providers/accounts_provider.dart';
import '../../../providers/transactions_provider.dart' hide DateTimeRange;
import '../../../providers/categories_provider.dart';
import '../../../providers/auth_provider.dart';

class MonthlyReportsTab extends ConsumerStatefulWidget {
  const MonthlyReportsTab({Key? key}) : super(key: key);

  @override
  ConsumerState<MonthlyReportsTab> createState() => _MonthlyReportsTabState();
}

class _MonthlyReportsTabState extends ConsumerState<MonthlyReportsTab> {
  List<String> _reportMonths = [];
  bool _isLoadingMonths = true;
  String? _selectedReportMonth;
  MonthlyReport? _selectedReport;
  bool _isLoadingReport = false;

  @override
  void initState() {
    super.initState();
    _loadReportMonths();
  }

  Future<void> _loadReportMonths() async {
    try {
      final months = await MonthlyReportGenerator.getAvailableReportMonths();
      if (mounted) {
        setState(() {
          _reportMonths = months;
          _isLoadingMonths = false;
          if (months.isNotEmpty) {
            _selectedReportMonth = months.first;
            _loadSelectedReport(months.first);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMonths = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading report months: $e')),
        );
      }
    }
  }

  Future<void> _loadSelectedReport(String monthStr) async {
    if (mounted) {
      setState(() {
        _isLoadingReport = true;
      });
    }
    try {
      final transactions = ref.read(transactionsProvider).transactions;
      final currency = ref.read(authProvider).profile?.preferredCurrency ?? 'USD';
      final report = await MonthlyReportGenerator.generateReportForMonth(
        monthStr,
        transactions,
        currency,
      );
      if (mounted) {
        setState(() {
          _selectedReport = report;
          _isLoadingReport = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingReport = false;
          _selectedReport = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e')),
        );
      }
    }
  }

  String _formatMonthLabel(String yyyyMM) {
    try {
      final date = DateTime.parse('$yyyyMM-01');
      return DateFormat('MMMM yyyy').format(date);
    } catch (_) {
      return yyyyMM;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = ref.watch(authProvider).profile?.preferredCurrency ?? 'USD';
    final categories = ref.watch(categoriesProvider).categories;
    final transactions = ref.watch(transactionsProvider).transactions;

    if (_isLoadingMonths) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40.0),
        child: Center(child: CircularProgressIndicator(color: Color(0xFFE53935))),
      );
    }

    if (_reportMonths.isEmpty) {
      return GlassmorphismCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              children: [
                Icon(Icons.description_outlined, size: 48, color: Colors.grey.withOpacity(0.5)),
                const SizedBox(height: 12),
                const Text(
                  'No Reports Available',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add transactions to generate monthly reports.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dropdown month selector
        Text(
          'SELECT REPORT MONTH',
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white38 : Colors.black38,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: (_reportMonths.contains(_selectedReportMonth))
                  ? _selectedReportMonth
                  : (_reportMonths.isNotEmpty ? _reportMonths.first : null),
              isExpanded: true,
              dropdownColor: isDark ? const Color(0xFF161625) : Colors.white,
              icon: Icon(Icons.keyboard_arrow_down, color: isDark ? Colors.white70 : Colors.black54),
              items: _reportMonths.map((month) {
                return DropdownMenuItem<String>(
                  value: month,
                  child: Text(
                    _formatMonthLabel(month),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF1A1A26),
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedReportMonth = val;
                  });
                  _loadSelectedReport(val);
                }
              },
            ),
          ),
        ),

        const SizedBox(height: 20),

        if (_isLoadingReport)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40.0),
            child: Center(child: CircularProgressIndicator(color: Color(0xFFE53935))),
          )
        else if (_selectedReport != null) ...[
          // 1. Overview Card
          Text(
            'FINANCIAL REPORT SUMMARY',
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white38 : Colors.black38,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          GlassmorphismCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedReport!.formattedMonth.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Savings Rate: ${_selectedReport!.savingsRate.toStringAsFixed(1)}%',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Inflow', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatter.format(_selectedReport!.totalIncome, currency),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Outflow', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatter.format(_selectedReport!.totalExpense, currency),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFE53935)),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Net Savings', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatter.format(_selectedReport!.totalSavings, currency),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: _selectedReport!.totalSavings >= 0 ? Colors.blue : const Color(0xFFE53935),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_selectedReport!.savingsRate / 100.0).clamp(0.0, 1.0),
                    backgroundColor: isDark ? Colors.white10 : Colors.black12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _selectedReport!.savingsRate >= 20.0 ? Colors.green : (_selectedReport!.savingsRate > 0.0 ? Colors.blue : const Color(0xFFE53935)),
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. Budget Compliance
          Text(
            'BUDGET PERFORMANCE',
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white38 : Colors.black38,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          GlassmorphismCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Budget Enforcements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(
                      '${_selectedReport!.totalBudgets - _selectedReport!.budgetsExceeded} of ${_selectedReport!.totalBudgets} Kept',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: _selectedReport!.budgetsExceeded > 0 ? const Color(0xFFE53935) : Colors.green,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20, thickness: 0.5),
                if (_selectedReport!.budgetDetails.isEmpty)
                  const Center(child: Text('No budgets configured for this month.', style: TextStyle(color: Colors.grey, fontSize: 12)))
                else
                  ..._selectedReport!.budgetDetails.map((b) {
                    final isOver = b['spent'] > b['limit'];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              b['categoryName'] as String,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text(
                            '${CurrencyFormatter.format(b['spent'] as double, currency)} / ${CurrencyFormatter.format(b['limit'] as double, currency)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isOver ? const Color(0xFFE53935) : (isDark ? Colors.white70 : Colors.black87),
                              fontWeight: isOver ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 3. AI Smart Suggestions
          Text(
            'AI ADVISORY RECOMMENDATIONS',
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white38 : Colors.black38,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          ..._selectedReport!.suggestions.map((suggestion) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: GlassmorphismCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.orangeAccent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: const TextStyle(fontSize: 12.5, height: 1.4, fontFamily: 'Inter'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_alert, size: 18, color: Colors.blueAccent),
                      onPressed: () async {
                        try {
                          await NotificationService.instance.showCustomAlert(
                            "Monthly Report Reminder",
                            suggestion,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Report Alert Reminder Created!')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to set reminder: $e')),
                            );
                          }
                        }
                      },
                      tooltip: 'Set Notification Reminder',
                    ),
                  ],
                ),
              ),
            );
          }).toList(),

          const SizedBox(height: 20),

          // 4. Export Button
          ElevatedButton.icon(
            onPressed: () async {
              try {
                final Map<int, String> categoryNames = {
                  for (var cat in categories) cat.id ?? 0: cat.name
                };
                final accounts = ref.read(accountsProvider).accounts;
                final Map<int, String> accountNames = {
                  for (var acc in accounts) acc.id ?? 0: acc.name
                };
                final selectedMonthTxs = transactions.where((tx) {
                  return DateFormat('yyyy-MM').format(tx.date) == _selectedReportMonth;
                }).toList();

                await PdfReportHelper.generateAndShareReport(
                  transactions: selectedMonthTxs,
                  categoryNames: categoryNames,
                  accountNames: accountNames,
                  currency: currency,
                  dateRangeStr: _selectedReport!.formattedMonth,
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to export PDF: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Export & Share PDF Report'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ],
    );
  }
}
