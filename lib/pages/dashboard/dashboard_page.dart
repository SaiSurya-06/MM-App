import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/transactions_provider.dart';
import '../../providers/accounts_provider.dart';
import '../transactions/transaction_form.dart';
import '../../widgets/common/toast_notification.dart';
import '../../core/localization/app_localizations.dart';

// Sub-widgets
import 'widgets/summary_cards.dart';
import 'widgets/chart_section.dart';
import 'widgets/calendar_widget.dart';
import 'widgets/today_summary_card.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  final ScrollController _scrollController = ScrollController();
  bool _showFab = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        if (_showFab) {
          setState(() {
            _showFab = false;
          });
        }
      } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
        if (!_showFab) {
          setState(() {
            _showFab = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getLocaleGreeting(WidgetRef ref) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'good_morning'.tr(ref);
    } else if (hour < 17) {
      return 'good_afternoon'.tr(ref);
    } else {
      return 'good_evening'.tr(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final analyticsState = ref.watch(analyticsProvider);
    final transactionsState = ref.watch(transactionsProvider);

    final profile = authState.profile;
    final userName = profile?.name ?? 'User';
    final currency = profile?.preferredCurrency ?? 'USD';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: AnimatedOpacity(
        opacity: _showFab ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        child: AnimatedScale(
          scale: _showFab ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          child: FloatingActionButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const TransactionForm(),
              );
            },
            backgroundColor: const Color(0xFFE53935),
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Trigger state reload
            ref.read(accountsProvider.notifier).loadAccounts();
            ref.read(transactionsProvider.notifier).loadTransactions();
          },
          color: const Color(0xFFE53935),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 750),
            curve: Curves.easeOutQuart,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Branding Header Row
                  Row(
                    children: [
                      Image.asset(
                        'assets/logo.png',
                        height: 32,
                        width: 32,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'money_manager'.tr(ref),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  
                  // Welcome User Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getLocaleGreeting(ref) + ',',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.grey : const Color(0xFF6C6C7D),
                                fontFamily: 'Inter',
                              ),
                            ),
                            Text(
                              userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1A1A26),
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => GoRouter.of(context).push('/analytics'),
                            icon: Icon(Icons.trending_up, color: isDark ? Colors.white70 : Colors.black54),
                            tooltip: 'Trend Analytics',
                          ),
                          IconButton(
                            onPressed: () => GoRouter.of(context).push('/settings'),
                            icon: Icon(Icons.settings_outlined, color: isDark ? Colors.white70 : Colors.black54),
                            tooltip: 'Settings',
                          ),
                          IconButton(
                            onPressed: () {
                              ref.read(authProvider.notifier).logout();
                              ToastNotification.show(context, 'Logged out successfully.');
                            },
                            icon: Icon(Icons.logout, color: isDark ? Colors.white70 : Colors.black54),
                            tooltip: 'Log Out',
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 1. Summary Cards Section
                  SummaryCards(
                    totalBalance: analyticsState.totalBalance,
                    monthlyIncome: analyticsState.monthlyIncome,
                    monthlyExpenses: analyticsState.monthlyExpenses,
                    netSavings: analyticsState.netSavings,
                    healthScore: analyticsState.healthScore,
                    currency: currency,
                    isLoading: analyticsState.isLoading,
                  ),
                  
                  const SizedBox(height: 20),

                  // Today's Summary Section
                  if (!analyticsState.isLoading)
                    TodaySummaryCard(
                      todayIncome: analyticsState.todayIncome,
                      todayExpenses: analyticsState.todayExpenses,
                      majorExpenseCategory: analyticsState.todayMajorExpenseCategory,
                      majorExpenseAmount: analyticsState.todayMajorExpenseAmount,
                      majorIncomeCategory: analyticsState.todayMajorIncomeCategory,
                      majorIncomeAmount: analyticsState.todayMajorIncomeAmount,
                      currency: currency,
                    ),
                  
                  const SizedBox(height: 20),

                  // 2. Charts Section
                  ChartSection(
                    monthlyData: analyticsState.monthlyData,
                    categoryData: analyticsState.categoryData,
                    incomeCategoryData: analyticsState.incomeCategoryData,
                    personCategoryData: analyticsState.personCategoryData,
                    personIncomeCategoryData: analyticsState.personIncomeCategoryData,
                    netWorthData: analyticsState.netWorthData,
                    isLoading: analyticsState.isLoading,
                  ),
                  
                  const SizedBox(height: 20),

                  // 3. Interactive Calendar Section
                  CalendarWidget(
                    transactions: transactionsState.transactions,
                  ),
                  
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
