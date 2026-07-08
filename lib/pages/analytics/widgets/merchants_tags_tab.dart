import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/transaction.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../widgets/common/glassmorphism_card.dart';
import '../../../providers/auth_provider.dart';
import '../trend_analytics_page.dart';

class MerchantsTagsTab extends ConsumerStatefulWidget {
  const MerchantsTagsTab({Key? key}) : super(key: key);

  @override
  ConsumerState<MerchantsTagsTab> createState() => _MerchantsTagsTabState();
}

class _MerchantsTagsTabState extends ConsumerState<MerchantsTagsTab> {
  bool _showAllMerchants = false;
  bool _showAllTags = false;

  String _normalizeMerchant(String title) {
    String t = title.toLowerCase().trim();
    if (t.contains('swiggy')) return 'swiggy';
    if (t.contains('zomato')) return 'zomato';
    if (t.contains('uber')) return 'uber';
    if (t.contains('netflix')) return 'netflix';
    if (t.contains('amazon')) return 'amazon';
    if (t.contains('spotify')) return 'spotify';
    if (t.contains('walmart')) return 'walmart';
    
    // Strip trailing numbers/order details
    t = t.replaceAll(RegExp(r'\s*\d+.*'), '');
    return t;
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  void _showMerchantTransactionsDialog(BuildContext context, String merchantKey, List<Transaction> allTransactions, String currency, bool isDark) {
    final merchantTxs = allTransactions.where((tx) => _normalizeMerchant(tx.title) == merchantKey && tx.type == 'expense').toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF161625) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Transactions: ${_capitalize(merchantKey)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 350,
            child: merchantTxs.isEmpty
                ? const Center(child: Text('No transactions found.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: merchantTxs.length,
                    itemBuilder: (context, index) {
                      final tx = merchantTxs[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text(
                          DateFormat('MMM dd, yyyy').format(tx.date),
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        trailing: Text(
                          '-${CurrencyFormatter.format(tx.amount, currency)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFE53935)),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  void _showTagTransactionsDialog(BuildContext context, String tagKey, List<Transaction> allTransactions, String currency, bool isDark) {
    final tagTxs = allTransactions.where((tx) {
      if (tx.type != 'expense' || tx.tags.isEmpty) return false;
      return tx.tags.split(RegExp(r'[;,]')).map((t) => t.trim().toLowerCase()).contains(tagKey);
    }).toList()..sort((a, b) => b.date.compareTo(a.date));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF161625) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Transactions: #$tagKey',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 350,
            child: tagTxs.isEmpty
                ? const Center(child: Text('No transactions found.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: tagTxs.length,
                    itemBuilder: (context, index) {
                      final tx = tagTxs[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text(
                          DateFormat('MMM dd, yyyy').format(tx.date),
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        trailing: Text(
                          '-${CurrencyFormatter.format(tx.amount, currency)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFE53935)),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final derivedValues = ref.watch(derivedAnalyticsProvider);
    final authState = ref.watch(authProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = authState.profile?.preferredCurrency ?? 'USD';
    final transactions = derivedValues.filteredTransactions;

    // 1. Fuzzy group merchants
    final Map<String, double> merchantSpends = {};
    for (var tx in transactions) {
      if (tx.type == 'expense') {
        final norm = _normalizeMerchant(tx.title);
        merchantSpends[norm] = (merchantSpends[norm] ?? 0.0) + tx.amount;
      }
    }
    final sortedMerchants = merchantSpends.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 2. Group tags spent with robust parsing
    final Map<String, double> tagSpends = {};
    for (var tx in transactions) {
      if (tx.type == 'expense' && tx.tags.isNotEmpty) {
        final parts = tx.tags.split(RegExp(r'[;,]'));
        for (var part in parts) {
          final t = part.trim().toLowerCase();
          if (t.isNotEmpty) {
            tagSpends[t] = (tagSpends[t] ?? 0.0) + tx.amount;
          }
        }
      }
    }
    final sortedTags = tagSpends.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final merchantLimit = _showAllMerchants ? sortedMerchants.length : 5;
    final tagLimit = _showAllTags ? sortedTags.length : 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Merchants Analysis
        Text(
          'Top Merchants / Payees',
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
            children: [
              if (sortedMerchants.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('No merchant records found.', style: TextStyle(color: Colors.grey))),
                )
              else ...[
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: math.min(sortedMerchants.length, merchantLimit),
                  itemBuilder: (context, index) {
                    final item = sortedMerchants[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _showMerchantTransactionsDialog(context, item.key, transactions, currency, isDark),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.storefront_outlined, size: 14, color: Colors.orange),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _capitalize(item.key),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    CurrencyFormatter.format(item.value, currency),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Inter'),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (sortedMerchants.length > 5) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFFE53935)),
                    onPressed: () => setState(() => _showAllMerchants = !_showAllMerchants),
                    icon: Icon(_showAllMerchants ? Icons.expand_less : Icons.expand_more, size: 16),
                    label: Text(_showAllMerchants ? 'Show Less' : 'Show More'),
                  ),
                ],
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Tag Volume
        Text(
          'Spending by Tags',
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
            children: [
              if (sortedTags.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('No tagged transactions found.', style: TextStyle(color: Colors.grey))),
                )
              else ...[
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: math.min(sortedTags.length, tagLimit),
                  itemBuilder: (context, index) {
                    final item = sortedTags[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _showTagTransactionsDialog(context, item.key, transactions, currency, isDark),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.label_outline, size: 14, color: Colors.blueAccent),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '#${item.key}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueAccent),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    CurrencyFormatter.format(item.value, currency),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Inter'),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (sortedTags.length > 5) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFFE53935)),
                    onPressed: () => setState(() => _showAllTags = !_showAllTags),
                    icon: Icon(_showAllTags ? Icons.expand_less : Icons.expand_more, size: 16),
                    label: Text(_showAllTags ? 'Show Less' : 'Show More'),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}
