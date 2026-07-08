import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/transaction.dart';
import '../../../models/category.dart';
import '../../../providers/accounts_provider.dart';
import '../../../providers/transactions_provider.dart';
import '../../../providers/categories_provider.dart';
import '../../../providers/transaction_templates_provider.dart';
import '../../../widgets/common/toast_notification.dart';
import '../../../core/utils/ai_categorization_helper.dart';
import '../../core/database/database.dart';
import '../categories/category_form.dart';

class TransactionForm extends ConsumerStatefulWidget {
  final Transaction? transaction;
  final DateTime? initialDate;
  final String? initialType; // 'income', 'expense', 'transfer'

  const TransactionForm({
    super.key,
    this.transaction,
    this.initialDate,
    this.initialType,
  });

  @override
  ConsumerState<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends ConsumerState<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late TextEditingController _tagsController;
  
  late String _selectedType; // 'income', 'expense', 'transfer'
  int? _selectedAccountId;
  int? _selectedTargetAccountId; // Only for transfers
  int? _selectedCreditCardAccountId; // Target credit card for payback category
  int? _selectedCategoryId;
  int? _selectedSubcategoryId;
  late DateTime _selectedDate;
  late String _selectedRecurrence; // 'none', 'daily', 'weekly', 'monthly', 'yearly'
  DateTime? _selectedRecurrenceEndDate;
  final List<String> _recurrenceOptions = ['none', 'daily', 'weekly', 'monthly', 'yearly'];

  String _categorizeMode = 'category'; // 'category' or 'person'
  bool _initializedMode = false;

  bool _isSplitMode = false;
  List<Map<String, dynamic>> _splits = [];
  bool _saveAsTemplate = false;
  bool _isAutoCategorized = false;

  bool _hasUnsavedChanges() {
    final tx = widget.transaction;
    if (tx == null) {
      return _titleController.text.trim().isNotEmpty ||
             _amountController.text.trim().isNotEmpty ||
             _noteController.text.trim().isNotEmpty ||
             _tagsController.text.trim().isNotEmpty;
    } else {
      final titleChanged = _titleController.text.trim() != tx.title;
      final amountChanged = (double.tryParse(_amountController.text.trim()) ?? 0.0) != tx.amount;
      
      String originalNote = tx.note ?? '';
      String currentNote = _noteController.text.trim();
      
      final noteChanged = currentNote != originalNote;
      final tagsChanged = _tagsController.text.trim() != tx.tags;
      final typeChanged = _selectedType != tx.type;
      final accountChanged = _selectedAccountId != tx.accountId;
      final categoryChanged = _selectedCategoryId != tx.categoryId;
      final subcategoryChanged = _selectedSubcategoryId != tx.subcategoryId;
      
      return titleChanged || amountChanged || noteChanged || tagsChanged || typeChanged || accountChanged || categoryChanged || subcategoryChanged;
    }
  }

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _titleController = TextEditingController(text: tx?.title ?? '');
    _amountController = TextEditingController(text: tx?.amount.toString() ?? '');
    _noteController = TextEditingController(text: tx?.note ?? '');
    _tagsController = TextEditingController(text: tx?.tags ?? '');
    
    _selectedType = tx?.type ?? widget.initialType ?? 'expense';
    _selectedAccountId = tx?.accountId;
    _selectedRecurrence = tx?.recurrence ?? 'none';
    _selectedRecurrenceEndDate = tx?.recurrenceEndDate;
    _selectedDate = tx?.date ?? widget.initialDate ?? DateTime.now();

    if (_selectedType == 'transfer') {
      _selectedTargetAccountId = tx?.transferToAccountId ?? _parseDestAccountId(tx?.note);
    }
    
    _selectedCreditCardAccountId = tx?.transferToAccountId ?? _parseCreditCardTargetAccountId(tx?.note);

    _selectedCategoryId = tx?.categoryId;
    _selectedSubcategoryId = tx?.subcategoryId;

