import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database.dart';
import '../../providers/budgets_provider.dart';
import '../../widgets/common/glassmorphism_card.dart';
import '../../widgets/common/premium_background.dart';

class BudgetBlueprintPage extends ConsumerStatefulWidget {
  const BudgetBlueprintPage({super.key});

  @override
  ConsumerState<BudgetBlueprintPage> createState() => _BudgetBlueprintPageState();
}

class _BudgetBlueprintPageState extends ConsumerState<BudgetBlueprintPage> {
  final _formKey = GlobalKey<FormState>();
  final _incomeController = TextEditingController(text: "5000");
  final _fixedExpensesController = TextEditingController(text: "2000");
  final _savingsGoalController = TextEditingController(text: "1000");
  
  String _selectedStrategy = "50/30/20 Rule";
  bool _hasGenerated = false;

  // Generated Blueprint Data
  double _income = 0.0;
  double _fixedExpenses = 0.0;
  double _savingsGoal = 0.0;

  double _targetNeeds = 0.0;
  double _targetWants = 0.0;
  double _targetSavings = 0.0;

  double _actualNeedsAvg = 0.0;
  double _actualWantsAvg = 0.0;

  Map<int, double> _categorySpendAverages = {};
  Map<int, String> _categoryTypes = {};

  final List<String> _strategies = [
    "50/30/20 Rule",
    "70/20/10 Rule",
    "Zero-Based Budgeting",
  ];

  @override
  void dispose() {
    _incomeController.dispose();
    _fixedExpensesController.dispose();
    _savingsGoalController.dispose();
    super.dispose();
  }

