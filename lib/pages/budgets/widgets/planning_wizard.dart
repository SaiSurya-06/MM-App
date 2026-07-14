import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/planning_state_provider.dart';
import '../../../widgets/common/glassmorphism_card.dart';
import '../../../widgets/common/toast_notification.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/categories_provider.dart';
import '../../../models/category.dart';

class PlanningWizard extends ConsumerStatefulWidget {
  final VoidCallback onCompleted;
  const PlanningWizard({super.key, required this.onCompleted});

  @override
  ConsumerState<PlanningWizard> createState() => _PlanningWizardState();
}

class _PlanningWizardState extends ConsumerState<PlanningWizard> {
  final _salaryController = TextEditingController();
  final _otherIncomeController = TextEditingController();
  final Map<String, TextEditingController> _categoryControllers = {};
  
  final _needsAmountController = TextEditingController();
  final _wantsAmountController = TextEditingController();
  final _savingsAmountController = TextEditingController();
  final _investmentsAmountController = TextEditingController();
  final _emergencyAmountController = TextEditingController();

  final _needsAmountFocus = FocusNode();
  final _wantsAmountFocus = FocusNode();
  final _savingsAmountFocus = FocusNode();
  final _investmentsAmountFocus = FocusNode();
  final _emergencyAmountFocus = FocusNode();

  final Map<String, List<String>> _groupCategories = {};
  final Set<String> _deletedCategories = {};

  void _initializeCategories() {
    if (_groupCategories.isNotEmpty) return;

    final state = ref.read(planningStateProvider);
    final dbCategories = ref.read(categoriesProvider).categories;

    final Set<String> allNeeds = {};
    final Set<String> allWants = {};
    final Set<String> allSavings = {};
    final Set<String> allInvestments = {};

    // 1. Add categories from DB (Categories module)
    for (var cat in dbCategories) {
      if (cat.type == 'income') continue;
      final group = state.customCategoryGroups[cat.name] ?? _classifyCategory(cat.name);
      if (group == 'Needs') allNeeds.add(cat.name);
      if (group == 'Wants') allWants.add(cat.name);
      if (group == 'Savings') allSavings.add(cat.name);
      if (group == 'Investments') allInvestments.add(cat.name);
    }

    // 2. Add categories from state.categoryBudgets (active/historical planning budgets)
    for (var catName in state.categoryBudgets.keys) {
      final group = state.customCategoryGroups[catName] ?? _classifyCategory(catName);
      if (group == 'Needs') allNeeds.add(catName);
      if (group == 'Wants') allWants.add(catName);
      if (group == 'Savings') allSavings.add(catName);
      if (group == 'Investments') allInvestments.add(catName);
    }

    _groupCategories['Needs'] = allNeeds.toList();
    _groupCategories['Wants'] = allWants.toList();
    _groupCategories['Savings'] = allSavings.toList();
    _groupCategories['Investments'] = allInvestments.toList();
  }

