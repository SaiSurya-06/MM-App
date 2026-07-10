import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/planning_state_provider.dart';
import '../../providers/money_intelligence_provider.dart';
import 'widgets/planning_wizard.dart';
import 'widgets/plan_tab.dart';
import 'widgets/track_tab.dart';
import 'widgets/adjust_tab.dart';
import 'widgets/review_tab.dart';

class BudgetsPage extends ConsumerStatefulWidget {
  const BudgetsPage({super.key});

  @override
  ConsumerState<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends ConsumerState<BudgetsPage> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final planningState = ref.watch(planningStateProvider);
    final intelState = ref.watch(moneyIntelligenceProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F11) : const Color(0xFFF3F4F6);
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);

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

    // 3. Wizard Flow: If no monthly plan completed
    if (!planningState.isCompleted) {
      return PlanningWizard(
        onCompleted: () {
          ref.read(planningStateProvider.notifier).loadPlanningMeta();
        },
      );
    }

    // 4. Main Workspace Layout with 4 Tabs
    final List<Widget> tabs = [
      const PlanTab(),
      const TrackTab(),
      const AdjustTab(),
      const ReviewTab(),
    ];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Good Evening Surya 👋',
          style: TextStyle(color: textColor, fontFamily: 'Inter', fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(planningStateProvider.notifier).loadPlanningMeta();
              ref.read(planningStateProvider.notifier).loadWeeklyCheckins();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: IndexedStack(
            index: _selectedTab,
            children: tabs,
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (index) => setState(() => _selectedTab = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        backgroundColor: isDark ? const Color(0xFF1E1E24) : Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Plan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: 'Track',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tune),
            label: 'Adjust',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.rate_review),
            label: 'Review',
          ),
        ],
      ),
    );
  }
}
