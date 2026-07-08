import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/transactions_provider.dart' hide DateTimeRange;
import '../../providers/transactions_provider.dart' as tp;
import '../../providers/accounts_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/categories_provider.dart';
import '../../providers/transaction_templates_provider.dart';
import '../../models/category.dart';
import '../../models/transaction.dart';
import '../../models/account.dart';
import 'transaction_list_item.dart';
import 'transaction_form.dart';
import '../../widgets/common/toast_notification.dart';
import '../../core/database/database.dart';
import '../../widgets/common/glassmorphism_card.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/pdf_report_helper.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  final TextEditingController _searchController = TextEditingController();
  final Set<Transaction> _selectedTxs = {};
  bool _isSelectionMode = false;
  Timer? _searchDebounce;


  void _showBulkEditCategoryDialog(BuildContext context) {
    final categories = ref.read(categoriesProvider).categories;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        title: const Text('Bulk Change Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, idx) {
              final cat = categories[idx];
              final hex = '0xFF${cat.color.replaceAll("#", "")}';
              final color = Color(int.tryParse(hex) ?? 0xFF757575);
              return ListTile(
                leading: Icon(Icons.category, color: color),
                title: Text(cat.name),
                onTap: () async {
                  final success = await ref.read(transactionsProvider.notifier).bulkEditCategory(
                    _selectedTxs.toList(),
                    cat.id!,
                  );
                  if (success && mounted) {
                    ToastNotification.show(context, 'Updated category for ${_selectedTxs.length} transactions.');
                    setState(() {
                      _isSelectionMode = false;
                      _selectedTxs.clear();
                    });
                  }
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showBulkDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Transactions'),
        content: Text('Are you sure you want to delete ${_selectedTxs.length} transactions? This will revert account balances.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935), foregroundColor: Colors.white),
            onPressed: () async {
              final success = await ref.read(transactionsProvider.notifier).bulkDeleteTransactions(_selectedTxs.toList());
              if (success && mounted) {
                ToastNotification.show(context, 'Deleted ${_selectedTxs.length} transactions.');
                setState(() {
                  _isSelectionMode = false;
                  _selectedTxs.clear();
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesRow(BuildContext context, String currency, bool isDark) {
    final templatesState = ref.watch(transactionTemplatesProvider);
    if (templatesState.templates.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick-Add Templates', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
          const SizedBox(height: 8),
          SizedBox(
            height: 54,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: templatesState.templates.length,
              itemBuilder: (context, idx) {
                final tmpl = templatesState.templates[idx];
                final cat = _categoryMap[tmpl.categoryId] ?? {
                  'name': 'Other',
                  'color': '757575',
                  'icon': 'category'
                };
                final hex = '0xFF${(cat['color'] as String).replaceAll("#", "")}';
                final color = Color(int.tryParse(hex) ?? 0xFF757575);

                return GestureDetector(
                  onTap: () async {
                    final success = await ref.read(transactionsProvider.notifier).addTransaction(
                      accountId: tmpl.accountId,
                      categoryId: tmpl.categoryId,
                      title: tmpl.title,
                      amount: tmpl.amount,
                      type: tmpl.type,
                      date: DateTime.now(),
                      recurrence: 'none',
                      isPrivate: false,
                    );
                    if (success && mounted) {
                      ToastNotification.show(context, 'Logged: ${tmpl.title} (${CurrencyFormatter.format(tmpl.amount, currency)})');
                    }
                  },
                  onLongPress: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Template'),
                        content: Text('Do you want to delete the template "${tmpl.title}"?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935), foregroundColor: Colors.white),
                            onPressed: () async {
                              await ref.read(transactionTemplatesProvider.notifier).deleteTemplate(tmpl.id!);
                              Navigator.pop(context);
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.flash_on, color: color, size: 16),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(tmpl.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            Text(CurrencyFormatter.format(tmpl.amount, currency), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _showExportDateRangeSelector(BuildContext context) async {
    final DateTime now = DateTime.now();
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Select Export Date Range',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRangeOption(context, 'Last 1 Month', () {
                final start = now.subtract(const Duration(days: 30));
                final range = tp.DateTimeRange(start: start, end: now);
                final str = 'Last 1 Month (${DateFormat('yyyy-MM-dd').format(start)} to ${DateFormat('yyyy-MM-dd').format(now)})';
                Navigator.of(context).pop({'range': range, 'label': str, 'start': start, 'end': now});
              }),
              const SizedBox(height: 10),
              _buildRangeOption(context, 'Last 3 Months', () {
                final start = now.subtract(const Duration(days: 90));
                final range = tp.DateTimeRange(start: start, end: now);
                final str = 'Last 3 Months (${DateFormat('yyyy-MM-dd').format(start)} to ${DateFormat('yyyy-MM-dd').format(now)})';
                Navigator.of(context).pop({'range': range, 'label': str, 'start': start, 'end': now});
              }),
              const SizedBox(height: 10),
              _buildRangeOption(context, 'Custom Date Range', () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  initialDateRange: DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
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
                  final range = tp.DateTimeRange(start: picked.start, end: picked.end);
                  final str = '${DateFormat('yyyy-MM-dd').format(picked.start)} to ${DateFormat('yyyy-MM-dd').format(picked.end)}';
                  if (context.mounted) {
                    Navigator.of(context).pop({'range': range, 'label': str, 'start': picked.start, 'end': picked.end});
                  }
                }
              }),
              const SizedBox(height: 10),
              _buildRangeOption(context, 'All Transactions', () {
                Navigator.of(context).pop({'range': null, 'label': 'All Transactions', 'start': null, 'end': null});
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRangeOption(BuildContext context, String label, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFF161625) : Colors.black.withOpacity(0.03),
          foregroundColor: isDark ? Colors.white : Colors.black87,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onTap,
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Inter'),
        ),
      ),
    );
  }
  Map<int, Map<String, dynamic>> _categoryMap = {};
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final db = await AppDatabase.instance.database;
      final list = await db.query('category');
      final Map<int, Map<String, dynamic>> map = {};
      for (var cat in list) {
        map[cat['id'] as int] = cat;
      }
      setState(() {
        _categoryMap = map;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _exportPdfReport(
    BuildContext context,
    List<Transaction> filteredTxs,
    String currency,
    Map<int, String> accountMap,
  ) async {
    final selection = await _showExportDateRangeSelector(context);
    if (selection == null) return; // User cancelled

    if (!context.mounted) return;
    final themeName = await showDialog<String>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          title: const Text('Choose PDF Report Style', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Classic Red'),
                leading: const Icon(Icons.palette, color: Colors.red),
                onTap: () => Navigator.pop(context, 'classic'),
              ),
              ListTile(
                title: const Text('Modern Blue'),
                leading: const Icon(Icons.palette, color: Colors.indigo),
                onTap: () => Navigator.pop(context, 'modern_blue'),
              ),
              ListTile(
                title: const Text('Minimalist Gray'),
                leading: const Icon(Icons.palette, color: Colors.grey),
                onTap: () => Navigator.pop(context, 'minimalist'),
              ),
              ListTile(
                title: const Text('Premium Gold'),
                leading: const Icon(Icons.palette, color: Colors.orange),
                onTap: () => Navigator.pop(context, 'premium_gold'),
              ),
            ],
          ),
        );
      },
    ) ?? 'classic';

    final Map<int, String> categoryNames = {};
    _categoryMap.forEach((id, cat) {
      categoryNames[id] = cat['name'] as String;
    });
    
    // Filter transactions to export based on selected range
    List<Transaction> exportTxs = filteredTxs;
    final start = selection['start'] as DateTime?;
    final end = selection['end'] as DateTime?;
    if (start != null && end != null) {
      final startOfDay = DateTime(start.year, start.month, start.day);
      final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
      exportTxs = filteredTxs.where((tx) {
        return (tx.date.isAfter(startOfDay) || tx.date.isAtSameMomentAs(startOfDay)) &&
               (tx.date.isBefore(endOfDay) || tx.date.isAtSameMomentAs(endOfDay));
      }).toList();
    }

    await PdfReportHelper.generateAndShareReport(
      transactions: exportTxs,
      categoryNames: categoryNames,
      accountNames: accountMap,
      currency: currency,
      dateRangeStr: selection['label'] as String,
      themeName: themeName,
    );
  }

  void _openTransactionForm(BuildContext context, [Transaction? tx]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionForm(transaction: tx),
    );
  }



  @override
  Widget build(BuildContext context) {
    final txState = ref.watch(transactionsProvider);
    final authState = ref.watch(authProvider);
    final accounts = ref.watch(accountsProvider).accounts;
    final categories = ref.watch(categoriesProvider).categories;

    final currency = authState.profile?.preferredCurrency ?? 'USD';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredTxs = ref.watch(transactionsProvider.notifier).getFilteredTransactions(includeProjected: true);

    double totalIncome = 0.0;
    double totalExpense = 0.0;
    for (var tx in filteredTxs) {
      if (tx.type == 'income') {
        totalIncome += tx.amount;
      } else if (tx.type == 'expense') {
        totalExpense += tx.amount;
      }
    }

    // Map account IDs to names
    final Map<int, String> accountMap = {};
    for (var acc in accounts) {
      accountMap[acc.id!] = acc.name;
    }

    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedTxs.clear();
                  });
                },
              ),
              title: Text('${_selectedTxs.length} Selected'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: () {
                    setState(() {
                      _selectedTxs.addAll(filteredTxs);
                    });
                  },
                  tooltip: 'Select All',
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _showBulkEditCategoryDialog(context),
                  tooltip: 'Bulk Edit Category',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _showBulkDeleteConfirm(context),
                  tooltip: 'Bulk Delete',
                ),
              ],
            )
          : AppBar(
              title: Row(
                children: [
                  Image.asset('assets/logo.png', height: 26, width: 26),
                  const SizedBox(width: 8),
                  const Text('Ledger'),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    ref.read(transactionsProvider.notifier).toggleSortOrder();
                  },
                  icon: Icon(txState.sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                  tooltip: txState.sortAscending ? 'Sort Oldest First' : 'Sort Newest First',
                ),
                IconButton(
                  onPressed: () {
                    ref.read(transactionsProvider.notifier).resetFilters();
                    _searchController.clear();
                  },
                  icon: const Icon(Icons.filter_alt_off),
                  tooltip: 'Reset Filters',
                ),
                IconButton(
                  onPressed: () => _exportPdfReport(context, filteredTxs, currency, accountMap),
                  icon: const Icon(Icons.picture_as_pdf),
                  tooltip: 'Export PDF Report',
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    if (value == 'import') {
                      ref.read(transactionsProvider.notifier).importTransactionsFromCsv(context);
                    } else if (value == 'export') {
                      final selection = await _showExportDateRangeSelector(context);
                      if (selection == null) return; // User cancelled
                      if (context.mounted) {
                        await ref.read(transactionsProvider.notifier).exportTransactionsToCsv(
                          context,
                          dateRange: selection['range'] as tp.DateTimeRange?,
                          dateRangeStr: selection['label'] as String?,
                        );
                      }
                    } else if (value == 'json') {
                      final selection = await _showExportDateRangeSelector(context);
                      if (selection == null) return; // User cancelled
                      if (context.mounted) {
                        await ref.read(transactionsProvider.notifier).exportTransactionsToJson(
                          context,
                          dateRange: selection['range'] as tp.DateTimeRange?,
                          dateRangeStr: selection['label'] as String?,
                        );
                      }
                    } else if (value == 'pdf') {
                      await _exportPdfReport(context, filteredTxs, currency, accountMap);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'import',
                      child: Row(
                        children: [
                          Icon(Icons.file_upload, size: 20),
                          SizedBox(width: 8),
                          Text('Import CSV'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'export',
                      child: Row(
                        children: [
                          Icon(Icons.file_download, size: 20),
                          SizedBox(width: 8),
                          Text('Export CSV'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'json',
                      child: Row(
                        children: [
                          Icon(Icons.code, size: 20),
                          SizedBox(width: 8),
                          Text('Export JSON'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'pdf',
                      child: Row(
                        children: [
                          Icon(Icons.picture_as_pdf, size: 20),
                          SizedBox(width: 8),
                          Text('Export PDF Report'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTransactionForm(context),
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: TweenAnimationBuilder<double>(
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
        child: Column(
          children: [
            // Filtered Stats Header (Bento Grid)
            if (filteredTxs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0),
                child: Row(
                  children: [
                    // Total Count Card
                    Expanded(
                      child: GlassmorphismCard(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LOGGED',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9,
                                color: isDark ? Colors.white38 : Colors.black38,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${filteredTxs.length}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Income Card
                    Expanded(
                      flex: 2,
                      child: GlassmorphismCard(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                        color: isDark 
                            ? Colors.green.withOpacity(0.06) 
                            : Colors.green.withOpacity(0.04),
                        borderColor: Colors.green.withOpacity(0.15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FILTERED INFLOW',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9,
                                color: isDark ? Colors.white38 : Colors.black38,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '+${CurrencyFormatter.format(totalIncome, currency)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Expense Card
                    Expanded(
                      flex: 2,
                      child: GlassmorphismCard(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                        color: isDark 
                            ? const Color(0xFFE53935).withOpacity(0.06) 
                            : const Color(0xFFE53935).withOpacity(0.04),
                        borderColor: const Color(0xFFE53935).withOpacity(0.15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FILTERED OUTFLOW',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9,
                                color: isDark ? Colors.white38 : Colors.black38,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '-${CurrencyFormatter.format(totalExpense, currency)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE53935),
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Quick-Add Templates Row
            _buildTemplatesRow(context, currency, isDark),

            // Search & Filter Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search title or note...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                _searchDebounce?.cancel();
                                ref.read(transactionsProvider.notifier).setSearchQuery('');
                              },
                              icon: const Icon(Icons.clear),
                            )
                          : null,
                    ),
                    onChanged: (val) {
                      _searchDebounce?.cancel();
                      _searchDebounce = Timer(const Duration(milliseconds: 300), () {
                        ref.read(transactionsProvider.notifier).setSearchQuery(val);
                      });
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Horizontal Filter Chips Row
                  SizedBox(
                    height: 38,
                    child: Row(
                      children: [
                        Expanded(
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              // Type filter: Expense
                              _buildFilterChip(
                                label: 'Expenses',
                                isSelected: txState.filterType == 'expense',
                                onSelected: (selected) {
                                  ref.read(transactionsProvider.notifier).setFilterType(selected ? 'expense' : null);
                                },
                              ),
                              const SizedBox(width: 8),

                              // Type filter: Income
                              _buildFilterChip(
                                label: 'Incomes',
                                isSelected: txState.filterType == 'income',
                                onSelected: (selected) {
                                  ref.read(transactionsProvider.notifier).setFilterType(selected ? 'income' : null);
                                },
                              ),
                              const SizedBox(width: 8),

                              // Type filter: Transfer
                              _buildFilterChip(
                                label: 'Transfers',
                                isSelected: txState.filterType == 'transfer',
                                onSelected: (selected) {
                                  ref.read(transactionsProvider.notifier).setFilterType(selected ? 'transfer' : null);
                                },
                              ),
                              
                              if (accounts.isNotEmpty) ...[
                                const SizedBox(width: 12),
                                // Account selector chip
                                _buildAccountSelectorChip(accounts),
                              ],
                              if (categories.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                _buildCategorySelectorChip(categories),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Advanced filters trigger button
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                          ),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const AdvancedFiltersSheet(),
                            );
                          },
                          icon: const Icon(Icons.tune, size: 18),
                          tooltip: 'Advanced Filters',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1, thickness: 0.5),

            // Ledger List
            Expanded(
              child: txState.isLoading || _isLoadingCategories
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)))
                  : filteredTxs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: isDark ? Colors.white30 : Colors.black26,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No transactions found.',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: filteredTxs.length,
                          itemBuilder: (context, index) {
                            final tx = filteredTxs[index];
                            
                            // Look up category metadata
                            final cat = _categoryMap[tx.categoryId] ?? {
                              'name': 'Other',
                              'color': '757575',
                              'icon': 'category'
                            };

                            final accName = accountMap[tx.accountId] ?? 'Account';
                            final isSelected = _selectedTxs.contains(tx);

                            final listItem = TransactionListItem(
                              transaction: tx,
                              categoryName: cat['name'] as String,
                              categoryColorHex: cat['color'] as String,
                              categoryIconKey: cat['icon'] as String,
                              accountName: accName,
                              currency: currency,
                              onTap: () {
                                if (_isSelectionMode) {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedTxs.remove(tx);
                                      if (_selectedTxs.isEmpty) {
                                        _isSelectionMode = false;
                                      }
                                    } else {
                                      _selectedTxs.add(tx);
                                    }
                                  });
                                } else {
                                  // Prevent editing virtual projections directly
                                  if (tx.id != null && tx.id! < 0) {
                                    ToastNotification.show(
                                      context, 
                                      'This is a projected future transaction. Edit the original transaction to modify it.',
                                      isWarning: true
                                    );
                                    return;
                                  }
                                  _openTransactionForm(context, tx);
                                }
                              },
                              onLongPress: () {
                                if (!_isSelectionMode) {
                                  setState(() {
                                    _isSelectionMode = true;
                                    _selectedTxs.add(tx);
                                  });
                                }
                              },
                              confirmDismiss: (direction) async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) {
                                    final isDark = Theme.of(context).brightness == Brightness.dark;
                                    return AlertDialog(
                                      backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                                      title: const Text('Delete Transaction', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      content: Text('Are you sure you want to delete "${tx.title}"? This will modify your account balance.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFE53935),
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                return confirmed == true;
                              },
                              onDismissed: (direction) async {
                                final success = await ref.read(transactionsProvider.notifier).deleteTransaction(tx);
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Deleted "${tx.title}"'),
                                      backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                                        ),
                                      ),
                                      action: SnackBarAction(
                                        label: 'Undo',
                                        textColor: const Color(0xFFE53935),
                                        onPressed: () async {
                                          await ref.read(transactionsProvider.notifier).restoreTransaction(tx);
                                        },
                                      ),
                                    ),
                                  );
                                }
                              },
                            );
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: _isSelectionMode
                                  ? Row(
                                      children: [
                                        Checkbox(
                                          value: isSelected,
                                          activeColor: const Color(0xFFE53935),
                                          onChanged: (val) {
                                            setState(() {
                                              if (val == true) {
                                                _selectedTxs.add(tx);
                                              } else {
                                                _selectedTxs.remove(tx);
                                                if (_selectedTxs.isEmpty) {
                                                  _isSelectionMode = false;
                                                }
                                              }
                                            });
                                          },
                                        ),
                                        Expanded(child: listItem),
                                      ],
                                    )
                                  : listItem,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required ValueChanged<bool> onSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      checkmarkColor: Colors.white,
      selectedColor: const Color(0xFFE53935),
      labelStyle: TextStyle(
        color: isSelected 
            ? Colors.white 
            : (isDark ? Colors.white70 : Colors.black87),
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontFamily: 'Inter',
      ),
      backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.black.withOpacity(0.02),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected 
              ? const Color(0xFFE53935) 
              : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
        ),
      ),
    );
  }

  Widget _buildAccountSelectorChip(List<Account> accounts) {
    final txState = ref.watch(transactionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final selectedAccount = accounts.firstWhere(
      (a) => a.id == txState.filterAccountId,
      orElse: () => Account(name: 'All Accounts', type: 'Bank', balance: 0, icon: '', color: '', isShared: false, createdAt: DateTime.now()),
    );
    
    final isSelected = txState.filterAccountId != null;
 
    return Theme(
      data: Theme.of(context).copyWith(canvasColor: isDark ? const Color(0xFF161625) : Colors.white),
      child: PopupMenuButton<int?>(
        initialValue: txState.filterAccountId,
        onSelected: (id) {
          ref.read(transactionsProvider.notifier).setFilterAccount(id);
        },
        itemBuilder: (context) {
          final items = <PopupMenuEntry<int?>>[
            const PopupMenuItem<int?>(
              value: null,
              child: Text('All Accounts', style: TextStyle(fontSize: 13)),
            ),
            const PopupMenuDivider(),
          ];
          items.addAll(accounts.map((a) {
            return PopupMenuItem<int?>(
              value: a.id,
              child: Text(a.name, style: const TextStyle(fontSize: 13)),
            );
          }));
          return items;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFFE53935) 
                : (isDark ? const Color(0xFF1E1E2E) : Colors.black.withOpacity(0.02)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected 
                  ? const Color(0xFFE53935) 
                  : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedAccount.name,
                style: TextStyle(
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                size: 14,
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelectorChip(List<Category> categories) {
    final txState = ref.watch(transactionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final selectedCategory = categories.firstWhere(
      (c) => c.id == txState.filterCategoryId,
      orElse: () => Category(name: 'All Categories', icon: '', color: '', isDefault: false, type: 'both'),
    );
    
    final isSelected = txState.filterCategoryId != null;
    
    return Theme(
      data: Theme.of(context).copyWith(canvasColor: isDark ? const Color(0xFF161625) : Colors.white),
      child: PopupMenuButton<int?>(
        initialValue: txState.filterCategoryId,
        onSelected: (id) {
          ref.read(transactionsProvider.notifier).setFilterCategory(id);
        },
        itemBuilder: (context) {
          final items = <PopupMenuEntry<int?>>[
            const PopupMenuItem<int?>(
              value: null,
              child: Text('All Categories', style: TextStyle(fontSize: 13)),
            ),
            const PopupMenuDivider(),
          ];
          items.addAll(categories.map((c) {
            return PopupMenuItem<int?>(
              value: c.id,
              child: Text(c.name, style: const TextStyle(fontSize: 13)),
            );
          }));
          return items;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFFE53935) 
                : (isDark ? const Color(0xFF1E1E2E) : Colors.black.withOpacity(0.02)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected 
                  ? const Color(0xFFE53935) 
                  : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedCategory.name,
                style: TextStyle(
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                size: 14,
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdvancedFiltersSheet extends ConsumerStatefulWidget {
  const AdvancedFiltersSheet({Key? key}) : super(key: key);

  @override
  ConsumerState<AdvancedFiltersSheet> createState() => _AdvancedFiltersSheetState();
}

class _AdvancedFiltersSheetState extends ConsumerState<AdvancedFiltersSheet> {
  final TextEditingController _presetNameController = TextEditingController();

  List<String> _extractTags(Transaction tx) {
    final List<String> tags = [];
    final RegExp regex = RegExp(r'#(\w+)');
    final String text = '${tx.title} ${tx.note ?? ""}';
    for (var match in regex.allMatches(text)) {
      final tag = match.group(1)?.toLowerCase();
      if (tag != null && !tags.contains(tag)) {
        tags.add(tag);
      }
    }
    return tags;
  }

  @override
  void dispose() {
    _presetNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txState = ref.watch(transactionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final maxTransactionAmount = txState.transactions.isEmpty
        ? 1000.0
        : txState.transactions.map((t) => t.amount).fold<double>(0.0, (m, val) => val > m ? val : m);

    final Set<String> allTags = {};
    for (var tx in txState.transactions) {
      allTags.addAll(_extractTags(tx));
    }

    final double currentMin = txState.minAmount ?? 0.0;
    final double currentMax = (txState.maxAmount ?? maxTransactionAmount).clamp(currentMin, maxTransactionAmount);

    final authState = ref.watch(authProvider);
    final currency = authState.profile?.preferredCurrency ?? 'USD';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161625) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
              'Advanced Filters',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
            ),
            const SizedBox(height: 20),

            const Text('Amount Range', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Inter')),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(CurrencyFormatter.format(currentMin, currency), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Text(CurrencyFormatter.format(currentMax, currency), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            RangeSlider(
              values: RangeValues(currentMin, currentMax),
              min: 0.0,
              max: maxTransactionAmount,
              divisions: maxTransactionAmount > 0 ? maxTransactionAmount.round().clamp(1, 100) : 1,
              activeColor: const Color(0xFFE53935),
              inactiveColor: Colors.grey.withOpacity(0.3),
              labels: RangeLabels(
                CurrencyFormatter.format(currentMin, currency),
                CurrencyFormatter.format(currentMax, currency),
              ),
              onChanged: (RangeValues values) {
                ref.read(transactionsProvider.notifier).setMinAmount(values.start == 0.0 ? null : values.start);
                ref.read(transactionsProvider.notifier).setMaxAmount(values.end == maxTransactionAmount ? null : values.end);
              },
            ),
            const SizedBox(height: 20),

            if (allTags.isNotEmpty) ...[
              const Text('Filter by Tag', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Inter')),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: allTags.map((tag) {
                  final isSelected = txState.selectedTags.contains(tag);
                  return FilterChip(
                    label: Text('#$tag'),
                    selected: isSelected,
                    checkmarkColor: Colors.white,
                    selectedColor: const Color(0xFFE53935),
                    labelStyle: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87), fontSize: 11),
                    onSelected: (selected) {
                      final updated = List<String>.from(txState.selectedTags);
                      if (selected) {
                        updated.add(tag);
                      } else {
                        updated.remove(tag);
                      }
                      ref.read(transactionsProvider.notifier).setSelectedTags(updated);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            const Text('Filter Presets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Inter')),
            const SizedBox(height: 8),
            if (txState.presets.isEmpty)
              const Text('No saved filter presets yet.', style: TextStyle(fontSize: 12, color: Colors.grey))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: txState.presets.length,
                itemBuilder: (context, idx) {
                  final preset = txState.presets[idx];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(preset['name'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                          onPressed: () {
                            final Map<String, dynamic> filters = jsonDecode(preset['filters_json'] as String);
                            ref.read(transactionsProvider.notifier).applyPreset(filters);
                            ToastNotification.show(context, 'Preset "${preset['name']}" applied.');
                            Navigator.pop(context);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E2E) : Colors.white,
                                title: const Text('Delete Filter Preset', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                content: Text('Are you sure you want to delete preset "${preset['name']}"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE53935),
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await ref.read(transactionsProvider.notifier).deletePreset(preset['id'] as int);
                              ToastNotification.show(context, 'Preset deleted.');
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _presetNameController,
                    decoration: const InputDecoration(
                      labelText: 'Preset Name',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    final name = _presetNameController.text.trim();
                    if (name.isEmpty) {
                      ToastNotification.show(context, 'Please enter a name for the preset', isError: true);
                      return;
                    }
                    await ref.read(transactionsProvider.notifier).savePreset(name);
                    _presetNameController.clear();
                    if (mounted) {
                      ToastNotification.show(context, 'Preset "$name" saved.');
                    }
                  },
                  child: const Text('Save Preset'),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

