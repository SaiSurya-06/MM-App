import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/account.dart';
import '../../core/utils/currency_formatter.dart';
import '../../widgets/common/glassmorphism_card.dart';
import 'account_card.dart';
import 'account_form.dart';
import 'account_transactions_page.dart';

class AccountsPage extends ConsumerWidget {
  const AccountsPage({Key? key}) : super(key: key);

  void _openAccountForm(BuildContext context, [Account? account]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AccountForm(account: account),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsState = ref.watch(accountsProvider);
    final authState = ref.watch(authProvider);

    final currency = authState.profile?.preferredCurrency ?? 'USD';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 26, width: 26),
            const SizedBox(width: 8),
            const Text('Accounts'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _openAccountForm(context),
            icon: const Icon(Icons.add_card),
          ),
        ],
      ),
      body: accountsState.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)))
          : TweenAnimationBuilder<double>(
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
              child: CustomScrollView(
                slivers: [
                  // Total Balance Summary Card (Bento style)
                  SliverPadding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00ACC1), Color(0xFF4CAF50)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00ACC1).withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AGGREGATE LIQUIDITY',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  CurrencyFormatter.format(
                                    accountsState.accounts.fold<double>(
                                      0.0,
                                      (sum, acc) => acc.type != 'Credit Card' ? sum + acc.balance : sum,
                                    ),
                                    currency,
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                Icon(Icons.account_balance_wallet, color: Colors.white.withOpacity(0.8), size: 24),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Active across ${accountsState.accounts.length} asset classes',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 10,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Credit Utilization Card (Shown only if credit cards exist)
                  ...[
                    (() {
                      final ccAccounts = accountsState.accounts.where((a) => a.type == 'Credit Card').toList();
                      if (ccAccounts.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

                      double totalLimit = 0.0;
                      double totalUsed = 0.0;
                      for (var cc in ccAccounts) {
                        totalLimit += cc.limitAmount ?? 0.0;
                        totalUsed += cc.pendingPayment;
                      }

                      if (totalLimit <= 0.0) return const SliverToBoxAdapter(child: SizedBox.shrink());

                      final utilization = (totalUsed / totalLimit) * 100.0;
                      final isOverLimit = utilization > 100.0;
                      final isHighUtilization = utilization >= 30.0;
                      
                      final Color progressColor = isOverLimit 
                          ? const Color(0xFFE53935) 
                          : (isHighUtilization ? Colors.orange : Colors.green);

                      return SliverPadding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0),
                        sliver: SliverToBoxAdapter(
                          child: GlassmorphismCard(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'CREDIT UTILIZATION',
                                      style: TextStyle(
                                        color: isDark ? Colors.white70 : Colors.black87,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                    Text(
                                      '${utilization.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        color: progressColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: (utilization / 100.0).clamp(0.0, 1.0),
                                    backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Used: ${CurrencyFormatter.format(totalUsed, currency)}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                    Text(
                                      'Limit: ${CurrencyFormatter.format(totalLimit, currency)}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ],
                                ),
                                if (isHighUtilization) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        isOverLimit ? Icons.error_outline : Icons.warning_amber_outlined, 
                                        color: progressColor, 
                                        size: 12
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          isOverLimit 
                                              ? 'Over limit! Pay back immediately.' 
                                              : 'High utilization (>30%). May affect credit score.',
                                          style: TextStyle(
                                            color: progressColor,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }()),
                  ],

                  // My Accounts Section Header
                  SliverPadding(
                    padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 18.0, bottom: 8.0),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'MY ACCOUNTS',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.black45,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),

                  // My Accounts Grid
                  if (accountsState.accounts.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                      sliver: SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              'No financial accounts created yet.',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: ((MediaQuery.of(context).size.width - 32 - 12) / 2) / 172.0,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final account = accountsState.accounts[index];
                            final cardItem = AccountCard(
                              account: account,
                              currency: currency,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AccountTransactionsPage(account: account),
                                  ),
                                );
                              },
                              onLongPress: () => _openAccountForm(context, account),
                            );

                            return Dismissible(
                              key: ValueKey(account.id ?? account.createdAt.millisecondsSinceEpoch),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE53935),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.white,
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                return await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                                    title: const Text('Delete Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    content: Text('Are you sure you want to delete account "${account.name}"? This will delete all its transactions and modify net worth.'),
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
                              },
                              onDismissed: (direction) async {
                                final success = await ref.read(accountsProvider.notifier).deleteAccount(account.id!);
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Deleted "${account.name}"'),
                                      backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                                        ),
                                      ),
                                      action: SnackBarAction(
                                        label: 'Undo',
                                        textColor: const Color(0xFFE53935),
                                        onPressed: () async {
                                          await ref.read(accountsProvider.notifier).restoreAccount(account);
                                        },
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: cardItem,
                            );
                          },
                          childCount: accountsState.accounts.length,
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 40),
                  ),
                ],
              ),
            ),
    );
  }
}