  Future<void> _generateBlueprint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _income = double.parse(_incomeController.text);
      _fixedExpenses = double.parse(_fixedExpensesController.text);
      _savingsGoal = double.parse(_savingsGoalController.text);
    });

    // 1. Calculate Targets based on Strategy
    if (_selectedStrategy == "50/30/20 Rule") {
      _targetNeeds = _income * 0.50;
      _targetWants = _income * 0.30;
      _targetSavings = _income * 0.20;
    } else if (_selectedStrategy == "70/20/10 Rule") {
      _targetNeeds = _income * 0.70;
      _targetSavings = _income * 0.20;
      _targetWants = _income * 0.10;
    } else {
      // Zero-Based Budgeting (Needs: 60%, Wants: 20%, Savings: 20%)
      _targetNeeds = _income * 0.60;
      _targetWants = _income * 0.20;
      _targetSavings = _income * 0.20;
    }

    // 2. Fetch Category data and historical spending from Database
    final db = await AppDatabase.instance.database;

    // Load categories
    final List<Map<String, dynamic>> cats = await db.query('category');
    final catNames = <int, String>{};
    final catTypes = <int, String>{};
    for (var c in cats) {
      final id = c['id'] as int;
      catNames[id] = c['name'] as String;
      
      // Classify default category types
      final nameLower = (c['name'] as String).toLowerCase();
      if (nameLower == 'rent' || nameLower == 'utilities' || nameLower == 'health' || nameLower == 'transport' || nameLower == 'credit card payment') {
        catTypes[id] = 'needs';
      } else if (nameLower == 'food' || nameLower == 'entertainment' || nameLower == 'other') {
        catTypes[id] = 'wants';
      } else {
        catTypes[id] = 'wants'; // Default
      }
    }

    // Load transaction spending for the last 3 months
    final List<Map<String, dynamic>> txs = await db.rawQuery('''
      SELECT category_id, amount, strftime('%Y-%m', date) as month
      FROM transaction_log
      WHERE type = 'expense'
    ''');

    // Group spending by month and category
    final monthlySpending = <String, Map<int, double>>{};
    final uniqueMonths = <String>{};

    for (var tx in txs) {
      final month = tx['month'] as String;
      final catId = tx['category_id'] as int;
      final amt = (tx['amount'] as num).toDouble();
      
      uniqueMonths.add(month);
      monthlySpending.putIfAbsent(month, () => {});
      monthlySpending[month]![catId] = (monthlySpending[month]![catId] ?? 0.0) + amt;
    }

    // Calculate average spending per category
    final catAverages = <int, double>{};
    final numMonths = uniqueMonths.isNotEmpty ? uniqueMonths.length : 1;

    for (var month in uniqueMonths) {
      final spendMap = monthlySpending[month]!;
      for (var entry in spendMap.entries) {
        catAverages[entry.key] = (catAverages[entry.key] ?? 0.0) + (entry.value / numMonths);
      }
    }

    // Sum actual average Needs and Wants
    double actualNeeds = 0.0;
    double actualWants = 0.0;

    for (var catId in catNames.keys) {
      final avg = catAverages[catId] ?? 0.0;
      final type = catTypes[catId] ?? 'wants';
      if (type == 'needs') {
        actualNeeds += avg;
      } else {
        actualWants += avg;
      }
    }

    setState(() {
      _actualNeedsAvg = actualNeeds;
      _actualWantsAvg = actualWants;
      _categorySpendAverages = catAverages;
      _categoryTypes = catTypes;
      _hasGenerated = true;
    });
  }

  Future<void> _applyBudgets() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Apply Budgets"),
        content: Text("This will update or create category budgets for the current month based on the $_selectedStrategy blueprint. Proceed?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
            child: const Text("Apply"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final currentMonth = DateTime.now().toIso8601String().substring(0, 7);
    final budgetsNotifier = ref.read(budgetsProvider.notifier);

    // Heuristically distribute Needs and Wants budgets
    // Filter categories into Needs vs Wants lists
    final needsCatIds = _categoryTypes.entries
        .where((e) => e.value == 'needs')
        .map((e) => e.key)
        .toList();
    final wantsCatIds = _categoryTypes.entries
        .where((e) => e.value == 'wants')
        .map((e) => e.key)
        .toList();

    // Helper function to distribute limits proportionally or evenly
    Future<void> distribute(List<int> catIds, double totalTarget) async {
      double totalActual = 0.0;
      for (var id in catIds) {
        totalActual += _categorySpendAverages[id] ?? 0.0;
      }

      for (var id in catIds) {
        double limitAmount;
        if (totalActual > 0) {
          final proportion = (_categorySpendAverages[id] ?? 0.0) / totalActual;
          limitAmount = totalTarget * proportion;
        } else {
          limitAmount = totalTarget / catIds.length;
        }

        // Clamp to a nice round number, min $10
        limitAmount = (limitAmount / 10).roundToDouble() * 10;
        if (limitAmount < 10) limitAmount = 10;

        await budgetsNotifier.setBudget(
          id,
          limitAmount,
          recurrence: 'monthly',
        );
      }
    }

    // Apply distributions
    await distribute(needsCatIds, _targetNeeds);
    await distribute(wantsCatIds, _targetWants);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Blueprint applied! budgets successfully created for $currentMonth."),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Budgeting Blueprint",
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: textColor,
          ),
        ),
      ),
      body: PremiumBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputsForm(isDark),
              if (_hasGenerated) ...[
                const SizedBox(height: 24),
                _buildBlueprintResults(isDark),
                const SizedBox(height: 24),
                _buildRecommendationsCard(isDark),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _applyBudgets,
                    icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                    label: const Text(
                      "Apply Blueprint to Budgets",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputsForm(bool isDark) {
    return GlassmorphismCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "PLAN DETAILS",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _incomeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: "Monthly Net Income",
                prefixText: "\$ ",
                border: OutlineInputBorder(),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return "Income is required";
                if (double.tryParse(val) == null || double.parse(val) <= 0) {
                  return "Please enter a valid amount";
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fixedExpensesController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: "Estimated Fixed Expenses (Rent, Bills)",
                prefixText: "\$ ",
                border: OutlineInputBorder(),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return "Fixed expenses required";
                if (double.tryParse(val) == null || double.parse(val) < 0) {
                  return "Please enter a valid amount";
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _savingsGoalController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: "Savings / Goal Target",
                prefixText: "\$ ",
                border: OutlineInputBorder(),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return "Savings target required";
                if (double.tryParse(val) == null || double.parse(val) < 0) {
                  return "Please enter a valid amount";
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            const Text(
              "BUDGETING STRATEGY",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: isDark ? Colors.white24 : Colors.black26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedStrategy,
                  isExpanded: true,
                  items: _strategies.map((s) {
                    return DropdownMenuItem<String>(
                      value: s,
                      child: Text(s, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedStrategy = val;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _generateBlueprint,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Generate Blueprint",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlueprintResults(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Blueprint Breakdown ($_selectedStrategy)",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildBlueprintCard(
          title: "Needs (Fixed & Vital)",
          target: _targetNeeds,
          actual: _actualNeedsAvg,
          color: Colors.blueAccent,
          subtitle: "Rent, Utilities, Transport, Health",
        ),
        const SizedBox(height: 12),
        _buildBlueprintCard(
          title: "Wants (Variable & Flexible)",
          target: _targetWants,
          actual: _actualWantsAvg,
          color: Colors.orangeAccent,
          subtitle: "Food, Entertainment, Shopping",
        ),
        const SizedBox(height: 12),
        _buildBlueprintCard(
          title: "Savings & Goals",
          target: _targetSavings,
          actual: 0.0,
          color: Colors.greenAccent,
          subtitle: "Savings Goals, Investments, Debt Payoff",
          hideActual: true,
        ),
      ],
    );
  }

  Widget _buildBlueprintCard({
    required String title,
    required double target,
    required double actual,
    required Color color,
    required String subtitle,
    bool hideActual = false,
  }) {
    final percent = target > 0 ? (actual / target) : 0.0;
    final progress = percent.clamp(0.0, 1.0);
    final statusColor = percent > 1.0 ? const Color(0xFFE53935) : color;

    return GlassmorphismCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Target: \$${target.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          if (!hideActual) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Actual Average: \$${actual.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: percent > 1.0 ? const Color(0xFFE53935) : null,
                  ),
                ),
                Text(
                  "${(percent * 100).toStringAsFixed(0)}%",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                color: statusColor,
                minHeight: 8,
              ),
            ),
          ] else ...[
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Auto-Allocated directly to Savings",
                  style: TextStyle(fontSize: 12, color: Colors.green),
                ),
                Icon(Icons.savings_outlined, color: Colors.green),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard(bool isDark) {
    final list = <Widget>[];

    // Heuristics
    if (_actualNeedsAvg > _targetNeeds) {
      list.add(_buildRecommendationRow(
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFE53935),
        text: "Your average Needs spending (\$${_actualNeedsAvg.toStringAsFixed(0)}) is higher than the recommended \$${_targetNeeds.toStringAsFixed(0)}. Review bills or contracts to see where you can trim fixed costs.",
      ));
    } else {
      list.add(_buildRecommendationRow(
        icon: Icons.check_circle_outline,
        color: Colors.green,
        text: "Your Needs spending is well within limits! This creates a great margin for savings.",
      ));
    }

    if (_actualWantsAvg > _targetWants) {
      final excess = _actualWantsAvg - _targetWants;
      list.add(_buildRecommendationRow(
        icon: Icons.lightbulb_outline,
        color: Colors.orangeAccent,
        text: "Your Wants spending exceeds the target by \$${excess.toStringAsFixed(0)}. We recommend adding budget limits on discretionary categories (like Entertainment and Food) to save \$${excess.toStringAsFixed(0)}.",
      ));
    }

    if (_fixedExpenses + _savingsGoal > _income) {
      list.add(_buildRecommendationRow(
        icon: Icons.error_outline,
        color: const Color(0xFFE53935),
        text: "Warning: Your combined fixed expenses and savings goal exceed your total income! Consider adjusting your savings target down or finding additional income sources.",
      ));
    } else {
      final leftover = _income - _fixedExpenses - _savingsGoal;
      if (leftover > 0) {
        list.add(_buildRecommendationRow(
          icon: Icons.savings_outlined,
          color: Colors.green,
          text: "You have \$${leftover.toStringAsFixed(0)} left over each month after fixed expenses and savings. You can allocate this surplus to extra debt payoff or accelerate your savings goals!",
        ));
      }
    }

    return GlassmorphismCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "BLUEPRINT INSIGHTS",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          ...list,
        ],
      ),
    );
  }

  Widget _buildRecommendationRow({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
