import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/savings_goals_provider.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/budgets_provider.dart';
import '../../providers/categories_provider.dart';
import '../../models/savings_goal.dart';
import '../../core/analytics/financial_engine.dart';
import '../../core/analytics/ai_analyst.dart';
import '../../widgets/common/glassmorphism_card.dart';
import '../../widgets/common/toast_notification.dart';
import '../../core/utils/currency_formatter.dart';

class SavingsGoalsPage extends ConsumerStatefulWidget {
  const SavingsGoalsPage({super.key});

  @override
  ConsumerState<SavingsGoalsPage> createState() => _SavingsGoalsPageState();
}

class _SavingsGoalsPageState extends ConsumerState<SavingsGoalsPage> {
  void _openAddGoalSheet([SavingsGoal? goal]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GoalFormSheet(goal: goal),
    );
  }

  void _showContributeDialog(SavingsGoal goal, String currency) {
    final accounts = ref.read(accountsProvider).accounts;
    if (accounts.isEmpty) {
      ToastNotification.show(context, 'Please create a funding account first.', isError: true);
      return;
    }

    int? selectedAccountId = accounts.first.id;
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Contribute to ${goal.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Source Account', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                value: selectedAccountId,
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                items: accounts.map((acc) => DropdownMenuItem(value: acc.id, child: Text('${acc.name} (${CurrencyFormatter.format(acc.balance, currency)})'))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedAccountId = val);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Contribution Amount',
                  prefixIcon: Icon(Icons.savings_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final amt = double.tryParse(amountController.text) ?? 0.0;
                if (amt <= 0) {
                  ToastNotification.show(context, 'Please enter a valid amount', isError: true);
                  return;
                }
                final acc = accounts.firstWhere((a) => a.id == selectedAccountId);
                if (acc.balance < amt) {
                  ToastNotification.show(context, 'Insufficient balance in selected account.', isError: true);
                  return;
                }

                final success = await ref.read(savingsGoalsProvider.notifier).addContribution(
                      goalId: goal.id!,
                      fromAccountId: selectedAccountId!,
                      amount: amt,
                    );
                if (success && context.mounted) {
                  ToastNotification.show(context, 'Contributed ${CurrencyFormatter.format(amt, currency)} to ${goal.name}!');
                  Navigator.pop(context);
                }
              },
              child: const Text('Contribute'),
            ),
          ],
        ),
      ),
    );
  }

  void _showWithdrawDialog(SavingsGoal goal, String currency) {
    final accounts = ref.read(accountsProvider).accounts;
    if (accounts.isEmpty) {
      ToastNotification.show(context, 'Please create a destination account first.', isError: true);
      return;
    }

    int? selectedAccountId = accounts.first.id;
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Withdraw from ${goal.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Destination Account', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                value: selectedAccountId,
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                items: accounts.map((acc) => DropdownMenuItem(value: acc.id, child: Text('${acc.name} (${CurrencyFormatter.format(acc.balance, currency)})'))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedAccountId = val);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Withdrawal Amount',
                  prefixIcon: Icon(Icons.outbox_outlined),
                ),
              ),
            ],
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
                final amt = double.tryParse(amountController.text) ?? 0.0;
                if (amt <= 0) {
                  ToastNotification.show(context, 'Please enter a valid amount', isError: true);
                  return;
                }
                if (goal.currentAmount < amt) {
                  ToastNotification.show(context, 'Cannot withdraw more than current savings.', isError: true);
                  return;
                }

                final success = await ref.read(savingsGoalsProvider.notifier).withdrawFunds(
                      goalId: goal.id!,
                      toAccountId: selectedAccountId!,
                      amount: amt,
                    );
                if (success && context.mounted) {
                  ToastNotification.show(context, 'Withdrew ${CurrencyFormatter.format(amt, currency)} from ${goal.name}!');
                  Navigator.pop(context);
                }
              },
              child: const Text('Withdraw'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getGoalIcon(String name) {
    switch (name) {
      case 'flight':
        return Icons.flight;
      case 'directions_car':
        return Icons.directions_car;
      case 'home':
        return Icons.home;
      case 'school':
        return Icons.school;
      case 'celebration':
        return Icons.celebration;
      default:
        return Icons.savings;
    }
  }

  @override
  Widget build(BuildContext context) {
    final goalsState = ref.watch(savingsGoalsProvider);
    final authState = ref.watch(authProvider);
    final analyticsState = ref.watch(analyticsProvider);
    final currency = authState.profile?.preferredCurrency ?? 'USD';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        actions: [
          IconButton(
            onPressed: () => _openAddGoalSheet(),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: goalsState.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)))
          : goalsState.goals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.savings_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      const Text(
                        'No savings goals set yet.',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _openAddGoalSheet(),
                        icon: const Icon(Icons.add),
                        label: const Text('Create Savings Goal'),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: goalsState.goals.length,
                  itemBuilder: (context, index) {
                    final goal = goalsState.goals[index];
                    final progress = goal.targetAmount > 0 
                        ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0)
                        : 0.0;
                    
                    final hex = '0xFF${goal.color.replaceAll("#", "")}';
                    final goalColor = Color(int.tryParse(hex) ?? 0xFF4CAF50);

                    final proj = analyticsState.aiGoalProjections.firstWhere(
                      (p) => p.goalId == goal.id,
                      orElse: () => AiGoalProjection(
                        goalId: goal.id,
                        goalName: goal.name,
                        targetAmount: goal.targetAmount,
                        currentAmount: goal.currentAmount,
                        monthsRemaining: 0.0,
                        status: 'On Track',
                        probability: 100.0,
                      ),
                    );
                    final probabilityStr = proj.probability >= 0 ? '${proj.probability.toStringAsFixed(0)}%' : 'N/A';

                    return GestureDetector(
                      onTap: () => _openAddGoalSheet(goal),
                      child: GlassmorphismCard(
                        padding: const EdgeInsets.all(14.0),
                        color: isDark ? goalColor.withValues(alpha: 0.08) : goalColor.withValues(alpha: 0.04),
                        borderColor: goalColor.withValues(alpha: 0.15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: goalColor.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(_getGoalIcon(goal.icon), color: goalColor, size: 18),
                                ),
                                Text(
                                  '${(progress * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: goalColor),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  goal.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${CurrencyFormatter.format(goal.currentAmount, currency)} of ${CurrencyFormatter.format(goal.targetAmount, currency)}',
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 4,
                                    backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
                                    valueColor: AlwaysStoppedAnimation<Color>(goalColor),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Builder(
                                      builder: (context) {
                                        if (goal.targetDate == null) {
                                          return const Text(
                                            'No Limit',
                                            style: TextStyle(fontSize: 9, color: Colors.grey),
                                          );
                                        }
                                        final now = DateTime.now();
                                        final diff = goal.targetDate!.difference(now);
                                        String countdownText = '';
                                        if (diff.isNegative) {
                                          countdownText = 'Overdue';
                                        } else {
                                          final days = diff.inDays;
                                          if (days > 30) {
                                            final months = (days / 30).round();
                                            countdownText = '$months mo left';
                                          } else {
                                            countdownText = '$days days left';
                                          }
                                        }
                                        return Text(
                                          '${DateFormat('MM/yy').format(goal.targetDate!)} ($countdownText)',
                                          style: const TextStyle(fontSize: 9, color: Colors.grey),
                                        );
                                      }
                                    ),
                                    const SizedBox(height: 2),
                                    Tooltip(
                                      message: 'AI projections assume historical consistency and may vary with sudden spending shifts.',
                                      triggerMode: TooltipTriggerMode.tap,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Prob: $probabilityStr',
                                            style: TextStyle(
                                              fontSize: 8.5, 
                                              color: proj.probability > 75 
                                                  ? Colors.green 
                                                  : (proj.probability > 40 ? Colors.orange : Colors.red), 
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Inter',
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          Icon(
                                            Icons.info_outline,
                                            size: 9,
                                            color: isDark ? Colors.white38 : Colors.black38,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                      style: IconButton.styleFrom(
                                        backgroundColor: const Color(0xFFE53935).withValues(alpha: 0.12),
                                        foregroundColor: const Color(0xFFE53935),
                                      ),
                                      onPressed: () => _showWithdrawDialog(goal, currency),
                                      icon: const Icon(Icons.remove, size: 14),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                      style: IconButton.styleFrom(
                                        backgroundColor: goalColor.withValues(alpha: 0.15),
                                        foregroundColor: goalColor,
                                      ),
                                      onPressed: () => _showContributeDialog(goal, currency),
                                      icon: const Icon(Icons.add, size: 14),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class GoalFormSheet extends ConsumerStatefulWidget {
  final SavingsGoal? goal;
  const GoalFormSheet({super.key, this.goal});

  @override
  ConsumerState<GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends ConsumerState<GoalFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _targetAmountController;
  late String _selectedIcon;
  late String _selectedColor;
  DateTime? _selectedDate;
  int _monthsToReduce = 1;

  final List<Map<String, String>> _icons = [
    {'name': 'Savings', 'key': 'savings'},
    {'name': 'Travel', 'key': 'flight'},
    {'name': 'Car', 'key': 'directions_car'},
    {'name': 'Home', 'key': 'home'},
    {'name': 'Education', 'key': 'school'},
    {'name': 'Party', 'key': 'celebration'},
  ];

  final List<Map<String, String>> _colors = [
    {'name': 'Teal', 'hex': '#00ACC1'},
    {'name': 'Orange', 'hex': '#FB8C00'},
    {'name': 'Purple', 'hex': '#8E24AA'},
    {'name': 'Blue', 'hex': '#1E88E5'},
    {'name': 'Green', 'hex': '#4CAF50'},
    {'name': 'Pink', 'hex': '#E91E63'},
  ];

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    _nameController = TextEditingController(text: g?.name ?? '');
    _targetAmountController = TextEditingController(text: g?.targetAmount.toString() ?? '');
    _selectedIcon = g?.icon ?? 'savings';
    _selectedColor = g?.color ?? '#00ACC1';
    _selectedDate = g?.targetDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 90)),
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
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final target = double.tryParse(_targetAmountController.text) ?? 0.0;

    bool success;
    if (widget.goal == null) {
      success = await ref.read(savingsGoalsProvider.notifier).addGoal(
            name: name,
            targetAmount: target,
            targetDate: _selectedDate,
            color: _selectedColor,
            icon: _selectedIcon,
          );
    } else {
      final updated = widget.goal!.copyWith(
        name: name,
        targetAmount: target,
        targetDate: _selectedDate,
        color: _selectedColor,
        icon: _selectedIcon,
      );
      success = await ref.read(savingsGoalsProvider.notifier).updateGoal(updated);
    }

    if (success && mounted) {
      ToastNotification.show(context, widget.goal == null ? 'Savings goal created.' : 'Savings goal saved.');
      Navigator.pop(context);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E2E) : Colors.white,
        title: const Text('Delete Savings Goal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this savings goal?'),
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
    if (confirmed != true) return;

    final success = await ref.read(savingsGoalsProvider.notifier).deleteGoal(widget.goal!.id!);
    if (success && mounted) {
      ToastNotification.show(context, 'Savings goal deleted.');
      Navigator.pop(context);
    }
  }

  IconData _getIconData(String key) {
    switch (key) {
      case 'flight':
        return Icons.flight;
      case 'directions_car':
        return Icons.directions_car;
      case 'home':
        return Icons.home;
      case 'school':
        return Icons.school;
      case 'celebration':
        return Icons.celebration;
      default:
        return Icons.savings;
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
                widget.goal == null ? 'New Savings Goal' : 'Edit Goal Details',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Goal Target (e.g. Vacation Fund)', prefixIcon: Icon(Icons.badge_outlined)),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _targetAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Target Amount', prefixIcon: Icon(Icons.flag_outlined)),
                validator: (val) => val == null || double.tryParse(val) == null || double.parse(val) <= 0 ? 'Enter valid target amount' : null,
              ),
              const SizedBox(height: 12),

              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Target Date (Optional)', prefixIcon: Icon(Icons.calendar_today)),
                  child: Text(
                    _selectedDate != null 
                        ? DateFormat('MMMM dd, yyyy').format(_selectedDate!) 
                        : 'No Timeline / Forever', 
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text('Tag Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _colors.length,
                  itemBuilder: (context, index) {
                    final item = _colors[index];
                    final colorHex = '0xFF${item["hex"]!.replaceAll("#", "")}';
                    final color = Color(int.parse(colorHex));
                    final isSelected = _selectedColor == item['hex'];

                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = item['hex']!),
                      child: Container(
                        width: 34,
                        height: 34,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: isDark ? Colors.white : Colors.black, width: 2.5) : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              const Text('Goal Icon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _icons.length,
                  itemBuilder: (context, index) {
                    final item = _icons[index];
                    final key = item['key']!;
                    final isSelected = _selectedIcon == key;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedIcon = key),
                      child: Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? const Color(0xFFE53935).withValues(alpha: 0.15)
                              : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
                          borderRadius: BorderRadius.circular(10),
                          border: isSelected ? Border.all(color: const Color(0xFFE53935), width: 1.5) : null,
                        ),
                        child: Icon(
                          _getIconData(key),
                          color: isSelected ? const Color(0xFFE53935) : Colors.grey,
                          size: 18,
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (widget.goal != null) ...[
                Builder(
                  builder: (context) {
                    final currency = ref.watch(authProvider).profile?.preferredCurrency ?? 'USD';
                    final analyticsState = ref.watch(analyticsProvider);
                    final budgetsState = ref.watch(budgetsProvider);
                    final categoriesState = ref.watch(categoriesProvider);

                    double averageSavingsVelocity = 0.0;
                    final monthlyData = analyticsState.monthlyData;
                    if (monthlyData.isNotEmpty) {
                      int count = 0;
                      double savingsSum = 0.0;
                      for (int i = monthlyData.length - 1; i >= 0 && count < 3; i--) {
                        savingsSum += (monthlyData[i].income - monthlyData[i].expense);
                        count++;
                      }
                      if (count > 0) {
                        averageSavingsVelocity = savingsSum / count;
                      }
                    }

                    final optResult = FinancialEngine.optimizeGoalSavings(
                      targetAmount: widget.goal!.targetAmount,
                      currentAmount: widget.goal!.currentAmount,
                      currentSavingsRate: averageSavingsVelocity,
                      budgets: budgetsState.budgets,
                      categories: categoriesState.categories,
                      categoryMonthlySpends: budgetsState.categorySpendings,
                      monthsToReduce: _monthsToReduce,
                      currencyCode: currency,
                    );

                    if (averageSavingsVelocity <= 10.0) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 12),
                        const Text(
                          'Goal Trajectory Optimizer',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFE53935)),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Adjust your category budgets to reach your goal earlier.',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Reach goal earlier by:', style: TextStyle(fontSize: 13)),
                            DropdownButton<int>(
                              value: _monthsToReduce,
                              dropdownColor: isDark ? const Color(0xFF161625) : Colors.white,
                              items: [1, 2, 3, 6, 12].map((m) => DropdownMenuItem(
                                value: m,
                                child: Text('$m month${m > 1 ? "s" : ""}'),
                              )).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _monthsToReduce = val);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            optResult.recommendationText,
                            style: const TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
                          ),
                        ),
                        if (optResult.suggestions.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                              foregroundColor: const Color(0xFF4CAF50),
                              side: const BorderSide(color: Color(0xFF4CAF50), width: 1),
                              minimumSize: const Size(double.infinity, 44),
                            ),
                            onPressed: () async {
                              await ref.read(budgetsProvider.notifier).applyOptimizations(optResult.suggestions);
                              if (context.mounted) {
                                ToastNotification.show(context, 'Budgets successfully optimized!');
                              }
                            },
                            icon: const Icon(Icons.flash_on, size: 16),
                            label: const Text('Apply Budget Optimization', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ],
                    );
                  }
                ),
              ],

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _save,
                child: Text(widget.goal == null ? 'Create Goal' : 'Save Changes'),
              ),
              if (widget.goal != null) ...[
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
                  label: const Text('Delete Goal', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
