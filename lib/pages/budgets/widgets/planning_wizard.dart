import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/planning_state_provider.dart';
import '../../../widgets/common/glassmorphism_card.dart';
import '../../../core/utils/currency_formatter.dart';

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        const Text('Drag the sliders to adjust your core budget splits.', style: TextStyle(color: Colors.grey)),
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
          onChanged: (newVal) => notifier.updatePercentages(needs: newVal),
        ),
        _buildDraggableSlider(
          label: 'Wants (Lifestyle)',
          val: state.wantsPct,
          color: Colors.amber,
          totalIncome: totalIncome,
          onChanged: (newVal) => notifier.updatePercentages(wants: newVal),
        ),
        _buildDraggableSlider(
          label: 'Savings',
          val: state.savingsPct,
          color: Colors.green,
          totalIncome: totalIncome,
          onChanged: (newVal) => notifier.updatePercentages(savings: newVal),
        ),
        _buildDraggableSlider(
          label: 'Investments',
          val: state.investmentsPct,
          color: Colors.purple,
          totalIncome: totalIncome,
          onChanged: (newVal) => notifier.updatePercentages(investments: newVal),
        ),
        _buildDraggableSlider(
          label: 'Emergency Fund',
          val: state.emergencyPct,
          color: Colors.cyan,
          totalIncome: totalIncome,
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
    required ValueChanged<double> onChanged,
  }) {
    final amt = (val / 100.0) * totalIncome;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('${val.toStringAsFixed(0)}% (₹${CurrencyFormatter.format(amt, 'INR')})', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: val,
            min: 0,
            max: 100,
            divisions: 20,
            activeColor: color,
            onChanged: (newVal) => onChanged(newVal.roundToDouble()),
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
          _buildCategoryGroupInput('Essentials (Needs cap: ₹${needsLimit.toStringAsFixed(0)})', [
            'Rent',
            'Electricity',
            'Internet',
            'Utilities',
            'Insurance',
          ], state, notifier),
        
        if (state.wantsPct > 0)
          _buildCategoryGroupInput('Lifestyle (Wants cap: ₹${wantsLimit.toStringAsFixed(0)})', [
            'Food',
            'Shopping',
            'Entertainment',
            'Dining',
            'Travel',
          ], state, notifier),

        if (state.savingsPct > 0)
          _buildCategoryGroupInput('Savings (Savings cap: ₹${savingsLimit.toStringAsFixed(0)})', [
            'Emergency Savings',
            'Vacation Fund',
            'Bike Goal',
          ], state, notifier),

        if (state.investmentsPct > 0)
          _buildCategoryGroupInput('Investments (Investments cap: ₹${investmentsLimit.toStringAsFixed(0)})', [
            'Mutual Funds',
            'Stocks',
            'Gold',
          ], state, notifier),
      ],
    );
  }

  Widget _buildCategoryGroupInput(
    String groupTitle,
    List<String> items,
    PlanningState state,
    PlanningStateNotifier notifier,
  ) {
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
        GlassmorphismCard(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: items.map((item) {
                if (!_categoryControllers.containsKey(item)) {
                  final initialVal = state.categoryBudgets[item];
                  _categoryControllers[item] = TextEditingController(
                    text: initialVal != null && initialVal > 0 ? initialVal.toStringAsFixed(0) : '',
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: _categoryControllers[item],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: item,
                      prefixText: '₹ ',
                      border: const UnderlineInputBorder(),
                    ),
                    onChanged: (val) {
                      final valDouble = double.tryParse(val) ?? 0.0;
                      notifier.updateCategoryBudget(item, valDouble);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
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
          Text('₹${CurrencyFormatter.format(value, 'INR')}', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
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
