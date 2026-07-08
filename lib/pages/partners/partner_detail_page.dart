import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/account.dart';
import '../../models/transaction.dart';
import '../../providers/partner_sync_provider.dart';
import '../../widgets/common/glassmorphism_card.dart';
import '../../core/utils/currency_formatter.dart';
import '../transactions/transaction_list_item.dart';

class PartnerDetailPage extends ConsumerStatefulWidget {
  final Account account;

  const PartnerDetailPage({super.key, required this.account});

  @override
  ConsumerState<PartnerDetailPage> createState() => _PartnerDetailPageState();
}

class _PartnerDetailPageState extends ConsumerState<PartnerDetailPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showTransactionDetails(PartnerTransaction tx, String currency) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Amount', '${tx.type == 'income' ? '+' : '-'}${CurrencyFormatter.format(tx.amount, currency)}', valueColor: tx.type == 'income' ? Colors.green : const Color(0xFFE53935)),
            _buildDetailRow('Account', tx.accountName),
            _buildDetailRow('Category', tx.categoryName),
            _buildDetailRow('Date', tx.date.toIso8601String().substring(0, 10)),
            if (tx.note != null && tx.note!.isNotEmpty)
              _buildDetailRow('Note', tx.note!),
            if (tx.recurrence != 'none')
              _buildDetailRow('Recurrence', tx.recurrence),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor, fontWeight: valueColor != null ? FontWeight.bold : null),
            ),
          ),
        ],
      ),
    );
  }

  void _showConflictResolverDialog(BuildContext context, PartnerSyncState syncState, ConflictRecord conflict) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setState) {
            final localBal = conflict.localData['balance'] as double? ?? 0.0;
            final partnerBal = conflict.partnerData['balance'] as double? ?? 0.0;
            final localLimit = conflict.localData['limit_amount'] as double?;
            final partnerLimit = conflict.partnerData['limit_amount'] as double?;
            
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              title: Text(
                'Resolve Conflict: ${conflict.name}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Inter'),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This account has different values on both devices. Choose which version to keep:',
                    style: TextStyle(fontSize: 13, height: 1.4, fontFamily: 'Inter'),
                  ),
                  const SizedBox(height: 20),
                  
                  // Option 1: Keep Mine
                  InkWell(
                    onTap: () async {
                      Navigator.pop(context);
                      await ref.read(partnerSyncProvider.notifier).resolveConflict(conflict, true);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Resolved: Kept your local version.')),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(10),
                        color: const Color(0xFFE53935).withValues(alpha: 0.04),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Keep My Version', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFE53935), fontFamily: 'Inter')),
                                const SizedBox(height: 4),
                                Text('Balance: ${CurrencyFormatter.format(localBal, syncState.partnerCurrency)}', style: const TextStyle(fontSize: 12, fontFamily: 'Inter')),
                                if (localLimit != null)
                                  Text('Limit: ${CurrencyFormatter.format(localLimit, syncState.partnerCurrency)}', style: const TextStyle(fontSize: 12, fontFamily: 'Inter')),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Color(0xFFE53935)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Option 2: Keep Partner's
                  InkWell(
                    onTap: () async {
                      Navigator.pop(context);
                      await ref.read(partnerSyncProvider.notifier).resolveConflict(conflict, false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Resolved: Kept partner\'s version.')),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.green.withValues(alpha: 0.04),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Keep ${syncState.partnerName}\'s Version', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green, fontFamily: 'Inter')),
                                const SizedBox(height: 4),
                                Text('Balance: ${CurrencyFormatter.format(partnerBal, syncState.partnerCurrency)}', style: const TextStyle(fontSize: 12, fontFamily: 'Inter')),
                                if (partnerLimit != null)
                                  Text('Limit: ${CurrencyFormatter.format(partnerLimit, syncState.partnerCurrency)}', style: const TextStyle(fontSize: 12, fontFamily: 'Inter')),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.green),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(partnerSyncProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0D14) : const Color(0xFFF5F5F7);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A26);
    final subTextColor = isDark ? const Color(0xFFB0B0C0) : const Color(0xFF6C6C7D);

    // Filter transactions that belong to this account
    final List<PartnerTransaction> accountTxs = syncState.partnerTransactions.where((tx) {
      return tx.accountName == widget.account.name;
    }).toList();

    // Locally filter transactions based on search query
    final filteredTxs = accountTxs.where((tx) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final titleMatch = tx.title.toLowerCase().contains(q);
      final noteMatch = tx.note?.toLowerCase().contains(q) ?? false;
      final categoryMatch = tx.categoryName.toLowerCase().contains(q);
      return titleMatch || noteMatch || categoryMatch;
    }).toList();

    final hex = '0xFF${widget.account.color.replaceAll("#", "")}';
    final cardColor = Color(int.tryParse(hex) ?? 0xFFE53935);

    // Check conflict for this account
    final accountConflict = syncState.conflicts.firstWhere(
      (c) => c.type == 'account' && c.name == widget.account.name,
      orElse: () => ConflictRecord(type: '', name: '', localData: {}, partnerData: {}),
    );
    final hasConflict = accountConflict.name.isNotEmpty;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(widget.account.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Conflict warning banner
          if (hasConflict)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFC107).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFB300), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sync Conflict Detected',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'This account has conflicting details on the server.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB300),
                      foregroundColor: Colors.black,
                      minimumSize: const Size(70, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _showConflictResolverDialog(context, syncState, accountConflict),
                    child: const Text(
                      'Resolve',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                    ),
                  ),
                ],
              ),
            ),

          // Header Card showing Account Balance info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GlassmorphismCard(
              color: isDark ? cardColor.withValues(alpha: 0.12) : cardColor.withValues(alpha: 0.06),
              borderColor: cardColor.withValues(alpha: 0.2),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.account.type.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const Icon(
                        Icons.people_outline,
                        color: Colors.grey,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.format(widget.account.balance, syncState.partnerCurrency),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: widget.account.balance >= 0 
                          ? textColor
                          : const Color(0xFFE53935),
                      fontFamily: 'Inter',
                    ),
                  ),
                  if (widget.account.type == 'Credit Card') ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: widget.account.pendingPayment > 0 ? const Color(0xFFE53935) : Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Pending Payment: ${CurrencyFormatter.format(widget.account.pendingPayment < 0 ? 0.0 : widget.account.pendingPayment, syncState.partnerCurrency)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: widget.account.pendingPayment > 0
                                ? const Color(0xFFE53935)
                                : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Sync Freshness Indicator
                  if (syncState.lastSyncTime != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.sync,
                          color: syncState.isSyncing ? Colors.amber : Colors.green,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Last Synced: ${DateFormat('yyyy-MM-dd HH:mm').format(syncState.lastSyncTime!.toLocal())}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Inter'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const Divider(height: 1, thickness: 0.5),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search account transactions...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: TextStyle(color: textColor, fontSize: 13),
            ),
          ),

          // Transactions List
          Expanded(
            child: filteredTxs.isEmpty
                ? Center(
                    child: Text(
                      accountTxs.isEmpty
                          ? 'No transactions logged for this account.'
                          : 'No matching transactions found.',
                      style: TextStyle(color: subTextColor),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredTxs.length,
                    itemBuilder: (context, index) {
                      final tx = filteredTxs[index];
                      
                      // Map to standard transaction object
                      final modelTx = Transaction(
                        title: tx.title,
                        amount: tx.amount,
                        type: tx.type,
                        date: tx.date,
                        note: tx.note,
                        recurrence: tx.recurrence,
                        isPrivate: false,
                        accountId: 0,
                        categoryId: 0,
                        createdAt: tx.date,
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: TransactionListItem(
                          transaction: modelTx,
                          categoryName: tx.categoryName,
                          categoryColorHex: tx.categoryColor,
                          categoryIconKey: tx.categoryIcon,
                          accountName: tx.accountName,
                          currency: syncState.partnerCurrency,
                          onTap: () => _showTransactionDetails(tx, syncState.partnerCurrency),
                          onLongPress: () => _showTransactionDetails(tx, syncState.partnerCurrency),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
