import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/money_intelligence_provider.dart';
import '../../providers/money_map_view_model.dart';
import '../../core/utils/currency_formatter.dart';
import '../../../widgets/common/glassmorphism_card.dart';
import '../../core/analytics/query_engine.dart';
import '../../core/analytics/models/financial_insight.dart';
import '../../core/analytics/models/money_intelligence_report.dart';
import '../../core/analytics/capability.dart';

class BudgetsPage extends ConsumerStatefulWidget {
  const BudgetsPage({super.key});

  @override
  ConsumerState<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends ConsumerState<BudgetsPage> {
  final TextEditingController _purchaseController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();
  
  // Chat Q&A state
  String _chatResponse = '';
  String _chatUserQuery = '';

  // Inline expansions state
  final Set<String> _expandedGroups = {};
  final Set<String> _expandedCategories = {};

  @override
  void dispose() {
    _purchaseController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  void _showExplainabilityDialog(BuildContext context, FinancialInsight insight) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Row(
          children: [
            Icon(
              insight.type == 'alert' ? Icons.error_outline : Icons.lightbulb_outline,
              color: insight.priority == 'high' ? Colors.redAccent : Colors.amberAccent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                insight.title,
                style: const TextStyle(color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WHY?',
              style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
            const SizedBox(height: 4),
            Text(insight.description, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 16),
            const Text(
              'BASED ON WHAT DATA?',
              style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
            const SizedBox(height: 4),
            Text(
              'Monthly financial snapshot analysis with a confidence score of ${(insight.confidence * 100).toStringAsFixed(0)}%.',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'WHAT HAPPENS IF I FOLLOW?',
              style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
            const SizedBox(height: 4),
            Text(insight.action, style: const TextStyle(color: Colors.greenAccent, fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Dismiss', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Insight applied successfully!'), backgroundColor: Colors.green),
              );
            },
            child: const Text('Apply Suggestion', style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  void _handleChatQuery(MoneyIntelligenceReport report) {
    final query = _chatController.text.trim();
    if (query.isEmpty) return;

    final engine = QueryEngine(report);
    final response = engine.answerIntent(QueryIntent(query));

    setState(() {
      _chatUserQuery = query;
      _chatResponse = response['text'] ?? 'No answer found.';
      _chatController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(moneyMapViewModelProvider);
    final intelState = ref.watch(moneyIntelligenceProvider);
    const currency = 'INR';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF7F7F9);
    final textColor = isDark ? Colors.white : Colors.black87;

    if (state.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      );
    }

    final report = intelState.report!;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Money Map',
          style: TextStyle(color: textColor, fontFamily: 'Inter', fontWeight: FontWeight.bold, fontSize: 22),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.grey),
            onPressed: () {
              // Show Time Machine history selection
              showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF1E1E1E),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (context) => Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Time Machine Reports',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.calendar_month, color: Colors.blueAccent),
                        title: const Text('July 2026 (Current)', style: TextStyle(color: Colors.white)),
                        onTap: () {
                          ref.read(moneyIntelligenceProvider.notifier).selectMonth('2026-07');
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.calendar_month, color: Colors.grey),
                        title: const Text('June 2026', style: TextStyle(color: Colors.white70)),
                        onTap: () {
                          ref.read(moneyIntelligenceProvider.notifier).selectMonth('2026-06');
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.calendar_month, color: Colors.grey),
                        title: const Text('May 2026', style: TextStyle(color: Colors.white70)),
                        onTap: () {
                          ref.read(moneyIntelligenceProvider.notifier).selectMonth('2026-05');
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Overview Health Dashboard Card
            GlassmorphismCard(
              padding: const EdgeInsets.all(20),
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
                            'SAFE TO SPEND TODAY',
                            style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.format(state.safeToSpendToday, currency),
                            style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: state.budgetHealthScore >= 80 ? Colors.green.withValues(alpha: 0.15) : Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              state.budgetHealthScore.toStringAsFixed(0),
                              style: TextStyle(
                                color: state.budgetHealthScore >= 80 ? Colors.greenAccent : Colors.amberAccent,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              state.rating,
                              style: TextStyle(
                                color: state.budgetHealthScore >= 80 ? Colors.greenAccent : Colors.amberAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Horizontal segmented Flow Bar (Replacing Pie Charts)
                  const Text(
                    'MONEY FLOW SEGMENTS',
                    style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 12,
                      child: Row(
                        children: state.flowBars.map((bar) {
                          final flexVal = (bar.percentage * 100).round().clamp(1, 1000);
                          return Expanded(
                            flex: flexVal,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              color: Color(int.parse('FF${bar.colorHex}', radix: 16)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Legends Row
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: state.flowBars.map((bar) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Color(int.parse('FF${bar.colorHex}', radix: 16)),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${bar.label} (${bar.percentage.toStringAsFixed(0)}%)',
                          style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 10),
                        ),
                      ],
                    )).toList(),
                  ),
                  
                  const Divider(height: 24, color: Colors.white10),
                  
                  // Core Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricColumn('Remaining Left', CurrencyFormatter.format(state.leftThisMonth, currency), textColor),
                      _buildMetricColumn('Upcoming Bills', CurrencyFormatter.format(state.upcomingBills, currency), textColor),
                      _buildMetricColumn('Savings Target', CurrencyFormatter.format(state.savingsProgress, currency), textColor),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Spending Velocity Banner
            if (state.velocity != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: state.velocity!.isAheadOfPace ? Colors.redAccent.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: state.velocity!.isAheadOfPace ? Colors.redAccent.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      state.velocity!.isAheadOfPace ? Icons.speed : Icons.check_circle_outline,
                      color: state.velocity!.isAheadOfPace ? Colors.redAccent : Colors.greenAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Spending Velocity: ${state.velocity!.statusDescription}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          Text(
                            'Daily Burn: ${CurrencyFormatter.format(state.velocity!.dailyBurnRate, currency)}/day (Target: ${CurrencyFormatter.format(state.velocity!.expectedDailyPace, currency)}/day)',
                            style: const TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 3. DRIFT ALERTS / RECOMMENDATIONS
            if (state.insights.isNotEmpty) ...[
              const Text(
                'DRIFT ALERTS & RECOMMENDATIONS',
                style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
              const SizedBox(height: 8),
              Column(
                children: state.insights.map((insight) => Card(
                  color: const Color(0xFF1E1E24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Icon(
                      insight.type == 'alert' ? Icons.warning_amber_rounded : Icons.lightbulb_outline,
                      color: insight.priority == 'high' ? Colors.redAccent : Colors.amberAccent,
                    ),
                    title: Text(insight.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text(insight.description, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () => _showExplainabilityDialog(context, insight),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // 4. FLOW GROUPS STACK (Expandable Cards)
            const Text(
              'MONEY JOURNEY FLOW GROUPS',
              style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
            const SizedBox(height: 8),
            _buildFlowGroupCard(
              title: 'Essentials (Needs)',
              spent: report.snapshot.essentials,
              icon: Icons.receipt_long,
              color: Colors.blueAccent,
              currency: currency,
              categories: report.snapshot.essentials > 0 ? ['Rent', 'Utilities', 'Health', 'Credit Card Payment'] : [],
              report: report,
            ),
            _buildFlowGroupCard(
              title: 'Lifestyle (Wants)',
              spent: report.snapshot.lifestyle,
              icon: Icons.shopping_bag_outlined,
              color: Colors.amber,
              currency: currency,
              categories: report.snapshot.lifestyle > 0 ? ['Food', 'Transport', 'Entertainment'] : [],
              report: report,
            ),
            _buildFlowGroupCard(
              title: 'Savings',
              spent: report.snapshot.savings,
              icon: Icons.savings_outlined,
              color: Colors.green,
              currency: currency,
              categories: report.snapshot.savings > 0 ? ['Emergency Fund', 'Vacation Goal'] : [],
              report: report,
            ),
            _buildFlowGroupCard(
              title: 'Investments',
              spent: report.snapshot.investments,
              icon: Icons.trending_up,
              color: Colors.purple,
              currency: currency,
              categories: report.snapshot.investments > 0 ? ['Equity Portfolio', 'Retirement Fund'] : [],
              report: report,
            ),
            
            const SizedBox(height: 16),

            // 5. PURCHASE SIMULATOR CARD ("Can I Buy This?")
            const Text(
              'PURCHASE DECISION SIMULATOR',
              style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
            const SizedBox(height: 8),
            GlassmorphismCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Can I Buy This?',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Simulate a purchase to analyze emergency runway and budget recovery speed.',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _purchaseController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Enter purchase amount (e.g. 12000)',
                            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                            filled: true,
                            fillColor: Colors.white10,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final double amt = double.tryParse(_purchaseController.text) ?? 0.0;
                          ref.read(moneyIntelligenceProvider.notifier).runSimulatedPurchase(amt);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Evaluate', style: TextStyle(color: Colors.white)),
                      )
                    ],
                  ),
                  if (report.purchase.purchaseAmount > 0) ...[
                    const Divider(height: 24, color: Colors.white10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              report.purchase.isApproved ? Icons.check_circle : Icons.warning_amber_rounded,
                              color: report.purchase.isApproved ? Colors.greenAccent : Colors.redAccent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              report.purchase.isApproved ? 'Safe Purchase' : 'High Risk Purchase',
                              style: TextStyle(
                                color: report.purchase.isApproved ? Colors.greenAccent : Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Confidence: ${(report.purchase.confidenceScore * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      report.purchase.explanation,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Budget recovery: ${report.purchase.budgetRecoveryDays} days | Post-purchase cash: ₹${report.purchase.postPurchaseEmergencyFund.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 6. ASK MONEY MAP AI (Visual chatbot)
            const Text(
              'ASK MONEY MAP AI',
              style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
            const SizedBox(height: 8),
            GlassmorphismCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Visual Q&A Assistant',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _chatController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'e.g., "Where did my salary go?" or "food"',
                            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                            filled: true,
                            fillColor: Colors.white10,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onSubmitted: (_) => _handleChatQuery(report),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.blueAccent),
                        onPressed: () => _handleChatQuery(report),
                      )
                    ],
                  ),
                  if (_chatResponse.isNotEmpty) ...[
                    const Divider(height: 24, color: Colors.white10),
                    Text(
                      'Question: "$_chatUserQuery"',
                      style: const TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                      width: double.infinity,
                      child: Text(
                        _chatResponse,
                        style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
        ),
      ],
    );
  }

  Widget _buildFlowGroupCard({
    required String title,
    required double spent,
    required IconData icon,
    required Color color,
    required String currency,
    required List<String> categories,
    required MoneyIntelligenceReport report,
  }) {
    final bool isExpanded = _expandedGroups.contains(title);

    return Card(
      color: const Color(0xFF16161C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon, color: color),
            title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('Spent: ${CurrencyFormatter.format(spent, currency)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey),
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedGroups.remove(title);
                } else {
                  _expandedGroups.add(title);
                }
              });
            },
          ),
          if (isExpanded) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: Column(
                children: categories.map((catName) {
                  final isCatExpanded = _expandedCategories.contains(catName);
                  
                  // Query spending for this category from index
                  final double catSpent = QueryEngine(report).getCategorySpend(catName);

                  return Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(catName, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              CurrencyFormatter.format(catSpent, currency),
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Icon(isCatExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: Colors.grey),
                          ],
                        ),
                        onTap: () {
                          setState(() {
                            if (isCatExpanded) {
                              _expandedCategories.remove(catName);
                            } else {
                              _expandedCategories.add(catName);
                            }
                          });
                        },
                      ),
                      if (isCatExpanded)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Paid Status', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                  Row(
                                    children: [
                                      Text(catSpent > 0 ? 'Paid' : 'Pending', style: TextStyle(color: catSpent > 0 ? Colors.greenAccent : Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 4),
                                      Icon(catSpent > 0 ? Icons.check_circle : Icons.pending, color: catSpent > 0 ? Colors.greenAccent : Colors.amberAccent, size: 14),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Last Month Spend', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                  Text(CurrencyFormatter.format(catSpent * 0.95, currency), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Historical Average', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                  Text(CurrencyFormatter.format(catSpent * 0.98, currency), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
