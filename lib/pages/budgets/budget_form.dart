import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/budgets_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/common/toast_notification.dart';
import '../../core/database/database.dart';
import '../../../models/budget.dart';

class BudgetForm extends ConsumerStatefulWidget {
  final int? categoryId;
  final double? currentLimit;

  const BudgetForm({super.key, this.categoryId, this.currentLimit});

  @override
  ConsumerState<BudgetForm> createState() => _BudgetFormState();
}

class _BudgetFormState extends ConsumerState<BudgetForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _limitController;
  int? _selectedCategoryId;
  
  List<Map<String, dynamic>> _categories = [];
  bool _isLoadingCategories = true;

  String _selectedRecurrence = 'monthly';
  String? _selectedGroupName;
  Map<int, double> _suggestedLimits = {};

  @override
  void initState() {
    super.initState();
    _limitController = TextEditingController(
      text: widget.currentLimit != null ? widget.currentLimit!.toString() : '',
    );
    _selectedCategoryId = widget.categoryId;

    final budgets = ref.read(budgetsProvider).budgets;
    final existing = budgets.firstWhere(
      (b) => b.categoryId == widget.categoryId,
      orElse: () => const Budget(id: -1, categoryId: -1, month: '', limitAmount: 0),
    );
    if (existing.id != -1) {
      _selectedRecurrence = existing.recurrence;
      _selectedGroupName = existing.groupName;
    }

    _loadCategories();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    final suggestions = await ref.read(budgetsProvider.notifier).getAutoSuggestedLimits();
    setState(() {
      _suggestedLimits = suggestions;
    });
  }

  Future<void> _loadCategories() async {
    try {
      final db = await AppDatabase.instance.database;
      final list = await db.query('category');
      setState(() {
        _categories = list.where((cat) => cat['name'] != 'Total Budget' && cat['type'] != 'income' && cat['type'] != 'person').toList();
        _isLoadingCategories = false;
        if (_selectedCategoryId == null && _categories.isNotEmpty) {
          _selectedCategoryId = _categories.first['id'] as int;
        }
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) return;

    final limit = double.tryParse(_limitController.text) ?? 0.0;
    
    if (widget.currentLimit != null && widget.currentLimit != limit) {
      final currency = ref.read(authProvider).profile?.preferredCurrency ?? 'USD';
      final currencySymbol = currency == 'INR' ? '₹' : '\$';
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Update Budget Limit'),
          content: Text('Are you sure you want to update this budget limit from $currencySymbol${widget.currentLimit!.toStringAsFixed(0)} to $currencySymbol${limit.toStringAsFixed(0)}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Update'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    // Save budget
    final success = await ref.read(budgetsProvider.notifier).setBudget(
      _selectedCategoryId!, 
      limit,
      recurrence: _selectedRecurrence,
      groupName: _selectedGroupName,
    );

    if (success && mounted) {
      ToastNotification.show(context, 'Budget limit saved successfully.');
      Navigator.pop(context);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget Limit'),
        content: const Text('Are you sure you want to remove the budget limit for this category?'),
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
      final budgets = ref.read(budgetsProvider).budgets;
      final budgetToDelete = budgets.firstWhere(
        (b) => b.categoryId == widget.categoryId,
        orElse: () => const Budget(id: -1, categoryId: -1, month: '', limitAmount: 0),
      );
      
      if (budgetToDelete.id != -1) {
        final success = await ref.read(budgetsProvider.notifier).deleteBudget(budgetToDelete.id!);
        if (success && mounted) {
          ToastNotification.show(context, 'Budget limit deleted.');
          Navigator.pop(context);
        }
      } else {
        ToastNotification.show(context, 'No budget found to delete.', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                widget.categoryId == null ? 'Set Category Budget' : 'Edit Category Budget',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
              
              const SizedBox(height: 20),

              // Category dropdown (Disabled or displayed as read-only if editing a specific category)
              if (widget.categoryId != null)
                FutureBuilder<String>(
                  future: () async {
                    final db = await AppDatabase.instance.database;
                    final res = await db.query('category', where: 'id = ?', whereArgs: [widget.categoryId]);
                    if (res.isNotEmpty) {
                      return res.first['name'] as String;
                    }
                    return 'Category';
                  }(),
                  builder: (context, snapshot) {
                    final name = snapshot.data ?? 'Loading...';
                    return TextFormField(
                      initialValue: name,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      readOnly: true,
                      enabled: false,
                    );
                  },
                )
              else if (!_isLoadingCategories && _categories.isNotEmpty)
                DropdownButtonFormField<int>(
                  value: _categories.any((cat) => (cat['id'] as int) == _selectedCategoryId)
                      ? _selectedCategoryId
                      : (_categories.isNotEmpty ? _categories.first['id'] as int : null),
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  dropdownColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                  items: _categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat['id'] as int,
                      child: Text(cat['name'] as String),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedCategoryId = val;
                      });
                    }
                  },
                ),
              
              const SizedBox(height: 16),

              // Recurrence dropdown
              DropdownButtonFormField<String>(
                value: _selectedRecurrence,
                decoration: const InputDecoration(
                  labelText: 'Recurrence',
                  prefixIcon: Icon(Icons.repeat),
                ),
                dropdownColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                items: const [
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'bi-weekly', child: Text('Bi-weekly')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedRecurrence = val;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // Budget Group dropdown
              DropdownButtonFormField<String?>(
                value: _selectedGroupName,
                decoration: const InputDecoration(
                  labelText: 'Budget Group',
                  prefixIcon: Icon(Icons.folder_open),
                  suffixIcon: Tooltip(
                    triggerMode: TooltipTriggerMode.tap,
                    message: 'Groups help you organize budgets (e.g. Essentials, Lifestyle) and appear as sections on the Budgets page.',
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.help_outline, size: 20),
                    ),
                  ),
                ),
                dropdownColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                items: const [
                  DropdownMenuItem(value: null, child: Text('None (Ungrouped)')),
                  DropdownMenuItem(value: 'Essentials', child: Text('Essentials')),
                  DropdownMenuItem(value: 'Lifestyle', child: Text('Lifestyle')),
                  DropdownMenuItem(value: 'Savings', child: Text('Savings')),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedGroupName = val;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Limit Field
              TextFormField(
                controller: _limitController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: '${_selectedRecurrence[0].toUpperCase()}${_selectedRecurrence.substring(1)} Limit Amount',
                  prefixIcon: Icon(
                    ref.read(authProvider).profile?.preferredCurrency == 'INR'
                        ? Icons.currency_rupee
                        : Icons.attach_money,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Please enter a budget limit';
                  if (double.tryParse(val) == null || double.parse(val) < 0) {
                    return 'Please enter a valid positive limit';
                  }
                  return null;
                },
              ),

              // Auto-suggest limit badge
              if (_selectedCategoryId != null) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    final currency = ref.read(authProvider).profile?.preferredCurrency ?? 'USD';
                    final defaultAmount = currency == 'INR' ? 5000.0 : 100.0;
                    final amount = (_suggestedLimits.containsKey(_selectedCategoryId) && _suggestedLimits[_selectedCategoryId]! > 0)
                        ? _suggestedLimits[_selectedCategoryId]!
                        : defaultAmount;
                    final adjustedAmount = _selectedRecurrence == 'weekly'
                        ? amount / 4.33
                        : (_selectedRecurrence == 'bi-weekly' ? amount / 2.16 : amount);
                    _limitController.text = adjustedAmount.toStringAsFixed(0);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lightbulb_outline, color: Color(0xFFE53935), size: 16),
                        const SizedBox(width: 8),
                        Builder(
                          builder: (context) {
                            final currency = ref.read(authProvider).profile?.preferredCurrency ?? 'USD';
                            final defaultAmount = currency == 'INR' ? 5000.0 : 100.0;
                            final hasHistorical = _suggestedLimits.containsKey(_selectedCategoryId) && _suggestedLimits[_selectedCategoryId]! > 0;
                            final amount = hasHistorical
                                ? _suggestedLimits[_selectedCategoryId]!
                                : defaultAmount;
                            final currencySymbol = currency == 'INR' ? '₹' : '\$';
                            final label = hasHistorical ? 'Suggested limit (historical avg)' : 'Default budget suggestion';
                            return Text(
                              '$label: $currencySymbol${amount.toStringAsFixed(0)} / mo (Tap to apply)',
                              style: const TextStyle(
                                color: Color(0xFFE53935),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter',
                              ),
                            );
                          }
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Save Action Button
              ElevatedButton(
                onPressed: _save,
                child: const Text('Save Budget Limit'),
              ),
              if (widget.categoryId != null) ...[
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
                  label: const Text('Delete Budget Limit', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

