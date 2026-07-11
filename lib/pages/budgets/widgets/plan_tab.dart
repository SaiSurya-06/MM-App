import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/planning_state_provider.dart';
import '../../../widgets/common/glassmorphism_card.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/categories_provider.dart';
import '../../../models/category.dart';

class PlanTab extends ConsumerStatefulWidget {
  const PlanTab({super.key});

  @override
  ConsumerState<PlanTab> createState() => _PlanTabState();
}

class _PlanTabState extends ConsumerState<PlanTab> {
  final Map<String, TextEditingController> _controllers = {};
  final Set<String> _deletedDefaultCategories = {};

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(planningStateProvider);
    final notifier = ref.read(planningStateProvider.notifier);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    
    final totalIncome = state.salary + state.otherIncome;
    final totalPct = state.needsPct + state.wantsPct + state.savingsPct + state.investmentsPct + state.emergencyPct;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Total Income Summary Card
          GlassmorphismCard(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Estimated Monthly Income', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            '₹${CurrencyFormatter.format(totalIncome, 'INR')}',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Reset Plan'),
                        onPressed: () {
                          notifier.resetPlan();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. Core Splits Sliders
          Text('Core Splits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 4),
          Text(
            'Sum: ${totalPct.toStringAsFixed(0)}% (Must be 100% to save changes)',
            style: TextStyle(fontSize: 13, color: totalPct == 100.0 ? Colors.green : Colors.redAccent),
          ),
          const SizedBox(height: 12),
          
          GlassmorphismCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildSliderRow('Needs', state.needsPct, Colors.blueAccent, (val) => notifier.updatePercentages(needs: val)),
                  _buildSliderRow('Wants', state.wantsPct, Colors.amber, (val) => notifier.updatePercentages(wants: val)),
                  _buildSliderRow('Savings', state.savingsPct, Colors.green, (val) => notifier.updatePercentages(savings: val)),
                  _buildSliderRow('Investments', state.investmentsPct, Colors.purple, (val) => notifier.updatePercentages(investments: val)),
                  _buildSliderRow('Emergency', state.emergencyPct, Colors.cyan, (val) => notifier.updatePercentages(emergency: val)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 3. Category Budgets Inputs
          Text('Category Limits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 12),
          
          _buildCategoryInputsSection(state, notifier),
          
          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: totalPct == 100.0
                ? () async {
                    await notifier.commitPlanToDatabase();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Plan saved successfully!'), backgroundColor: Colors.green),
                    );
                  }
                : null,
            icon: const Icon(Icons.save),
            label: const Text('Save Plan Changes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSliderRow(String label, double val, Color color, ValueChanged<double> onChanged) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('${val.toStringAsFixed(0)}%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: val,
          min: 0,
          max: 100,
          divisions: 100,
          activeColor: color,
          onChanged: (newVal) => onChanged(newVal.roundToDouble()),
        ),
      ],
    );
  }

