import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/account.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/transactions_provider.dart' hide DateTimeRange;
import '../../providers/auth_provider.dart';
import '../../providers/categories_provider.dart';
import '../../widgets/common/glassmorphism_card.dart';
import '../../core/utils/currency_formatter.dart';

class AccountComparisonPage extends ConsumerStatefulWidget {
  const AccountComparisonPage({Key? key}) : super(key: key);

  @override
  ConsumerState<AccountComparisonPage> createState() => _AccountComparisonPageState();
}

class _AccountComparisonPageState extends ConsumerState<AccountComparisonPage> {
  String _sortBy = 'balance';
  Set<int> _selectedAccountIds = {};
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accounts = ref.read(accountsProvider).accounts;
      setState(() {
        _selectedAccountIds = accounts.map((a) => a.id!).toSet();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final accountsState = ref.watch(accountsProvider);
    final txState = ref.watch(transactionsProvider);
    final authState = ref.watch(authProvider);
    final categoriesState = ref.watch(categoriesProvider);
    final currency = authState.profile?.preferredCurrency ?? 'USD';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final currentMonth = now.toIso8601String().substring(0, 7);

    final accounts = accountsState.accounts;
    if (accounts.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Account Comparison')),
        body: const Center(child: Text('No accounts to compare.', style: TextStyle(color: Colors.grey))),
      );
    }

    final filteredAccounts = accounts.where((a) => _selectedAccountIds.contains(a.id)).toList();

    // Calculate per-account metrics
    final List<Map<String, dynamic>> accountMetrics = [];
    double totalBalance = 0;
    double totalIncome = 0;
    double totalExpenses = 0;

    for (var acc in filteredAccounts) {
      double monthIncome = 0;
      double monthExpenses = 0;

      for (var tx in txState.transactions) {
        bool inDateRange = true;
        if (_selectedDateRange != null) {
          inDateRange = (tx.date.isAfter(_selectedDateRange!.start) || tx.date.isAtSameMomentAs(_selectedDateRange!.start)) &&
                        (tx.date.isBefore(_selectedDateRange!.end) || tx.date.isAtSameMomentAs(_selectedDateRange!.end));
        } else {
          inDateRange = tx.date.toIso8601String().substring(0, 7) == currentMonth;
        }
        if (!inDateRange) continue;

        bool related = false;
        if (tx.accountId == acc.id) {
          related = true;
        } else if (tx.type == 'transfer' && tx.note != null && tx.note!.contains('target account ID: ${acc.id}')) {
          related = true;
        }

        if (related) {
          if (tx.type == 'income') monthIncome += tx.amount;
          else if (tx.type == 'expense') monthExpenses += tx.amount;
        }
      }

      final net = monthIncome - monthExpenses;
      totalBalance += acc.balance;
      totalIncome += monthIncome;
      totalExpenses += monthExpenses;

      accountMetrics.add({
        'account': acc,
        'income': monthIncome,
        'expenses': monthExpenses,
        'net': net,
        'utilization': acc.type == 'Credit Card' && acc.limitAmount != null && acc.limitAmount! > 0
            ? (acc.balance.abs() / acc.limitAmount!).clamp(0.0, 1.0)
            : 0.0,
      });
    }

    // Sort
    accountMetrics.sort((a, b) {
      switch (_sortBy) {
        case 'balance':
          return (b['account'] as Account).balance.compareTo((a['account'] as Account).balance);
        case 'income':
          return (b['income'] as double).compareTo(a['income'] as double);
        case 'expenses':
          return (b['expenses'] as double).compareTo(a['expenses'] as double);
        case 'net':
          return (b['net'] as double).compareTo(a['net'] as double);
        default:
          return 0;
      }
    });

    // Chart data
    final List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < accountMetrics.length && i < 6; i++) {
      final m = accountMetrics[i];
      barGroups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(toY: m['income'] as double, color: const Color(0xFF4CAF50), width: 12, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
          BarChartRodData(toY: m['expenses'] as double, color: const Color(0xFFE53935), width: 12, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
        ],
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Comparison'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                initialDateRange: _selectedDateRange ?? DateTimeRange(
                  start: DateTime(now.year, now.month, 1),
                  end: DateTime(now.year, now.month, now.day),
                ),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.dark(
                        primary: const Color(0xFFE53935),
                        onPrimary: Colors.white,
                        surface: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() {
                  _selectedDateRange = picked;
                });
              }
            },
            tooltip: 'Select Date Range',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (val) => setState(() => _sortBy = val),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'balance', child: Text('Sort by Balance')),
              const PopupMenuItem(value: 'income', child: Text('Sort by Income')),
              const PopupMenuItem(value: 'expenses', child: Text('Sort by Expenses')),
              const PopupMenuItem(value: 'net', child: Text('Sort by Net')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account selection chips
            const Text('SELECT ACCOUNTS TO COMPARE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
            const SizedBox(height: 8),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: accounts.map((acc) {
                  final hex = '0xFF${acc.color.replaceAll("#", "")}';
                  final color = Color(int.tryParse(hex) ?? 0xFF757575);
                  final isSelected = _selectedAccountIds.contains(acc.id);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(acc.name),
                      selected: isSelected,
                      checkmarkColor: Colors.white,
                      selectedColor: color,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontFamily: 'Inter',
                      ),
                      backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.black.withOpacity(0.02),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected ? color : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
                        ),
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedAccountIds.add(acc.id!);
                          } else {
                            if (_selectedAccountIds.length > 1) {
                              _selectedAccountIds.remove(acc.id);
                            }
                          }
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            if (_selectedDateRange != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Comparing: ${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.end)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey, fontFamily: 'Inter'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _selectedDateRange = null),
                      child: const Text('Reset Range', style: TextStyle(color: Color(0xFFE53935), fontSize: 12, fontFamily: 'Inter')),
                    ),
                  ],
                ),
              ),
            ],

            if (filteredAccounts.isEmpty) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: Text('Select at least one account to compare.', style: TextStyle(color: Colors.grey)),
                ),
              ),
            ] else ...[
              // Summary
              GlassmorphismCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _summaryColumn('Total Balance', CurrencyFormatter.format(totalBalance, currency), const Color(0xFF1E88E5), isDark),
                    _summaryColumn('Total Income', CurrencyFormatter.format(totalIncome, currency), const Color(0xFF4CAF50), isDark),
                    _summaryColumn('Total Expenses', CurrencyFormatter.format(totalExpenses, currency), const Color(0xFFE53935), isDark),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Bar chart
              if (barGroups.isNotEmpty) ...[
                const Text('INCOME VS EXPENSES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                const SizedBox(height: 12),
                GlassmorphismCard(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    height: 190,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        barGroups: barGroups,
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              getTitlesWidget: (val, meta) {
                                final idx = val.toInt();
                                if (idx < accountMetrics.length) {
                                  final name = (accountMetrics[idx]['account'] as Account).name;
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    angle: -0.5,
                                    child: Text(
                                      name.length > 8 ? '${name.substring(0, 8)}..' : name,
                                      style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: false),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _legendDot(const Color(0xFF4CAF50), 'Income', isDark),
                    const SizedBox(width: 16),
                    _legendDot(const Color(0xFFE53935), 'Expenses', isDark),
                  ],
                ),
              ],
              const SizedBox(height: 24),

              // Account detail cards
              const Text('ACCOUNT DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
              const SizedBox(height: 12),
              ...accountMetrics.map((m) {
                final acc = m['account'] as Account;
                final hex = '0xFF${acc.color.replaceAll("#", "")}';
                final color = Color(int.tryParse(hex) ?? 0xFFE53935);
                final net = m['net'] as double;
                final utilization = m['utilization'] as double;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: GlassmorphismCard(
                    padding: const EdgeInsets.all(16),
                    color: isDark ? color.withOpacity(0.08) : color.withOpacity(0.04),
                    borderColor: color.withOpacity(0.15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(acc.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Inter')),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(acc.type.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color, fontFamily: 'Inter')),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _metricItem('Balance', CurrencyFormatter.format(acc.balance, currency), isDark),
                            _metricItem('Income', CurrencyFormatter.format(m['income'] as double, currency), isDark, valueColor: const Color(0xFF4CAF50)),
                            _metricItem('Expenses', CurrencyFormatter.format(m['expenses'] as double, currency), isDark, valueColor: const Color(0xFFE53935)),
                            _metricItem('Net', CurrencyFormatter.format(net, currency), isDark, valueColor: net >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFE53935)),
                          ],
                        ),
                        if (acc.type == 'Credit Card' && acc.limitAmount != null && acc.limitAmount! > 0) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: utilization,
                              minHeight: 6,
                              backgroundColor: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                utilization > 0.8 ? const Color(0xFFE53935) : (utilization > 0.5 ? Colors.orange : const Color(0xFF4CAF50)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Credit Utilization: ${(utilization * 100).toStringAsFixed(0)}% of ${CurrencyFormatter.format(acc.limitAmount!, currency)}',
                            style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black38, fontFamily: 'Inter'),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryColumn(String label, String value, Color color, bool isDark) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black38, fontFamily: 'Inter')),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color, fontFamily: 'Inter')),
      ],
    );
  }

  Widget _metricItem(String label, String value, bool isDark, {Color? valueColor}) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 9, color: isDark ? Colors.white38 : Colors.black26, fontFamily: 'Inter')),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: valueColor ?? (isDark ? Colors.white : Colors.black), fontFamily: 'Inter')),
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label, bool isDark) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black38, fontFamily: 'Inter')),
      ],
    );
  }
}
