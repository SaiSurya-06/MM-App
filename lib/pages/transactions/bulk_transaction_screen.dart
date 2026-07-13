import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../models/account.dart';
import '../../providers/transactions_provider.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/categories_provider.dart';
import '../../widgets/common/glassmorphism_card.dart';
import '../../widgets/common/toast_notification.dart';
import 'package:intl/intl.dart';

enum BulkMode { add, edit }

class BulkTransactionScreen extends ConsumerStatefulWidget {
  final BulkMode mode;
  final List<Transaction>? initialTransactions; // Selected transactions for edit mode

  const BulkTransactionScreen({
    super.key,
    required this.mode,
    this.initialTransactions,
  });

  @override
  ConsumerState<BulkTransactionScreen> createState() => _BulkTransactionScreenState();
}

class _EditableTxRow {
  final int? id; // Null for new, present for existing edits
  String type; // 'expense', 'income', 'transfer'
  DateTime date;
  final TextEditingController titleController;
  final TextEditingController amountController;
  int categoryId;
  int accountId;
  int? transferToAccountId;
  String note;
  String recurrence;
  bool isPrivate;

  _EditableTxRow({
    this.id,
    required this.type,
    required this.date,
    required String title,
    required double amount,
    required this.categoryId,
    required this.accountId,
    this.transferToAccountId,
    this.note = '',
    this.recurrence = 'none',
    this.isPrivate = false,
  })  : titleController = TextEditingController(text: title),
        amountController = TextEditingController(
          text: amount > 0 ? amount.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '') : '',
        );

  void dispose() {
    titleController.dispose();
    amountController.dispose();
  }
}