    if (tx != null && tx.id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExistingSplits(tx.id!);
      });
    }
  }

  Future<void> _loadExistingSplits(int parentId) async {
    final splits = await ref.read(transactionsProvider.notifier).getSplitsForParent(parentId);
    if (splits.isNotEmpty) {
      setState(() {
        _isSplitMode = true;
        _splits = splits.map((s) => {
          'categoryId': s.categoryId,
          'amount': s.amount,
          'note': s.note ?? '',
          'tags': s.tags,
        }).toList();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _suggestTags() {
    final title = _titleController.text.trim();
    final note = _noteController.text.trim();
    final text = '$title $note'.toLowerCase();
    
    // Auto-detect hashtag words like #vacation, #dining, #gift
    final RegExp hashRegex = RegExp(r'#(\w+)');
    final List<String> currentTags = _tagsController.text
        .split(',')
        .map((t) => t.trim().toLowerCase())
        .where((t) => t.isNotEmpty)
        .toList();
        
    bool changed = false;
    for (var match in hashRegex.allMatches('$title $note')) {
      final tag = match.group(1);
      if (tag != null && !currentTags.contains(tag.toLowerCase())) {
        currentTags.add(tag.toLowerCase());
        changed = true;
      }
    }
    
    // Keywords suggestions
    final keywordMap = {
      'vacation': ['trip', 'flight', 'hotel', 'airbnb', 'tourist', 'booking'],
      'dining': ['swiggy', 'zomato', 'restaurant', 'dinner', 'cafe', 'foodie'],
      'gift': ['gift', 'birthday', 'anniversary', 'present', 'wrapping'],
      'utilities': ['electricity', 'water', 'internet', 'broadband', 'gas bill', 'wifi'],
      'commute': ['uber', 'ola', 'metro', 'train ticket', 'bus ticket', 'cab'],
    };
    
    keywordMap.forEach((tag, keywords) {
      if (!currentTags.contains(tag)) {
        for (var keyword in keywords) {
          if (text.contains(keyword)) {
            currentTags.add(tag);
            changed = true;
            break;
          }
        }
      }
    });

    if (changed) {
      _tagsController.text = currentTags.join(', ');
    }
  }

  int? _parseDestAccountId(String? note) {
    if (note == null) return null;
    final regExp = RegExp(r'Transfer to target account ID: (\d+)');
    final match = regExp.firstMatch(note);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }

  int? _parseCreditCardTargetAccountId(String? note) {
    if (note == null) return null;
    final regExp = RegExp(r'Credit Card Payment to target account ID: (\d+)');
    final match = regExp.firstMatch(note);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }

  void _autoCategorize(String text) {
    final title = text.trim();
    if (title.isEmpty) return;

    final categories = ref.read(categoriesProvider).categories;
    final transactions = ref.read(transactionsProvider).transactions;
    final filteredCategories = categories.where((cat) {
      if (_selectedType == 'income') {
        return cat.type == 'income' || cat.type == 'both' || cat.type == 'person';
      } else if (_selectedType == 'expense') {
        return cat.type == 'expense' || cat.type == 'both' || cat.type == 'person';
      }
      return true;
    }).toList();

    if (filteredCategories.isEmpty) return;

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final targetCategoryId = AiCategorizationHelper.classify(
      title,
      amount,
      transactions,
      filteredCategories,
    );

    if (targetCategoryId != null && _selectedCategoryId != targetCategoryId) {
      final matchedCat = categories.any((c) => c.id == targetCategoryId)
          ? categories.firstWhere((c) => c.id == targetCategoryId)
          : null;
      setState(() {
        _selectedCategoryId = targetCategoryId;
        _isAutoCategorized = true;
        if (matchedCat != null) {
          _categorizeMode = matchedCat.type == 'person' ? 'person' : 'category';
        }
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFE53935),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectRecurrenceEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedRecurrenceEndDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFE53935),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedRecurrenceEndDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedAccountId == null) {
      ToastNotification.show(context, 'Please select an account', isError: true);
      return;
    }

    final categories = ref.read(categoriesProvider).categories;
    final selectedCategory = categories.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => const Category(id: -1, name: '', icon: '', color: '', isDefault: false, type: 'both'),
    );
    final isCreditCardPayment = _selectedType != 'transfer' && selectedCategory.name.toLowerCase() == 'credit card payment';

    if (_selectedType == 'transfer') {
      if (_selectedTargetAccountId == null) {
        ToastNotification.show(context, 'Please select a destination account', isError: true);
        return;
      }
      if (_selectedAccountId == _selectedTargetAccountId) {
        ToastNotification.show(context, 'Source and destination accounts must be different', isError: true);
        return;
      }
    } else if (isCreditCardPayment) {
      if (_selectedCreditCardAccountId == null) {
        ToastNotification.show(context, 'Please select a Credit Card to pay back', isError: true);
        return;
      }
      if (_selectedAccountId == _selectedCreditCardAccountId) {
        ToastNotification.show(context, 'Source and Credit Card accounts must be different', isError: true);
        return;
      }
    }

    final title = _titleController.text.trim();
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ToastNotification.show(context, 'Please enter an amount', isError: true);
      return;
    }
    final amount = double.tryParse(amountText) ?? 0.0;
    if (amount <= 0.0) {
      ToastNotification.show(context, 'Amount must be greater than zero', isError: true);
      return;
    }
    final amtParts = amountText.split('.');
    if (amtParts.length > 1 && amtParts[1].length > 2) {
      ToastNotification.show(context, 'Amount cannot have more than 2 decimal places', isError: true);
      return;
    }
    final tags = _tagsController.text.trim();
    
    // Create correct notes formatting for transfer tracking
    String? note = _noteController.text.trim();
    if (_selectedType == 'transfer') {
      final destAcc = ref.read(accountsProvider).accounts.firstWhere((a) => a.id == _selectedTargetAccountId);
      note = 'Transfer to target account ID: $_selectedTargetAccountId (${destAcc.name}). ${note.isEmpty ? "" : note}';
    } else if (isCreditCardPayment) {
      final ccAcc = ref.read(accountsProvider).accounts.firstWhere((a) => a.id == _selectedCreditCardAccountId);
      note = 'Credit Card Payment to target account ID: $_selectedCreditCardAccountId (${ccAcc.name}). ${note.isEmpty ? "" : note}';
    }

    // Splits validation
    if (_isSplitMode && _selectedType != 'transfer') {
      if (_splits.isEmpty) {
        ToastNotification.show(context, 'Please add at least one category split', isError: true);
        return;
      }
      double splitSum = 0.0;
      for (var s in _splits) {
        splitSum += s['amount'] as double;
      }
      if ((splitSum - amount).abs() > 0.01) {
        ToastNotification.show(
          context,
          'Sum of category splits (${splitSum.toStringAsFixed(2)}) must match the total transaction amount (${amount.toStringAsFixed(2)})',
          isError: true,
        );
        return;
      }
    }

    final categoryId = _selectedType == 'transfer' ? 8 : _selectedCategoryId!;
    final transferToAccountId = _selectedType == 'transfer'
        ? _selectedTargetAccountId
        : (isCreditCardPayment ? _selectedCreditCardAccountId : null);

    bool success;
    int? parentId;

    if (widget.transaction == null) {
      parentId = await ref.read(transactionsProvider.notifier).addTransactionAndReturnId(
            accountId: _selectedAccountId!,
            categoryId: categoryId,
            title: title,
            amount: amount,
            type: _selectedType,
            date: _selectedDate,
            note: note.isEmpty ? null : note,
            recurrence: _selectedRecurrence,
            recurrenceEndDate: _selectedRecurrence == 'none' ? null : _selectedRecurrenceEndDate,
            isPrivate: false,
            tags: tags,
            transferToAccountId: transferToAccountId,
            subcategoryId: _selectedSubcategoryId,
          );
      success = parentId != null;
    } else {
      parentId = widget.transaction!.id;
      final updated = widget.transaction!.copyWith(
        accountId: _selectedAccountId!,
        categoryId: categoryId,
        title: title,
        amount: amount,
        type: _selectedType,
        date: _selectedDate,
        note: note.isEmpty ? null : note,
        recurrence: _selectedRecurrence,
        recurrenceEndDate: _selectedRecurrence == 'none' ? null : _selectedRecurrenceEndDate,
        isPrivate: false,
        tags: tags,
        transferToAccountId: transferToAccountId,
        subcategoryId: _selectedSubcategoryId,
      );
      
      // If updating a split transaction, remove its old child rows first
      final db = await AppDatabase.instance.database;
      await db.delete('transaction_log', where: 'parent_id = ?', whereArgs: [parentId]);

      success = await ref.read(transactionsProvider.notifier).updateTransaction(updated, widget.transaction!);
    }

    if (success && parentId != null) {
      if (_isSplitMode && _selectedType != 'transfer') {
        await ref.read(transactionsProvider.notifier).splitTransaction(
              parentTransactionId: parentId,
              splits: _splits,
            );
      }

      // Save as Template if checked
      if (_saveAsTemplate && widget.transaction == null) {
        await ref.read(transactionTemplatesProvider.notifier).addTemplate(
              title: title,
              amount: amount,
              type: _selectedType,
              categoryId: categoryId,
              accountId: _selectedAccountId!,
            );
      }

      if (mounted) {
        ToastNotification.show(
          context,
          widget.transaction == null ? 'Transaction logged successfully!' : 'Transaction logged successfully!',
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction? This will modify your account balance.'),
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

    if (confirmed == true && mounted) {
      final success = await ref.read(transactionsProvider.notifier).deleteTransaction(widget.transaction!);
      if (success && mounted) {
        ToastNotification.show(context, 'Transaction deleted.');
        Navigator.pop(context); // Close TransactionForm
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider).accounts;
    final categoriesState = ref.watch(categoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final allCategories = categoriesState.categories;
    final isLoadingCategories = categoriesState.isLoading;

    final filteredCategories = allCategories.where((cat) {
      if (_selectedType == 'income') {
        return cat.type == 'income' || cat.type == 'both' || cat.type == 'person';
      } else if (_selectedType == 'expense') {
        return cat.type == 'expense' || cat.type == 'both' || cat.type == 'person';
      }
      return true;
    }).toList();

    final standardCategories = allCategories.where((cat) {
      if (_selectedType == 'income') {
        return (cat.type == 'income' || cat.type == 'both') && cat.type != 'person' && cat.parentId == null;
      } else if (_selectedType == 'expense') {
        return (cat.type == 'expense' || cat.type == 'both') && cat.type != 'person' && cat.parentId == null;
      }
      return cat.type != 'person' && cat.parentId == null;
    }).toList();

    final personCategories = allCategories.where((cat) => cat.type == 'person' && cat.parentId == null).toList();

    if (!_initializedMode && !isLoadingCategories) {
      _initializedMode = true;
      if (widget.transaction != null && _selectedCategoryId != null) {
        final txCategory = allCategories.firstWhere(
          (c) => c.id == _selectedCategoryId,
          orElse: () => const Category(id: -1, name: '', icon: '', color: '', isDefault: false, type: 'both'),
        );
        if (txCategory.type == 'person') {
          _categorizeMode = 'person';
        }
        if (txCategory.parentId != null) {
          _selectedSubcategoryId = txCategory.id;
          _selectedCategoryId = txCategory.parentId;
        } else {
          _selectedSubcategoryId = widget.transaction!.subcategoryId;
        }
      }
    }

    // Set default selected account if null
    if (_selectedAccountId == null && accounts.isNotEmpty) {
      _selectedAccountId = accounts.first.id;
    }
    if (_selectedType == 'transfer' && _selectedTargetAccountId == null && accounts.length > 1) {
      // Pick second account as target by default
      _selectedTargetAccountId = accounts.firstWhere((a) => a.id != _selectedAccountId).id;
    }

    // Set default selected category if null/invalid
    if (_selectedType != 'transfer' && !isLoadingCategories) {
      if (_categorizeMode == 'category' && standardCategories.isNotEmpty) {
        if (_selectedCategoryId == null || !standardCategories.any((c) => c.id == _selectedCategoryId)) {
          _selectedCategoryId = standardCategories.first.id;
        }
      } else if (_categorizeMode == 'person' && personCategories.isNotEmpty) {
        if (_selectedCategoryId == null || !personCategories.any((c) => c.id == _selectedCategoryId)) {
          _selectedCategoryId = personCategories.first.id;
        }
      }
    }

    return PopScope(
      canPop: !_hasUnsavedChanges(),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              title: const Text('Discard Changes?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
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
                  child: const Text('Discard'),
                ),
              ],
            );
          },
        );
        if (confirmed == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161625) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 24,
        ),
        child: SingleChildScrollView(
          child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pull Bar Indicator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                widget.transaction == null ? 'Log Transaction' : 'Edit Transaction',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
              
              const SizedBox(height: 16),

              // Transaction Type Selector Row
              Row(
                children: [
                  _buildTypeButton('expense', 'Expense', const Color(0xFFE53935)),
                  const SizedBox(width: 8),
                  _buildTypeButton('income', 'Income', Colors.green),
                  const SizedBox(width: 8),
                  _buildTypeButton('transfer', 'Transfer', Colors.blue),
                ],
              ),
              
              const SizedBox(height: 20),

              // Title Field
              TextFormField(
                controller: _titleController,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  prefixIcon: Icon(Icons.title),
                ),
                onChanged: (val) {
                  if (_selectedType == 'expense') {
                    _autoCategorize(val);
                  }
                },
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter a title';
                  return null;
                },
              ),
              
              const SizedBox(height: 16),

              // Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Please enter an amount';
                  final parsed = double.tryParse(val);
                  if (parsed == null || parsed <= 0) {
                    return 'Please enter a valid positive number';
                  }
                  if (val.contains('.')) {
                    final parts = val.split('.');
                    if (parts.length > 1 && parts[1].length > 2) {
                      return 'Amount cannot have more than 2 decimal places';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Account dropdown
              if (accounts.isNotEmpty)
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedAccountId,
                        decoration: InputDecoration(
                          labelText: _selectedType == 'transfer' ? 'Source Account' : 'Account',
                          prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                        ),
                        dropdownColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                        items: accounts.map((acc) {
                          return DropdownMenuItem(value: acc.id, child: Text(acc.name));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedAccountId = val;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Color(0xFFE53935)),
                      onPressed: () => _showQuickAddAccountDialog(context),
                      tooltip: 'Quick Add Account',
                    ),
                  ],
                ),

              const SizedBox(height: 16),

              // Target Account dropdown (Only for transfers)
              if (_selectedType == 'transfer' && accounts.length > 1) ...[
                DropdownButtonFormField<int>(
                  value: _selectedTargetAccountId,
                  decoration: const InputDecoration(
                    labelText: 'Destination Account',
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  ),
                  dropdownColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                  items: accounts.map((acc) {
                    return DropdownMenuItem(value: acc.id, child: Text(acc.name));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedTargetAccountId = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Split transaction toggle (only for non-transfers)
              if (_selectedType != 'transfer') ...[
                SwitchListTile(
                  value: _isSplitMode,
                  activeColor: const Color(0xFFE53935),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Split transaction across categories', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  onChanged: (val) {
                    setState(() {
                      _isSplitMode = val;
                      if (val && _splits.isEmpty) {
                        _splits.add({
                          'categoryId': filteredCategories.isNotEmpty ? filteredCategories.first.id : null,
                          'amount': 0.0,
                          'note': '',
                        });
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Category vs Person toggle and dropdown (Shown only if not in split mode and not transfer)
              if (_selectedType != 'transfer' && !_isSplitMode && !isLoadingCategories) ...[
                // Categorize By Segmented Toggle (Category vs Person)
                const Text(
                  'Categorize By',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _categorizeMode = 'category';
                            if (standardCategories.isNotEmpty) {
                              _selectedCategoryId = standardCategories.first.id;
                            }
                          });
                        },
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: _categorizeMode == 'category'
                                ? const Color(0xFFE53935)
                                : (isDark ? const Color(0xFF1E1E2E) : Colors.black.withValues(alpha: 0.02)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _categorizeMode == 'category'
                                  ? const Color(0xFFE53935)
                                  : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04)),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Category',
                              style: TextStyle(
                                color: _categorizeMode == 'category' ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                fontWeight: _categorizeMode == 'category' ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _categorizeMode = 'person';
                            if (personCategories.isNotEmpty) {
                              _selectedCategoryId = personCategories.first.id;
                            } else {
                              _selectedCategoryId = null;
                            }
                          });
                        },
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: _categorizeMode == 'person'
                                ? Colors.purple
                                : (isDark ? const Color(0xFF1E1E2E) : Colors.black.withValues(alpha: 0.02)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _categorizeMode == 'person'
                                  ? Colors.purple
                                  : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04)),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Person',
                              style: TextStyle(
                                color: _categorizeMode == 'person' ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                fontWeight: _categorizeMode == 'person' ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Now show the actual dropdown or "Add Person" message
                if (_categorizeMode == 'category' && standardCategories.isNotEmpty) ...[
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _selectedCategoryId,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          dropdownColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                          items: standardCategories.map((cat) {
                            return DropdownMenuItem(
                              value: cat.id,
                              child: Text(cat.name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedCategoryId = val;
                                _selectedSubcategoryId = null; // Reset subcategory when category changes
                                _isAutoCategorized = false;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Color(0xFFE53935)),
                        onPressed: () => _showQuickAddCategoryDialog(context),
                        tooltip: 'Quick Add Category',
                      ),
                    ],
                  ),
                  if (_isAutoCategorized) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, size: 12, color: Colors.purple),
                        const SizedBox(width: 4),
                        Text(
                          'AI Auto-categorized',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.purple[200] : Colors.purple[700],
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Sub-category Selector Section
                  () {
                    final subcategories = allCategories.where((c) => c.parentId == _selectedCategoryId).toList();
                    if (subcategories.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int?>(
                                value: subcategories.any((sub) => sub.id == _selectedSubcategoryId)
                                    ? _selectedSubcategoryId
                                    : null,
                                decoration: const InputDecoration(
                                  labelText: 'Sub-category (Optional)',
                                  prefixIcon: Icon(Icons.subdirectory_arrow_right),
                                ),
                                dropdownColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                                items: [
                                  const DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text('None'),
                                  ),
                                  ...subcategories.map((sub) {
                                    return DropdownMenuItem<int?>(
                                      value: sub.id,
                                      child: Text(sub.name),
                                    );
                                  }),
                                ],
                                onChanged: (val) {
                                  setState(() {
                                    _selectedSubcategoryId = val;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Color(0xFFE53935)),
                              onPressed: () => _showQuickAddSubcategoryDialog(context),
                              tooltip: 'Quick Add Sub-category',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }(),
                ] else if (_categorizeMode == 'person') ...[
                  if (personCategories.isNotEmpty) ...[
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedCategoryId,
                            decoration: const InputDecoration(
                              labelText: 'Select Person',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            dropdownColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                            items: personCategories.map((cat) {
                              return DropdownMenuItem(
                                value: cat.id,
                                child: Text(cat.name),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedCategoryId = val;
                                  _isAutoCategorized = false;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Color(0xFFE53935)),
                          onPressed: () => _showQuickAddPersonDialog(context),
                          tooltip: 'Quick Add Person',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'No persons registered yet. Add a person category first.',
                            style: TextStyle(fontSize: 13, color: Colors.purple),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(120, 36),
                            ),
                            onPressed: () async {
                              final added = await showModalBottomSheet<bool>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => const CategoryForm(),
                              );
                              if (added == true) {
                                // Categories provider will auto refresh
                              }
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Person Category', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ]
                ],

                // Credit Card target selector if the "Credit Card Payment" category is selected
                () {
                  final selectedCategory = allCategories.firstWhere(
                    (c) => c.id == _selectedCategoryId,
                    orElse: () => const Category(id: -1, name: '', icon: '', color: '', isDefault: false, type: 'both'),
                  );
                  final isCreditCardPayment = selectedCategory.name.toLowerCase() == 'credit card payment';
                  if (isCreditCardPayment) {
                    final creditCards = accounts.where((a) => a.type == 'Credit Card').toList();
                    if (creditCards.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          'No Credit Card accounts found. Please add a Credit Card account in the Accounts tab first.',
                          style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                        ),
                      );
                    }
                    if (_selectedCreditCardAccountId == null || !creditCards.any((cc) => cc.id == _selectedCreditCardAccountId)) {
                      _selectedCreditCardAccountId = creditCards.first.id;
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<int>(
                          value: _selectedCreditCardAccountId,
                          decoration: const InputDecoration(
                            labelText: 'Select Credit Card to Pay',
                            prefixIcon: Icon(Icons.credit_card_outlined),
                          ),
                          dropdownColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                          items: creditCards.map((cc) {
                            return DropdownMenuItem(value: cc.id, child: Text(cc.name));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedCreditCardAccountId = val;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                }(),
              ],

              // Split transaction details allocation UI
              if (_selectedType != 'transfer' && _isSplitMode && !isLoadingCategories && filteredCategories.isNotEmpty) ...[
                Text('Category Splits', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white70 : Colors.black87)),
                const SizedBox(height: 8),
                ...List.generate(_splits.length, (idx) {
                  final split = _splits[idx];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E2E) : Colors.black.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<int>(
                                value: split['categoryId'] as int?,
                                decoration: const InputDecoration(labelText: 'Split Category', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                dropdownColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                                items: filteredCategories.map((cat) {
                                  return DropdownMenuItem(value: cat.id, child: Text(cat.name));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _splits[idx]['categoryId'] = val;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: split['amount'] > 0 ? split['amount'].toString() : '',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Amount', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Required';
                                  final amt = double.tryParse(v);
                                  if (amt == null || amt <= 0) return 'Invalid';
                                  final parts = v.split('.');
                                  if (parts.length > 1 && parts[1].length > 2) return 'Max 2 decimals';
                                  return null;
                                },
                                onChanged: (val) {
                                  final amt = double.tryParse(val) ?? 0.0;
                                  setState(() {
                                    _splits[idx]['amount'] = amt;
                                  });
                                },
                              ),
                            ),
                            if (_splits.length > 1) ...[
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFE53935)),
                                onPressed: () {
                                  setState(() {
                                    _splits.removeAt(idx);
                                  });
                                },
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: split['note'] as String?,
                          decoration: const InputDecoration(labelText: 'Split Note (Optional)', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                          onChanged: (val) {
                            setState(() {
                              _splits[idx]['note'] = val;
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _splits.add({
                          'categoryId': filteredCategories.isNotEmpty ? filteredCategories.first.id : null,
                          'amount': 0.0,
                          'note': '',
                        });
                      });
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Split Category'),
                  ),
                ),
                Builder(
                  builder: (context) {
                    final totalAmount = double.tryParse(_amountController.text) ?? 0.0;
                    double allocatedSum = 0.0;
                    for (var s in _splits) {
                      allocatedSum += s['amount'] as double;
                    }
                    final diff = totalAmount - allocatedSum;
                    final isMatched = diff.abs() < 0.01;
                    
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isMatched ? Colors.green.withValues(alpha: 0.08) : const Color(0xFFE53935).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isMatched ? Colors.green.withValues(alpha: 0.2) : const Color(0xFFE53935).withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Sum: \$${allocatedSum.toStringAsFixed(2)} / \$${totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isMatched ? Colors.green : const Color(0xFFE53935),
                            ),
                          ),
                          Text(
                            isMatched ? 'Fully Allocated' : 'Remaining: \$${diff.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isMatched ? Colors.green : const Color(0xFFE53935),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                ),
                const SizedBox(height: 16),
              ],



              // Date Picker
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    DateFormat('MMMM dd, yyyy').format(_selectedDate),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Note Field
              TextFormField(
                controller: _noteController,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  prefixIcon: Icon(Icons.notes),
                ),
                onChanged: (_) => _suggestTags(),
              ),

              const SizedBox(height: 16),

              // Tags Field
              TextFormField(
                controller: _tagsController,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: 'Tags (Optional, comma-separated)',
                  prefixIcon: Icon(Icons.tag),
                  hintText: 'e.g. vacation, dining, gift',
                ),
              ),

              const SizedBox(height: 16),

              // Recurrence Selector
              DropdownButtonFormField<String>(
                value: _selectedRecurrence,
                decoration: const InputDecoration(
                  labelText: 'Recurrence',
                  prefixIcon: Icon(Icons.autorenew),
                ),
                dropdownColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                items: _recurrenceOptions.map((opt) {
                  return DropdownMenuItem(value: opt, child: Text(opt.toUpperCase()));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedRecurrence = val;
                      if (val != 'none' && _selectedRecurrenceEndDate == null) {
                        _selectedRecurrenceEndDate = DateTime.now().add(const Duration(days: 30));
                      }
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // Recurrence End Date Picker
              if (_selectedRecurrence != 'none') ...[
                InkWell(
                  onTap: _selectRecurrenceEndDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Recurrence End Date',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      _selectedRecurrenceEndDate != null
                          ? DateFormat('MMMM dd, yyyy').format(_selectedRecurrenceEndDate!)
                          : 'Select end date',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 24),

              // Save as Template switch (only when logging new transaction)
              if (widget.transaction == null) ...[
                SwitchListTile(
                  value: _saveAsTemplate,
                  activeColor: const Color(0xFFE53935),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Save as Quick-Add Template', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  onChanged: (val) {
                    setState(() {
                      _saveAsTemplate = val;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Save Action Button
              ElevatedButton(
                onPressed: _save,
                child: Text(widget.transaction == null ? 'Log Transaction' : 'Save Changes'),
              ),
              if (widget.transaction != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE53935),
                    side: const BorderSide(color: Color(0xFFE53935)),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete Transaction', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildTypeButton(String type, String label, Color color) {
    final active = _selectedType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
            _initializedMode = false;
            
            // Re-evaluate defaults on type change
            final categoriesState = ref.read(categoriesProvider);
            if (!categoriesState.isLoading) {
              final filtered = categoriesState.categories.where((cat) {
                if (cat.parentId != null) return false;
                if (_selectedType == 'income') {
                  return cat.type == 'income' || cat.type == 'both' || cat.type == 'person';
                } else if (_selectedType == 'expense') {
                  return cat.type == 'expense' || cat.type == 'both' || cat.type == 'person';
                }
                return cat.type != 'person';
              }).toList();
              if (filtered.isNotEmpty) {
                if (_selectedCategoryId == null || !filtered.any((c) => c.id == _selectedCategoryId)) {
                  _selectedCategoryId = filtered.first.id;
                  _selectedSubcategoryId = null;
                }
              }
            }
          });
        },
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: active 
                ? color 
                : (isDark ? const Color(0xFF1E1E2E) : Colors.black.withValues(alpha: 0.02)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active 
                  ? color 
                  : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04)),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getDarkVariant(String lightHex) {
    switch (lightHex.toUpperCase()) {
      case 'E53935': return 'B71C1C';
      case '4CAF50': return '1B5E20';
      case '1E88E5': return '0D47A1';
      case 'FFB300': return 'FF6F00';
      case '8E24AA': return '4A148C';
      case '00ACC1': return '006064';
      case 'FB8C00': return 'E65100';
      case 'F06292': return '880E4F';
      case '4DB6AC': return '004D40';
      case '795548': return '3E2723';
      case '757575': return '212121';
      case '3F51B5': return '1A237E';
      default: return '212121';
    }
  }

  void _showQuickAddCategoryDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController();
    String selectedType = _selectedType == 'transfer' ? 'expense' : _selectedType;
    String selectedColor = '757575'; // default Grey
    String selectedIcon = 'category'; // default

    final List<String> popularColors = [
      'E53935', // Red
      '4CAF50', // Green
      '1E88E5', // Blue
      'FFB300', // Amber
      '8E24AA', // Purple
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              title: const Text('Quick Add Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Category Name',
                        hintText: 'e.g. Shopping',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),
                    const Text('Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildDialogTypeBtn(setDialogState, 'expense', 'Expense', const Color(0xFFE53935), selectedType, (type) {
                          selectedType = type;
                        }),
                        const SizedBox(width: 8),
                        _buildDialogTypeBtn(setDialogState, 'income', 'Income', Colors.green, selectedType, (type) {
                          selectedType = type;
                        }),
                        const SizedBox(width: 8),
                        _buildDialogTypeBtn(setDialogState, 'both', 'Both', Colors.blue, selectedType, (type) {
                          selectedType = type;
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Select Color', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      children: popularColors.map((colorHex) {
                        final color = Color(int.parse('0xFF$colorHex'));
                        final isSelected = selectedColor == colorHex;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedColor = colorHex),
                          child: Container(
                            width: 32,
                            height: 32,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: isDark ? Colors.white : Colors.black, width: 2)
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final newCat = Category(
                      name: name,
                      type: selectedType,
                      icon: selectedIcon,
                      color: selectedColor,
                      isDefault: false,
                      darkColor: _getDarkVariant(selectedColor),
                    );

                    final newId = await ref.read(categoriesProvider.notifier).addCategory(newCat);
                    if (newId != null && context.mounted) {
                      setState(() {
                        _selectedCategoryId = newId;
                        _selectedSubcategoryId = null;
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDialogTypeBtn(
    StateSetter setDialogState,
    String type,
    String label,
    Color color,
    String currentSelectedType,
    ValueChanged<String> onSelected,
  ) {
    final active = currentSelectedType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setDialogState(() {
            onSelected(type);
          });
        },
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: active ? color : (isDark ? const Color(0xFF282838) : Colors.black.withValues(alpha: 0.02)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showQuickAddSubcategoryDialog(BuildContext context) {
    if (_selectedCategoryId == null) return;

    final allCats = ref.read(categoriesProvider).categories;
    final parentCat = allCats.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => const Category(name: '', icon: 'category', color: '757575', isDefault: false),
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          title: Text('Quick Add Sub-category under ${parentCat.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Sub-category Name',
              hintText: 'e.g. Zomato',
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final newSub = Category(
                  name: name,
                  type: parentCat.type,
                  icon: parentCat.icon,
                  color: parentCat.color,
                  isDefault: false,
                  parentId: parentCat.id,
                  darkColor: parentCat.darkColor,
                );

                final newId = await ref.read(categoriesProvider.notifier).addCategory(newSub);
                if (newId != null && context.mounted) {
                  setState(() {
                    _selectedSubcategoryId = newId;
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showQuickAddPersonDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          title: const Text('Quick Add Person', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Person Name',
              hintText: 'e.g. John Doe',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final newPerson = Category(
                  name: name,
                  type: 'person',
                  icon: 'person',
                  color: '8E24AA',
                  isDefault: false,
                  darkColor: '4A148C',
                );

                final newId = await ref.read(categoriesProvider.notifier).addCategory(newPerson);
                if (newId != null && context.mounted) {
                  setState(() {
                    _selectedCategoryId = newId;
                    _selectedSubcategoryId = null;
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showQuickAddAccountDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController();
    final balanceController = TextEditingController(text: '0');
    String selectedType = 'Bank';
    String selectedColor = '1E88E5'; // default Blue

    final types = ['Bank', 'Credit Card', 'Cash', 'Investment', 'Other'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              title: const Text('Quick Add Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Account Name',
                        hintText: 'e.g. HDFC Bank',
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Account Type',
                      ),
                      dropdownColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                      items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedType = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: balanceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Initial Balance',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final balance = double.tryParse(balanceController.text) ?? 0.0;
                    const isShared = false;

                    final newId = await ref.read(accountsProvider.notifier).addAccount(
                      name,
                      selectedType,
                      balance,
                      'account_balance',
                      selectedColor,
                      isShared,
                    );

                    if (newId != null && context.mounted) {
                      setState(() {
                        _selectedAccountId = newId;
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
