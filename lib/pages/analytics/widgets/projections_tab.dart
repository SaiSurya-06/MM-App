import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/transaction.dart';
import '../../../models/savings_goal.dart';
import '../../../models/category.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../widgets/common/glassmorphism_card.dart';
import '../../../providers/analytics_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/savings_goals_provider.dart';
import '../../../providers/categories_provider.dart';
import '../trend_analytics_page.dart';

class ProjectionsTab extends ConsumerStatefulWidget {
  const ProjectionsTab({Key? key}) : super(key: key);

  @override
  ConsumerState<ProjectionsTab> createState() => _ProjectionsTabState();
}

class _ProjectionsTabState extends ConsumerState<ProjectionsTab> {
  final Map<int, double> _scenarioReductions = {};
  
  // Cache for Monte Carlo simulations calculated locally
  Map<int, double>? _localMonteCarloCache;
  int _lastTxsLength = 0;
  int _lastGoalsLength = 0;

  @override
  Widget build(BuildContext context) {
    final derivedValues = ref.watch(derivedAnalyticsProvider);
    final authState = ref.watch(authProvider);
    final goalsState = ref.watch(savingsGoalsProvider);
    final categoriesState = ref.watch(categoriesProvider);
    final analyticsState = ref.watch(analyticsProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = authState.profile?.preferredCurrency ?? 'USD';

    final transactions = derivedValues.filteredTransactions;
    final goals = goalsState.goals;
    final categories = categoriesState.categories;
    final totalBalance = derivedValues.totalBalance;
    final daysElapsed = derivedValues.daysElapsed;
    final daysRemaining = derivedValues.daysRemaining;
    final monthlyIncome = derivedValues.monthlyIncome;
    final monthlyExpense = derivedValues.monthlyExpense;
    final dailyBurnRate = derivedValues.dailyBurnRate;
    final currentCategorySpends = derivedValues.currentCategorySpends;

    // 1. Calculate locally cached Monte Carlo simulations
    final mData = analyticsState.monthlyData;
    final thisMonthSavings = monthlyIncome - monthlyExpense;

    if (_localMonteCarloCache == null || 
        transactions.length != _lastTxsLength || 
        goals.length != _lastGoalsLength) {
      _localMonteCarloCache = _runMonteCarloSimulation(goals, mData, thisMonthSavings);
      _lastTxsLength = transactions.length;
      _lastGoalsLength = goals.length;
    }
    final monteCarloChances = _localMonteCarloCache!;

    // 2. Recurring Expense committed
    final recurringTxs = transactions.where((tx) => tx.recurrence != 'none' && tx.type == 'expense').toList();
    double committedRecurring = 0.0;
    for (var tx in recurringTxs) {
      double monthlyEquiv = 0.0;
      switch (tx.recurrence) {
        case 'daily': monthlyEquiv = tx.amount * 30.43; break;
        case 'weekly': monthlyEquiv = tx.amount * 4.35; break;
        case 'monthly': monthlyEquiv = tx.amount; break;
        case 'yearly': monthlyEquiv = tx.amount / 12.0; break;
      }
      committedRecurring += monthlyEquiv;
    }
    double discretionary = monthlyIncome - committedRecurring;

    // What-If Scenario Calculation
    double savingsAdjustment = 0.0;
    _scenarioReductions.forEach((catId, reduction) {
      final spent = currentCategorySpends[catId] ?? 0.0;
      savingsAdjustment += spent * reduction;
    });

    final newExpense = (monthlyExpense - savingsAdjustment).clamp(0.0, double.infinity);
    final newSavingsRate = monthlyIncome > 0 ? ((monthlyIncome - newExpense) / monthlyIncome * 100) : 0.0;
    final newDailyBurn = daysElapsed > 0 ? (newExpense / daysElapsed) : 0.0;
    final newRunwayDays = newDailyBurn > 0 ? (totalBalance / newDailyBurn) : double.infinity;

    final isSparseData = transactions.length < 10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sparse Data warning banner
        if (isSparseData) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withOpacity(0.4), width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.amber, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sparse Transaction History',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'You have logged only ${transactions.length} transactions. AI projections and Monte Carlo simulations require a larger dataset to model variance accurately and may be highly speculative.',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // What-If Scenario Modeler
        Text(
          'Interactive What-If Scenario Modeler',
          style: TextStyle(
            fontSize: 10, 
            color: isDark ? Colors.white38 : Colors.black38, 
            fontWeight: FontWeight.bold, 
            letterSpacing: 1.0
          ),
        ),
        const SizedBox(height: 8),
        GlassmorphismCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Optimize Category Budgets',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              const Text(
                'Adjust sliders to model budget cuts or increases (up to 200%) and see instant runway/savings projections.',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
              const SizedBox(height: 16),

              // Build list of categories with slider
              for (var cat in categories.where((c) => c.type == 'expense' || c.type == 'both')) ...[
                if ((currentCategorySpends[cat.id!] ?? 0.0) > 0) ...[
                  _buildScenarioSliderRow(
                    categoryName: cat.name,
                    categoryId: cat.id!,
                    spent: currentCategorySpends[cat.id!] ?? 0.0,
                    currency: currency,
                  ),
                  const SizedBox(height: 10),
                ],
              ],

              const Divider(height: 20, thickness: 0.5),

              // Live impact result metrics
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('New Savings Rate', style: TextStyle(color: Colors.grey, fontSize: 10)),
                      const SizedBox(height: 4),
                      Text(
                        '${newSavingsRate.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 14, 
                          color: newSavingsRate > 0 ? Colors.green : const Color(0xFFE53935)
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Projected Runway', style: TextStyle(color: Colors.grey, fontSize: 10)),
                      const SizedBox(height: 4),
                      Text(
                        newRunwayDays.isInfinite ? '∞' : '${newRunwayDays.toStringAsFixed(0)} Days',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue),
                      ),
                    ],
                  ),
                ],
              ),

              if (savingsAdjustment != 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: savingsAdjustment > 0 ? Colors.green.withOpacity(0.1) : const Color(0xFFE53935).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        savingsAdjustment > 0 ? Icons.check_circle_outline : Icons.warning_amber_rounded, 
                        color: savingsAdjustment > 0 ? Colors.green : const Color(0xFFE53935), 
                        size: 16
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          savingsAdjustment > 0
                              ? 'Saving ${CurrencyFormatter.format(savingsAdjustment, currency)} this month will increase your runway by ${(newRunwayDays - (dailyBurnRate > 0 ? totalBalance / dailyBurnRate : 0)).toStringAsFixed(0)} days!'
                              : 'Increasing spending by ${CurrencyFormatter.format(-savingsAdjustment, currency)} this month will reduce your runway by ${((dailyBurnRate > 0 ? totalBalance / dailyBurnRate : 0) - (newRunwayDays.isInfinite ? 0.0 : newRunwayDays)).toStringAsFixed(0)} days!',
                          style: TextStyle(
                            color: savingsAdjustment > 0 ? Colors.green : const Color(0xFFE53935), 
                            fontSize: 10, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Recurring Expense Committed vs Discretionary
        Text(
          'Recurring Bills & Pre-Committed Income',
          style: TextStyle(
            fontSize: 10, 
            color: isDark ? Colors.white38 : Colors.black38, 
            fontWeight: FontWeight.bold, 
            letterSpacing: 1.0
          ),
        ),
        const SizedBox(height: 8),
        GlassmorphismCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Committed Recurring', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(committedRecurring, currency),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFE53935)),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Discretionary Income', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(discretionary, currency),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (committedRecurring > (monthlyIncome * 0.5))
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFE53935), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pre-committed expenses exceed 50% of your monthly income. Consider cancelling redundant subscriptions.',
                          style: TextStyle(color: Color(0xFFE53935), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              if (recurringTxs.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text('No active recurring transactions tracked.', style: TextStyle(color: Colors.grey, fontSize: 11)),
                )
              else ...[
                const SizedBox(height: 10),
                const Text('Active Subscriptions/Recurring Bills:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                for (var tx in recurringTxs.take(3)) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(tx.title, style: const TextStyle(fontSize: 12)),
                        Text(
                          '${CurrencyFormatter.format(tx.amount, currency)} (${tx.recurrence})',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Savings Goal Monte Carlo Projections
        Text(
          'Savings Timeline Monte Carlo Simulation',
          style: TextStyle(
            fontSize: 10, 
            color: isDark ? Colors.white38 : Colors.black38, 
            fontWeight: FontWeight.bold, 
            letterSpacing: 1.0
          ),
        ),
        const SizedBox(height: 8),
        GlassmorphismCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Probability of Hitting Goals',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              const Text(
                'Probability calculated from 1000 simulated savings rates reflecting historical volatility.',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
              const SizedBox(height: 14),
              if (goals.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('No active savings goals found.', style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: goals.length,
                  itemBuilder: (context, index) {
                    final goal = goals[index];
                    final chance = monteCarloChances[goal.id] ?? 0.0;
                    final pct = chance * 100.0;

                    return Padding(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(goal.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(
                                '${pct.toStringAsFixed(0)}% Probability',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: chance > 0.75 
                                      ? Colors.green 
                                      : (chance > 0.4 ? Colors.orange : const Color(0xFFE53935)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: (pct).round(),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: chance > 0.75 
                                          ? Colors.green 
                                          : (chance > 0.4 ? Colors.orange : const Color(0xFFE53935)),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: (100 - pct).round(),
                                  child: const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScenarioSliderRow({
    required String categoryName,
    required int categoryId,
    required double spent,
    required String currency,
  }) {
    final currentReduction = _scenarioReductions[categoryId] ?? 0.0;
    final isIncrease = currentReduction < 0;
    final pctText = isIncrease 
        ? '+${(-currentReduction * 100).toStringAsFixed(0)}%'
        : '-${(currentReduction * 100).toStringAsFixed(0)}%';
    final amtText = CurrencyFormatter.format(spent * currentReduction.abs(), currency);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(categoryName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
            Text(
              '$pctText ($amtText)',
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 12, 
                color: isIncrease ? const Color(0xFFE53935) : Colors.green
              ),
            ),
          ],
        ),
        Slider(
          value: currentReduction,
          onChanged: (val) {
            setState(() {
              _scenarioReductions[categoryId] = val;
            });
          },
          min: -1.0,
          max: 1.0,
          activeColor: const Color(0xFFE53935),
          inactiveColor: Colors.grey.withOpacity(0.2),
        ),
      ],
    );
  }

  // Local helper to calculate Monte Carlo simulations
  Map<int, double> _runMonteCarloSimulation(List<SavingsGoal> goals, List<MonthlyComparison> mData, double thisMonthSavings) {
    final Map<int, double> results = {};
    final random = math.Random();
    
    List<double> savingsDist = mData.map((d) => d.income - d.expense).toList();
    if (savingsDist.isEmpty) {
      savingsDist.add(thisMonthSavings);
    }
    if (savingsDist.every((s) => s <= 0)) {
      savingsDist = [thisMonthSavings, thisMonthSavings * 0.8, thisMonthSavings * 1.2];
    }

    final now = DateTime.now();

    for (var goal in goals) {
      if (goal.id == null) continue;
      final remaining = goal.targetAmount - goal.currentAmount;
      if (remaining <= 0) {
        results[goal.id!] = 1.0;
        continue;
      }

      int targetMonths = 12;
      if (goal.targetDate != null) {
        targetMonths = ((goal.targetDate!.year - now.year) * 12) + (goal.targetDate!.month - now.month);
        if (targetMonths <= 0) targetMonths = 1;
      }

      int successes = 0;
      for (int trial = 0; trial < 1000; trial++) {
        double current = goal.currentAmount;
        for (int m = 0; m < targetMonths; m++) {
          double sample = savingsDist[random.nextInt(savingsDist.length)];
          sample *= (0.9 + random.nextDouble() * 0.2);
          current += sample;
        }
        if (current >= goal.targetAmount) {
          successes++;
        }
      }
      results[goal.id!] = successes / 1000.0;
    }
    return results;
  }
}
