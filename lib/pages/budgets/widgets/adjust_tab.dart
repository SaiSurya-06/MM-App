import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/budgets_provider.dart';
import '../../../providers/categories_provider.dart';
import '../../../providers/money_intelligence_provider.dart';
import '../../../widgets/common/glassmorphism_card.dart';
import '../../../core/analytics/models/financial_insight.dart';
import '../../../models/category.dart';

class AdjustTab extends ConsumerStatefulWidget {
  const AdjustTab({super.key});

  @override
  ConsumerState<AdjustTab> createState() => _AdjustTabState();
}

class _AdjustTabState extends ConsumerState<AdjustTab> {
  int? _sourceCategoryId;
  int? _destCategoryId;
  final _amountController = TextEditingController();
  final _purchaseController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _purchaseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final budgetsState = ref.watch(budgetsProvider);
    final categoriesState = ref.watch(categoriesProvider);
    final intelState = ref.watch(moneyIntelligenceProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    if (budgetsState.isLoading || categoriesState.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
    }

    final activeBudgets = budgetsState.budgets;
    final categories = categoriesState.categories;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Move Budget / Shifting Section
          Text('Reallocate Budget', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 12),
          
          GlassmorphismCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Shifting money from one category to another helps you manage unexpected expenses.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  
                  // Source Dropdown
                  DropdownButtonFormField<int>(
                    value: _sourceCategoryId,
                    style: TextStyle(color: textColor),
                    decoration: const InputDecoration(labelText: 'From Category'),
                    items: activeBudgets.map((b) {
                      final cat = categories.firstWhere((c) => c.id == b.categoryId, orElse: () => const Category(id: -99, name: 'Unknown', icon: '', color: '', isDefault: false));
                      return DropdownMenuItem<int>(
                        value: b.categoryId,
                        child: Text('${cat.name} (Max: ₹${b.limitAmount.toStringAsFixed(0)})'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _sourceCategoryId = val),
                  ),
                  const SizedBox(height: 12),

                  // Destination Dropdown
                  DropdownButtonFormField<int>(
                    value: _destCategoryId,
                    style: TextStyle(color: textColor),
                    decoration: const InputDecoration(labelText: 'To Category'),
                    items: activeBudgets.map((b) {
                      final cat = categories.firstWhere((c) => c.id == b.categoryId, orElse: () => const Category(id: -99, name: 'Unknown', icon: '', color: '', isDefault: false));
                      return DropdownMenuItem<int>(
                        value: b.categoryId,
                        child: Text(cat.name),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _destCategoryId = val),
                  ),
                  const SizedBox(height: 16),

                  // Amount textfield
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: textColor),
                    decoration: const InputDecoration(
                      labelText: 'Reallocation Amount',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: _sourceCategoryId != null && _destCategoryId != null && _amountController.text.isNotEmpty
                        ? () async {
                            final double reallocAmt = double.tryParse(_amountController.text) ?? 0.0;
                            if (reallocAmt <= 0) return;

                            final sourceBudget = activeBudgets.firstWhere((b) => b.categoryId == _sourceCategoryId);
                            final destBudget = activeBudgets.firstWhere((b) => b.categoryId == _destCategoryId);

                            if (sourceBudget.limitAmount < reallocAmt) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Source category has insufficient funds!'), backgroundColor: Colors.redAccent),
                              );
                              return;
                            }

                            // Perform updates
                            await ref.read(budgetsProvider.notifier).setBudget(_sourceCategoryId!, sourceBudget.limitAmount - reallocAmt);
                            await ref.read(budgetsProvider.notifier).setBudget(_destCategoryId!, destBudget.limitAmount + reallocAmt);

                            _amountController.clear();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Budget reallocated successfully!'), backgroundColor: Colors.green),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                    child: const Text('Confirm Shift'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 2. Can I Buy This Simulator Section
          Text('Can I Buy This? (Advisor Simulator)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 12),
          
          GlassmorphismCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _purchaseController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: textColor),
                    decoration: const InputDecoration(
                      labelText: 'Enter Simulated Purchase Amount',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      final val = double.tryParse(_purchaseController.text) ?? 0.0;
                      ref.read(moneyIntelligenceProvider.notifier).runSimulatedPurchase(val);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, foregroundColor: Colors.black),
                    child: const Text('Evaluate Purchase'),
                  ),
                  
                  if (intelState.report != null && intelState.simulatedPurchaseAmount > 0) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      intelState.report!.purchase.isApproved ? '✔ PURCHASE APPROVED' : '⚠ PURCHASE NOT RECOMMENDED',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: intelState.report!.purchase.isApproved ? Colors.greenAccent : Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      intelState.report!.purchase.explanation,
                      style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Remaining Runway Fund:', style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 12)),
                        Text('₹${intelState.report!.purchase.postPurchaseEmergencyFund.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 3. AI Suggestions / Recommendations
          if (intelState.report != null && intelState.report!.insights.isNotEmpty) ...[
            Text('AI Insights & Suggestions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 12),
            
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: intelState.report!.insights.length,
              itemBuilder: (context, index) {
                final insight = intelState.report!.insights[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: GlassmorphismCard(
                    child: ListTile(
                      leading: Icon(
                        insight.type == 'alert' ? Icons.warning_amber : Icons.lightbulb_outline,
                        color: insight.priority == 'high' ? Colors.redAccent : Colors.amberAccent,
                      ),
                      title: Text(insight.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(insight.description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                      onTap: () => _showExplainabilityDialog(context, insight),
                    ),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
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
}
