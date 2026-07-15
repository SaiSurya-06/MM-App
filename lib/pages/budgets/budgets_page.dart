import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/planning_state_provider.dart';
import '../../providers/money_intelligence_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budgets_provider.dart';
import '../../providers/categories_provider.dart';
import '../../providers/money_map_view_model.dart';
import '../../core/utils/currency_formatter.dart';
import '../../widgets/common/glassmorphism_card.dart';
import 'widgets/planning_wizard.dart';
import 'widgets/plan_tab.dart';
import 'widgets/track_tab.dart';
import 'widgets/adjust_tab.dart';
import 'widgets/review_tab.dart';
import '../../models/category.dart';

class BudgetsPage extends ConsumerStatefulWidget {
  const BudgetsPage({super.key});

  @override
  ConsumerState<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends ConsumerState<BudgetsPage> {
  int _selectedTab = 0;
  bool _showWizard = false;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  void _selectMonth(BuildContext context, WidgetRef ref, String currentMonthStr) {
    final parts = currentMonthStr.split('-');
    int selectedYear = parts.length == 2 ? int.tryParse(parts[0]) ?? DateTime.now().year : DateTime.now().year;
    int selectedMonth = parts.length == 2 ? int.tryParse(parts[1]) ?? DateTime.now().month : DateTime.now().month;

    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Month & Year',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: () {
                                setModalState(() {
                                  selectedYear--;
                                });
                              },
                            ),
                            Text(
                              '$selectedYear',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () {
                                setModalState(() {
                                  selectedYear++;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.0,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final monthNum = index + 1;
                        final isSelected = selectedMonth == monthNum;
                        return InkWell(
                          onTap: () {
                            setModalState(() {
                              selectedMonth = monthNum;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blueAccent
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              months[index].substring(0, 3),
                              style: TextStyle(
                                color: isSelected ? Colors.white : null,
                                fontWeight: isSelected ? FontWeight.bold : null,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            final monthStr = '$selectedYear-${selectedMonth.toString().padLeft(2, '0')}';
                            ref.read(planningStateProvider.notifier).changeMonth(monthStr);
                            ref.read(budgetsProvider.notifier).selectMonth(monthStr);
                            ref.read(moneyIntelligenceProvider.notifier).selectMonth(monthStr);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                          ),
                          child: const Text('Select'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final planningState = ref.watch(planningStateProvider);
    final intelState = ref.watch(moneyIntelligenceProvider);
    final authState = ref.watch(authProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F11) : const Color(0xFFF3F4F6);
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final userName = authState.profile?.name ?? 'Surya';

    // 1. Loading State
    if (planningState.isLoading || intelState.isLoading) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      );
    }

    // 2. Error State
    if (planningState.errorMessage != null) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Failed to Load Money Map',
                  style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  planningState.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => ref.read(planningStateProvider.notifier).loadPlanningMeta(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 3. First-Time Landing & Onboarding Wizard Flow
    if (!planningState.isCompleted) {
      if (!_showWizard) {
        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            title: const Text('Money Map', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          drawer: _buildDrawer(userName, isDark),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.map_outlined,
                    color: Colors.blueAccent,
                    size: 80,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome to Money Map, $userName 👋',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Money Map is your premium workspace to plan, track, adjust, and review your finances. Choose a strategy, allocate your income, and let our AI Advisor guide you.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showWizard = true;
                      });
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text("Let's Plan Your Budget"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        return PlanningWizard(
          onCompleted: () {
            setState(() {
              _showWizard = false;
            });
            ref.read(planningStateProvider.notifier).loadPlanningMeta();
          },
        );
      }
    }

    // 4. Main Workspace Layout with 5 Tabs (Dashboard + 4 Detailed tabs)
    final List<Widget> tabs = [
      _buildDashboardView(context, planningState, intelState, textColor, isDark),
      const PlanTab(),
      const TrackTab(),
      const AdjustTab(),
      const ReviewTab(),
    ];

    final String appBarTitle;
    switch (_selectedTab) {
      case 0:
        appBarTitle = 'Money Map';
        break;
      case 1:
        appBarTitle = 'Plan & Splits';
        break;
      case 2:
        appBarTitle = 'Track Budgets';
        break;
      case 3:
        appBarTitle = 'Adjust & Simulate';
        break;
      case 4:
        appBarTitle = 'Weekly Review';
        break;
      default:
        appBarTitle = 'Money Map';
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          appBarTitle,
          style: TextStyle(color: textColor, fontFamily: 'Inter', fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Select Month',
            onPressed: () => _selectMonth(context, ref, planningState.selectedMonth),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(planningStateProvider.notifier).loadPlanningMeta();
              ref.read(planningStateProvider.notifier).loadWeeklyCheckins();
            },
          ),
        ],
      ),
      drawer: _buildDrawer(userName, isDark),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: IndexedStack(
            index: _selectedTab,
            children: tabs,
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(String userName, bool isDark) {
    return Drawer(
      backgroundColor: isDark ? const Color(0xFF161618) : Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E24) : Colors.blueAccent,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Money Map',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hi $userName, plan your money',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined, color: Colors.blueAccent),
            title: const Text('Dashboard'),
            selected: _selectedTab == 0,
            onTap: () {
              setState(() => _selectedTab = 0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment_outlined, color: Colors.blueAccent),
            title: const Text('Plan Budget'),
            selected: _selectedTab == 1,
            onTap: () {
              setState(() => _selectedTab = 1);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.track_changes, color: Colors.green),
            title: const Text('Track Budgets'),
            selected: _selectedTab == 2,
            onTap: () {
              setState(() => _selectedTab = 2);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.tune, color: Colors.amber),
            title: const Text('Adjust & Simulate'),
            selected: _selectedTab == 3,
            onTap: () {
              setState(() => _selectedTab = 3);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.rate_review, color: Colors.purple),
            title: const Text('Weekly Review'),
            selected: _selectedTab == 4,
            onTap: () {
              setState(() => _selectedTab = 4);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardView(
    BuildContext context,
    PlanningState state,
    MoneyIntelligenceState intelState,
    Color textColor,
    bool isDark,
  ) {
    final budgetsState = ref.watch(budgetsProvider);
    final categoriesState = ref.watch(categoriesProvider);
    final moneyMapState = ref.watch(moneyMapViewModelProvider);

    if (budgetsState.isLoading || categoriesState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.blueAccent),
      );
    }

    final totalIncome = state.salary + state.otherIncome;
    final totalPct = state.needsPct + state.wantsPct + state.savingsPct + state.investmentsPct + state.emergencyPct;
    final userName = ref.watch(authProvider).profile?.name ?? 'Surya';

    // Time-based greeting
    final greeting = '${_getGreeting()}, $userName 👋';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          // Greeting Section
          Text(
            greeting,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your monthly financial blueprint overview',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Overview Cards Row
          Row(
            children: [
              Expanded(
                child: GlassmorphismCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.bolt, color: Colors.amberAccent, size: 18),
                            SizedBox(width: 6),
                            Text('Safe to Spend', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          CurrencyFormatter.format(moneyMapState.safeToSpendToday, 'INR'),
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Inter'),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${moneyMapState.daysRemaining} days remaining',
                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassmorphismCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.payments_outlined, color: Colors.blueAccent, size: 18),
                            SizedBox(width: 6),
                            Text('Planned Income', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          CurrencyFormatter.format(totalIncome, 'INR'),
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Inter'),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Allocated: ${totalPct.toStringAsFixed(0)}%',
                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Core Splits
          Text(
            'Core Splits',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Inter'),
          ),
          const SizedBox(height: 12),
          GlassmorphismCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildSplitsBar(state),
                  const SizedBox(height: 16),
                  _buildSplitsLegendRow('Needs', state.needsPct, Colors.blueAccent),
                  const SizedBox(height: 8),
                  _buildSplitsLegendRow('Wants', state.wantsPct, Colors.amber),
                  const SizedBox(height: 8),
                  _buildSplitsLegendRow('Savings', state.savingsPct, Colors.green),
                  if (state.investmentsPct > 0) ...[
                    const SizedBox(height: 8),
                    _buildSplitsLegendRow('Investments', state.investmentsPct, Colors.purple),
                  ],
                  if (state.emergencyPct > 0) ...[
                    const SizedBox(height: 8),
                    _buildSplitsLegendRow('Emergency', state.emergencyPct, Colors.cyan),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Budget vs Actual Mini Tracker
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Category Budgets',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Inter'),
              ),
              GestureDetector(
                onTap: () => setState(() => _selectedTab = 2), // Jump to Track tab
                child: const Text(
                  'View All',
                  style: TextStyle(color: Colors.blueAccent, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMiniBudgetTracker(budgetsState, categoriesState, textColor),
          const SizedBox(height: 24),

          // Top Recommendation card
          if (intelState.report != null && intelState.report!.insights.isNotEmpty) ...[
            Text(
              'Advisor Recommendation',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Inter'),
            ),
            const SizedBox(height: 12),
            _buildTopRecommendation(intelState.report!.insights.first, textColor),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildSplitsBar(PlanningState state) {
    final double needs = state.needsPct;
    final double wants = state.wantsPct;
    final double savings = state.savingsPct;
    final double investments = state.investmentsPct;
    final double emergency = state.emergencyPct;

    final double total = needs + wants + savings + investments + emergency;
    if (total == 0) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 14,
        color: Colors.grey.withOpacity(0.15),
        child: Row(
          children: [
            if (needs > 0)
              Expanded(
                flex: needs.toInt(),
                child: Container(color: Colors.blueAccent),
              ),
            if (wants > 0)
              Expanded(
                flex: wants.toInt(),
                child: Container(color: Colors.amber),
              ),
            if (savings > 0)
              Expanded(
                flex: savings.toInt(),
                child: Container(color: Colors.green),
              ),
            if (investments > 0)
              Expanded(
                flex: investments.toInt(),
                child: Container(color: Colors.purple),
              ),
            if (emergency > 0)
              Expanded(
                flex: emergency.toInt(),
                child: Container(color: Colors.cyan),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitsLegendRow(String label, double pct, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        const Spacer(),
        Text('${pct.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildMiniBudgetTracker(BudgetsState budgetsState, CategoriesState categoriesState, Color textColor) {
    final budgets = budgetsState.budgets;
    final categories = categoriesState.categories;

    if (budgets.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(
          child: Text('No budgets created yet.', style: TextStyle(color: Colors.grey, fontSize: 13)),
        ),
      );
    }

    // Show top 3 budgets
    final displayBudgets = budgets.take(3).toList();

    return Column(
      children: displayBudgets.map((budget) {
        final cat = categories.firstWhere(
          (c) => c.id == budget.categoryId,
          orElse: () => const Category(id: -99, name: 'Other', icon: 'payments', color: 'E53935', isDefault: true),
        );

        final actualSpent = budgetsState.categorySpendings[budget.categoryId] ?? 0.0;
        final plannedLimit = budget.limitAmount;
        final percent = plannedLimit > 0 ? (actualSpent / plannedLimit).clamp(0.0, 1.0) : 0.0;
        final isOver = actualSpent > plannedLimit;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GlassmorphismCard(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(
                        isOver
                            ? 'Overspent'
                            : '${(percent * 100).toStringAsFixed(0)}% Used',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isOver ? Colors.redAccent : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 6,
                      backgroundColor: Colors.grey.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(isOver ? Colors.redAccent : Colors.blueAccent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopRecommendation(dynamic insight, Color textColor) {
    return GlassmorphismCard(
      child: ListTile(
        leading: const Icon(Icons.lightbulb_outline, color: Colors.amberAccent),
        title: Text(insight.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            insight.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () => setState(() => _selectedTab = 3), // Jump to Adjust tab where recommendations live
      ),
    );
  }
}