class _BulkTransactionScreenState extends ConsumerState<BulkTransactionScreen> {
  final List<_EditableTxRow> _rows = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupInitialRows();
    });
  }

  void _setupInitialRows() {
    final accounts = ref.read(accountsProvider).accounts;
    final categories = ref.read(categoriesProvider).categories;

    if (accounts.isEmpty || categories.isEmpty) return;

    final defaultAccount = accounts.first.id!;
    final defaultCategory = categories.first.id!;

    setState(() {
      if (widget.mode == BulkMode.edit && widget.initialTransactions != null) {
        for (var tx in widget.initialTransactions!) {
          _rows.add(_EditableTxRow(
            id: tx.id,
            type: tx.type,
            date: tx.date,
            title: tx.title,
            amount: tx.amount,
            categoryId: tx.categoryId,
            accountId: tx.accountId,
            transferToAccountId: tx.transferToAccountId,
            note: tx.note ?? '',
            recurrence: tx.recurrence,
            isPrivate: tx.isPrivate,
          ));
        }
      } else {
        // Start with 2 empty rows in Add Mode
        _addNewRow(defaultAccount, defaultCategory);
        _addNewRow(defaultAccount, defaultCategory);
      }
    });
  }

  void _addNewRow(int defaultAccount, int defaultCategory) {
    _rows.add(_EditableTxRow(
      type: 'expense',
      date: DateTime.now(),
      title: '',
      amount: 0,
      categoryId: defaultCategory,
      accountId: defaultAccount,
    ));
  }

  @override
  void dispose() {
    for (var r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, _EditableTxRow row) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: row.date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        row.date = picked;
      });
    }
  }

  Future<void> _saveAll() async {
    // 1. Validation
    if (_rows.isEmpty) {
      ToastNotification.show(context, 'Please add at least one transaction row.', isError: true);
      return;
    }

    final List<Transaction> validatedList = [];
    final List<Transaction> originalListForEdit = [];

    for (int i = 0; i < _rows.length; i++) {
      final row = _rows[i];
      final title = row.titleController.text.trim();
      final amountStr = row.amountController.text.trim();
      final amount = double.tryParse(amountStr) ?? 0.0;

      if (title.isEmpty) {
        ToastNotification.show(context, 'Row #${i + 1}: Title cannot be empty.', isError: true);
        return;
      }
      if (amount <= 0) {
        ToastNotification.show(context, 'Row #${i + 1}: Amount must be greater than zero.', isError: true);
        return;
      }
      if (row.type == 'transfer' && row.transferToAccountId == null) {
        ToastNotification.show(context, 'Row #${i + 1}: Please select destination account for transfer.', isError: true);
        return;
      }
      if (row.type == 'transfer' && row.accountId == row.transferToAccountId) {
        ToastNotification.show(context, 'Row #${i + 1}: Source and destination accounts must be different.', isError: true);
        return;
      }

      final tx = Transaction(
        id: row.id,
        accountId: row.accountId,
        categoryId: row.categoryId,
        title: title,
        amount: amount,
        type: row.type,
        date: row.date,
        note: row.note.isEmpty ? null : row.note,
        recurrence: row.recurrence,
        isPrivate: row.isPrivate,
        transferToAccountId: row.type == 'transfer' ? row.transferToAccountId : null,
        createdAt: DateTime.now(),
      );

      validatedList.add(tx);

      if (widget.mode == BulkMode.edit) {
        final original = widget.initialTransactions!.firstWhere((t) => t.id == row.id);
        originalListForEdit.add(original);
      }
    }

    // 2. Execution
    bool success = false;
    if (widget.mode == BulkMode.add) {
      success = await ref.read(transactionsProvider.notifier).bulkAddTransactions(validatedList);
    } else {
      success = await ref.read(transactionsProvider.notifier).bulkUpdateTransactions(
        originalListForEdit,
        validatedList,
      );
    }

    if (mounted) {
      if (success) {
        ToastNotification.show(
          context,
          widget.mode == BulkMode.add
              ? 'Successfully added ${validatedList.length} transactions.'
              : 'Successfully updated ${validatedList.length} transactions.',
        );
        Navigator.pop(context, true); // Return true to refresh list
      } else {
        final error = ref.read(transactionsProvider).errorMessage ?? 'An error occurred';
        ToastNotification.show(context, 'Save failed: $error', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider).accounts;
    final categories = ref.watch(categoriesProvider).categories;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF0F0F11) : const Color(0xFFF3F4F6);
    final cardBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.mode == BulkMode.add ? 'Bulk Add Transactions' : 'Bulk Edit Transactions',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Inter'),
        ),
        actions: [
          TextButton(
            onPressed: _saveAll,
            child: const Text(
              'Save All',
              style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _rows.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.blueAccent),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _rows.length,
                      itemBuilder: (context, index) {
                        final row = _rows[index];
                        return _buildRowCard(index, row, accounts, categories, cardBg, textColor, isDark);
                      },
                    ),
            ),
            if (widget.mode == BulkMode.add && accounts.isNotEmpty && categories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _addNewRow(accounts.first.id!, categories.first.id!),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Another Transaction Row', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blueAccent,
                          side: const BorderSide(color: Colors.blueAccent),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowCard(
    int index,
    _EditableTxRow row,
    List<Account> accounts,
    List<Category> categories,
    Color cardBg,
    Color textColor,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: GlassmorphismCard(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header index & Delete
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transaction #${index + 1}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor.withOpacity(0.6)),
                  ),
                  if (widget.mode == BulkMode.add)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                      onPressed: () {
                        setState(() {
                          final removed = _rows.removeAt(index);
                          removed.dispose();
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // 1. Sliding capsule Type selector
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white12 : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildTypeButton(row, 'expense', 'Expense', Colors.redAccent),
                    _buildTypeButton(row, 'income', 'Income', Colors.green),
                    _buildTypeButton(row, 'transfer', 'Transfer', Colors.blueAccent),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Date Chip Picker
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _selectDate(context, row),
                    style: TextButton.styleFrom(
                      backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.03),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: Text(
                      DateFormat('EEE, MMM d, yyyy').format(row.date),
                      style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. Title & Amount
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: row.titleController,
                      decoration: InputDecoration(
                        labelText: 'Title / Description',
                        labelStyle: const TextStyle(fontSize: 12),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueAccent.withOpacity(0.6)),
                        ),
                      ),
                      style: TextStyle(color: textColor, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: row.amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        labelStyle: const TextStyle(fontSize: 12),
                        prefixText: '₹ ',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueAccent.withOpacity(0.6)),
                        ),
                      ),
                      style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4. Source Account & Category
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: row.accountId,
                      decoration: const InputDecoration(
                        labelText: 'Account',
                        labelStyle: TextStyle(fontSize: 12),
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(color: textColor, fontSize: 13),
                      items: accounts.map((acc) {
                        return DropdownMenuItem<int>(
                          value: acc.id,
                          child: Text(acc.name, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            row.accountId = val;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: row.categoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        labelStyle: TextStyle(fontSize: 12),
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(color: textColor, fontSize: 13),
                      items: categories.map((cat) {
                        return DropdownMenuItem<int>(
                          value: cat.id,
                          child: Text(cat.name, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            row.categoryId = val;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),

              // 5. Transfer Target Account (only visible if transfer)
              if (row.type == 'transfer') ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: row.transferToAccountId,
                  decoration: const InputDecoration(
                    labelText: 'Destination Account',
                    labelStyle: TextStyle(fontSize: 12),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: TextStyle(color: textColor, fontSize: 13),
                  items: accounts.map((acc) {
                    return DropdownMenuItem<int>(
                      value: acc.id,
                      child: Text(acc.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      row.transferToAccountId = val;
                    });
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(
    _EditableTxRow row,
    String type,
    String label,
    Color activeColor,
  ) {
    final isSelected = row.type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            row.type = type;
            if (type != 'transfer') {
              row.transferToAccountId = null;
            }
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