  String _classifyCategory(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('rent') || name.contains('bill') || name.contains('utility') || name.contains('utilities') || name.contains('electricity') || name.contains('internet') || name.contains('water') || name.contains('insurance')) {
      return 'Needs';
    }
    if (name.contains('food') || name.contains('shopping') || name.contains('entertainment') || name.contains('dining') || name.contains('movie') || name.contains('travel')) {
      return 'Wants';
    }
    if (name.contains('saving') || name.contains('emergency')) {
      return 'Savings';
    }
    if (name.contains('invest') || name.contains('stock') || name.contains('mutual')) {
      return 'Investments';
    }
    return 'Wants';
  }

  @override
  void initState() {
    super.initState();
    final state = ref.read(planningStateProvider);
    _salaryController.text = state.salary > 0 ? state.salary.toStringAsFixed(0) : '';
    _otherIncomeController.text = state.otherIncome > 0 ? state.otherIncome.toStringAsFixed(0) : '';
  }

  @override
  void dispose() {
    _salaryController.dispose();
    _otherIncomeController.dispose();
    for (var c in _categoryControllers.values) {
      c.dispose();
    }
    _needsAmountController.dispose();
    _wantsAmountController.dispose();
    _savingsAmountController.dispose();
    _investmentsAmountController.dispose();
    _emergencyAmountController.dispose();

    _needsAmountFocus.dispose();
    _wantsAmountFocus.dispose();
    _savingsAmountFocus.dispose();
    _investmentsAmountFocus.dispose();
    _emergencyAmountFocus.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _initializeCategories();
    final state = ref.watch(planningStateProvider);
    final notifier = ref.read(planningStateProvider.notifier);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F11) : const Color(0xFFF3F4F6);
    final cardBg = isDark ? const Color(0xFF1E1E24) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Monthly Planning Session', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: state.currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => notifier.setStep(state.currentStep - 1),
              )
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Step indicator
              _buildStepIndicator(state.currentStep),
              const SizedBox(height: 20),
              
              Expanded(
                child: SingleChildScrollView(
                  child: _buildStepContent(state, notifier, cardBg, textColor),
                ),
              ),
              
              const SizedBox(height: 20),
              _buildNavigationButtons(state, notifier),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int currentStep) {
    return Row(
      children: List.generate(5, (index) {
        final isActive = index <= currentStep;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 4,
            decoration: BoxDecoration(
              color: isActive ? Colors.blueAccent : Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepContent(PlanningState state, PlanningStateNotifier notifier, Color cardBg, Color textColor) {
    switch (state.currentStep) {
      case 0:
        return _buildIncomeStep(cardBg, textColor);
      case 1:
        return _buildStrategyStep(state, notifier, cardBg, textColor);
      case 2:
        return _buildSlidersStep(state, notifier, cardBg, textColor);
      case 3:
        return _buildCategoryStep(state, notifier, cardBg, textColor);
      case 4:
        return _buildSummaryStep(state, notifier, cardBg, textColor);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIncomeStep(Color cardBg, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Let\'s Plan Your Income', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 8),
        const Text('Enter your expected cash inflows for this month.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        GlassmorphismCard(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                TextField(
                  controller: _salaryController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: textColor, fontSize: 18),
                  decoration: const InputDecoration(
                    labelText: 'Monthly Salary / Primary Income',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    final amt = double.tryParse(val) ?? 0.0;
                    ref.read(planningStateProvider.notifier).updateSalary(amt);
                  },
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _otherIncomeController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: textColor, fontSize: 18),
                  decoration: const InputDecoration(
                    labelText: 'Other Income (Side hustle, dividends, etc.)',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    final amt = double.tryParse(val) ?? 0.0;
                    ref.read(planningStateProvider.notifier).updateOtherIncome(amt);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStrategyStep(PlanningState state, PlanningStateNotifier notifier, Color cardBg, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choose Budget Strategy', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 8),
        const Text('Select a template or framework to automatically allocate your funds.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        _buildStrategyCard(
          title: '50/30/20 Strategy',
          desc: 'Recommended. 50% Needs, 30% Wants, 20% Savings.',
          strategy: '50/30/20',
          selectedStrategy: state.strategy,
          notifier: notifier,
        ),
        _buildStrategyCard(
          title: 'Zero-Based Budget',
          desc: 'Every single rupee is assigned a specific job: 60% Needs, 20% Wants, 10% Savings, 10% Investments.',
          strategy: 'zero_based',
          selectedStrategy: state.strategy,
          notifier: notifier,
        ),
        _buildStrategyCard(
          title: 'Envelope System',
          desc: 'Tangible division: 45% Needs, 25% Wants, 15% Savings, 10% Investments, 5% Emergency.',
          strategy: 'envelope',
          selectedStrategy: state.strategy,
          notifier: notifier,
        ),
        _buildStrategyCard(
          title: 'Custom Allocation',
          desc: 'Control all sliders manually to fit your unique style.',
          strategy: 'custom',
          selectedStrategy: state.strategy,
          notifier: notifier,
        ),
      ],
    );
  }

  Widget _buildStrategyCard({
    required String title,
    required String desc,
    required String strategy,
    required String selectedStrategy,
    required PlanningStateNotifier notifier,
  }) {
    final isSelected = strategy == selectedStrategy;
    return GestureDetector(
      onTap: () => notifier.selectStrategy(strategy),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(color: isSelected ? Colors.blueAccent : Colors.grey.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_off,
                color: isSelected ? Colors.blueAccent : Colors.grey,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(desc, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlidersStep(PlanningState state, PlanningStateNotifier notifier, Color cardBg, Color textColor) {
    final totalPercent = state.needsPct + state.wantsPct + state.savingsPct + state.investmentsPct + state.emergencyPct;
    final totalIncome = state.salary + state.otherIncome;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Refine Allocations', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 8),
        const Text('Drag the sliders or enter exact amounts to adjust your core budget splits.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 20),
        
        Text(
          'Total Allocated: ${totalPercent.toStringAsFixed(0)}% / 100%',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: totalPercent == 100.0 ? Colors.green : Colors.redAccent,
          ),
        ),
        const SizedBox(height: 16),

        _buildDraggableSlider(
          label: 'Needs (Essentials)',
          val: state.needsPct,
          color: Colors.blueAccent,
          totalIncome: totalIncome,
          controller: _needsAmountController,
          focusNode: _needsAmountFocus,
          onChanged: (newVal) => notifier.updatePercentages(needs: newVal),
        ),
        _buildDraggableSlider(
          label: 'Wants (Lifestyle)',
          val: state.wantsPct,
          color: Colors.amber,
          totalIncome: totalIncome,
          controller: _wantsAmountController,
          focusNode: _wantsAmountFocus,
          onChanged: (newVal) => notifier.updatePercentages(wants: newVal),
        ),
        _buildDraggableSlider(
          label: 'Savings',
          val: state.savingsPct,
          color: Colors.green,
          totalIncome: totalIncome,
          controller: _savingsAmountController,
          focusNode: _savingsAmountFocus,
          onChanged: (newVal) => notifier.updatePercentages(savings: newVal),
        ),
        _buildDraggableSlider(
          label: 'Investments',
          val: state.investmentsPct,
          color: Colors.purple,
          totalIncome: totalIncome,
          controller: _investmentsAmountController,
          focusNode: _investmentsAmountFocus,
          onChanged: (newVal) => notifier.updatePercentages(investments: newVal),
        ),
        _buildDraggableSlider(
          label: 'Emergency Fund',
          val: state.emergencyPct,
          color: Colors.cyan,
          totalIncome: totalIncome,
          controller: _emergencyAmountController,
          focusNode: _emergencyAmountFocus,
          onChanged: (newVal) => notifier.updatePercentages(emergency: newVal),
        ),
      ],
    );
  }

  Widget _buildDraggableSlider({
    required String label,
    required double val,
    required Color color,
    required double totalIncome,
    required TextEditingController controller,
    required FocusNode focusNode,
    required ValueChanged<double> onChanged,
  }) {
    final amt = (val / 100.0) * totalIncome;
    
    // Sync controller with value if not focused
    if (!focusNode.hasFocus) {
      controller.text = amt > 0 ? amt.toStringAsFixed(0) : '';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Text(
                    '${val.toStringAsFixed(0)}%  ',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  SizedBox(
                    width: 110,
                    height: 32,
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.end,
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                      decoration: InputDecoration(
                        prefixText: '₹ ',
                        prefixStyle: TextStyle(color: color.withOpacity(0.7), fontWeight: FontWeight.bold),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: color, width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.withOpacity(0.4)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (text) {
                        final enteredAmt = double.tryParse(text) ?? 0.0;
                        if (totalIncome > 0) {
                          final calculatedPct = ((enteredAmt / totalIncome) * 100.0).clamp(0.0, 100.0);
                          onChanged(calculatedPct.roundToDouble());
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          Slider(
            value: val,
            min: 0,
            max: 100,
            divisions: 100,
            activeColor: color,
            onChanged: (newVal) {
              onChanged(newVal.roundToDouble());
              final newAmt = (newVal / 100.0) * totalIncome;
              controller.text = newAmt.toStringAsFixed(0);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStep(PlanningState state, PlanningStateNotifier notifier, Color cardBg, Color textColor) {
    final totalIncome = state.salary + state.otherIncome;

    final double needsLimit = (state.needsPct / 100) * totalIncome;
    final double wantsLimit = (state.wantsPct / 100) * totalIncome;
    final double savingsLimit = (state.savingsPct / 100) * totalIncome;
    final double investmentsLimit = (state.investmentsPct / 100) * totalIncome;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 8),
        const Text('Estimate planned limits for specific expenses.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        
        if (state.needsPct > 0)
          _buildCategoryGroupInput(
            'Essentials (Needs cap: ${CurrencyFormatter.format(needsLimit, 'INR')})',
            'Needs',
            _groupCategories['Needs'] ?? [],
            state,
            notifier,
          ),
        
        if (state.wantsPct > 0)
          _buildCategoryGroupInput(
            'Lifestyle (Wants cap: ${CurrencyFormatter.format(wantsLimit, 'INR')})',
            'Wants',
            _groupCategories['Wants'] ?? [],
            state,
            notifier,
          ),

        if (state.savingsPct > 0)
          _buildCategoryGroupInput(
            'Savings (Savings cap: ${CurrencyFormatter.format(savingsLimit, 'INR')})',
            'Savings',
            _groupCategories['Savings'] ?? [],
            state,
            notifier,
          ),

        if (state.investmentsPct > 0)
          _buildCategoryGroupInput(
            'Investments (Investments cap: ${CurrencyFormatter.format(investmentsLimit, 'INR')})',
            'Investments',
            _groupCategories['Investments'] ?? [],
            state,
            notifier,
          ),
      ],
    );
  }

  Widget _buildCategoryGroupInput(
    String groupTitle,
    String groupKey,
    List<String> items,
    PlanningState state,
    PlanningStateNotifier notifier,
  ) {
    return DragTarget<String>(
      onWillAccept: (data) => data != null && !items.contains(data),
      onAccept: (data) {
        String? sourceGroup;
        for (var entry in _groupCategories.entries) {
          if (entry.value.contains(data)) {
            sourceGroup = entry.key;
            break;
          }
        }
        if (sourceGroup != null) {
          setState(() {
            _groupCategories[sourceGroup!]!.remove(data);
            _groupCategories[groupKey]!.add(data);
          });
          notifier.setCustomCategoryGroup(data, groupKey);
          ToastNotification.show(context, 'Moved "$data" to $groupKey');
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                groupTitle,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isHovering ? Colors.blueAccent : Colors.transparent,
                  width: 2.0,
                ),
              ),
              child: GlassmorphismCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'Drag categories here',
                            style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic),
                          ),
                        )
                      else
                        ...items.map((item) {
                          if (!_categoryControllers.containsKey(item)) {
                            final initialVal = state.categoryBudgets[item];
                            _categoryControllers[item] = TextEditingController(
                              text: initialVal != null && initialVal > 0 ? initialVal.toStringAsFixed(0) : '',
                            );
                          }
                          return LongPressDraggable<String>(
                            data: item,
                            feedback: Material(
                              color: Colors.transparent,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.drag_indicator, color: Colors.white, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      item,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: _buildCategoryRow(item, groupKey, state, notifier),
                            ),
                            child: _buildCategoryRow(item, groupKey, state, notifier),
                          );
                        }),
                      
                      const Divider(height: 24),
                      
                      OutlinedButton.icon(
                        onPressed: () => _showAddCategoryDialog(context, groupKey, state, notifier),
                        icon: const Icon(Icons.add, size: 16),
                        label: Text('Add Category to $groupKey'),
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
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildCategoryRow(
    String item,
    String groupKey,
    PlanningState state,
    PlanningStateNotifier notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const Icon(Icons.drag_indicator, size: 18, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, size: 16, color: Colors.blueAccent.withOpacity(0.8)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Rename',
                  onPressed: () => _showRenameCategoryDialog(context, item, groupKey, state, notifier),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 16, color: Colors.redAccent.withOpacity(0.8)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Delete',
                  onPressed: () => _showDeleteCategoryDialog(context, item, groupKey, state, notifier),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          Expanded(
            child: TextField(
              controller: _categoryControllers[item],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: '₹ ',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (val) {
                final valDouble = double.tryParse(val) ?? 0.0;
                notifier.updateCategoryBudget(item, valDouble);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showRenameCategoryDialog(
    BuildContext context,
    String oldName,
    String groupKey,
    PlanningState state,
    PlanningStateNotifier notifier,
  ) {
    final textController = TextEditingController(text: oldName);
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
                if (newName.isEmpty || newName == oldName) {
                  Navigator.pop(context);
                  return;
                }

                // 1. Rename in database if it exists
                final dbCategories = ref.read(categoriesProvider).categories;
                final existingCat = dbCategories.firstWhere(
                  (c) => c.name.toLowerCase() == oldName.toLowerCase(),
                  orElse: () => const Category(id: -99, name: '', icon: '', color: '', isDefault: false),
                );

                if (existingCat.id != -99) {
                  final updatedCat = existingCat.copyWith(name: newName);
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

                // 2. Rename locally in _groupCategories list
                setState(() {
                  final list = _groupCategories[groupKey];
                  if (list != null) {
                    final index = list.indexOf(oldName);
                    if (index != -1) {
                      list[index] = newName;
                    }
                  }
                });

                // 3. Rename in notifier and update controller
                notifier.renameCategoryBudget(oldName, newName);
                final controller = _categoryControllers.remove(oldName);
                if (controller != null) {
                  _categoryControllers[newName] = controller;
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

  void _showDeleteCategoryDialog(
    BuildContext context,
    String catName,
    String groupKey,
    PlanningState state,
    PlanningStateNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove from Budget'),
          content: Text('Are you sure you want to remove "$catName" from your budget plan? This will clear its budget limit for this month, but will NOT delete the category or affect your transactions.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                // 1. Remove locally
                setState(() {
                  _groupCategories[groupKey]?.remove(catName);
                  _deletedCategories.add(catName.toLowerCase());
                });

                // 2. Remove budget mapping and controller
                notifier.removeCategoryBudget(catName);
                final controller = _categoryControllers.remove(catName);
                controller?.dispose();

                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  void _showAddCategoryDialog(
    BuildContext context,
    String groupKey,
    PlanningState state,
    PlanningStateNotifier notifier,
  ) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Category to $groupKey'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Category Name'),
            autofocus: true,
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

                // 1. Insert Category into DB
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

                // 2. Add locally
                setState(() {
                  _groupCategories[groupKey]?.add(name);
                  _deletedCategories.remove(name.toLowerCase());
                });

                // 3. Update notifier budget state & controllers
                notifier.updateCategoryBudget(name, 0.0);
                notifier.setCustomCategoryGroup(name, groupKey);
                _categoryControllers[name] = TextEditingController(text: '');

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
  }

  Widget _buildSummaryStep(PlanningState state, PlanningStateNotifier notifier, Color cardBg, Color textColor) {
    final totalIncome = state.salary + state.otherIncome;
    final totalPlannedCategories = state.categoryBudgets.values.fold(0.0, (sum, val) => sum + val);
    final leftOver = totalIncome - totalPlannedCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Confirm Money Plan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 8),
        const Text('Review your allocations before saving.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        
        GlassmorphismCard(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildSummaryRow('Estimated Income', totalIncome, textColor),
                const Divider(),
                _buildSummaryRow('Needs Allocation', (state.needsPct / 100) * totalIncome, textColor),
                _buildSummaryRow('Wants Allocation', (state.wantsPct / 100) * totalIncome, textColor),
                _buildSummaryRow('Savings Allocation', (state.savingsPct / 100) * totalIncome, textColor),
                _buildSummaryRow('Investments Allocation', (state.investmentsPct / 100) * totalIncome, textColor),
                _buildSummaryRow('Emergency Fund', (state.emergencyPct / 100) * totalIncome, textColor),
                const Divider(),
                _buildSummaryRow(
                  'Unallocated Leftover',
                  leftOver,
                  leftOver >= 0 ? Colors.greenAccent : Colors.redAccent,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        if (leftOver > 0) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.blueAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI Suggestion: You still have ₹${leftOver.toStringAsFixed(0)} left over. '
                    'Would you like to allocate it to your Emergency Fund or Mutual Investments?',
                    style: TextStyle(fontSize: 13, color: textColor.withValues(alpha: 0.8)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildSummaryRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(CurrencyFormatter.format(value, 'INR'), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(PlanningState state, PlanningStateNotifier notifier) {
    final totalPercent = state.needsPct + state.wantsPct + state.savingsPct + state.investmentsPct + state.emergencyPct;
    final totalIncome = state.salary + state.otherIncome;

    bool canProceed = true;
    if (state.currentStep == 0 && totalIncome <= 0.0) {
      canProceed = false;
    } else if (state.currentStep == 2 && totalPercent != 100.0) {
      canProceed = false;
    }

    final isLastStep = state.currentStep == 4;

    return Row(
      children: [
        if (state.currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: () => notifier.setStep(state.currentStep - 1),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Back'),
            ),
          ),
        if (state.currentStep > 0) const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: canProceed
                ? () async {
                    if (isLastStep) {
                      await notifier.commitPlanToDatabase();
                      widget.onCompleted();
                    } else {
                      notifier.setStep(state.currentStep + 1);
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(isLastStep ? 'Save and Create Plan' : 'Continue'),
          ),
        ),
      ],
    );
  }
}
