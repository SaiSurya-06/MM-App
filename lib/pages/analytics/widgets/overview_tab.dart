import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../widgets/common/glassmorphism_card.dart';
import '../../../providers/analytics_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/notifications/notification_service.dart';
import '../trend_analytics_page.dart';

class OverviewTab extends ConsumerStatefulWidget {
  const OverviewTab({super.key});

  @override
  ConsumerState<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<OverviewTab> {
  bool _showGuide = true;

  @override
  Widget build(BuildContext context) {
    final derivedValues = ref.watch(derivedAnalyticsProvider);
    final analyticsState = ref.watch(analyticsProvider);
    final authState = ref.watch(authProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = authState.profile?.preferredCurrency ?? 'USD';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGuideCard(isDark),
        
        // Health Score Card wrapped in Semantics
        Semantics(
          label: 'Financial Health Score Card',
          hint: 'Shows your financial health score out of 100 based on savings, budgets, stability, and anomalies.',
          child: GlassmorphismCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Ring gauge
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 76,
                      height: 76,
                      child: CircularProgressIndicator(
                        value: derivedValues.healthScore / 100.0,
                        strokeWidth: 8,
                        backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          derivedValues.healthScore > 75 
                              ? Colors.green 
                              : (derivedValues.healthScore > 45 ? Colors.orange : const Color(0xFFE53935)),
                        ),
                      ),
                    ),
                    Text(
                      derivedValues.healthScore.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Financial Health Score',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Based on Savings Rate, Budget Compliance (${derivedValues.budgetCompliance.toStringAsFixed(0)}%), DTI, Stability, and Anomalies.',
                        style: const TextStyle(color: Colors.grey, fontSize: 11, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Burn Rate Dashboard Grid wrapped in Semantics
        Semantics(
          label: 'Burn Rate and Runway Dashboard Grid',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Burn Rate & Runway',
                style: TextStyle(
                  fontSize: 10, 
                  color: isDark ? Colors.white38 : Colors.black38, 
                  fontWeight: FontWeight.bold, 
                  letterSpacing: 1.0
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildValueCard(
                      title: 'Daily Burn Rate',
                      value: '${CurrencyFormatter.format(derivedValues.dailyBurnRate, currency)}/day',
                      subtitle: 'Monthly spend speed',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildValueCard(
                      title: 'Projected Balance',
                      value: CurrencyFormatter.format(derivedValues.projectedMonthEndBalance, currency),
                      subtitle: 'Month-end estimate',
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildValueCard(
                      title: 'Estimated Runway',
                      value: derivedValues.runwayDays.isInfinite ? '∞' : '${derivedValues.runwayDays.toStringAsFixed(0)} Days',
                      subtitle: 'Runway if income stops',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildValueCard(
                      title: 'Safe to Spend Today',
                      value: CurrencyFormatter.format(derivedValues.safeToSpendToday, currency),
                      subtitle: 'Keep budget compliance',
                      isDark: isDark,
                      highlightColor: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Velocity speedometer / Momentum Card
        Semantics(
          label: 'Spending Velocity and Momentum Card',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Spending Velocity (Momentum)',
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
                            const Text(
                              'Spending Velocity',
                              style: TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${derivedValues.velocity >= 0 ? '+' : ''}${CurrencyFormatter.format(derivedValues.velocity, currency)}',
                              style: TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.bold,
                                color: derivedValues.velocity > 0 ? const Color(0xFFE53935) : Colors.green,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Acceleration',
                              style: TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${derivedValues.acceleration >= 0 ? '+' : ''}${CurrencyFormatter.format(derivedValues.acceleration, currency)}/mo²',
                              style: TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.bold,
                                color: derivedValues.acceleration > 0 ? const Color(0xFFE53935) : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, thickness: 0.5),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          derivedValues.acceleration > 0 ? Icons.speed : Icons.thumb_up_alt_outlined,
                          color: derivedValues.acceleration > 0 ? const Color(0xFFE53935) : Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            derivedValues.velocityTrendText,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Period Comparison (This Month vs Last Month) Card
        const SizedBox(height: 16),
        Semantics(
          label: 'Period Comparison Card',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Period Comparison',
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
                      'This Month vs Last Month',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    _buildCompareRow(
                      label: 'Income',
                      thisMonth: derivedValues.monthlyIncome,
                      lastMonth: derivedValues.runwayDays != double.infinity && derivedValues.runwayDays > 0 && analyticsState.monthlyData.length >= 2 
                          ? analyticsState.monthlyData[analyticsState.monthlyData.length - 2].income 
                          : 0.0,
                      currency: currency,
                      isDark: isDark,
                      isPositiveGood: true,
                    ),
                    const SizedBox(height: 10),
                    _buildCompareRow(
                      label: 'Expenses',
                      thisMonth: derivedValues.monthlyExpense,
                      lastMonth: derivedValues.runwayDays != double.infinity && derivedValues.runwayDays > 0 && analyticsState.monthlyData.length >= 2 
                          ? analyticsState.monthlyData[analyticsState.monthlyData.length - 2].expense 
                          : 0.0,
                      currency: currency,
                      isDark: isDark,
                      isPositiveGood: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // YoY Comparison Card
        const SizedBox(height: 16),
        Semantics(
          label: 'Year-Over-Year Comparison Card',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Year-Over-Year Comparison',
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
                    Text(
                      'Spending for ${DateFormat('MMMM').format(DateTime.now())}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    _buildYoYRow(
                      label: '${DateTime.now().year}',
                      amount: derivedValues.spendThisYearMonth,
                      maxAmount: [derivedValues.spendThisYearMonth, derivedValues.spendLastYearMonth, derivedValues.spendTwoYearsAgoMonth].reduce((a, b) => a > b ? a : b),
                      currency: currency,
                      isDark: isDark,
                      color: const Color(0xFFE53935),
                    ),
                    const SizedBox(height: 8),
                    _buildYoYRow(
                      label: '${DateTime.now().year - 1}',
                      amount: derivedValues.spendLastYearMonth,
                      maxAmount: [derivedValues.spendThisYearMonth, derivedValues.spendLastYearMonth, derivedValues.spendTwoYearsAgoMonth].reduce((a, b) => a > b ? a : b),
                      currency: currency,
                      isDark: isDark,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(height: 8),
                    _buildYoYRow(
                      label: '${DateTime.now().year - 2}',
                      amount: derivedValues.spendTwoYearsAgoMonth,
                      maxAmount: [derivedValues.spendThisYearMonth, derivedValues.spendLastYearMonth, derivedValues.spendTwoYearsAgoMonth].reduce((a, b) => a > b ? a : b),
                      currency: currency,
                      isDark: isDark,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // AI Advisory Recommendations Card List
        if (analyticsState.aiRecommendations.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'AI Advisory Recommendations',
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white38 : Colors.black38,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          ...analyticsState.aiRecommendations.map((rec) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: GlassmorphismCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      rec.type == 'warning' ? Icons.warning_amber_rounded : Icons.lightbulb_outline,
                      color: rec.type == 'warning' ? Colors.redAccent : Colors.orangeAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rec.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            rec.description,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.3,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_alert, size: 18, color: Colors.blueAccent),
                      onPressed: () async {
                        await NotificationService.instance.showCustomAlert(
                          rec.title,
                          rec.description,
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Alert Reminder Created!')),
                        );
                      },
                      tooltip: 'Set Notification Reminder',
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildGuideCard(bool isDark) {
    if (!_showGuide) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: InkWell(
          onTap: () => setState(() => _showGuide = true),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.help_outline, size: 16, color: Color(0xFFE53935)),
                const SizedBox(width: 6),
                Text(
                  "Show Layman's Guide & Explanation",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GlassmorphismCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "💡 Guide: How does this work?",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF1A1A26),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() => _showGuide = false),
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildGuideItem(
              title: "🏆 Financial Health Score",
              description: "A single score (0-100) representing your overall financial safety. It grades you based on how much you save (Savings Rate), staying under budget (Compliance), debt level (Debt-to-Income), and stability of your income.",
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _buildGuideItem(
              title: "🔥 Daily Burn Rate",
              description: "The average amount you spend each day. Think of it as how fast your cash is \"burning\" away.",
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _buildGuideItem(
              title: "✈️ Cash Runway",
              description: "How many days your current money will last if you keep spending at your current daily rate and had no new income.",
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _buildGuideItem(
              title: "🛡️ Safe-to-Spend Today",
              description: "An estimate of what you can spend today without exceeding your remaining budget limits for the month. It recalculates daily.",
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _buildGuideItem(
              title: "🎲 Projections & Simulations (Projections Tab)",
              description: "To estimate if you will hit your savings goals, the app runs 1,000 simulations (Monte Carlo paths) based on your past spending habits. It shows the mathematical probability of hitting your target on time.",
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideItem({required String title, required String description, required bool isDark}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          description,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey[400] : const Color(0xFF555566),
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildValueCard({
    required String title,
    required String value,
    required String subtitle,
    required bool isDark,
    Color? highlightColor,
  }) {
    return GlassmorphismCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black54),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: highlightColor ?? (isDark ? Colors.white : const Color(0xFF1A1A26)),
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 9, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCompareRow({
    required String label,
    required double thisMonth,
    required double lastMonth,
    required String currency,
    required bool isDark,
    required bool isPositiveGood,
  }) {
    final diff = thisMonth - lastMonth;
    final pct = lastMonth > 0 ? (diff / lastMonth * 100) : 0.0;
    final isIncrease = diff > 0;
    final isGood = (isIncrease && isPositiveGood) || (!isIncrease && !isPositiveGood);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            Row(
              children: [
                Text(
                  '${isIncrease ? '+' : ''}${pct.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: diff == 0 ? Colors.grey : (isGood ? Colors.green : const Color(0xFFE53935)),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  isIncrease ? Icons.arrow_upward : (diff == 0 ? Icons.remove : Icons.arrow_downward),
                  color: diff == 0 ? Colors.grey : (isGood ? Colors.green : const Color(0xFFE53935)),
                  size: 14,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('This Month', style: TextStyle(color: Colors.grey[400], fontSize: 9)),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.format(thisMonth, currency),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Inter'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Last Month', style: TextStyle(color: Colors.grey[400], fontSize: 9)),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.format(lastMonth, currency),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Inter'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildYoYRow({
    required String label,
    required double amount,
    required double maxAmount,
    required String currency,
    required bool isDark,
    required Color color,
  }) {
    final pct = maxAmount > 0 ? (amount / maxAmount).clamp(0.02, 1.0) : 0.02;
    return Row(
      children: [
        SizedBox(width: 40, child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500))),
        Expanded(
          child: Container(
            height: 8,
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              widthFactor: pct,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 70,
          child: Text(
            CurrencyFormatter.format(amount, currency),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
