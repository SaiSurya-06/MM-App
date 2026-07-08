import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_actions/quick_actions.dart';
import '../common/premium_background.dart';
import '../../pages/transactions/transaction_form.dart';
import '../../providers/budgets_provider.dart';
import '../../providers/partner_sync_provider.dart';

class ScaffoldWithBottomNavBar extends ConsumerStatefulWidget {
  final Widget child;
  const ScaffoldWithBottomNavBar({super.key, required this.child});

  @override
  ConsumerState<ScaffoldWithBottomNavBar> createState() => _ScaffoldWithBottomNavBarState();
}

class _ScaffoldWithBottomNavBarState extends ConsumerState<ScaffoldWithBottomNavBar> {
  static const _channel = MethodChannel('com.example.money_manager/widget_actions');

  @override
  void initState() {
    super.initState();
    const QuickActions quickActions = QuickActions();
    quickActions.initialize((String shortcutType) {
      if (shortcutType == 'action_add_transaction') {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _openTransactionForm();
          }
        });
      }
    });
    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
        type: 'action_add_transaction',
        localizedTitle: 'Add Transaction',
        icon: 'ic_launcher',
      ),
    ]);

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onWidgetAction') {
        final action = call.arguments as String?;
        if (action != null) {
          _handleWidgetAction(action);
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialWidgetAction();
    });
  }

  Future<void> _checkInitialWidgetAction() async {
    try {
      final action = await _channel.invokeMethod<String>('getWidgetAction');
      if (action != null) {
        _handleWidgetAction(action);
      }
    } catch (_) {}
  }

  void _handleWidgetAction(String action) {
    String? type;
    if (action == 'add_expense') type = 'expense';
    if (action == 'add_income') type = 'income';
    if (action == 'add_transfer') type = 'transfer';
    
    if (type != null) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          _openTransactionForm(initialType: type);
        }
      });
    }
  }

  void _openTransactionForm({String? initialType}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionForm(initialType: initialType),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/accounts')) return 2;
    if (location.startsWith('/budgets')) return 3;
    if (location.startsWith('/partners')) return 4;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/dashboard');
        break;
      case 1:
        GoRouter.of(context).go('/transactions');
        break;
      case 2:
        GoRouter.of(context).go('/accounts');
        break;
      case 3:
        GoRouter.of(context).go('/budgets');
        break;
      case 4:
        GoRouter.of(context).go('/partners');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final budgetsState = ref.watch(budgetsProvider);
    final partnerSyncState = ref.watch(partnerSyncProvider);

    // Check if any budget is overspent
    bool isAnyBudgetOverspent = false;
    for (var b in budgetsState.budgets) {
      final spent = budgetsState.categorySpendings[b.categoryId] ?? 0.0;
      final limit = b.limitAmount;
      if (spent > limit) {
        isAnyBudgetOverspent = true;
        break;
      }
    }

    // Check if any sync conflicts exist
    bool isAnySyncConflict = partnerSyncState.conflicts.isNotEmpty;
    
    return Scaffold(
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! < -500) {
            // Swipe left -> Next tab
            final nextIndex = (selectedIndex + 1) % 5;
            _onItemTapped(nextIndex, context);
          } else if (details.primaryVelocity! > 500) {
            // Swipe right -> Prev tab
            final prevIndex = (selectedIndex - 1 + 5) % 5;
            _onItemTapped(prevIndex, context);
          }
        },
        behavior: HitTestBehavior.translucent,
        child: PremiumBackground(child: widget.child),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Ledger',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'Accounts',
            ),
            BottomNavigationBarItem(
              icon: isAnyBudgetOverspent
                  ? const Badge(
                      label: Text('!'),
                      child: Icon(Icons.pie_chart_outline_outlined),
                    )
                  : const Icon(Icons.pie_chart_outline_outlined),
              activeIcon: isAnyBudgetOverspent
                  ? const Badge(
                      label: Text('!'),
                      child: Icon(Icons.pie_chart),
                    )
                  : const Icon(Icons.pie_chart),
              label: 'Budgets',
            ),
            BottomNavigationBarItem(
              icon: isAnySyncConflict
                  ? const Badge(
                      label: Text('!'),
                      child: Icon(Icons.grid_view_rounded),
                    )
                  : const Icon(Icons.grid_view_rounded),
              activeIcon: isAnySyncConflict
                  ? const Badge(
                      label: Text('!'),
                      child: Icon(Icons.grid_view_rounded),
                    )
                  : const Icon(Icons.grid_view_rounded),
              label: 'More',
            ),
          ],
          currentIndex: selectedIndex,
          onTap: (index) => _onItemTapped(index, context),
        ),
      ),
    );
  }
}
