import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/account.dart';
import '../../models/transaction.dart';
import '../../providers/transactions_provider.dart' hide DateTimeRange;
import '../../providers/categories_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/glassmorphism_card.dart';
import '../../core/utils/currency_formatter.dart';
import '../transactions/transaction_list_item.dart';
import '../transactions/transaction_form.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../widgets/common/toast_notification.dart';

class AccountTransactionsPage extends ConsumerStatefulWidget {
  final Account account;

  const AccountTransactionsPage({Key? key, required this.account}) : super(key: key);

  @override
  ConsumerState<AccountTransactionsPage> createState() => _AccountTransactionsPageState();
}

class _AccountTransactionsPageState extends ConsumerState<AccountTransactionsPage> {
  DateTimeRange? _selectedDateRange;

  void _openTransactionForm(BuildContext context, Transaction tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionForm(transaction: tx),
    );
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    final txState = ref.watch(transactionsProvider);
    final categoriesState = ref.watch(categoriesProvider);
    final authState = ref.watch(authProvider);

    final currency = authState.profile?.preferredCurrency ?? 'USD';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter transactions that affect this account
    final List<Transaction> accountTxs = txState.transactions.where((tx) {
      bool matchesAccount = false;
      if (tx.accountId == account.id) {
        matchesAccount = true;
      } else if (tx.type == 'transfer' && tx.note != null && tx.note!.contains('Transfer to target account ID: ${account.id}')) {
        matchesAccount = true;
      } else if (tx.note != null && tx.note!.contains('Credit Card Payment to target account ID: ${account.id}')) {
        matchesAccount = true;
      }

      if (!matchesAccount) return false;

      if (_selectedDateRange != null) {
        return (tx.date.isAfter(_selectedDateRange!.start) || tx.date.isAtSameMomentAs(_selectedDateRange!.start)) &&
               (tx.date.isBefore(_selectedDateRange!.end) || tx.date.isAtSameMomentAs(_selectedDateRange!.end));
      }
      return true;
    }).toList();

    // Map categories for quick lookup
    final Map<int, Map<String, dynamic>> categoryMap = {};
    for (var cat in categoriesState.categories) {
      categoryMap[cat.id!] = {
        'name': cat.name,
        'color': cat.color,
        'icon': cat.icon,
      };
    }

    final hex = '0xFF${account.color.replaceAll("#", "")}';
    final cardColor = Color(int.tryParse(hex) ?? 0xFFE53935);