  Widget _buildCategoryInputsSection(PlanningState state, PlanningStateNotifier notifier) {
    final defaultCategories = [
      'Rent', 'Utilities', 'Electricity', 'Internet', 'Insurance', // Needs
      'Food', 'Shopping', 'Entertainment', 'Dining', 'Travel',     // Wants
      'Emergency Savings', 'Vacation Fund',                        // Savings
      'Mutual Funds', 'Stocks',                                    // Investments
    ];

    final dbCategories = ref.watch(categoriesProvider).categories;
    final dbCategoryNames = dbCategories.map((c) => c.name.toLowerCase()).toSet();

    // Compile category representation list
    final List<_CategoryItem> items = [];

    // 1. Add DB categories that are not income
    for (var cat in dbCategories) {
      if (cat.type != 'income') {
        items.add(_CategoryItem(
          id: cat.id,
          name: cat.name,
          isDefault: cat.isDefault,
          category: cat,
        ));
      }
    }

    // 2. Add default categories if they aren't in the database categories list yet AND not locally deleted
    for (var defName in defaultCategories) {
      if (!dbCategoryNames.contains(defName.toLowerCase()) && !_deletedDefaultCategories.contains(defName.toLowerCase())) {
        items.add(_CategoryItem(
          id: null,
          name: defName,
          isDefault: true,
          category: null,
        ));
      }
    }

    // 3. Add any category from state.categoryBudgets not listed yet
    final listedNames = items.map((x) => x.name.toLowerCase()).toSet();
    for (var entry in state.categoryBudgets.entries) {
      final name = entry.key;
      if (!listedNames.contains(name.toLowerCase())) {
        items.add(_CategoryItem(
          id: null,
          name: name,
          isDefault: false,
          category: null,
        ));
      }
    }

    return GlassmorphismCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ...items.map((item) {
              if (!_controllers.containsKey(item.name)) {
                final val = state.categoryBudgets[item.name] ?? 0.0;
                _controllers[item.name] = TextEditingController(
                  text: val > 0 ? val.toStringAsFixed(0) : '',
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit, size: 16, color: Colors.blueAccent.withOpacity(0.8)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Rename Category',
                            onPressed: () => _showRenameCategoryDialog(context, item, state, notifier),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: Icon(Icons.delete_outline, size: 16, color: Colors.redAccent.withOpacity(0.8)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Delete Category',
                            onPressed: () => _showDeleteCategoryDialog(context, item, state, notifier),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controllers[item.name],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          prefixText: '₹ ',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        onChanged: (val) {
                          final valDouble = double.tryParse(val) ?? 0.0;
                          notifier.updateCategoryBudget(item.name, valDouble);
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
            
            const Divider(height: 24),
            
            OutlinedButton.icon(
              onPressed: () => _showAddCategoryDialog(context, state, notifier),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Category'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blueAccent,
                side: const BorderSide(color: Colors.blueAccent),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameCategoryDialog(BuildContext context, _CategoryItem item, PlanningState state, PlanningStateNotifier notifier) {
    final textController = TextEditingController(text: item.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Category'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(labelText: 'New Name'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = textController.text.trim();
                if (newName.isEmpty || newName == item.name) {
                  Navigator.pop(context);
                  return;
                }

                // 1. Rename in database if it has ID
                if (item.id != null && item.category != null) {
                  final updatedCat = item.category!.copyWith(name: newName);
                  final success = await ref.read(categoriesProvider.notifier).updateCategory(updatedCat);
                  if (!success) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to rename category in database.'), backgroundColor: Colors.redAccent),
                      );
                    }
                    Navigator.pop(context);
                    return;
                  }
                }

                // 2. Rename key in state.categoryBudgets and update controller mapping
                notifier.renameCategoryBudget(item.name, newName);
                final controller = _controllers.remove(item.name);
                if (controller != null) {
                  _controllers[newName] = controller;
                }

                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteCategoryDialog(BuildContext context, _CategoryItem item, PlanningState state, PlanningStateNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Category'),
          content: Text('Are you sure you want to delete "${item.name}"? This will also delete any budget limits associated with it.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                // 1. Remove from DB if has ID
                if (item.id != null) {
                  final success = await ref.read(categoriesProvider.notifier).deleteCategory(item.id!);
                  if (!success) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to delete category from database.'), backgroundColor: Colors.redAccent),
                      );
                    }
                    Navigator.pop(context);
                    return;
                  }
                } else {
                  // If it's a default category not saved in DB yet, track it locally so we ignore it
                  setState(() {
                    _deletedDefaultCategories.add(item.name.toLowerCase());
                  });
                }

                // 2. Remove budget mapping & controller
                notifier.removeCategoryBudget(item.name);
                final controller = _controllers.remove(item.name);
                controller?.dispose();

                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showAddCategoryDialog(BuildContext context, PlanningState state, PlanningStateNotifier notifier) {
    final nameController = TextEditingController();
    String selectedGroup = 'Wants'; // Default group classification

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Category'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Category Name'),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedGroup,
                    decoration: const InputDecoration(labelText: 'Group / Allocation'),
                    items: ['Needs', 'Wants', 'Savings', 'Investments']
                        .map((grp) => DropdownMenuItem(value: grp, child: Text(grp)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedGroup = val;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      Navigator.pop(context);
                      return;
                    }

                    // 1. Insert Category into Database dynamically
                    final newCat = Category(
                      name: name,
                      icon: 'account_balance_wallet',
                      color: '607D8B',
                      isDefault: false,
                      type: 'expense',
                    );

                    final catId = await ref.read(categoriesProvider.notifier).addCategory(newCat);
                    if (catId == null) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to add category to database.'), backgroundColor: Colors.redAccent),
                        );
                      }
                      Navigator.pop(context);
                      return;
                    }

                    // 2. Add to local controllers and notifier budget state
                    notifier.updateCategoryBudget(name, 0.0);
                    notifier.setCustomCategoryGroup(name, selectedGroup);
                    _controllers[name] = TextEditingController(text: '');

                    // Ensure if we had previously marked it deleted, we restore it
                    setState(() {
                      _deletedDefaultCategories.remove(name.toLowerCase());
                    });

                    if (mounted) {
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

class _CategoryItem {
  final int? id;
  final String name;
  final bool isDefault;
  final Category? category;

  _CategoryItem({
    required this.id,
    required this.name,
    required this.isDefault,
    required this.category,
  });
}
