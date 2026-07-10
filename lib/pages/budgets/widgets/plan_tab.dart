import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/planning_state_provider.dart';
import '../../../widgets/common/glassmorphism_card.dart';
import '../../../core/utils/currency_formatter.dart';

class PlanTab extends ConsumerStatefulWidget {
  const PlanTab({super.key});

  @override
  ConsumerState<PlanTab> createState() => _PlanTabState();
}

class _PlanTabState extends ConsumerState<PlanTab> {
  final Map<String, TextEditingController> _controllers = {};

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
          divisions: 20,
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

    return GlassmorphismCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: defaultCategories.map((item) {
            if (!_controllers.containsKey(item)) {
              final val = state.categoryBudgets[item] ?? 0.0;
              _controllers[item] = TextEditingController(
                text: val > 0 ? val.toStringAsFixed(0) : '',
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(item, style: const TextStyle(fontWeight: FontWeight.w500)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controllers[item],
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
          }).toList(),
        ),
      ),
    );
  }
}