    // Calculate running balance history
    final List<FlSpot> spots = [];
    if (accountTxs.isNotEmpty) {
      double running = account.balance;
      final List<double> values = [running];
      
      final backwardsTxs = List<Transaction>.from(accountTxs)..sort((a, b) => b.date.compareTo(a.date));
      for (var tx in backwardsTxs) {
        double change = 0.0;
        if (tx.accountId == account.id) {
          if (tx.type == 'income') {
            change = tx.amount;
          } else {
            change = -tx.amount;
          }
        } else {
          change = tx.amount;
        }
        running -= change;
        values.insert(0, running);
      }
      
      final int showCount = values.length > 15 ? 15 : values.length;
      final startIdx = values.length - showCount;
      for (int i = 0; i < showCount; i++) {
        spots.add(FlSpot(i.toDouble(), values[startIdx + i]));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(account.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.date_range,
              color: _selectedDateRange != null ? const Color(0xFFE53935) : null,
            ),
            tooltip: 'Filter by Date Range',
            onPressed: () async {
              final now = DateTime.now();
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
          ),
          IconButton(
            tooltip: 'Reconcile Bank Statement',
            icon: const Icon(Icons.receipt_long),
            onPressed: () async {
              final items = await ref.read(transactionsProvider.notifier).parseStatementCsv(account.id!);
              if (items != null && items.isNotEmpty && context.mounted) {
                _showReconciliationDialog(context, ref, items, currency, account.id!);
              } else if (items != null && items.isEmpty && context.mounted) {
                ToastNotification.show(context, 'Statement contains no valid transactions.');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Card showing Account Balance info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GlassmorphismCard(
              color: isDark ? cardColor.withOpacity(0.1) : cardColor.withOpacity(0.05),
              borderColor: cardColor.withOpacity(0.15),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        account.type.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Icon(
                        account.isShared ? Icons.people_outline : Icons.person_outline,
                        color: Colors.grey,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.format(account.balance, currency),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: account.balance >= 0 
                          ? (isDark ? Colors.white : const Color(0xFF1A1A26))
                          : const Color(0xFFE53935),
                      fontFamily: 'Inter',
                    ),
                  ),
                  if (account.type == 'Credit Card') ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: account.pendingPayment > 0 ? const Color(0xFFE53935) : Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Pending Payment: ${CurrencyFormatter.format(account.pendingPayment < 0 ? 0.0 : account.pendingPayment, currency)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: account.pendingPayment > 0
                                ? const Color(0xFFE53935)
                                : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          if (_selectedDateRange != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filtered: ${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.end)}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey, fontFamily: 'Inter'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selectedDateRange = null),
                    child: const Text('Clear Filter', style: TextStyle(color: Color(0xFFE53935), fontSize: 11, fontFamily: 'Inter')),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: GlassmorphismCard(
              padding: const EdgeInsets.all(16.0),
              child: spots.length >= 2
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'BALANCE TREND (LAST 15 TXS)',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.0,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 100,
                          child: LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: false),
                              titlesData: const FlTitlesData(
                                show: true,
                                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: spots,
                                  isCurved: true,
                                  color: cardColor,
                                  barWidth: 2.5,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      colors: [
                                        cardColor.withOpacity(0.18),
                                        cardColor.withOpacity(0.0),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ],
                              lineTouchData: LineTouchData(
                                touchTooltipData: LineTouchTooltipData(
                                  getTooltipColor: (_) => isDark ? const Color(0xFF1E1E2E) : Colors.white,
                                  getTooltipItems: (touchedSpots) {
                                    return touchedSpots.map((spot) {
                                      final val = spot.y;
                                      return LineTooltipItem(
                                        CurrencyFormatter.format(val, currency),
                                        TextStyle(
                                          color: isDark ? Colors.white : Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      );
                                    }).toList();
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: 125,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.show_chart_rounded,
                            color: isDark ? Colors.white30 : Colors.black26,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No Trend Data Yet',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white30 : Colors.black26,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Requires at least 2 transactions to display a trend line.',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white30 : Colors.black26,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),

          const Divider(height: 1, thickness: 0.5),

          // Transactions List
          Expanded(
            child: txState.isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)))
                : accountTxs.isEmpty
                    ? Center(
                        child: Text(
                          'No transactions logged for this account.',
                          style: TextStyle(color: isDark ? Colors.white30 : Colors.black38),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: accountTxs.length,
                        itemBuilder: (context, index) {
                          final tx = accountTxs[index];
                          
                          // Resolve category details
                          final cat = categoryMap[tx.categoryId] ?? {
                            'name': 'Other',
                            'color': '757575',
                            'icon': 'category'
                          };

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: TransactionListItem(
                              transaction: tx,
                              categoryName: cat['name'] as String,
                              categoryColorHex: cat['color'] as String,
                              categoryIconKey: cat['icon'] as String,
                              accountName: account.name,
                              currency: currency,
                              onTap: () {
                                _openTransactionForm(context, tx);
                              },
                              onLongPress: () {
                                _openTransactionForm(context, tx);
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showReconciliationDialog(BuildContext context, WidgetRef ref, List<ReconciliationItem> items, String currency, int accountId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final unmatchedCount = items.where((it) => !it.isMatched).length;
        
        return StatefulBuilder(
          builder: (context, setModalState) => Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161625) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Auto-Reconciliation',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                ),
                const SizedBox(height: 6),
                Text(
                  'We matched transactions from your statement with entries in the app. Unmatched transactions can be imported.',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, idx) {
                      final item = items[idx];
                      final amountColor = item.type == 'income' ? const Color(0xFF4CAF50) : const Color(0xFFE53935);
                      final sign = item.type == 'income' ? '+' : '-';
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: item.isMatched 
                                ? const Color(0xFF4CAF50).withOpacity(0.3) 
                                : Colors.grey.withOpacity(0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        DateFormat('MMM dd, yyyy').format(item.date),
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                      const SizedBox(width: 8),
                                      if (item.isMatched)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF4CAF50).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.check, size: 8, color: Color(0xFF4CAF50)),
                                              SizedBox(width: 2),
                                              Text('Matched', style: TextStyle(fontSize: 8, color: Color(0xFF4CAF50), fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '$sign${CurrencyFormatter.format(item.amount, currency)}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: amountColor),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: unmatchedCount > 0 ? const Color(0xFFE53935) : Colors.grey,
                        ),
                        onPressed: unmatchedCount > 0 
                            ? () async {
                                final success = await ref.read(transactionsProvider.notifier).importReconciledTransactions(
                                  accountId: accountId,
                                  items: items,
                                );
                                if (success && context.mounted) {
                                  ToastNotification.show(context, 'Imported $unmatchedCount unmatched transactions.');
                                  Navigator.pop(context);
                                }
                              }
                            : null,
                        child: Text('Import ($unmatchedCount)'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
